import Foundation

/// Delight & Polish "Surprise" micro-delight — small recognitions that
/// surface when the kid does something unusual that the system notices
/// and names back warmly. Distinct from ``MasteryMoment`` (internalization)
/// and the Discovery surface (intentional hidden content): Surprise fires
/// when the kid's CURRENT tale combines with their HISTORY in a way the
/// system can recognize as fresh. Per
/// `@Docs/AUDIT_MICRO_DELIGHT_COVERAGE_2026-06-24.md` § Reds — Surprise.
///
/// Register: Bramble grandmother per `@.claude/rules/distributed-
/// narrative.md` § "Pattern B — hero mascot stays primary". The
/// recognition celebrates the FRESH presence of a pattern (first
/// new-mood / first new voice preset / a within-session
/// tradition-echo) WITHOUT shaming the absence of variety on prior
/// sessions.
///
/// Pure-value + `nonisolated` so view code can derive the moment
/// without crossing an actor boundary. Returns `nil` when no archetype
/// fires for the just-finished tale.
///
/// **Anti-shame contract** (locked by unit tests):
/// - The copy never frames the absence of variety as "finally" /
///   "always" / "never tried" / "should have". Each archetype's
///   headline + body celebrates the presence of variety.
/// - Suppressed on distress paths (callers don't derive a moment when
///   ``BrambleMentor.lastDistressAxis`` is non-nil).
/// - Priority discipline: ``MasteryMoment`` wins when both would fire
///   (mastery = deeper, rarer signal); the surprise strip is suppressed
///   in that case. The strip sits BELOW the voice-variation callout
///   when both are present (surprise is the lighter recognition).
nonisolated public enum SurpriseMoment: String, Sendable, Hashable, CaseIterable, Codable {
    /// First time the kid tells a tale in a mood they've never used
    /// before (e.g., 12 funny tales, then their first scary). Bramble
    /// names the freshness without grading the prior streak.
    case firstNewMoodExplored = "first_new_mood_explored"
    /// Within-session pairing: the kid told a tale + opened the
    /// tradition gallery in the same sitting AND today's tale mood
    /// matches the region's craft primitive on at least one tradition
    /// they viewed. Bramble names the pairing.
    case traditionEchoSameSession = "tradition_echo_same_session"
    /// First time the kid uses a non-narrator voice preset (ogre /
    /// sprite / sage / hero) in any tale. Distinct from the
    /// ``MasteryMoment/voiceVariationMastery`` archetype which fires
    /// at ≥ 3 distinct presets across one tale; this fires the FIRST
    /// time the kid ever uses ANY non-narrator preset.
    case voicePresetFreshUse = "voice_preset_fresh_use"

    /// SF Symbol name for the strip's lead glyph. Drawn at `.tint` so
    /// it matches Bramble's existing register.
    public var systemImage: String {
        switch self {
        case .firstNewMoodExplored:      return "leaf.arrow.circlepath"
        case .traditionEchoSameSession:  return "rays"
        case .voicePresetFreshUse:       return "waveform"
        }
    }

    /// One-line strip header (caption weight). The strip body is the
    /// ``body`` below; both are surfaced in the strip card.
    public var headline: String {
        switch self {
        case .firstNewMoodExplored:
            return "A new room you walked into."
        case .traditionEchoSameSession:
            return "A tradition next door to your tale."
        case .voicePresetFreshUse:
            return "A new voice you tried on."
        }
    }

    /// Body line — Bramble-register recognition; never grades the
    /// absence of variety.
    public var body: String {
        switch self {
        case .firstNewMoodExplored:
            return "That mood is fresh in your telling — and it suited you."
        case .traditionEchoSameSession:
            return "You told the tale and you reached for a tradition. The two are talking to each other."
        case .voicePresetFreshUse:
            return "Trying a voice on is its own kind of craft — that one carried."
        }
    }
}

