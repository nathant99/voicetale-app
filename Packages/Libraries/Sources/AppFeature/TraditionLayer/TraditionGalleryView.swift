import SwiftUI
import SwiftData
import Models
import Services
import SharedUI
import ForgeCelebration

/// Tradition gallery — 5 short kid-readable explainers of oral-storytelling
/// lineages. Per `@.claude/rules/trauma-informed-content.md` §
/// Cultural-sensitivity gates, every entry surfaces an explicit
/// cultural-credit note + optional content warning. The Indigenous-oral-
/// histories card defaults to its content warning expanded.
public struct TraditionGalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.gamificationService) private var gamification
    @Environment(\.analyticsService) private var analytics
    @Environment(\.celebrationCoordinator) private var celebration
    @Environment(\.sessionTally) private var sessionTally
    @State private var catalog: TraditionCatalog?
    @State private var loadError: String?
    /// Delight & Polish "Discovery" micro-delight — count of traditions
    /// the kid has not yet expanded. Drives the discovery callout above
    /// the gallery list. Recomputed on appear + after each `onExplore`
    /// tap (since expanding a tradition turns it from "unexplored" →
    /// "explored").
    @State private var unexploredCount: Int = 0
    /// Easter-eggs Phase C — snapshot of the kid's progress fed into
    /// ``TraditionUnlockEvaluator`` to decide which easter-egg entries
    /// surface in the rendered list. Rebuilt on appear + after each
    /// `onExplore` tap (since exploring a tradition advances both the
    /// expanded set + the per-tradition listen count). Per
    /// `@Docs/PLAN_EASTER_EGGS_TRADITION_UNLOCKS.md` § Phase C.
    @State private var unlockSnapshot: TraditionUnlockSnapshot = TraditionUnlockSnapshot()

    public init() {}

    public var body: some View {
        NavigationStack {
            content
                .voiceTaleNavigationTitle("Traditions")
                .onAppear(perform: load)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let catalog {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    catalogIntro
                    if let calloutCopy = Self.discoveryCalloutCopy(unexploredCount: unexploredCount) {
                        traditionDiscoveryCallout(calloutCopy)
                    }
                    ForEach(visibleEntries(in: catalog)) { entry in
                        TraditionCard(entry: entry, onExplore: {
                            VoiceTaleStore.recordTraditionExplored(slug: entry.slug, in: modelContext)
                            let outcome = gamification.awardXP(
                                for: .traditionExplored(slug: entry.slug),
                                in: modelContext
                            )
                            if outcome.leveledUp {
                                celebration.levelUp(newLevel: outcome.newLevel)
                            }
                            for badge in outcome.newBadges {
                                celebration.badgeEarned(title: badge.title)
                                sessionTally.recordBadgeEarned(title: badge.title)
                            }
                            analytics.track(.traditionExplored(slug: entry.slug))
                            // Surprise micro-delight tradition-echo signal —
                            // record the tradition's craft-register slugs so
                            // ``TellView.deriveSurpriseMomentIfAny()`` can fire
                            // ``SurpriseMoment.traditionEchoSameSession`` when
                            // the kid tells a tale in a matching mood within
                            // the same sitting. Per PR-B 2026-06-24 NINTH-round.
                            sessionTally.recordTraditionExpanded(slug: entry.slug)
                            // Discovery callout updates as the kid expands
                            // traditions — pull the next iteration of
                            // unexplored count from the persistence layer.
                            recomputeUnexploredCount()
                            // Phase C — rebuild the unlock snapshot so any
                            // easter-egg entry whose predicate just flipped to
                            // true becomes visible on the next render.
                            rebuildUnlockSnapshot()
                        })
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        } else if let loadError {
            ContentUnavailableView(
                "Couldn't load traditions",
                systemImage: "exclamationmark.triangle",
                description: Text(loadError)
            )
        } else {
            ProgressView().padding()
        }
    }

    private var catalogIntro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Honor the storytellers before us")
                .font(.title3.weight(.semibold))
            Text("Five oral-storytelling traditions, credited to the communities they belong to. You can listen, learn, and leave knowing where the craft of telling came from.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    /// Delight & Polish "Discovery" micro-delight — surfaces a Bramble-
    /// register callout above the tradition list inviting the kid to
    /// pull a tradition card closer when they're ready. Per
    /// `@Docs/AUDIT_MICRO_DELIGHT_COVERAGE_2026-06-24.md` § Yellow —
    /// Discovery expansion.
    @ViewBuilder
    private func traditionDiscoveryCallout(_ copy: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(.tint)
            Text(copy)
                .font(.callout)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Discovery hint: \(copy)"))
    }

    /// Pure-function copy resolver for the discovery callout. Returns
    /// `nil` when the kid has explored every tradition (no callout
    /// needed) — the copy never names the count, never frames remaining
    /// traditions as deficient.
    ///
    /// Public + `nonisolated` so unit tests can exercise the resolver
    /// without spinning up the SwiftUI host.
    nonisolated public static func discoveryCalloutCopy(unexploredCount: Int) -> String? {
        guard unexploredCount > 0 else { return nil }
        if unexploredCount == 1 {
            return "One tradition is waiting — pull it closer when you're ready."
        }
        return "More traditions are waiting — pull one closer when you're ready."
    }

    private func load() {
        guard catalog == nil else { return }
        do {
            catalog = try TraditionCatalogLoader.loadBundled()
            recomputeUnexploredCount()
            // Phase C — build the initial unlock snapshot so the very
            // first render correctly filters easter-eggs (today the
            // catalog ships ZERO easter-egg entries; this is wiring,
            // not behavior change).
            rebuildUnlockSnapshot()
        } catch {
            loadError = "\(error)"
        }
    }

    /// Easter-eggs Phase C — rebuild the kid's progress snapshot from
    /// the persistence layer so the unlock evaluator can re-decide which
    /// easter-egg entries surface. Idempotent and cheap. Per
    /// `@Docs/PLAN_EASTER_EGGS_TRADITION_UNLOCKS.md` § Phase C.
    private func rebuildUnlockSnapshot() {
        unlockSnapshot = Self.buildSnapshot(in: modelContext)
    }

    /// Pure-function snapshot builder for the easter-eggs Phase C
    /// evaluator. Public + `nonisolated` so unit tests can exercise the
    /// derivation against an in-memory ``ModelContext`` without
    /// instantiating the SwiftUI host.
    ///
    /// Sources, all already-shipped:
    /// - `VoiceTaleStore.fetchTraditionExploration` → expanded slugs +
    ///   per-tradition listen counts
    /// - `VoiceTaleStore.fetchTales` → saved-tale count + moods covered
    /// - `VoiceTaleStore.fetchProgress` → completed kit IDs
    @MainActor
    public static func buildSnapshot(in modelContext: ModelContext) -> TraditionUnlockSnapshot {
        let exploration = VoiceTaleStore.fetchTraditionExploration(in: modelContext)
        let expandedSlugs = Set(
            exploration.compactMap { $0.firstExploredAt != nil ? $0.slug : nil }
        )
        var revisitCount: [String: Int] = [:]
        for record in exploration {
            if record.listenCount > 0 {
                revisitCount[record.slug] = record.listenCount
            }
        }
        let tales = VoiceTaleStore.fetchTales(in: modelContext)
        let moodsCovered = Set(tales.map(\.mood))
        let kitsCompleted = VoiceTaleStore.progressSnapshot(in: modelContext).completedKitIDs
        return TraditionUnlockSnapshot(
            expandedBaseTraditions: expandedSlugs,
            savedTales: tales.count,
            moodsCovered: moodsCovered,
            kitsCompleted: kitsCompleted,
            traditionRevisitCount: revisitCount
        )
    }

    /// Easter-eggs Phase C — entries the gallery should render against
    /// the current snapshot. Base-tier entries are always visible;
    /// easter-egg entries appear ONLY when their unlock condition
    /// resolves true through ``TraditionUnlockEvaluator``. An
    /// easter-egg entry whose `unlockCondition` is `nil` is treated as
    /// gate-failed (a defensive default — Phase D submission MUST set a
    /// condition string; the catalog never ships a nil-condition
    /// easter-egg). Today the catalog ships ZERO easter-egg entries
    /// (gated on Phase D external reviewer per ADR-016) — this filter
    /// is wiring, not behavior change.
    ///
    /// Public + `nonisolated` so unit tests can exercise the filter
    /// against a constructed catalog without a SwiftUI host.
    nonisolated public static func filteredVisibleEntries(
        in catalog: TraditionCatalog,
        snapshot: TraditionUnlockSnapshot
    ) -> [TraditionEntry] {
        catalog.entries.filter { entry in
            if entry.isEasterEgg == false {
                return true
            }
            guard let condition = entry.unlockCondition else {
                // Gate-failed default — never surface an easter-egg
                // whose author forgot to set an unlock predicate.
                return false
            }
            return TraditionUnlockEvaluator.isUnlocked(
                condition: condition,
                snapshot: snapshot
            )
        }
    }

    /// Convenience wrapper around ``filteredVisibleEntries(in:snapshot:)``
    /// using the view's own `unlockSnapshot` state.
    private func visibleEntries(in catalog: TraditionCatalog) -> [TraditionEntry] {
        Self.filteredVisibleEntries(in: catalog, snapshot: unlockSnapshot)
    }

    /// Reads the catalog + the explored-tradition persistence layer to
    /// compute how many catalog entries have NOT yet been expanded.
    /// Idempotent and cheap — called on appear + after each `onExplore`
    /// tap so the discovery callout fades correctly as the kid pulls
    /// traditions closer one by one.
    private func recomputeUnexploredCount() {
        guard let catalog else { return }
        let explored = Set(
            VoiceTaleStore.fetchTraditionExploration(in: modelContext)
                .compactMap { $0.firstExploredAt != nil ? $0.slug : nil }
        )
        unexploredCount = catalog.entries.reduce(into: 0) { count, entry in
            if !explored.contains(entry.slug) {
                count += 1
            }
        }
    }
}

private struct TraditionCard: View {
    let entry: TraditionEntry
    let onExplore: () -> Void

    @State private var isExpanded: Bool = false
    @State private var showContentWarning: Bool
    /// Shared anthology audio player — already env-injected at AppRootView
    /// scope so a single AVAudioPlayer instance drives both tale playback
    /// + tradition-sample playback. Reuse keeps AVAudioSession management
    /// in one place per `@.claude/rules/audio-pipeline.md`.
    @Environment(\.anthologyAudioPlayer) private var audioPlayer

    init(entry: TraditionEntry, onExplore: @escaping () -> Void) {
        self.entry = entry
        self.onExplore = onExplore
        // Default-expand the content warning on the Indigenous entry so the
        // kid sees it before tapping in.
        self._showContentWarning = State(initialValue: entry.contentWarning != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.displayName)
                    .font(.headline)
                Spacer()
                Text(entry.region)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 180)
            }
            if let warning = entry.contentWarning, showContentWarning {
                Label(warning, systemImage: "exclamationmark.shield.fill")
                    .font(.footnote)
                    .padding(10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.primary)
            }
            if isExpanded {
                Text(entry.summary)
                    .font(.body)
                Text("Craft primitive — \(entry.craftPrimitive)")
                    .font(.callout.italic())
                    .foregroundStyle(.secondary)
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cultural credit")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(entry.culturalCreditNote)
                        .font(.footnote)
                }
            } else {
                Text(entry.summary)
                    .font(.body)
                    .lineLimit(3)
            }
            HStack(spacing: 8) {
                Button(isExpanded ? "Show less" : "Read more") {
                    isExpanded.toggle()
                    if isExpanded { onExplore() }
                }
                .buttonStyle(.bordered)
                // PR-E (TENTH round) — play affordance gated on
                // `TraditionAudioCatalog`. Renders ONLY when a bundled
                // CAF exists for the entry. With zero audio samples in
                // the bundle today (labsmith asset gen pending per
                // `@Docs/HANDOFF_FROM_APP_TRADITION_AUDIO_SAMPLES.md`),
                // the affordance is silently absent — kid sees no
                // half-broken play button.
                if TraditionAudioCatalog.hasPlayableSample(for: entry) {
                    audioSampleButton
                }
                Spacer()
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text(accessibilityHint))
    }

    /// Audio sample affordance — only mounted when the catalog confirms
    /// a bundled CAF exists. Reuses the shared ``AnthologyAudioPlayer``
    /// from the environment so tradition playback ducks under the same
    /// AVAudioSession the anthology already manages.
    @ViewBuilder
    private var audioSampleButton: some View {
        if let url = TraditionAudioCatalog.resolveBundleURL(for: entry) {
            Button {
                playSample(at: url)
            } label: {
                Label("Listen", systemImage: audioIsPlaying(at: url) ? "stop.circle.fill" : "play.circle.fill")
                    .font(.callout)
            }
            .buttonStyle(.bordered)
            .accessibilityHint(audioIsPlaying(at: url)
                               ? Text("Stop the sample.")
                               : Text("Play a short sample of this tradition."))
        }
    }

    private func playSample(at url: URL) {
        if audioIsPlaying(at: url) {
            audioPlayer.stop()
        } else {
            audioPlayer.play(fileURL: url)
        }
    }

    private func audioIsPlaying(at url: URL) -> Bool {
        audioPlayer.isActive(for: url) && audioPlayer.state == .playing
    }

    /// VoiceOver label combining tradition name + region + cultural-credit
    /// register so the kid can scan the gallery without expanding every card.
    private var accessibilityLabel: String {
        var label = "\(entry.displayName), from \(entry.region)"
        if let warning = entry.contentWarning, showContentWarning {
            label += ". Content note: \(warning)"
        }
        return label
    }

    private var accessibilityHint: String {
        isExpanded
            ? "Tap Show less to collapse the explainer."
            : "Tap Read more to expand the explainer and read the cultural-credit note."
    }
}
