import Foundation
import Models

/// Pure-function evaluator for easter-eggs tradition unlocks. Phase B of the
/// easter-eggs hidden-tradition-unlocks PLAN per
/// `@Docs/PLAN_EASTER_EGGS_TRADITION_UNLOCKS.md`. Reads a snapshot of the
/// kid's progress (saved-tale count + moods covered + kits completed +
/// tradition revisit counts + expanded base traditions) and resolves whether
/// a given unlock-condition identifier (the string stored on
/// ``TraditionEntry/unlockCondition``) is currently satisfied.
///
/// Pre-reviewer-safe: Phase B locks ONLY the evaluator + its tests. Zero
/// easter-egg entries ship in the catalog today; the gallery filter (Phase
/// C) consumes this helper to decide visibility on a per-entry basis.
///
/// Pure value type + `nonisolated public` so callers can derive a verdict
/// without crossing an actor boundary. No I/O, no side effects, no random
/// — deterministic in the snapshot.
nonisolated public enum TraditionUnlockEvaluator {

    /// Returns `true` when the given unlock-condition identifier is
    /// satisfied by the kid's current snapshot. Unknown identifiers
    /// return `false` (conservative: a catalog with a typo'd condition
    /// keeps its easter-egg hidden rather than surfacing accidentally).
    ///
    /// Recognized predicate identifiers (Phase B; Phase D may extend):
    ///
    /// - `deep_listener` — kid has explored ALL 5 base-tier traditions AND
    ///   saved ≥ 5 tales. The exploration of the full base catalog +
    ///   substantial tale history is the load-bearing signal: the kid is
    ///   not just opening cards, they're sustaining a telling practice.
    /// - `cross_mood_explorer` — kid has saved at least one tale in each
    ///   of the 4 canonical moods (`funny` / `scary` / `tender` / `wild`).
    ///   The breadth-of-register signal: a kid who has voiced every mood
    ///   register has earned the right to discover a craft tradition that
    ///   names the register-as-a-whole.
    /// - `tradition_revisitor` — kid has revisited at least 2 distinct
    ///   base traditions ≥ 3 times each. The depth-of-curiosity signal:
    ///   the kid has spent time WITH traditions, not just past them.
    ///
    /// Returns false for any unknown identifier — Phase D may extend the
    /// recognized set, but doing so requires both a code change AND a
    /// reviewer-signed catalog entry; the conservative default prevents
    /// catalog-side typos from silently revealing hidden content.
    nonisolated public static func isUnlocked(
        condition: String,
        snapshot: TraditionUnlockSnapshot
    ) -> Bool {
        switch condition {
        case "deep_listener":
            return snapshot.expandedBaseTraditions.count >= 5
                && snapshot.savedTales >= 5
        case "cross_mood_explorer":
            return snapshot.moodsCovered.count == VoiceTaleMood.allCases.count
        case "tradition_revisitor":
            let qualifying = snapshot.traditionRevisitCount.values.reduce(into: 0) { count, visits in
                if visits >= 3 { count += 1 }
            }
            return qualifying >= 2
        default:
            // Unknown identifier: stay hidden. Phase D may extend the
            // recognized set; the failure mode is biased toward not
            // revealing content rather than over-revealing.
            return false
        }
    }
}

/// Snapshot of the kid's progress fed into ``TraditionUnlockEvaluator``.
/// Value type — built by the caller from `VoiceTaleStore` queries +
/// `PersistentTraditionEntry` reads. The evaluator never touches the
/// SwiftData layer directly so it stays trivially testable.
///
/// Phase B scaffolds the type with the minimum fields the three example
/// predicates need. Phase D may extend with additional fields (e.g.
/// `voicePresetsEverUsed`, `kitsCompleted`) when reviewer-signed entries
/// land — additive at the snapshot layer is back-compat free per the same
/// pre-App-Store Codable rule the schema additions used.
nonisolated public struct TraditionUnlockSnapshot: Sendable, Hashable {
    /// Slugs of base-tier traditions the kid has expanded ≥ once.
    /// Powers `deep_listener` (≥ 5 = full base catalog explored).
    public let expandedBaseTraditions: Set<String>
    /// Total saved tales across all moods. Powers `deep_listener`'s
    /// secondary clause + future depth-of-practice predicates.
    public let savedTales: Int
    /// Set of moods the kid has saved ≥ 1 tale in. Powers
    /// `cross_mood_explorer` (must equal the full 4-mood set).
    public let moodsCovered: Set<VoiceTaleMood>
    /// Set of question-kit IDs the kid has completed. Reserved for
    /// Phase D predicates that gate on curriculum depth.
    public let kitsCompleted: Set<Int>
    /// Per-tradition revisit counts (slug → revisit count). Powers
    /// `tradition_revisitor` (≥ 2 slugs with ≥ 3 visits each).
    public let traditionRevisitCount: [String: Int]

    public init(
        expandedBaseTraditions: Set<String> = [],
        savedTales: Int = 0,
        moodsCovered: Set<VoiceTaleMood> = [],
        kitsCompleted: Set<Int> = [],
        traditionRevisitCount: [String: Int] = [:]
    ) {
        self.expandedBaseTraditions = expandedBaseTraditions
        self.savedTales = savedTales
        self.moodsCovered = moodsCovered
        self.kitsCompleted = kitsCompleted
        self.traditionRevisitCount = traditionRevisitCount
    }
}
