import Foundation

/// Delight & Polish "Mastery moments" — small recognitions that surface
/// when the kid demonstrates an internalized story-craft pattern. Per
/// `@Docs/FEATURE_PLAN.md` § Delight & Polish → "Mastery moments — Distinct
/// screen ripple + chord when child internalizes story arc intuition".
///
/// Register: Bramble grandmother per `@.claude/rules/distributed-
/// narrative.md` § "Pattern B — hero mascot stays primary". The copy
/// celebrates the craft pattern without grading it as "advanced" or
/// "good" — recognition, not assessment.
///
/// Pure-value + `nonisolated` so view code can derive the moment without
/// crossing an actor boundary. Returns `nil` from ``derive(...)`` when no
/// pattern fires for the current tale — the surface simply doesn't
/// render.
///
/// **Anti-shame contract** (locked by unit tests):
/// - Mastery copy never frames mastery as "finally" / "still learning" /
///   "almost there". Each archetype's copy NAMES the craft pattern in
///   neutral-recognition register.
/// - The moment ALWAYS suppresses on distress paths (callers don't
///   derive a moment when ``BrambleMentor.lastDistressAxis`` is non-nil).
/// - Priority discipline: when the surface stack already has a distress
///   chip OR a voice-variation callout, the mastery callout is the
///   LOWEST-priority strip (it sits BELOW them visually).
nonisolated public enum MasteryMoment: String, Sendable, Hashable, CaseIterable, Codable {
    /// First time the kid lands all 5 beats in one tale (each beat
    /// `actualSeconds` within `targetSeconds ± tolerance`). The visual +
    /// haptic celebration tier from PR #86 fires on the SAME tale; this
    /// moment surface adds a printed recognition strip so the moment
    /// also lives on the post-tale reflection screen.
    case firstFiveBeat = "first_five_beat"
    /// Three tales in a row where the kid hit ≥ 4 of 5 beats within
    /// tolerance — a sustained arc-intuition streak (not a single hit).
    case sustainedArcStreak = "sustained_arc_streak"
    /// First tale where the kid used ≥ 3 distinct non-narrator voice
    /// characters across the 5 beats — the Phase 1.1 voice-variation
    /// surface is already there; this moment names the craft pattern.
    case voiceVariationMastery = "voice_variation_mastery"

    /// SF Symbol name for the strip's lead glyph. Drawn at `.tint` so it
    /// matches Bramble's existing register.
    public var systemImage: String {
        switch self {
        case .firstFiveBeat:           return "sparkles"
        case .sustainedArcStreak:      return "checkmark.seal"
        case .voiceVariationMastery:   return "waveform.path.ecg"
        }
    }

    /// One-line strip header (caption weight). The strip body is the
    /// ``body`` below; both are surfaced in the strip card.
    public var headline: String {
        switch self {
        case .firstFiveBeat:
            return "All five beats — held."
        case .sustainedArcStreak:
            return "Three in a row — the arc is yours."
        case .voiceVariationMastery:
            return "Three voices, one tale — a craft move."
        }
    }

    /// Body line — Bramble-register recognition; never grades.
    public var body: String {
        switch self {
        case .firstFiveBeat:
            return "Hook to close, every beat in tolerance. That's a shape the room can lean into."
        case .sustainedArcStreak:
            return "You've landed the arc three tales running. That's not luck — that's intuition."
        case .voiceVariationMastery:
            return "Three voices across one arc, each one carrying a different beat. That's a craft move."
        }
    }
}

/// Inputs the derivation function consumes to decide which mastery
/// archetype (if any) fires for the just-finished tale. Pure value type
/// so callers can build it from any source (in-memory tale data,
/// persisted snapshot, test fixture).
nonisolated public struct MasteryMomentInputs: Sendable, Hashable {
    /// `true` when every beat in this tale landed `actualSeconds` within
    /// `targetSeconds * (1 - tolerance) ... targetSeconds * (1 + tolerance)`.
    public let isFiveBeatTale: Bool
    /// Tally of the kid's prior tales where ≥ 4 of 5 beats landed in
    /// tolerance. Used by ``MasteryMoment/sustainedArcStreak`` — fires
    /// when this count reaches 2 AND the just-finished tale qualifies
    /// (so total in-a-row = 3).
    public let priorInToleranceTaleStreak: Int
    /// `true` when this tale qualifies (≥ 4 of 5 beats in tolerance).
    public let isCurrentTaleInTolerance: Bool
    /// Count of distinct non-narrator voice-character presets used
    /// across the 5 beats of the just-finished tale. The Phase 1.1
    /// voice-variation reflection trigger is `≥ 2`; mastery moment
    /// triggers at `≥ 3` so it's a more selective recognition.
    public let distinctNonNarratorVoices: Int
    /// `true` when the just-finished tale is the kid's FIRST five-beat
    /// tale (i.e. the inaugural celebration already fired). Used to
    /// gate ``MasteryMoment/firstFiveBeat`` to a single lifetime fire.
    public let isInauguralFiveBeatTale: Bool

    public init(
        isFiveBeatTale: Bool,
        priorInToleranceTaleStreak: Int,
        isCurrentTaleInTolerance: Bool,
        distinctNonNarratorVoices: Int,
        isInauguralFiveBeatTale: Bool
    ) {
        self.isFiveBeatTale = isFiveBeatTale
        self.priorInToleranceTaleStreak = priorInToleranceTaleStreak
        self.isCurrentTaleInTolerance = isCurrentTaleInTolerance
        self.distinctNonNarratorVoices = distinctNonNarratorVoices
        self.isInauguralFiveBeatTale = isInauguralFiveBeatTale
    }
}

extension MasteryMoment {
    /// Derive the mastery archetype that fires for the just-finished
    /// tale. Returns `nil` when no archetype qualifies. Priority order
    /// (highest first): `.firstFiveBeat` → `.sustainedArcStreak` →
    /// `.voiceVariationMastery`. A single moment fires per reflection
    /// — kid sees ONE recognition strip, not three stacked.
    ///
    /// Pure function — no side effects, no I/O. Testable without a
    /// SwiftUI host.
    public static func derive(from inputs: MasteryMomentInputs) -> MasteryMoment? {
        // First-five-beat lifetime moment beats everything — it's the
        // rarest by definition.
        if inputs.isInauguralFiveBeatTale {
            return .firstFiveBeat
        }
        // Sustained-arc streak (this tale qualifies + 2 prior tales in
        // streak = 3 in a row).
        if inputs.isCurrentTaleInTolerance && inputs.priorInToleranceTaleStreak >= 2 {
            return .sustainedArcStreak
        }
        // Voice variation mastery — ≥ 3 distinct non-narrator voices.
        if inputs.distinctNonNarratorVoices >= 3 {
            return .voiceVariationMastery
        }
        return nil
    }
}
