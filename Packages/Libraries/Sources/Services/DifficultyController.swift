import Foundation

/// Phase 2 DDA (Dynamic Difficulty Adjustment) engine — pure-function helper
/// that maps a kid's anthology depth into a Bramble reflection tier. Per
/// `@Docs/FEATURE_PLAN.md` § Engagement Foundation "DDA engine — invisible
/// difficulty across Bramble reflection depth + prompt sophistication".
///
/// The tier is INVISIBLE to the kid — they never see "Tier 2" or a difficulty
/// label. The DDA only varies Bramble's instruction body (per
/// ``BramblePromptBuilder/instructions(for:)``); the visible Anthology surface
/// + tale UI is unchanged.
///
/// Tiers (3 stops; deliberately coarse so the rebalance moments are slow):
///
/// | Tier        | Tales saved | Effect on Bramble |
/// |-------------|-------------|---|
/// | `.gentle`   | 0–3         | Validation-only register; Socratic prompts framed as wonder, never assignment. |
/// | `.standard` | 4–12        | Current production behaviour. One observation + one Socratic question. |
/// | `.deep`     | 13+         | Invites a deeper second observation + a Socratic question that nests two sub-questions. |
nonisolated public enum DifficultyController {
    public enum DifficultyTier: String, Sendable, Hashable, CaseIterable, Codable {
        case gentle
        case standard
        case deep
    }

    /// Threshold above which a kid graduates from `.gentle` into `.standard`.
    /// Exposed publicly so tests + the close-out doc can grep against the
    /// canonical number without re-deriving it.
    public static let gentleToStandardThreshold: Int = 4

    /// Threshold above which a kid graduates from `.standard` into `.deep`.
    public static let standardToDeepThreshold: Int = 13

    /// Map a tale count to the appropriate tier. Deterministic + total —
    /// every non-negative integer maps to a valid tier.
    public static func tier(forTalesCount count: Int) -> DifficultyTier {
        if count < gentleToStandardThreshold {
            return .gentle
        }
        if count < standardToDeepThreshold {
            return .standard
        }
        return .deep
    }
}
