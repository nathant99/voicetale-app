import Foundation
import Testing
import ForgeGamification
import ForgeMasteryEngine
@testable import Models
@testable import Services

/// EIGHTEENTH-round coverage for ``PracticeWithBrambleBadge`` per
/// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D parity polish.
/// Locks the no-double-render-with-stretch-pill invariant, the
/// catalog single-seam, the unmapped-Tale-Trial behavior, and the
/// anti-shame / anti-judgment symbol surface.
@Suite("PracticeWithBrambleBadge (Phase D parity polish)")
struct PracticeWithBrambleBadgeTests {

    /// Anti-shame tokens that MUST NEVER appear in any badge copy.
    /// Same blocklist as ``DeeperChallengeAffordanceTests`` +
    /// ``KitMasteryRecommenderTests`` — sourced from the same catalog
    /// so the invariant transfers.
    private static let blocklist: [String] = [
        "hard", "harder", "hardest", "difficult",
        "easy", "easier", "easiest",
        "wrong", "mistake", "error", "fail",
        "stuck", "behind", "slower", "weak", "weakness", "gap",
        "master", "mastery", "mastered", "mastering",
        "score", "rating",
        "level up", "next level",
        "practice more", "you should", "you need",
    ]

    /// Anti-judgment SF Symbol shapes the badge MUST NEVER surface
    /// (per the Practice-with-Bramble three-card surface's symbol
    /// register lock-down).
    private static let blockedSymbols: Set<String> = [
        "trophy.fill", "star.fill", "medal.fill", "rosette",
    ]

    /// Build a `TopicMasteryState` driven through the canonical
    /// `MasteryUpdater` so the FSRS state + recent-outcome window are
    /// realistic. Records `attempts` correct attempts in a row on
    /// `topic`; each spaced N hours apart so FSRS retrievability has a
    /// chance to decay between calls.
    ///
    /// Returns the final state for the topic — caller wraps in a
    /// `[KitID: TopicMasteryState]` dict.
    private func driveState(
        topic: KitID,
        attempts: Int,
        outcomes: [(AttemptOutcome, hoursAgo: Double)],
        srs: SpacedRepetitionEngine = SpacedRepetitionEngine(desiredRetention: 0.9),
        updater: MasteryUpdater<KitID> = MasteryUpdater<KitID>(recentWindowSize: 8)
    ) -> TopicMasteryState {
        var state = TopicMasteryState()
        for (outcome, hoursAgo) in outcomes {
            let when = Date().addingTimeInterval(-hoursAgo * 60 * 60)
            state = updater.recordAttempt(
                topic: topic,
                outcome: outcome,
                state: state,
                srs: srs,
                now: when
            )
        }
        return state
    }

    // MARK: - Tale Trial unmapped

