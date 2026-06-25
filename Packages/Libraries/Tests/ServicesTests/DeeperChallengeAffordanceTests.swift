import Foundation
import Testing
import ForgeMasteryEngine
@testable import Models
@testable import Services

/// Phase D coverage for ``DeeperChallengeAffordance`` per
/// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D. Locks the
/// edge-of-competence threshold, the catalog single-seam, and the
/// anti-shame token surface inherited from ``KitMasteryCopyCatalog``.
@Suite("DeeperChallengeAffordance (Phase D)")
struct DeeperChallengeAffordanceTests {

    /// Anti-shame tokens that MUST NEVER appear in any affordance copy.
    /// Same blocklist as ``KitMasteryRecommenderTests`` — sourced from
    /// the same ``KitMasteryCopyCatalog`` so the invariant transfers.
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

    // MARK: - Threshold gating

    @Test func belowThresholdReturnsFalse() {
        // The threshold is the engine's edge-of-competence floor —
        // 0.80. A kid at 0.79 is just shy and MUST NOT see the pill.
        #expect(DeeperChallengeAffordance.shouldSurface(masteryScore: 0.79) == false)
        #expect(DeeperChallengeAffordance.shouldSurface(masteryScore: 0.50) == false)
        #expect(DeeperChallengeAffordance.shouldSurface(masteryScore: 0.0) == false)
    }

    @Test func atThresholdReturnsTrue() {
        #expect(DeeperChallengeAffordance.shouldSurface(masteryScore: 0.80) == true)
    }

    @Test func aboveThresholdReturnsTrue() {
        #expect(DeeperChallengeAffordance.shouldSurface(masteryScore: 0.81) == true)
        #expect(DeeperChallengeAffordance.shouldSurface(masteryScore: 1.0) == true)
    }

    @Test func nilScoreReturnsFalse() {
        // Cold-launch kid — no prior attempt on the kit. The mode-card
        // MUST render unadorned per the "preserve the canonical surface
        // on cold launch" invariant.
        #expect(DeeperChallengeAffordance.shouldSurface(masteryScore: nil) == false)
    }

    // MARK: - Catalog single-seam

    @Test func brambleCopyDelegatesToCatalogStretchRationale() {
        // The affordance MUST source kid-facing copy from the catalog
        // with the `.stretch` rationale — not author it inline. Locks
        // the single-seam so the anti-shame token blocklist enforced at
        // the catalog layer still holds at the affordance surface.
        for kit in KitID.allCases {
            let affordance = DeeperChallengeAffordance.brambleCopy(for: kit)
            let catalog = KitMasteryCopyCatalog.line(for: .stretch, kit: kit)
            #expect(affordance == catalog,
                    "Affordance copy for \(kit) MUST match catalog .stretch line")
        }
    }

    @Test func brambleCopyPassesAntiShameBlocklist() {
        for kit in KitID.allCases {
            let line = DeeperChallengeAffordance.brambleCopy(for: kit).lowercased()
            for token in Self.blocklist {
                #expect(
                    !line.contains(token),
                    "Affordance copy for \(kit) contains shame token '\(token)': \"\(line)\""
                )
            }
        }
    }

    // MARK: - Symbol shape

    @Test func symbolNameMatchesStretchCatalogSymbol() {
        // Visual register must match the Practice-with-Bramble stretch
        // card (PR #132) so the kid sees the same shape across
        // surfaces. Locks the explicit sparkles choice + the explicit
        // anti-judgment symbol blocklist (no trophy / star / medal /
        // rosette).
        #expect(DeeperChallengeAffordance.symbolName == KitMasteryCopyCatalog.Kind.stretch.symbolName)
        #expect(DeeperChallengeAffordance.symbolName == "sparkles")
        let blockedSymbols: Set<String> = ["trophy.fill", "star.fill", "medal.fill", "rosette"]
        #expect(!blockedSymbols.contains(DeeperChallengeAffordance.symbolName))
    }

    // MARK: - Threshold constant

    @Test func thresholdConstantMatchesEngineEdgeOfCompetence() {
        // The 0.80 floor is the engine's "racing ahead" trigger per
        // `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D. Locking
        // the value makes a future tunable adjustment surface as a
        // test failure rather than a silent register shift.
        #expect(DeeperChallengeAffordance.masteryThreshold == 0.80)
    }
}
