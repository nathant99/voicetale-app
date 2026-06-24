import SwiftUI
import SwiftData
import Models
import Services
import SharedUI

/// Anthology gallery — every told tale the kid has saved, optionally filtered
/// by mood. Renders from value-type caches per
/// `@.claude/rules/swiftdata.md` § "Zero @Query in Views".
public struct AnthologyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.analyticsService) private var analytics
    @Environment(\.anthologyAudioPlayer) private var audioPlayer
    @Environment(\.forgeAudio) private var forgeAudio
    @State private var tales: [VoiceTaleEntry] = []
    @State private var moods: [AnthologyMoodData] = []
    /// Phase 2 anthology curation — kid-curated mood collections. Refreshed
    /// alongside ``tales`` on appear and after every create / add-tale /
    /// delete mutation.
    @State private var collections: [MoodCollectionData] = []
    /// Active collection filter — `nil` means "show every tale" (subject
    /// to the mood filter below). Not persisted: kid lands on the
    /// all-tales view at every cold launch so collections feel
    /// freshly-browsable rather than sticky.
    @State private var activeCollectionID: UUID?
    /// Sheet toggle for creating a new collection.
    @State private var isPresentingCollectionEditor = false
    /// Persisted filter selection. Survives app relaunches so a kid who
    /// last browsed only "tender" tales lands back on that view. Stored as
    /// the raw mood value (or empty for "all") because `@AppStorage` cannot
    /// box arbitrary Optional value types directly.
    @AppStorage("voicetale.anthology.filter") private var persistedFilterRaw: String = ""
    @State private var moodFilter: VoiceTaleMood?
    /// Pillar Deepening C1 — per-tale CAF export state. The exporter actor is
    /// shared across cards; per-card state lives in the `exportState` dict
    /// keyed by tale id so multiple cards can show "Exporting…" /
    /// "Share as audio" independently.
    @State private var exporter = VoiceTaleExporter()
    @State private var exportState: [UUID: TaleExportState] = [:]
    /// Delight & Polish "Share-worthy moments" — non-nil presents the
    /// published-tale certificate sheet for the given tale. Set by the
    /// per-card "Certificate" affordance; cleared on sheet dismiss.
    /// Per PR-F 2026-06-24 NINTH-round.
    @State private var certificateTale: VoiceTaleEntry?

    public init() {}

    private enum TaleExportState: Equatable {
        case idle
        case exporting
        case ready(URL)
        case failed(String)
    }

    public var body: some View {
        NavigationStack {
            content
                .voiceTaleNavigationTitle("Anthology")
                .onAppear(perform: handleAppear)
                .sheet(isPresented: $isPresentingCollectionEditor) {
                    CollectionEditorView(onSave: handleCreateCollection)
                }
                .sheet(item: $certificateTale) { tale in
                    PublishedTaleCertificateSheet(tale: tale)
                }
        }
    }

    private func handleAppear() {
        moodFilter = AnthologyView.decodeFilter(persistedFilterRaw)
        reload()
    }

    private func toggleCollectionFilter(_ id: UUID) {
        if activeCollectionID == id {
            activeCollectionID = nil
        } else {
            activeCollectionID = id
        }
    }

    /// Called from the editor sheet's Save button. Returns true so the
    /// sheet can dismiss; returns false on `nameEmpty` / `atCapacity` so
    /// the sheet can surface the error to the kid.
    private func handleCreateCollection(_ name: String, _ mood: VoiceTaleMood?) -> Bool {
        do {
            let created = try VoiceTaleStore.createCollection(
                name: name,
                mood: mood,
                in: modelContext
            )
            analytics.track(.anthologyCollectionCreated(mood: mood))
            collections = VoiceTaleStore.fetchCollections(in: modelContext)
            activeCollectionID = created.id
            return true
        } catch {
            return false
        }
    }

    private func handleDeleteCollection(_ id: UUID) {
        VoiceTaleStore.deleteCollection(id: id, in: modelContext)
        if activeCollectionID == id { activeCollectionID = nil }
        collections = VoiceTaleStore.fetchCollections(in: modelContext)
    }

    private func handleAddTaleToCollection(taleID: UUID, collectionID: UUID) {
        VoiceTaleStore.addTaleToCollection(
            collectionID: collectionID,
            taleID: taleID,
            in: modelContext
        )
        collections = VoiceTaleStore.fetchCollections(in: modelContext)
    }

    private func handleRemoveTaleFromCollection(taleID: UUID, collectionID: UUID) {
        VoiceTaleStore.removeTaleFromCollection(
            collectionID: collectionID,
            taleID: taleID,
            in: modelContext
        )
        collections = VoiceTaleStore.fetchCollections(in: modelContext)
    }

    /// Decode the `@AppStorage`-backed raw filter string into a typed
    /// optional mood. Empty / unknown values resolve to `nil` (the "All"
    /// selection). Exposed `static` so the unit test can verify the
    /// round-trip without spinning up a SwiftUI view.
    static func decodeFilter(_ raw: String) -> VoiceTaleMood? {
        guard !raw.isEmpty else { return nil }
        return VoiceTaleMood(rawValue: raw)
    }

    static func encodeFilter(_ mood: VoiceTaleMood?) -> String {
        mood?.rawValue ?? ""
    }

    /// Apply a new filter selection — persists the value and emits a
    /// categorical analytics event. Centralized so the chip taps and any
    /// future programmatic toggles flow through the same path. Fires the
    /// Delight & Polish "Juice layer" selection haptic only on a real
    /// change of value.
    private func applyFilter(_ mood: VoiceTaleMood?) {
        if moodFilter != mood {
            HapticsBridge.fireSelection()
        }
        moodFilter = mood
        persistedFilterRaw = AnthologyView.encodeFilter(mood)
        analytics.track(.anthologyFilterApplied(mood: mood))
    }

    @ViewBuilder
    private var content: some View {
        if tales.isEmpty {
            ContentUnavailableView(
                "No tales yet",
                systemImage: "books.vertical",
                description: Text("Every tale you save lands here. Tag a mood from the Tell tab.")
            )
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    collectionsShelf
                    moodFilterRow
                    moodRetrospectiveCard
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTales) { tale in
                            taleCard(tale)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
    }

    /// Delight & Polish "Share-worthy moments — mood-tag retrospectives".
    /// Surfaces above the filtered tale list when the kid has saved at
    /// least 3 tales of the currently-filtered mood. `MoodRetrospective`
    /// returns `nil` headlines below the 3-tale floor + when no mood
    /// filter is applied, so this view collapses cleanly the rest of
    /// the time. Per `@Docs/FEATURE_PLAN.md` § Delight & Polish.
    @ViewBuilder
    private var moodRetrospectiveCard: some View {
        if let mood = moodFilter,
           let headline = MoodRetrospective.headline(mood: mood, count: filteredTales.count),
           let body = MoodRetrospective.body(mood: mood, count: filteredTales.count) {
            VStack(alignment: .leading, spacing: 6) {
                Text(headline)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
            )
            .padding(.horizontal)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("\(headline) \(body)"))
        }
    }

    /// Horizontal-scrolling shelf of kid-curated collections + a "+ New
    /// collection" leading affordance. Tapping a chip filters the tale
    /// list to that collection; tapping the active chip clears the
    /// filter. Rendered above the mood filter row so the kid sees the
    /// shelves they've already built before the raw mood breakdown.
    private var collectionsShelf: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: { isPresentingCollectionEditor = true }) {
                    Label("New collection", systemImage: "plus.circle.fill")
                        .font(.callout.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color.accentColor.opacity(0.18))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityHint("Create a new mood-themed collection — like 'Bedtime spooks' or 'Funny five'.")
                ForEach(collections) { collection in
                    collectionChip(collection)
                }
            }
            .padding(.horizontal)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Collections shelf"))
    }

    private func collectionChip(_ collection: MoodCollectionData) -> some View {
        let isActive = activeCollectionID == collection.id
        return Button(action: { toggleCollectionFilter(collection.id) }) {
            HStack(spacing: 6) {
                Text(collection.name)
                    .font(.callout)
                Text("\(collection.taleCount)")
                    .font(.caption.monospacedDigit())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(Color.secondary.opacity(0.18))
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(isActive ? Color.accentColor.opacity(0.22) : Color.secondary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                handleDeleteCollection(collection.id)
            } label: {
                Label("Delete collection", systemImage: "trash")
            }
        }
        .accessibilityLabel(Text(collectionAccessibilityLabel(for: collection)))
        .accessibilityHint(
            isActive
                ? Text("Tap to clear the collection filter.")
                : Text("Show only the tales in this collection.")
        )
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    private func collectionAccessibilityLabel(for collection: MoodCollectionData) -> String {
        let mood = collection.mood?.displayLabel ?? "Any mood"
        let pluralized = collection.taleCount == 1 ? "tale" : "tales"
        return "\(collection.name), \(mood), \(collection.taleCount) \(pluralized)"
    }

    private var moodFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: { applyFilter(nil) }) {
                    Label("All", systemImage: "tray.full")
                        .font(.callout)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(moodFilter == nil ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityHint(
                    moodFilter == nil
                        ? Text("Showing every saved tale.")
                        : Text("Clear the mood filter to see every saved tale.")
                )
                .accessibilityAddTraits(moodFilter == nil ? [.isSelected] : [])
                ForEach(VoiceTaleMood.allCases, id: \.self) { mood in
                    Button(action: { applyFilter(mood) }) {
                        MoodTagView(mood: mood, isSelected: moodFilter == mood)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(
                        moodFilter == mood
                            ? Text("Showing only \(mood.displayLabel.lowercased()) tales.")
                            : Text("Filter the gallery to only \(mood.displayLabel.lowercased()) tales.")
                    )
                }
            }
            .padding(.horizontal)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Mood filter"))
    }

    private func taleCard(_ tale: VoiceTaleEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tale.title)
                    .font(.headline)
                Spacer()
                addToCollectionMenu(for: tale)
                MoodTagView(mood: tale.mood)
            }
            Text(tale.recordedAt, format: .relative(presentation: .named))
                .font(.caption)
                .foregroundStyle(.secondary)
            if !tale.transcript.isEmpty {
                Text(tale.transcript)
                    .font(.callout)
                    .lineLimit(3)
                    .foregroundStyle(.primary)
            }
            if let reflection = tale.reflection, let first = reflection.craftObservations.first {
                Text("\u{201C}\(first)\u{201D}")
                    .font(.footnote.italic())
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Label("\(Int(tale.durationSeconds))s", systemImage: "clock")
                Label("\(tale.beatTimeline.filter(\.isWithinTolerance).count)/\(tale.beatTimeline.count) beats", systemImage: "circle.dotted")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            playbackRow(for: tale)
            exportRow(for: tale)
            certificateRow(for: tale)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    /// "Listen back" row — plays the saved recording via
    /// ``AnthologyAudioPlayer``. The shared player guarantees only one tale
    /// plays at a time across the whole anthology; tapping a second card
    /// stops the first. ``ForgeAudioBridge`` ducks any (future) ambient
    /// music under the kid's voice for the duration of playback.
    @ViewBuilder
    private func playbackRow(for tale: VoiceTaleEntry) -> some View {
        if let audioURL = VoiceTaleStore.audioFileURL(for: tale.id, in: modelContext) {
            let isActive = audioPlayer.isActive(for: audioURL)
            let isPlaying = isActive && audioPlayer.state == .playing
            HStack(spacing: 10) {
                Button {
                    togglePlayback(for: tale, audioURL: audioURL)
                } label: {
                    Label(
                        isPlaying ? "Pause" : "Listen back",
                        systemImage: isPlaying ? "pause.circle.fill" : "play.circle.fill"
                    )
                    .font(.callout.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityHint(isPlaying
                    ? Text("Pause this tale.")
                    : Text("Play this tale back to listen to it again."))
                if isActive, audioPlayer.totalSeconds > 0 {
                    ProgressView(value: audioPlayer.progressFraction)
                        .progressViewStyle(.linear)
                        .tint(Color.accentColor)
                        .accessibilityLabel(Text("Playback progress"))
                        .accessibilityValue(Text("\(Int(audioPlayer.progressFraction * 100)) percent"))
                    Text(formattedTime(audioPlayer.elapsedSeconds))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        }
    }

    private func togglePlayback(for tale: VoiceTaleEntry, audioURL: URL) {
        if audioPlayer.isActive(for: audioURL), audioPlayer.state == .playing {
            audioPlayer.pause()
            forgeAudio.unduckIfNeeded()
        } else {
            forgeAudio.duckForSpeechIfNeeded()
            audioPlayer.play(fileURL: audioURL)
        }
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    /// Pillar Deepening C1 export affordance. State machine:
    ///
    /// - `.idle`: shows "Share as audio" button → tap triggers export
    /// - `.exporting`: shows a small ProgressView + "Preparing…"
    /// - `.ready(url)`: surfaces a `ShareLink` with the canonical CAF
    /// - `.failed(msg)`: shows a one-line apology + retry affordance
    ///
    /// Rendered only for tales that have an on-disk audio file (legacy
    /// transcript-only saves silently omit the row).
    @ViewBuilder
    private func exportRow(for tale: VoiceTaleEntry) -> some View {
        if let audioURL = VoiceTaleStore.audioFileURL(for: tale.id, in: modelContext) {
            let state = exportState[tale.id] ?? .idle
            HStack(spacing: 8) {
                // Waveform glyph is decorative — the adjacent button/share
                // surfaces own the semantic labeling. Marking the icon hidden
                // prevents VoiceOver from double-announcing. Per FEATURE_PLAN
                // line 135 "waveform a11y alternative for the export button" —
                // the ALTERNATIVE is the screen-reader-clean labeled control
                // next to it, NOT a verbose label on the icon itself.
                Image(systemName: "waveform")
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                switch state {
                case .idle:
                    Button("Share as audio") {
                        runExport(taleID: tale.id, sourceURL: audioURL)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityHint("Convert this tale to a canonical CAF audio file and share via the system share sheet.")
                case .exporting:
                    ProgressView()
                        .controlSize(.small)
                    Text("Preparing audio…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Preparing audio for sharing")
                case .ready(let url):
                    ShareLink(item: url) {
                        Label("Share audio", systemImage: "square.and.arrow.up")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .accessibilityHint("Share this tale's audio via the system share sheet.")
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            emitVoiceRecordingShared(for: tale)
                        }
                    )
                case .failed(let message):
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .accessibilityLabel("Audio share failed: \(message)")
                    Button("Retry") {
                        runExport(taleID: tale.id, sourceURL: audioURL)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityHint("Try the audio export again.")
                }
            }
            .padding(.top, 4)
        }
    }

    /// Fires `voiceRecordingShared` on the analytics engine when the user
    /// taps the `ShareLink`. Categorical-only payload (mood + bucketed
    /// duration); no PII per `Docs/TECHNICAL_DESIGN.md` § Analytics. Tap
    /// detection uses `.simultaneousGesture` because `ShareLink` doesn't
    /// expose an `onTap` callback in iOS 26.
    private func emitVoiceRecordingShared(for tale: VoiceTaleEntry) {
        analytics.track(
            .voiceRecordingShared(mood: tale.mood, durationSeconds: tale.durationSeconds)
        )
    }

    /// Delight & Polish "Share-worthy moments" — "Certificate" affordance
    /// per tale card. Opens ``PublishedTaleCertificateSheet`` which
    /// renders a kid-readable SwiftUI card the kid can save via the
    /// system share sheet (rasterized to PNG by `ImageRenderer`).
    /// Per @Docs/FEATURE_PLAN.md § Phase Delight & Polish — Share-worthy
    /// moments — published-tale certificates carry-over.
    private func certificateRow(for tale: VoiceTaleEntry) -> some View {
        Button {
            certificateTale = tale
        } label: {
            Label("Certificate", systemImage: "rosette")
                .font(.callout.weight(.semibold))
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityHint("Open a printable certificate card for this tale.")
    }

    /// Kicks off the CAF export off the MainActor + folds the result into
    /// per-tale state. The exporter is idempotent so retries are cheap.
    private func runExport(taleID: UUID, sourceURL: URL) {
        exportState[taleID] = .exporting
        Task {
            do {
                let url = try await exporter.exportCAF(from: sourceURL)
                exportState[taleID] = .ready(url)
            } catch {
                exportState[taleID] = .failed("Couldn't prep audio (\(error.localizedDescription)).")
            }
        }
    }

    /// Per-tale "Add to..." menu. Surfaces every collection in a Menu;
    /// each row toggles membership (Add when absent, Remove when
    /// present). When no collections exist yet, the menu shows the same
    /// "New collection" entry point as the shelf so the kid can curate
    /// inline.
    @ViewBuilder
    private func addToCollectionMenu(for tale: VoiceTaleEntry) -> some View {
        Menu {
            if collections.isEmpty {
                Button {
                    isPresentingCollectionEditor = true
                } label: {
                    Label("New collection…", systemImage: "plus.circle")
                }
            } else {
                ForEach(collections) { collection in
                    let isMember = collection.contains(tale.id)
                    Button {
                        if isMember {
                            handleRemoveTaleFromCollection(taleID: tale.id, collectionID: collection.id)
                        } else {
                            handleAddTaleToCollection(taleID: tale.id, collectionID: collection.id)
                        }
                    } label: {
                        Label(
                            collection.name,
                            systemImage: isMember ? "checkmark.circle.fill" : "circle"
                        )
                    }
                }
                Divider()
                Button {
                    isPresentingCollectionEditor = true
                } label: {
                    Label("New collection…", systemImage: "plus.circle")
                }
            }
        } label: {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.callout)
                .padding(6)
        }
        .accessibilityLabel(Text("Add to collection"))
        .accessibilityHint(Text("Add this tale to one of your collections, or create a new one."))
    }

    private var filteredTales: [VoiceTaleEntry] {
        var working = tales
        if let activeCollectionID,
           let active = collections.first(where: { $0.id == activeCollectionID }) {
            let allowed = Set(active.taleIDs)
            working = working.filter { allowed.contains($0.id) }
        }
        if let moodFilter {
            working = working.filter { $0.mood == moodFilter }
        }
        return working
    }

    private func reload() {
        tales = VoiceTaleStore.fetchTales(in: modelContext)
        moods = VoiceTaleStore.fetchAnthologyMoods(in: modelContext)
        collections = VoiceTaleStore.fetchCollections(in: modelContext)
    }
}
