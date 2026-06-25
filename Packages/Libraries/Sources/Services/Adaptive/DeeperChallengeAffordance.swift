import Foundation
import ForgeMasteryEngine
import Models

/// Phase D of the ForgeMasteryEngine integration per
/// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D — the
/// mastery-driven "deeper challenge" affordance that surfaces on each
/// unlocked Adventure mode-card when the kid's mastery on the
/// corresponding kit crosses an edge-of-competence threshold.
///
/// Pure value-type service — every method is `nonisolated` so previews
/// + tests can drive it without spinning up a SwiftData host. The
/// affordance never speaks "deeper challenge" out loud (engine-internal
/// term); kid-facing copy is sourced from
/// ``KitMasteryCopyCatalog/line(for:kit:)`` with the `.stretch`
/// rationale so the anti-shame token blocklist stays enforced at the
/// catalog seam.
///
/// **Anti-shame invariants** (locked at the test layer):
///
/// - The threshold is the engine's edge-of-competence floor (mastery
///   score ≥ 0.80). Below the threshold returns `false` — no pill.
/// - Tale Trial is unmapped in ``Models/ModeMasteryMapping`` —
///   surfacing a hint on a blind-judged surface would defeat the
///   rubric. The affordance never lights for Tale Trial.
/// - Kid-facing copy NEVER includes raw scores, "harder", "easier",
///   "wrong", "stuck", or "master" — all blocked at the
///   ``KitMasteryCopyCatalog`` blocklist that
///   ``KitMasteryRecommender`` already exercises.
/// - The analytics event ``deeperChallengeAvailable(mode:)`` travels
///   the mode raw value only — never the kit, never the mastery
///   score (anti-fingerprinting per COPPA-2026 anti-PII discipline).
public nonisolated enum DeeperChallengeAffordance {
    /// Edge-of-competence threshold. Calibrated to the engine's
    /// `target difficulty band [mastery + 0.10, 0.20]` heuristic — at
    /// mastery 0.80 the kid is in the "racing ahead" cohort the
    /// `.stretch` rationale is designed for. Calling this out as a
    /// static `let` makes the threshold a single-line tunable.
    public static let masteryThreshold: Double = 0.80

    /// Whether the deeper-challenge affordance should surface on a
    /// mode-card. `score` is the per-kit
    /// ``ForgeMasteryEngine.TopicMasteryState/masteryScore``. Returns
    /// `false` for `nil` (kit absent from cache) so cold-launch kids
    /// see the canonical unadorned mode-card.
    public static func shouldSurface(masteryScore score: Double?) -> Bool {
        guard let score else { return false }
        return score >= masteryThreshold
    }

    /// Kid-facing Bramble copy for the affordance. Always sourced from
    /// ``KitMasteryCopyCatalog`` with the `.stretch` rationale so the
    /// anti-shame token blocklist holds.
    public static func brambleCopy(for kit: KitID) -> String {
        KitMasteryCopyCatalog.line(for: .stretch, kit: kit)
    }

    /// SF Symbol for the affordance pill. Mirrors
    /// ``KitMasteryCopyCatalog.Kind/stretch/symbolName`` — `sparkles`
    /// — so the visual register matches the Practice-with-Bramble
    /// stretch card (PR #132). Explicitly NOT a trophy / star /
    /// medal / rosette per the catalog's anti-judgment symbol blocklist.
    public static let symbolName: String = KitMasteryCopyCatalog.Kind.stretch.symbolName
}
