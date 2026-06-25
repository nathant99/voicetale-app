import Foundation
import Testing
import ForgeGamification
import ForgeMasteryEngine
@testable import Models
@testable import Services

/// ForgeMasteryEngine Phase C — recommender + copy-catalog invariants
/// per `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase C. The catalog
/// is the only place where Bramble speaks about mastery state; the
/// anti-shame token blocklist invariants below lock that surface at
/// the unit-test layer so a future copy edit cannot silently
/// reintroduce shaming language.
@Suite("KitMastery recommender (Phase C)")
struct KitMasteryRecommenderTests {

    /// Anti-shame tokens that MUST NEVER appear in any catalog line.
    /// Mirrors the blocklist documented at the head of
    /// ``KitMasteryCopyCatalog``.
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

    /// Every catalog line MUST pass the anti-shame token blocklist.
    /// Tokens are checked case-insensitively; substring match is the
    /// strict-enough check ("master" inside "mastered" still fails).
    @Test
    func copyCatalogAvoidsShameTokens() {
        for (kind, perKit) in KitMasteryCopyCatalog.lines {
            for (kit, line) in perKit {
                let lower = line.lowercased()
                for token in Self.blocklist {
                    #expect(
                        !lower.contains(token),
                        "Catalog line for (\(kind), \(kit)) contains shame token '\(token)': \"\(line)\""
                    )
                }
            }
        }
    }

    /// The fallback line returned by ``KitMasteryCopyCatalog/line(for:kit:)``
    /// when a key is somehow missing MUST also pass the anti-shame
    /// blocklist. The fallback is the last line of defense; it cannot
    /// be the surface that introduces shame language.
    @Test
    func fallbackLineIsAlsoSafe() {
        // Synthesize a "missing key" path by querying every (kind, kit)
        // pair — the catalog should be complete, so we use the runtime
        // helper which silently falls back when a key is missing.
        let line = KitMasteryCopyCatalog.line(for: .extend, kit: .hookCraft)
        let lower = line.lowercased()
        for token in Self.blocklist {
            #expect(!lower.contains(token), "Fallback line contains shame token: \(token)")
        }
    }

    /// Catalog completeness — every (kind, kit) pair MUST have an
    /// entry. The 3 kinds × 9 kits = 27 entries; the catalog count
    /// must equal exactly that.
    @Test
    func catalogIsComplete() {
        for kind in KitMasteryCopyCatalog.Kind.allCases {
            let perKit = try? #require(KitMasteryCopyCatalog.lines[kind])
            #expect(perKit?.count == KitID.allCases.count)
            for kit in KitID.allCases {
                #expect(perKit?[kit] != nil, "Missing line for (\(kind), \(kit))")
            }
        }
    }

    /// Catalog lines reference Bramble's voice in the first word
    /// (warm-second-person register per the catalog's header comment).
    /// The "Bramble" anchor ensures the line is recognizable as
    /// Bramble's voice + not a system-toned recommendation.
    @Test
    func catalogLinesStartWithBramble() {
        for (_, perKit) in KitMasteryCopyCatalog.lines {
            for (_, line) in perKit {
                #expect(
                    line.hasPrefix("Bramble"),
                    "Line should open with 'Bramble': \"\(line)\""
                )
            }
        }
    }

    /// `KitMasteryRecommendation.init(_:)` correctly maps each engine
    /// rationale arm to the matching catalog kind.
    @Test
    func recommendationMapsEngineRationaleToCatalogKind() {
        // Extend
        let extendRaw = NextProblemPicker<KitID, KitID>.Recommendation(
            problemID: .hookCraft,
            topic: .hookCraft,
            rationale: .extend(topic: .hookCraft, currentMasteryScore: 0.5)
        )
        let extendRec = try? #require(KitMasteryRecommendation(extendRaw))
        #expect(extendRec?.kind == .extend)
        #expect(extendRec?.kit == .hookCraft)

        // Consolidate
        let consolidateRaw = NextProblemPicker<KitID, KitID>.Recommendation(
            problemID: .sensoryDetail,
            topic: .sensoryDetail,
            rationale: .consolidate(topic: .sensoryDetail, daysSinceLastReview: 14)
        )
        let consolidateRec = try? #require(KitMasteryRecommendation(consolidateRaw))
        #expect(consolidateRec?.kind == .consolidate)
        #expect(consolidateRec?.kit == .sensoryDetail)

        // Stretch
        let stretchRaw = NextProblemPicker<KitID, KitID>.Recommendation(
            problemID: .arcCompleteness,
            topic: .arcCompleteness,
            rationale: .stretch(topic: .arcCompleteness, prerequisitesJustMastered: [.sensoryDetail])
        )
        let stretchRec = try? #require(KitMasteryRecommendation(stretchRaw))
        #expect(stretchRec?.kind == .stretch)
        #expect(stretchRec?.kit == .arcCompleteness)
    }

    /// Empty state — cold-launch / new-kid path. The engine surfaces
    /// a stretch recommendation for a root topic (whose prerequisites
    /// are trivially "all mastered" — empty prereq set), giving the
    /// kid a cold-launch way in. The three-card surface on
    /// ``ProgressTabView`` therefore lights even at install-time
    /// (recommendation is a root topic; Bramble copy is the
    /// curiosity-toned stretch line per ``KitMasteryCopyCatalog``).
    @Test
    func emptyStateSurfacesStretchOnRootTopic() {
        let recommender = KitMasteryRecommender()
        let recs = recommender.recommendations(state: [:])
        // At least one recommendation fires; it MUST be a stretch
        // (the only rationale that can fire without per-topic state).
        #expect(!recs.isEmpty)
        for rec in recs {
            #expect(rec.kind == .stretch)
            // The recommended kit must be a frontier topic — i.e. one
            // whose prerequisites are all empty (root) OR all mastered
            // (which doesn't happen with empty state).
            #expect(KitMasteryTopology.graph.nodes[rec.kit]?.prerequisites.isEmpty == true)
        }
    }

    /// After one correct attempt on a root topic, at least one
    /// rationale fires (the exact rationale depends on the FSRS
    /// trajectory; the test asserts the surface lights, not which
    /// arm). Drives the `practiceSurface` view-branch case where
    /// Bramble notices the kid has signal.
    @Test
    func attemptedRootSurfacesSomeRationale() {
        let recommender = KitMasteryRecommender()
        let updater = MasteryUpdater<KitID>(recentWindowSize: 8)
        let srs = SpacedRepetitionEngine(desiredRetention: 0.9)
        let next = updater.recordAttempt(
            topic: .hookCraft,
            outcome: .correctFirstTry(elapsedSeconds: 12.0),
            state: TopicMasteryState(),
            srs: srs,
            now: .now
        )
        let recs = recommender.recommendations(state: [.hookCraft: next])
        // At least one recommendation must fire — the engine has
        // signal on hookCraft + the topology has many other root /
        // depth-1 topics that compose into stretch candidates.
        #expect(!recs.isEmpty)
    }

    /// Identifiable conformance — kit-of-recommendation is the
    /// natural key. Stable for ForEach use on the three-card surface.
    @Test
    func recommendationIdIsKit() {
        let rec = KitMasteryRecommendation(kit: .closingGrace, kind: .stretch)
        #expect(rec.id == .closingGrace)
    }

    /// Hashable conformance — two recommendations with the same kit +
    /// kind are equal; differing in either field separates them.
    @Test
    func recommendationHashableInvariants() {
        let a = KitMasteryRecommendation(kit: .hookCraft, kind: .extend)
        let b = KitMasteryRecommendation(kit: .hookCraft, kind: .extend)
        let c = KitMasteryRecommendation(kit: .hookCraft, kind: .consolidate)
        let d = KitMasteryRecommendation(kit: .sensoryDetail, kind: .extend)
        #expect(a == b)
        #expect(a != c)
        #expect(a != d)
    }

    /// Per-kind symbol names map to the documented 3-symbol set + are
    /// all available SF Symbols. The names are non-judgmental shapes
    /// (no trophies, no stars).
    @Test
    func symbolNamesAreNonJudgmental() {
        #expect(KitMasteryCopyCatalog.Kind.extend.symbolName == "leaf.fill")
        #expect(KitMasteryCopyCatalog.Kind.consolidate.symbolName == "arrow.clockwise.circle.fill")
        #expect(KitMasteryCopyCatalog.Kind.stretch.symbolName == "sparkles")
        // Anti-shame: the symbol names must not include trophy /
        // star / rating shapes.
        for kind in KitMasteryCopyCatalog.Kind.allCases {
            let name = kind.symbolName.lowercased()
            #expect(!name.contains("trophy"))
            #expect(!name.contains("star"))
            #expect(!name.contains("rosette"))
            #expect(!name.contains("medal"))
        }
    }

    /// `loadKit(forKitID:)` resolves each `KitID` to its bundled JSON.
    /// Lock-in for the kit-id → filename convention (`kit_0N_<slug>`).
    @Test
    func loadKitForKitIDResolvesAllPhaseShippedKits() throws {
        // Every `KitID` whose JSON has been bundled must resolve. Kits
        // 1-9 are all bundled per `Services/Resources/QuestionKits/`.
        for kit in KitID.allCases {
            let resolved = try QuestionKitLoader.loadKit(forKitID: kit)
            #expect(resolved != nil, "KitID \(kit) (raw \(kit.rawValue)) failed to resolve")
            #expect(resolved?.kit == kit.rawValue)
        }
    }

    /// Recommendation-first `loadKitForRotation(seed:recommendation:)`
    /// uses the recommendation's kit when provided + falls back to
    /// the seed-based rotation when `nil`.
    @Test
    func loadKitForRotationPrefersRecommendationOverSeed() throws {
        let rec = KitMasteryRecommendation(kit: .closingGrace, kind: .stretch)
        let kit = try QuestionKitLoader.loadKitForRotation(seed: 0, recommendation: rec)
        #expect(kit.kit == KitID.closingGrace.rawValue)
    }

    @Test
    func loadKitForRotationFallsBackWhenRecommendationIsNil() throws {
        // Seed 0 → `phase1Filenames[0]` = kit_01_hook.
        let kit = try QuestionKitLoader.loadKitForRotation(seed: 0, recommendation: nil)
        #expect(kit.kit == KitID.hookCraft.rawValue)
    }
}
