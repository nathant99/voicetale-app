import Testing
import Foundation
@testable import Models

/// Coverage for the `.deeperChallengeOpener` extension to
/// ``KitMasteryCopyCatalog`` per `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md`
/// § Phase D second-half. Locks: (1) every kit has a line, (2) every
/// line passes the anti-shame token blocklist, (3) every line opens
/// with the kid-recognizable "Bramble" voice, (4) the line uses
/// past-tense "noticed" register (the kid just finished a tale; Bramble
/// is reflecting back), (5) the symbolName mirrors `.stretch` (sparkles
/// — continuity from the Adventure-card affordance pill).
@Suite("KitMasteryCopyCatalogDeeperChallengeOpener")
struct KitMasteryCopyCatalogDeeperChallengeOpenerTests {
    private static let antiShameTokens = [
        "hard", "harder", "hardest", "difficult",
        "easy", "easier", "easiest",
        "wrong", "mistake", "error", "fail",
        "stuck", "behind", "slower", "weak", "weakness", "gap",
        "master", "mastery", "mastered", "mastering",
        "score", "rating", "level up", "next level",
        "practice more", "you should", "you need",
    ]

    // MARK: - Catalog completeness

    @Test func everyKitHasADeeperChallengeOpenerLine() {
        for kit in KitID.allCases {
            let line = KitMasteryCopyCatalog.line(for: .deeperChallengeOpener, kit: kit)
            #expect(!line.isEmpty,
                    "kit=\(kit) MUST have a deeperChallengeOpener line")
        }
    }

    @Test func everyOpenerLineOpensWithBramble() {
        for kit in KitID.allCases {
            let line = KitMasteryCopyCatalog.line(for: .deeperChallengeOpener, kit: kit)
            #expect(line.lowercased().hasPrefix("bramble"),
                    "kit=\(kit) opener must open with 'Bramble' — got: \(line)")
        }
    }

    @Test func everyOpenerUsesPastTenseNoticedRegister() {
        // The opener fires AFTER the kid finished telling a deeper-
        // challenge tale; the register is "I noticed you went deeper
        // there" reflecting-back. Future tense ("Bramble wonders how
        // your hook WILL land") is the wrong register for this slot.
        for kit in KitID.allCases {
            let line = KitMasteryCopyCatalog.line(for: .deeperChallengeOpener, kit: kit)
            #expect(line.lowercased().contains("noticed"),
                    "kit=\(kit) opener must contain past-tense 'noticed' — got: \(line)")
        }
    }

    // MARK: - Anti-shame blocklist

    @Test func everyOpenerPassesTheAntiShameTokenBlocklist() {
        for kit in KitID.allCases {
            let line = KitMasteryCopyCatalog.line(for: .deeperChallengeOpener, kit: kit).lowercased()
            for token in Self.antiShameTokens {
                #expect(!line.contains(token),
                        "kit=\(kit) opener contains shame token '\(token)': \(line)")
            }
        }
    }

    @Test func openerNeverNamesDeeperChallengeOrMasteryAloud() {
        // The kid never hears "deeper challenge" / "mastery" / "ZPD" /
        // "edge of competence" — those are engine terms. Bramble
        // speaks about what she NOTICED, not what category the kit fell
        // into.
        let engineTokens = ["deeper challenge", "mastery", "edge", "competence",
                            "zpd", "fsrs", "rationale", "extend", "consolidate",
                            "stretch"]
        for kit in KitID.allCases {
            let line = KitMasteryCopyCatalog.line(for: .deeperChallengeOpener, kit: kit).lowercased()
            for token in engineTokens {
                #expect(!line.contains(token),
                        "kit=\(kit) opener surfaces engine term '\(token)': \(line)")
            }
        }
    }

    // MARK: - Symbol continuity

    @Test func deeperChallengeOpenerReusesSparklesSymbol() {
        // Visual continuity from the affordance pill (`.stretch` →
        // sparkles) → reflection opener (sparkles). Trophy / star /
        // medal / rosette explicitly blocked.
        #expect(KitMasteryCopyCatalog.Kind.deeperChallengeOpener.symbolName == "sparkles")
    }

    @Test func deeperChallengeOpenerSymbolAvoidsJudgmentShapes() {
        let blocked = ["trophy", "star", "medal", "rosette", "crown", "checkmark.seal"]
        let symbol = KitMasteryCopyCatalog.Kind.deeperChallengeOpener.symbolName
        for token in blocked {
            #expect(!symbol.contains(token),
                    "opener symbol '\(symbol)' contains judgment token '\(token)'")
        }
    }

    // MARK: - Kind enum surface

    @Test func kindExposesAllFourCases() {
        #expect(KitMasteryCopyCatalog.Kind.allCases.count == 4)
        #expect(KitMasteryCopyCatalog.Kind.allCases.contains(.deeperChallengeOpener))
    }

    @Test func deeperChallengeOpenerRawValueIsStable() {
        // Stable string identifier — analytics + JSON snapshots may
        // reference this raw value across versions. Lock the byte
        // shape to catch accidental renames.
        #expect(KitMasteryCopyCatalog.Kind.deeperChallengeOpener.rawValue
                == "deeperChallengeOpener")
    }
}