/// Inputs the derivation function consumes to decide which surprise
/// archetype (if any) fires for the just-finished tale. Pure value type
/// so callers can build it from any source (in-memory tale data,
/// persisted snapshot, test fixture).
nonisolated public struct SurpriseMomentInputs: Sendable, Hashable {
    /// The mood of the just-finished tale. Required so the derivation
    /// can recognize whether `todayMood` is fresh against the
    /// ``moodsEverTold`` history.
    public let todayMood: VoiceTaleMood
    /// All moods the kid has saved a tale in BEFORE the just-finished
    /// one. Used by ``SurpriseMoment/firstNewMoodExplored`` — fires when
    /// `todayMood` is NOT in this set AND the set is non-empty (a brand-
    /// new kid telling their very first scary tale wouldn't get a
    /// "fresh mood" surprise; the surprise lives at the EDGE of an
    /// existing pattern).
    public let moodsEverTold: Set<VoiceTaleMood>
    /// `true` when the kid opened the tradition gallery in the same
    /// sitting as the just-finished tale AND the tradition card they
    /// most recently dwelled on shares the mood register with
    /// ``todayMood``. The "tradition-echo" archetype's first half. The
    /// caller computes the mood-register match via
    /// ``TraditionCatalogLoader`` — this struct just sees the resolved
    /// boolean.
    public let traditionEchoEligibleThisSession: Bool
    /// Voice-character preset slugs (e.g. `"narrator"`, `"hero"`) used
    /// across the 5 beats of the just-finished tale. The narrator
    /// preset is the default; non-narrator presets are the ones
    /// ``voicePresetFreshUse`` recognizes.
    public let todayPresets: Set<String>
    /// All non-narrator voice-character preset slugs the kid has used
    /// in any PRIOR tale. Used by ``SurpriseMoment/voicePresetFreshUse``
    /// — fires when ``todayPresets`` contains at least one
    /// non-narrator preset AND ``priorNonNarratorPresets`` is empty
    /// (a true first-encounter).
    public let priorNonNarratorPresets: Set<String>

    public init(
        todayMood: VoiceTaleMood,
        moodsEverTold: Set<VoiceTaleMood>,
        traditionEchoEligibleThisSession: Bool,
        todayPresets: Set<String>,
        priorNonNarratorPresets: Set<String>
    ) {
        self.todayMood = todayMood
        self.moodsEverTold = moodsEverTold
        self.traditionEchoEligibleThisSession = traditionEchoEligibleThisSession
        self.todayPresets = todayPresets
        self.priorNonNarratorPresets = priorNonNarratorPresets
    }
}

extension SurpriseMoment {
    /// The narrator preset slug — the default voice. Non-narrator
    /// presets are the ones ``voicePresetFreshUse`` recognizes.
    nonisolated public static let narratorSlug: String = "narrator"

    /// Derive the surprise archetype that fires for the just-finished
    /// tale. Returns `nil` when no archetype qualifies. Priority order
    /// (highest first): `.firstNewMoodExplored` → `.voicePresetFreshUse`
    /// → `.traditionEchoSameSession`. A single moment fires per
    /// reflection — kid sees ONE recognition strip, not three stacked.
    ///
    /// `firstNewMoodExplored` leads priority because it's the most
    /// emotionally legible — the kid stepped into a register they
    /// hadn't tried before. `voicePresetFreshUse` next because it
    /// recognizes a craft pattern that's narrower than mood breadth.
    /// `traditionEchoSameSession` last because it requires the kid to
    /// also have opened the gallery — the recognition is real but
    /// the signal is less direct.
    ///
    /// Pure function — no side effects, no I/O. Testable without a
    /// SwiftUI host.
    public static func derive(from inputs: SurpriseMomentInputs) -> SurpriseMoment? {
        // First-new-mood — kid has prior mood history AND today's
        // mood is fresh.
        if !inputs.moodsEverTold.isEmpty && !inputs.moodsEverTold.contains(inputs.todayMood) {
            return .firstNewMoodExplored
        }
        // Voice-preset fresh use — kid used a non-narrator preset
        // today AND has never used a non-narrator preset before.
        let todayNonNarrator = inputs.todayPresets.subtracting([narratorSlug])
        if !todayNonNarrator.isEmpty && inputs.priorNonNarratorPresets.isEmpty {
            return .voicePresetFreshUse
        }
        // Tradition-echo — kid opened gallery this session AND today's
        // tale mood matches a tradition register they dwelled on.
        if inputs.traditionEchoEligibleThisSession {
            return .traditionEchoSameSession
        }
        return nil
    }
}
