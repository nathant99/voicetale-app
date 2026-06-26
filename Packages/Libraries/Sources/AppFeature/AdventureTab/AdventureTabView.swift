import SwiftUI
import SwiftData
import Models
import Services
import SharedUI
import ForgeProgression
import ForgeAdventure
import ForgeModels

/// Phase 1 Adventure tab — surfaces the Word Workshop zone as 4 mode-cards
/// driven by a ``ForgeProgressionManager`` so the unlock thresholds match
/// `@Docs/FEATURE_PLAN.md` § Adventure Mode (3 / 5 / 7 saved tales).
///
/// The cards are kept hand-authored at Phase 1 because the Level-2
/// ``VoiceTaleHubContribution`` Quest-engine surface is the canonical entry
/// point (registered on the shared ``HubContributionRegistry`` at app launch
/// via ``AppRootView``); future Phase 1.1 / 2 work will surface mode-cards
/// directly from the contribution's `kitResources`.
public struct AdventureTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.kitMasteryStore) private var kitMasteryStore
    @Environment(\.analyticsService) private var analytics
    /// ForgeMasteryEngine Phase D second-half — cross-tab coordinator
    /// the deeper-challenge affordance pill posts to when tapped. The
    /// kid's Tell-tab recording start consumes the pending context +
    /// applies the catalog-sourced "I noticed you went deeper there"
    /// register at reflection time. `nil` on preview / unbootstrapped
    /// test surfaces — the pill silently degrades to a no-op
    /// (preserves the canonical mode-card-tap behavior).
    @Environment(\.recordingContextCoordinator) private var recordingContextCoordinator
    @State private var talesSavedCount: Int = 0
    @State private var isPresentingTaleTrial = false
    /// ForgeMasteryEngine Phase D — tracks which modes have already
    /// emitted ``deeperChallengeAvailable(mode:)`` this appearance so
    /// the analytics surface stays one-fire-per-mode. Cleared on
    /// disappear via `.id`-driven re-init; the round-trip from
    /// `.appear → .disappear → .appear` re-emits per the existing
    /// view-state convention.
    @State private var emittedDeeperChallengeModes: Set<String> = []
    /// EIGHTEENTH-round parity polish — tracks which (mode, kind)
    /// pairs have already emitted
    /// ``practiceWithBrambleAvailable(mode:kind:)`` this appearance so
    /// the analytics surface stays one-fire-per-mode-per-kind. Keyed
    /// by `"\(mode)|\(kind)"` so a card that swings from `.extend` →
    /// `.consolidate` between appearances re-emits cleanly.
    @State private var emittedPracticeBrambleBadges: Set<String> = []
    private let badgeRecommender = KitMasteryRecommender()

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    let manager = VoiceTaleProgressionGate.makeManager(
                        talesSavedCount: talesSavedCount
                    )
                    ForEach(modes, id: \.gateID) { mode in
                        modeCard(mode, manager: manager)
                    }
                }
                .padding()
            }
            .voiceTaleNavigationTitle("Word Workshop")
            .onAppear(perform: refreshTalesCount)
            .sheet(isPresented: $isPresentingTaleTrial) {
                TaleTrialView()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Word Workshop")
                .font(.title2.weight(.semibold))
            Text("Sharpen one piece of told-tale craft at a time. Modes unlock as you tell more.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func modeCard(_ mode: ModeCard, manager: ForgeProgressionManager) -> some View {
        let isUnlocked = manager.isUnlocked(mode.gateID)
        let unlockHint = manager.unlockHint(for: mode.gateID) ?? ""
        let isTrialEntry = (mode.gateID == VoiceTaleProgressionGate.taleTrialID && isUnlocked)
        if isTrialEntry {
            Button {
                isPresentingTaleTrial = true
            } label: {
                modeCardBody(
                    mode: mode,
                    isUnlocked: isUnlocked,
                    unlockHint: unlockHint
                )
            }
            .buttonStyle(.plain)
        } else {
            modeCardBody(
                mode: mode,
                isUnlocked: isUnlocked,
                unlockHint: unlockHint
            )
        }
    }

    private func modeCardBody(
        mode: ModeCard,
        isUnlocked: Bool,
        unlockHint: String
    ) -> some View {
        let deeperChallenge = deeperChallenge(for: mode, isUnlocked: isUnlocked)
        let badge = practiceBadge(for: mode, isUnlocked: isUnlocked, deeperChallengePresent: deeperChallenge != nil)
        return HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(mode.color.opacity(0.18))
                    .frame(width: 56, height: 56)
                Image(systemName: mode.systemImage)
                    .font(.system(size: 24))
                    .foregroundStyle(mode.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(mode.title)
                        .font(.headline)
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                Text(mode.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !isUnlocked {
                    Text(unlockHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let deeperChallenge {
                    deeperChallengePill(
                        copy: deeperChallenge.copy,
                        tint: mode.color,
                        kit: deeperChallenge.kit,
                        gateID: mode.gateID
                    )
                } else if let badge {
                    practiceBadgeView(badge: badge, tint: mode.color)
                }
            }
            Spacer()
        }
        .padding(16)
        .modifier(NavGridCardSurface(tint: mode.color, reduceTransparency: reduceTransparency))
        .opacity(isUnlocked ? 1 : 0.6)
        .accessibilityHint(isUnlocked ? "Open this Word Workshop mode" : "Locked: \(unlockHint)")
        .onAppear {
            if deeperChallenge != nil {
                emitDeeperChallengeAnalyticsOnce(for: mode.gateID)
            } else if let badge {
                emitPracticeBadgeAnalyticsOnce(for: mode.gateID, kind: badge.kind)
            }
        }
    }

    /// ForgeMasteryEngine Phase D — small kid-readable pill that
    /// surfaces ONLY on unlocked + mapped mode-cards whose dominant kit
    /// crosses the edge-of-competence threshold per
    /// ``DeeperChallengeAffordance/masteryThreshold``. Copy is sourced
    /// from ``KitMasteryCopyCatalog`` (single seam; anti-shame token
    /// blocklist enforced at the catalog).
    ///
    /// Phase D second-half: the pill is now a `Button` — tapping it
    /// posts the deeper-challenge `kit` to
    /// ``RecordingContextCoordinator`` AND routes the kid to the Tell
    /// tab via ``IntentTabCoordinator`` so the next recording start
    /// reads the pending context + Bramble's reflection opens with the
    /// catalog-sourced "I noticed you went deeper there" register.
    /// Per `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D
    /// second-half.
    private func deeperChallengePill(
        copy: String,
        tint: Color,
        kit: KitID,
        gateID: String
    ) -> some View {
        Button {
            handleDeeperChallengeTap(kit: kit, gateID: gateID)
        } label: {
            Label {
                Text(copy)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
            } icon: {
                Image(systemName: DeeperChallengeAffordance.symbolName)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.14), in: Capsule())
            .foregroundStyle(tint)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
        .accessibilityHint("Bramble has a curiosity for this mode. Tap to start a tale.")
    }

    /// Handle a deeper-challenge pill tap. Posts the kit context to
    /// the cross-tab coordinator + routes the kid to the Tell tab via
    /// ``IntentTabCoordinator`` so the next recording start applies
    /// the deeper-challenge register on Bramble's reflection. Fires
    /// the categorical ``deeperChallengeTaleStarted(mode:)`` analytics
    /// event — the mode raw value travels, the kit + the mastery
    /// score + Bramble copy NEVER travel (anti-fingerprinting per
    /// COPPA-2026 anti-PII). Silently degrades to "tab switch only"
    /// when the coordinator env value is `nil` (preview / test
    /// surfaces).
    private func handleDeeperChallengeTap(kit: KitID, gateID: String) {
        let raw = analyticsModeRawValue(for: gateID)
        analytics.track(.deeperChallengeTaleStarted(mode: raw))
        recordingContextCoordinator?.setPendingContext(
            TaleRecordingContext(deeperChallengeKit: kit)
        )
        IntentTabCoordinator.shared.request(destination: .tell)
    }

    /// Resolve the deeper-challenge copy + dominant kit for a mode-card.
    /// Returns `nil` when the card is locked, when the mode is unmapped
    /// (Tale Trial), when the store is unbootstrapped, or when the
    /// kid's mastery on the dominant kit hasn't crossed the
    /// ``DeeperChallengeAffordance/masteryThreshold``. The kit is
    /// included so the pill tap handler can post the deeper-challenge
    /// context to ``RecordingContextCoordinator`` (Phase D second-half).
    private func deeperChallenge(
        for mode: ModeCard,
        isUnlocked: Bool
    ) -> (copy: String, kit: KitID)? {
        guard isUnlocked else { return nil }
        guard let store = kitMasteryStore else { return nil }
        guard let kit = ModeMasteryMapping.dominantKit(forGateID: mode.gateID) else { return nil }
        let score = store.state(for: kit).masteryScore
        guard DeeperChallengeAffordance.shouldSurface(masteryScore: score) else { return nil }
        return (DeeperChallengeAffordance.brambleCopy(for: kit), kit)
    }

    /// Resolve the practice-with-Bramble badge for a mode-card.
    /// Returns `nil` when the card is locked, when the mode is unmapped
    /// (Tale Trial), when the store is unbootstrapped, when the
    /// deeper-challenge pill is already lit (no double-render), or
    /// when the engine surfaces no `.extend` / `.consolidate`
    /// recommendation for the dominant kit. Delegates to
    /// ``Services/Adaptive/PracticeWithBrambleBadge`` which preserves
    /// the catalog single-seam discipline.
    private func practiceBadge(
        for mode: ModeCard,
        isUnlocked: Bool,
        deeperChallengePresent: Bool
    ) -> KitMasteryRecommendation? {
        guard isUnlocked else { return nil }
        guard !deeperChallengePresent else { return nil }
        guard let store = kitMasteryStore else { return nil }
        guard let kit = ModeMasteryMapping.dominantKit(forGateID: mode.gateID) else { return nil }
        return PracticeWithBrambleBadge.badge(
            for: kit,
            masteryStates: store.cachedStates,
            recommender: badgeRecommender
        )
    }

    /// EIGHTEENTH-round parity polish — small-register badge that
    /// surfaces ONLY on unlocked + mapped mode-cards whose dominant
    /// kit lands in the `.extend` or `.consolidate` recommendation
    /// band. Symbol comes from ``KitMasteryCopyCatalog/Kind/symbolName``
    /// (`leaf.fill` / `arrow.clockwise.circle.fill`) — anti-judgment
    /// shapes per the catalog's existing blocklist.
    ///
    /// Informational badge — NOT a `Button` (the `.stretch` pill on
    /// Adventure owns the tap-to-act path via
    /// ``RecordingContextCoordinator``; the broader `.extend` /
    /// `.consolidate` tap-to-act path lives on
    /// ``AppFeature/ProgressTab/ProgressTabView``'s three-card surface).
    @ViewBuilder
    private func practiceBadgeView(
        badge: KitMasteryRecommendation,
        tint: Color
    ) -> some View {
        Label {
            Text(badge.brambleCopy)
                .font(.caption2.weight(.medium))
                .lineLimit(2)
        } icon: {
            Image(systemName: badge.kind.symbolName)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.10), in: Capsule())
        .foregroundStyle(tint.opacity(0.85))
        .padding(.top, 4)
        .accessibilityHint("Bramble has a curiosity for this mode.")
    }

    /// Emit ``practiceWithBrambleAvailable(mode:kind:)`` at most once
    /// per appearance per (mode, kind) so the analytics surface
    /// doesn't flood when the kid scrolls + re-renders the same card.
    /// Keyed by `"\(mode)|\(kind)"` so a card swinging between bands
    /// across appearances re-emits cleanly.
    private func emitPracticeBadgeAnalyticsOnce(
        for gateID: String,
        kind: KitMasteryCopyCatalog.Kind
    ) {
        let raw = analyticsModeRawValue(for: gateID)
        let key = "\(raw)|\(kind.rawValue)"
        guard !emittedPracticeBrambleBadges.contains(key) else { return }
        emittedPracticeBrambleBadges.insert(key)
        analytics.track(.practiceWithBrambleAvailable(mode: raw, kind: kind.rawValue))
    }

    /// Emit ``deeperChallengeAvailable(mode:)`` at most once per
    /// appearance per mode so the analytics surface doesn't flood when
    /// the kid scrolls + re-renders the same card.
    private func emitDeeperChallengeAnalyticsOnce(for gateID: String) {
        let raw = analyticsModeRawValue(for: gateID)
        guard !emittedDeeperChallengeModes.contains(raw) else { return }
        emittedDeeperChallengeModes.insert(raw)
        analytics.track(.deeperChallengeAvailable(mode: raw))
    }

    /// Stable raw value the analytics event carries. Strips the
    /// `voicetale.adventure.` prefix so the wire surface stays a kid-
    /// readable mode slug (mirrors ``ModeMasteryMapping/ModeCard``).
    private func analyticsModeRawValue(for gateID: String) -> String {
        if let mode = ModeMasteryMapping.ModeCard(rawValue: gateID) {
            switch mode {
            case .hookBuilder:      return "hook_builder"
            case .pacingWalk:       return "pacing_walk"
            case .turnDrill:        return "turn_drill"
            case .callbackRefrain:  return "callback_refrain"
            case .taleTrial:        return "tale_trial"
            }
        }
        return gateID
    }

    private func refreshTalesCount() {
        talesSavedCount = VoiceTaleStore.fetchTales(in: modelContext).count
    }

    private var modes: [ModeCard] {
        [
            ModeCard(
                gateID: VoiceTaleProgressionGate.hookBuilderID,
                title: "Hook Builder",
                subtitle: "Tell 30-second openers; Lean's body shows whether the hook pulled.",
                systemImage: "leaf.circle.fill",
                color: .orange
            ),
            ModeCard(
                gateID: VoiceTaleProgressionGate.pacingWalkID,
                title: "Pacing Walk",
                subtitle: "Tell your story to Slow's walking — pacing matches.",
                systemImage: "tortoise.fill",
                color: .green
            ),
            ModeCard(
                gateID: VoiceTaleProgressionGate.turnDrillID,
                title: "Turn Drill",
                subtitle: "Set up beats 1-3 so beat 4 rotates the meaning. Pivot watches.",
                systemImage: "arrow.triangle.2.circlepath",
                color: .teal
            ),
            ModeCard(
                gateID: VoiceTaleProgressionGate.callbackRefrainID,
                title: "Callback Refrain",
                subtitle: "A phrase at the open, the same phrase at the close. Refrain keeps score.",
                systemImage: "repeat",
                color: .pink
            ),
            ModeCard(
                gateID: VoiceTaleProgressionGate.taleTrialID,
                title: "Tale Trial",
                subtitle: "60 seconds. A random prompt. Bramble's blind judging — no scaffolding.",
                systemImage: "dice.fill",
                color: .indigo
            ),
        ]
    }

    private struct ModeCard {
        let gateID: String
        let title: String
        let subtitle: String
        let systemImage: String
        let color: Color
    }
}

#Preview {
    AdventureTabView()
}
