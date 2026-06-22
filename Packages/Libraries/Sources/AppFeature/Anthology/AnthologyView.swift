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
    @State private var moodFilter: VoiceTaleMood?
    /// Pillar Deepening C1 — per-tale CAF export state. The exporter actor is
    /// shared across cards; per-card state lives in the `exportState` dict
    /// keyed by tale id so multiple cards can show "Exporting…" /
    /// "Share as audio" independently.
    @State private var exporter = VoiceTaleExporter()
    @State private var exportState: [UUID: TaleExportState] = [:]

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
                .onAppear(perform: reload)
        }
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
                    moodFilterRow
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

    private var moodFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: { moodFilter = nil }) {
                    Label("All", systemImage: "tray.full")
                        .font(.callout)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(moodFilter == nil ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                ForEach(VoiceTaleMood.allCases, id: \.self) { mood in
                    Button(action: { moodFilter = mood }) {
                        MoodTagView(mood: mood, isSelected: moodFilter == mood)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private func taleCard(_ tale: VoiceTaleEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tale.title)
                    .font(.headline)
                Spacer()
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

    private var filteredTales: [VoiceTaleEntry] {
        guard let moodFilter else { return tales }
        return tales.filter { $0.mood == moodFilter }
    }

    private func reload() {
        tales = VoiceTaleStore.fetchTales(in: modelContext)
        moods = VoiceTaleStore.fetchAnthologyMoods(in: modelContext)
    }
}