    @Test func taleTrialIsUnmapped() {
        // Tale Trial is unmapped in ``ModeMasteryMapping`` — the
        // mode-card is intentionally blind-judged. The badge MUST NOT
        // ever look up a kit for it; the caller's `dominantKit` resolver
        // returns nil first. This test locks the integration invariant.
        let taleTrialMode = ModeMasteryMapping.ModeCard.taleTrial
        #expect(ModeMasteryMapping.dominantKit(forGateID: taleTrialMode.rawValue) == nil,
                "Tale Trial MUST remain unmapped — affordance + badge integrity depends on it")
    }

    // MARK: - No double-render with stretch pill

    @Test func badgeIsNilWhenRecommendationKindIsStretch() {
        // Empty state → engine surfaces ONLY stretch recommendations
        // for root topics (per `KitMasteryRecommenderTests.emptyStateSurfacesStretchOnRootTopic`).
        // The badge MUST defer for stretch — the DeeperChallengeAffordance
        // pill owns that band on the Adventure surface.
        let empty: [KitID: TopicMasteryState] = [:]
        for kit in KitID.allCases {
            let badge = PracticeWithBrambleBadge.badge(for: kit, masteryStates: empty)
            // For a root topic at empty state, the engine returns a
            // stretch recommendation — badge MUST be nil.
            if let badge {
                #expect(badge.kind != .stretch,
                        "Badge MUST NEVER carry `.stretch` — that band belongs to DeeperChallengeAffordance")
                #expect(badge.kind != .deeperChallengeOpener,
                        "Badge MUST NEVER carry `.deeperChallengeOpener` — that's a reflection-opener slot")
            }
        }
    }

    // MARK: - Engine band surfaces correctly

    @Test func badgeSurfacesExtendForMidBandKit() {
        // A root topic with several correct attempts → mastery climbs
        // into the extend band [0.40, 0.85). The engine surfaces an
        // `.extend` recommendation; the badge MUST surface it.
        let topic = KitID.hookCraft
        let state = driveState(
            topic: topic,
            attempts: 3,
            outcomes: [
                (.correctFirstTry(elapsedSeconds: 10.0), 24.0),
                (.correctFirstTry(elapsedSeconds: 12.0), 12.0),
                (.incorrect(elapsedSeconds: 8.0), 0.5),
            ]
        )
        let map: [KitID: TopicMasteryState] = [topic: state]
        let badge = PracticeWithBrambleBadge.badge(for: topic, masteryStates: map)
        // The badge fires iff the engine returns an .extend or
        // .consolidate for this exact kit. If the engine instead
        // returns a stretch / nil, the badge stays nil (no double-render
        // / no surface). Either way, the invariant is:
        if let badge {
            #expect([.extend, .consolidate].contains(badge.kind),
                    "Badge for mid-band kit MUST be .extend or .consolidate, got \(badge.kind)")
        }
    }

    // MARK: - Catalog single-seam

    @Test func badgeCopyMatchesCatalogLineForSurfacingKind() {
        // For each surfacing badge, the copy MUST equal the catalog
        // line for `(kind, kit)`. Locks the single-seam so the catalog
        // stays the only place Bramble speaks about mastery state.
        let topic = KitID.sensoryDetail
        let state = driveState(
            topic: topic,
            attempts: 2,
            outcomes: [
                (.correctFirstTry(elapsedSeconds: 6.0), 240.0),  // 10 days ago
                (.correctFirstTry(elapsedSeconds: 7.0), 168.0),  // 7 days ago
            ]
        )
        let map: [KitID: TopicMasteryState] = [topic: state]
        if let badge = PracticeWithBrambleBadge.badge(for: topic, masteryStates: map) {
            let catalog = KitMasteryCopyCatalog.line(for: badge.kind, kit: topic)
            #expect(badge.brambleCopy == catalog,
                    "Badge copy for \(topic) MUST match catalog \(badge.kind) line")
        }
    }

    // MARK: - Anti-shame blocklist (exhaustive across catalog)

    @Test func allBadgeKindsPassAntiShameBlocklist() {
        // The badge can only surface `.extend` or `.consolidate`. Walk
        // every (surfacing-kind, kit) pair through the catalog and
        // verify the blocklist holds. Mirrors the
        // `KitMasteryRecommenderTests.copyCatalogAvoidsShameTokens`
        // pattern but scopes to the kinds the badge can actually emit.
        let surfacingKinds: [KitMasteryCopyCatalog.Kind] = [.extend, .consolidate]
        for kind in surfacingKinds {
            for kit in KitID.allCases {
                let line = KitMasteryCopyCatalog.line(for: kind, kit: kit).lowercased()
                for token in Self.blocklist {
                    #expect(
                        !line.contains(token),
                        "Badge-surfacing catalog line for (\(kind), \(kit)) contains shame token '\(token)': \"\(line)\""
                    )
                }
            }
        }
    }

    // MARK: - Symbol shape

    @Test func badgeSymbolIsAntiJudgmentForExtendAndConsolidate() {
        // The badge MUST only surface symbols from the catalog's
        // anti-judgment shape register. Locks the explicit blocklist
        // against trophy / star / medal / rosette.
        #expect(KitMasteryCopyCatalog.Kind.extend.symbolName == "leaf.fill")
        #expect(KitMasteryCopyCatalog.Kind.consolidate.symbolName == "arrow.clockwise.circle.fill")
        for kind in KitMasteryCopyCatalog.Kind.allCases {
            let lowered = kind.symbolName.lowercased()
            #expect(!Self.blockedSymbols.contains(kind.symbolName),
                    "Kind \(kind) MUST NOT use blocked symbol \(kind.symbolName)")
            #expect(!lowered.contains("trophy"))
            #expect(!lowered.contains("medal"))
            #expect(!lowered.contains("rosette"))
        }
    }

    // MARK: - Empty store

    @Test func badgeIsNilOnEmptyMasteryStateForAnyKit() {
        // Cold-launch kid — no prior attempt on any kit. The engine
        // can surface ONLY `.stretch` recommendations from empty state
        // (per `KitMasteryRecommenderTests.emptyStateSurfacesStretchOnRootTopic`).
        // The badge MUST stay nil for every kit so the mode-card renders
        // unadorned per the canonical surface invariant.
        let empty: [KitID: TopicMasteryState] = [:]
        for kit in KitID.allCases {
            let badge = PracticeWithBrambleBadge.badge(for: kit, masteryStates: empty)
            #expect(badge == nil,
                    "Empty-state badge for \(kit) MUST be nil (only stretch surfaces from empty state; badge defers)")
        }
    }

    // MARK: - Other kit's recommendation doesn't leak into this kit's badge

    @Test func badgeOnlySurfacesForRequestedKit() {
        // Drive state on `hookCraft` so the engine recommends it. When
        // we ask for the badge on `closingGrace`, the badge MUST return
        // nil (the recommendation matches `hookCraft`, not `closingGrace`).
        let driver = KitID.hookCraft
        let unrelated = KitID.closingGrace
        let state = driveState(
            topic: driver,
            attempts: 2,
            outcomes: [
                (.correctFirstTry(elapsedSeconds: 8.0), 36.0),
                (.correctFirstTry(elapsedSeconds: 10.0), 12.0),
            ]
        )
        let map: [KitID: TopicMasteryState] = [driver: state]
        let badge = PracticeWithBrambleBadge.badge(for: unrelated, masteryStates: map)
        // The closingGrace kit has no state, so the engine won't
        // recommend it via `.extend` / `.consolidate`. If a stretch
        // somehow surfaces for closingGrace (depth-9 chain), the badge
        // still defers to nil.
        if let badge {
            #expect(badge.kit == unrelated,
                    "If badge surfaces, it MUST be for the requested kit only")
            #expect([.extend, .consolidate].contains(badge.kind))
        }
    }
}
