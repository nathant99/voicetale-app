import Foundation
import Testing
import Models
@testable import Services

/// Coverage for the easter-eggs Phase B evaluator shipped in PR-D of the
/// 2026-06-24 NINTH-round wire-up. Locks the three example predicates +
/// the conservative-fail unknown-identifier path + snapshot default
/// constructor + every boundary edge case (just-shy / exactly-at / just-past
/// the threshold). Pure-function tests — no SwiftData host needed.
///
/// Per `@Docs/PLAN_EASTER_EGGS_TRADITION_UNLOCKS.md` § Implementation phasing
/// Phase B.
@Suite("TraditionUnlockEvaluator")
struct TraditionUnlockEvaluatorTests {

    // MARK: - deep_listener predicate

    @Test func deepListenerFiresWithFullBaseAndFiveTales() {
        let snapshot = TraditionUnlockSnapshot(
            expandedBaseTraditions: ["griot", "indigenous-american-oral-history",
                                     "seanchai", "rakugo", "slam-poetry"],
            savedTales: 5
        )
        #expect(TraditionUnlockEvaluator.isUnlocked(
            condition: "deep_listener", snapshot: snapshot
        ))
    }

    @Test func deepListenerSilentBelowFiveBaseTraditions() {
        let snapshot = TraditionUnlockSnapshot(
            expandedBaseTraditions: ["griot", "seanchai", "rakugo", "slam-poetry"],
            savedTales: 12
        )
        #expect(TraditionUnlockEvaluator.isUnlocked(
            condition: "deep_listener", snapshot: snapshot
        ) == false)
    }

    @Test func deepListenerSilentBelowFiveTales() {
        let snapshot = TraditionUnlockSnapshot(
            expandedBaseTraditions: ["griot", "indigenous-american-oral-history",
                                     "seanchai", "rakugo", "slam-poetry"],
            savedTales: 4
        )
        #expect(TraditionUnlockEvaluator.isUnlocked(
            condition: "deep_listener", snapshot: snapshot
        ) == false)
    }

    @Test func deepListenerFiresOnExtraExpansionsAndTales() {
        // ≥ 5 on both axes — `>= 5` not `== 5`. Future easter-egg
        // traditions count toward exploration breadth; the predicate
        // must still fire when the kid has explored MORE than 5.
        let snapshot = TraditionUnlockSnapshot(
            expandedBaseTraditions: ["griot", "indigenous-american-oral-history",
                                     "seanchai", "rakugo", "slam-poetry",
                                     "bonus-easter"],
            savedTales: 27
        )
        #expect(TraditionUnlockEvaluator.isUnlocked(
            condition: "deep_listener", snapshot: snapshot
        ))
    }

    // MARK: - cross_mood_explorer predicate

    @Test func crossMoodExplorerFiresWithAllFourMoods() {
        let snapshot = TraditionUnlockSnapshot(
            moodsCovered: [.funny, .scary, .tender, .wild]
        )
        #expect(TraditionUnlockEvaluator.isUnlocked(
            condition: "cross_mood_explorer", snapshot: snapshot
        ))
    }

    @Test func crossMoodExplorerSilentWithThreeMoods() {
        let snapshot = TraditionUnlockSnapshot(
            moodsCovered: [.funny, .scary, .tender]
        )
        #expect(TraditionUnlockEvaluator.isUnlocked(
            condition: "cross_mood_explorer", snapshot: snapshot
        ) == false)
    }

    @Test func crossMoodExplorerSilentWhenAllSetButOne() {
        // Lock against the test that "any 3 of 4" was a regression.
        let combinations: [Set<VoiceTaleMood>] = [
            [.scary, .tender, .wild],   // missing funny
            [.funny, .tender, .wild],   // missing scary
            [.funny, .scary, .wild],    // missing tender
            [.funny, .scary, .tender],  // missing wild
        ]
        for combo in combinations {
            let snapshot = TraditionUnlockSnapshot(moodsCovered: combo)
            #expect(TraditionUnlockEvaluator.isUnlocked(
                condition: "cross_mood_explorer", snapshot: snapshot
            ) == false)
        }
    }

    @Test func crossMoodExplorerSilentForEmptyMoodSet() {
        let snapshot = TraditionUnlockSnapshot(moodsCovered: [])
        #expect(TraditionUnlockEvaluator.isUnlocked(
            condition: "cross_mood_explorer", snapshot: snapshot
        ) == false)
    }

    // MARK: - tradition_revisitor predicate

    @Test func traditionRevisitorFiresOnTwoSlugsWithThreeRevisitsEach() {
        let snapshot = TraditionUnlockSnapshot(
            traditionRevisitCount: ["griot": 3, "rakugo": 3]
        )
        #expect(TraditionUnlockEvaluator.isUnlocked(
            condition: "tradition_revisitor", snapshot: snapshot
        ))
    }

    @Test func traditionRevisitorSilentOnOneSlugWithThreeRevisits() {
        // One slug with revisits ≥ 3 is not enough — needs TWO distinct
        // slugs both reaching the threshold.
        let snapshot = TraditionUnlockSnapshot(
            traditionRevisitCount: ["griot": 7, "rakugo": 2]
        )
        #expect(TraditionUnlockEvaluator.isUnlocked(
            condition: "tradition_revisitor", snapshot: snapshot
        ) == false)
    }

    @Test func traditionRevisitorSilentOnSparseRevisits() {
        let snapshot = TraditionUnlockSnapshot(
            traditionRevisitCount: ["griot": 1, "rakugo": 2, "seanchai": 1]
        )
        #expect(TraditionUnlockEvaluator.isUnlocked(
            condition: "tradition_revisitor", snapshot: snapshot
        ) == false)
    }

    @Test func traditionRevisitorFiresOnThreeOrMoreQualifying() {
        let snapshot = TraditionUnlockSnapshot(
            traditionRevisitCount: ["griot": 5, "rakugo": 4, "seanchai": 3]
        )
        #expect(TraditionUnlockEvaluator.isUnlocked(
            condition: "tradition_revisitor", snapshot: snapshot
        ))
    }

    // MARK: - Unknown identifier (conservative-hide)

    @Test func unknownIdentifierReturnsFalse() {
        let richSnapshot = TraditionUnlockSnapshot(
            expandedBaseTraditions: ["griot", "indigenous-american-oral-history",
                                     "seanchai", "rakugo", "slam-poetry"],
            savedTales: 99,
            moodsCovered: [.funny, .scary, .tender, .wild],
            kitsCompleted: Set(1...9),
            traditionRevisitCount: ["griot": 20, "rakugo": 20]
        )
        // A predicate name not in the recognized set — must stay hidden
        // even with a maxed-out snapshot.
        #expect(TraditionUnlockEvaluator.isUnlocked(
            condition: "typo_in_catalog", snapshot: richSnapshot
        ) == false)
        #expect(TraditionUnlockEvaluator.isUnlocked(
            condition: "", snapshot: richSnapshot
        ) == false)
    }

    // MARK: - Default snapshot constructor

    @Test func defaultSnapshotIsEmpty() {
        let snapshot = TraditionUnlockSnapshot()
        #expect(snapshot.expandedBaseTraditions.isEmpty)
        #expect(snapshot.savedTales == 0)
        #expect(snapshot.moodsCovered.isEmpty)
        #expect(snapshot.kitsCompleted.isEmpty)
        #expect(snapshot.traditionRevisitCount.isEmpty)
        // None of the 3 example predicates fire on a default snapshot.
        for condition in ["deep_listener", "cross_mood_explorer", "tradition_revisitor"] {
            #expect(TraditionUnlockEvaluator.isUnlocked(
                condition: condition, snapshot: snapshot
            ) == false)
        }
    }

    // MARK: - Predicate independence

    @Test func predicatesAreIndependentOfOtherSnapshotFields() {
        // deep_listener firing should NOT depend on moodsCovered or kitsCompleted.
        let snapshot = TraditionUnlockSnapshot(
            expandedBaseTraditions: ["griot", "indigenous-american-oral-history",
                                     "seanchai", "rakugo", "slam-poetry"],
            savedTales: 5,
            moodsCovered: [],          // empty
            kitsCompleted: [],         // empty
            traditionRevisitCount: [:] // empty
        )
        #expect(TraditionUnlockEvaluator.isUnlocked(
            condition: "deep_listener", snapshot: snapshot
        ))
        // cross_mood_explorer doesn't fire here.
        #expect(TraditionUnlockEvaluator.isUnlocked(
            condition: "cross_mood_explorer", snapshot: snapshot
        ) == false)
    }
}
