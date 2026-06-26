import Foundation
import ForgeMasteryEngine
import Models

/// Adventure-card parity-polish service for the SEVENTEENTH-round
/// parent-dashboard weekly digest (PR #142). Brings the broader
/// `KitMasteryRecommender` surface — already lit on
/// ``AppFeature/ProgressTab/ProgressTabView``'s `practiceSurface`
/// three-card stack (PR #132) — onto each unlocked Adventure
/// mode-card as a small in-context badge.
///
/// The badge is the small-register sibling of the existing
/// ``DeeperChallengeAffordance`` pill (PR #136 + #139):
///
/// - The pill surfaces ONLY on the `.stretch` band (mastery score
///   `≥ 0.80`) with the `sparkles` symbol + the catalog's "Bramble's
///   wondering / curious / wonderful" register.
/// - This badge surfaces ONLY on the `.extend` / `.consolidate`
///   bands with the catalog's `leaf.fill` / `arrow.clockwise.circle.fill`
///   symbols + the catalog's "Bramble is curious / Bramble misses"
///   register.
/// - The two NEVER co-render on the same card: ``badge(for:store:)``
///   returns `nil` for `.stretch` so the existing pill stays the sole
///   stretch-band affordance.
///
/// Pure value-type service — every method is `nonisolated` so previews
/// + tests can drive it without spinning up a SwiftData host. The
/// badge never authors the kid-facing copy; it always sources via
/// ``KitMasteryCopyCatalog/line(for:kit:)`` so the catalog's anti-shame
/// token blocklist holds at the single seam.
///
/// **Anti-shame invariants** (locked at the test layer):
///
/// - Tale Trial is unmapped in ``Models/ModeMasteryMapping`` — the
///   badge NEVER lights on the blind-judged surface (same rule as
///   ``DeeperChallengeAffordance``).
/// - Returns `nil` for `.stretch` so the existing sparkles pill stays
///   the sole stretch-band affordance (no double-render).
/// - SF Symbols are sourced from
///   ``KitMasteryCopyCatalog/Kind/symbolName`` — `leaf.fill` for
///   `.extend` (growing) + `arrow.clockwise.circle.fill` for
///   `.consolidate` (revisit). Trophy / star / medal / rosette
///   explicitly blocked at the unit-test layer.
/// - Kid-facing copy NEVER includes raw scores, "harder", "easier",
///   "wrong", "stuck", or "master" — all blocked at the
///   ``KitMasteryCopyCatalog`` blocklist that
///   ``KitMasteryRecommender`` already exercises.
/// - The analytics event ``practiceWithBrambleAvailable(mode:kind:)``
///   travels the mode raw value + the kind raw value (`extend` /
///   `consolidate`) only — never the kit, never the mastery score
///   (anti-fingerprinting per COPPA-2026 anti-PII discipline).
public nonisolated enum PracticeWithBrambleBadge {
    /// Resolve the practice-with-Bramble badge for `kit` from the
    /// store's cached snapshot. Returns `nil` when the engine surfaces
    /// nothing for the kit, when the recommendation falls in the
    /// `.stretch` band (deferred to ``DeeperChallengeAffordance``), or
    /// when the store is unbootstrapped (cold-launch kid sees the
    /// canonical unadorned mode-card).
    ///
    /// The `recommender` parameter exists so tests can inject a
    /// custom-graph variant; in production every consumer shares the
    /// canonical 9-node topology per
    /// ``KitMasteryRecommender/init(graph:)``.
    public static func badge(
        for kit: KitID,
        masteryStates: [KitID: TopicMasteryState],
        recommender: KitMasteryRecommender = KitMasteryRecommender()
    ) -> KitMasteryRecommendation? {
        let recs = recommender.recommendations(state: masteryStates)
        guard let match = recs.first(where: { $0.kit == kit }) else { return nil }
        switch match.kind {
        case .extend, .consolidate:
            return match
        case .stretch, .deeperChallengeOpener:
            // The stretch band has a dedicated affordance pill on the
            // Adventure surface (sparkles) shipped PR #136. The badge
            // intentionally defers so the kid never sees a double-render.
            // `.deeperChallengeOpener` is a reflection-opener slot, not
            // a recommendation kind the engine emits — kept exhaustive
            // for compiler enforcement.
            return nil
        }
    }
}
