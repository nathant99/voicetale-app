import Foundation

/// Quartile bucket for a per-kit mastery score in `[0, 1]`. Used by the
/// `kitMasteryAdvanced(kit:fromBand:toBand:)` analytics surface so the
/// wire shape is categorical (4 cases) rather than a continuous double
/// — anti-fingerprinting + COPPA-2026 anti-PII discipline per
/// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase B + the band-only
/// rule codified in `@.claude/rules/age-assurance.md` § "2026 FTC
/// COPPA Rule Amendments" (no raw signals that approach session-
/// fingerprint territory).
///
/// Boundaries match the natural quartile split (0/.25/.5/.75/1.0):
///
/// | Band | Score range |
/// |---|---|
/// | `.emerging`   | 0.0 ≤ score < 0.25 |
/// | `.developing` | 0.25 ≤ score < 0.50 |
/// | `.meeting`    | 0.50 ≤ score < 0.75 |
/// | `.deepening`  | 0.75 ≤ score ≤ 1.00 |
///
/// Naming intentionally avoids "below grade level" / "above grade
/// level" framing — VoiceTale's anti-shame discipline (ADR-016)
/// frames growth as a journey, not a deficiency.
public nonisolated enum MasteryBand: String, Sendable, CaseIterable, Hashable {
    case emerging
    case developing
    case meeting
    case deepening

    /// Map a `masteryScore` in `[0, 1]` to its band. Out-of-range
    /// inputs clamp to the nearest band (a defensive choice — the
    /// engine guarantees `[0, 1]` but downstream consumers may drift).
    public static func band(forScore score: Double) -> MasteryBand {
        let clamped = max(0.0, min(1.0, score))
        switch clamped {
        case ..<0.25:    return .emerging
        case ..<0.50:    return .developing
        case ..<0.75:    return .meeting
        default:         return .deepening
        }
    }
}
