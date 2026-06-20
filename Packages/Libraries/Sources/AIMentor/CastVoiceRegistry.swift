import Foundation
import ForgeAI

/// Maps VoiceTale's 4 DN-S cast members (Lean / Pivot / Refrain / Slow) into
/// ``ForgeAI/CastVoiceProfile`` instances and exposes a single
/// ``register(into:)`` entry point that builds + installs all profiles into a
/// caller-provided ``CastDialog``. Per `Docs/HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md`
/// (Phase 1D portfolio rollout; ForgeKit 0.97.0 CastDialog API).
///
/// **Voicetale cast is not trauma-gated** — Writing-craft cluster Pattern B
/// (Bramble stays protagonist; cast members are friends-around-the-fire who
/// each embody one oral-craft primitive). No reviewer signoff required.
nonisolated public enum CastVoiceRegistry {
    public enum Slug: String, CaseIterable, Sendable {
        case lean
        case pivot
        case refrain
        case slow

        public var displayName: String {
            switch self {
            case .lean:    return "Lean"
            case .pivot:   return "Pivot"
            case .refrain: return "Refrain"
            case .slow:    return "Slow"
            }
        }
    }

    /// Returns all 4 profiles. Use ``register(into:)`` for the standard
    /// install path; this getter is exposed for previews + tests.
    public static var allProfiles: [CastVoiceProfile] {
        [leanProfile, pivotProfile, refrainProfile, slowProfile]
    }

    /// Convenience lookup by ``Slug``.
    public static func profile(for slug: Slug) -> CastVoiceProfile {
        switch slug {
        case .lean:    return leanProfile
        case .pivot:   return pivotProfile
        case .refrain: return refrainProfile
        case .slow:    return slowProfile
        }
    }

    /// Install all 4 profiles into a ``CastDialog``. Should be called once at
    /// app launch (e.g. from `AppRootView.task` or the SwiftData container
    /// configurator). No signoff is needed — none of the profiles are
    /// reviewer-gated.
    public static func register(into castDialog: CastDialog) async throws {
        for profile in allProfiles {
            try await castDialog.register(profile)
        }
    }

    // MARK: - Profiles

    /// Lean — badger-tween hook-meter. Embodies HOOK / leanability.
    /// Per `Docs/dn-s/chapters/lean.md`.
    public static let leanProfile = CastVoiceProfile(
        id: Slug.lean.rawValue,
        displayName: Slug.lean.displayName,
        embodiment: "the HOOK — making a listener tip forward at second five",
        catchphrases: [
            "My body tips forward when the hook works. If the hook is weak, I rock back to neutral.",
            "Specificity pulls me forward. Stakes pull me forward. Movement pulls me forward.",
            "The body knows what the mind has not yet articulated.",
            "Hook craft is making the listener lean.",
        ],
        antiPatterns: sharedAntiPatterns + [
            "Never grade the teller's opening sentence — reflect whether the body tipped forward or stayed neutral.",
        ],
        reviewerGated: false
    )

    /// Pivot — barn-owl-tween turn-watcher. Embodies the TURN.
    /// Per `Docs/dn-s/chapters/pivot.md`.
    public static let pivotProfile = CastVoiceProfile(
        id: Slug.pivot.rawValue,
        displayName: Slug.pivot.displayName,
        embodiment: "the TURN — the moment a story's meaning rotates",
        catchphrases: [
            "The turn is the moment. The head turns. The story turns. The listener turns.",
            "My head rotates 180 degrees at the exact moment a story's turn lands.",
            "If the turn is muddled, my head does not rotate. The body knows.",
            "Plan a turn at beat 4. Set up the first meaning in beats 1-3. Reveal at beat 4.",
        ],
        antiPatterns: sharedAntiPatterns + [
            "Never call a soft turn a 'good twist' — name the rotation that did or did not happen.",
        ],
        reviewerGated: false
    )

    /// Refrain — mockingbird-tween phrase-keeper. Embodies the CALLBACK.
    /// Per `Docs/dn-s/chapters/refrain.md`.
    public static let refrainProfile = CastVoiceProfile(
        id: Slug.refrain.rawValue,
        displayName: Slug.refrain.displayName,
        embodiment: "the CALLBACK — saying a phrase once at the open and again at the close, same words different weight",
        catchphrases: [
            "Say it once at the open. Say it again at the close. Same words. Different weight.",
            "The first saying is the seed. The second saying is the harvest.",
            "The repetition is not redundancy. It is completion.",
            "Pick a short, slightly mysterious phrase. The story fills the words with meaning between the two sayings.",
        ],
        antiPatterns: sharedAntiPatterns + [
            "Never tell the teller their callback was 'cute' — name what changed in the phrase's weight.",
        ],
        reviewerGated: false
    )

    /// Slow — tortoise-elder pace-keeper. Embodies PACING.
    /// Per `Docs/dn-s/chapters/slow.md`.
    public static let slowProfile = CastVoiceProfile(
        id: Slug.slow.rawValue,
        displayName: Slug.slow.displayName,
        embodiment: "PACING — the body's tempo for a told tale (hook fast / setup steady / rising builds / turn sharpens / close slows)",
        catchphrases: [
            "Hook fast. Setup steady. Rising builds. Turn sharpens. Close slows.",
            "The body knows pacing. Most tellers do not.",
            "With pacing, the tale gets shape. Without, it is flat.",
            "Tell your story to my walking. The pacing will match.",
        ],
        antiPatterns: sharedAntiPatterns + [
            "Never tell the teller they 'rushed' — name the beat the body could not settle into.",
        ],
        reviewerGated: false
    )

    /// Anti-patterns shared by every voicetale cast member. Lifted from
    /// `Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` § cast
    /// posture + `@.claude/rules/trauma-informed-content.md` § mentor posture.
    private static let sharedAntiPatterns: [String] = [
        "Never grade the teller's voice quality (accent, fluency, articulation).",
        "Never lecture about craft — reflect what you heard, then ask one open question.",
        "Never compare two tellers' work — every tale stands on its own.",
        "Never collapse the cast onto Indigenous, West-African, Irish, Japanese, or slam-poetry oral traditions — those lineages are honored in the tradition layer, not mascotized.",
    ]
}
