import Foundation
import ForgeMasteryEngine

/// Anti-shame Bramble-voice copy for the ForgeMasteryEngine Phase C
/// "Practice with Bramble" three-card surface. Each rationale-kind
/// (extend / consolidate / stretch) maps to a kid-readable line keyed
/// off the ``KitID`` of the recommended kit.
///
/// **The catalog is the only place where Bramble speaks about mastery
/// state.** Every other surface (analytics, log lines, internal state)
/// uses categorical band names (`emerging` / `developing` / `meeting`
/// / `deepening`) — never raw scores, never "harder" / "easier" /
/// "wrong" / "stuck" / "behind". The anti-shame invariants are
/// asserted at the unit-test layer via
/// `KitMasteryRecommenderTests.copyCatalogAvoidsShameTokens`.
///
/// Tone-shape rules (apply to every line in the catalog):
///
/// - **Never name the rationale**: don't say "extend / consolidate /
///   stretch" out loud — those are engine terms. Speak about Bramble
///   noticing the kit, never about the kid's score.
/// - **Use second-person warm address**: "you" / "your" (anti-
///   credentialism per CQ `CONTENT_STYLE_GUIDE.md` § 4.5).
/// - **Verbs of curiosity**: "wonder" / "notice" / "curious" / "play
///   with" — never "improve" / "fix" / "master".
/// - **Anti-shame token blocklist** (every entry MUST pass):
///   - `hard`, `harder`, `hardest`, `difficult`
///   - `easy`, `easier`, `easiest`
///   - `wrong`, `mistake`, `error`, `fail`
///   - `stuck`, `behind`, `slower`, `weak`, `weakness`, `gap`
///   - `master`, `mastery`, `mastered`, `mastering`
///   - `score`, `rating`, `level up`, `next level`
///   - `practice more`, `you should`, `you need`
///
/// Per `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase C open question
/// #3 — "anti-shame regression risk on stretch recommendations" — the
/// stretch tier in particular is constrained to NEVER frame the
/// recommended kit as "harder" or as something the kid hasn't mastered
/// yet.
public nonisolated enum KitMasteryCopyCatalog {

    /// Static catalog by rationale-kind. The rationale-kind is the
    /// stable string (one of `"extend" / "consolidate" / "stretch" /
    /// "deeperChallengeOpener"`) emitted by either
    /// ``KitMasteryRecommendation/Kind`` (the first three) or the
    /// Phase D second-half "I noticed you went deeper there"
    /// reflection-opener slot (the fourth); the per-`KitID` table
    /// inside each kind keys the per-kit line so each of the 9 craft
    /// kits has a vetted Bramble line per rationale.
    ///
    /// `.deeperChallengeOpener` opens Bramble's reflection on a tale
    /// the kid started from a deeper-challenge affordance pill
    /// (per ``Services/Adaptive/DeeperChallengeAffordance`` shipped
    /// PR #136 + ``TaleRecordingContext`` threading shipped this round).
    /// The line is prepended to the first craft observation by
    /// ``AIMentor/BrambleMentor`` so the kid hears "Bramble noticed
    /// you went deeper there" BEFORE the normal listening-back
    /// reflection. The catalog stays the single seam — never inline
    /// at the prompt-builder.
    public static let lines: [Kind: [KitID: String]] = [
        .extend: [
            .hookCraft:        "Bramble is curious how your next hook will land.",
            .sensoryDetail:    "Bramble wants to hear another tale rich with little sensory details.",
            .arcCompleteness:  "Bramble notices your arcs taking shape — want to walk one through?",
            .mood:             "Bramble's wondering what mood you'll lean into next.",
            .voiceCharacter:   "Bramble's curious which voice character will visit next.",
            .moodReprise:      "Bramble's noticing the way moods echo in your tales — let's play with that.",
            .pacingRhythm:     "Bramble's curious how your pacing will shape this one.",
            .surprisePivot:    "Bramble's wondering what surprise wants to land next.",
            .closingGrace:     "Bramble's curious how your next closing will breathe out.",
        ],
        .consolidate: [
            .hookCraft:        "Bramble hasn't heard a hook from you in a while — want to revisit?",
            .sensoryDetail:    "Bramble misses your sensory details — let's come back to those.",
            .arcCompleteness:  "Bramble was thinking about your arcs the other day. Want to revisit?",
            .mood:             "Bramble's been remembering your mood work — want to come back to it?",
            .voiceCharacter:   "Bramble's been wondering about your voice characters. Want to revisit?",
            .moodReprise:      "Bramble misses the way your moods reprise. Want to come back to it?",
            .pacingRhythm:     "Bramble's been thinking about your pacing. Want to revisit?",
            .surprisePivot:    "Bramble was just thinking about your surprises — want to revisit?",
            .closingGrace:     "Bramble's been wondering about your closings. Want to come back?",
        ],
        .stretch: [
            .hookCraft:        "Bramble's wondering what your hooks could open up next.",
            .sensoryDetail:    "Bramble's curious which sensory details want to land next.",
            .arcCompleteness:  "Bramble's wondering what new arc shape you'll find next.",
            .mood:             "Bramble's curious which mood is calling to you next.",
            .voiceCharacter:   "Bramble's curious which voice character wants to visit next.",
            .moodReprise:      "Bramble's wondering what reprise your tales might find next.",
            .pacingRhythm:     "Bramble's curious how your pacing might shift next.",
            .surprisePivot:    "Bramble's wondering what surprise is waiting to land.",
            .closingGrace:     "Bramble's curious what new closing shape is waiting for you.",
        ],
        .deeperChallengeOpener: [
            .hookCraft:        "Bramble noticed you reached for a sharper hook this time.",
            .sensoryDetail:    "Bramble noticed you let the sensory details breathe further this time.",
            .arcCompleteness:  "Bramble noticed you carried the arc all the way through this time.",
            .mood:             "Bramble noticed you leaned further into the mood this time.",
            .voiceCharacter:   "Bramble noticed you let the voice characters do more this time.",
            .moodReprise:      "Bramble noticed the way the mood came back around this time.",
            .pacingRhythm:     "Bramble noticed how the pacing breathed this time.",
            .surprisePivot:    "Bramble noticed the way the surprise turned this time.",
            .closingGrace:     "Bramble noticed how your closing breathed out this time.",
        ],
    ]

    /// Look up the kid-readable Bramble line for a given recommendation
    /// kind + kit. Returns a generic anti-shame fallback ("Bramble's
    /// curious what you'll bring to this one.") if the per-kit entry is
    /// somehow missing — the fallback still passes the anti-shame token
    /// blocklist invariants.
    public static func line(for kind: Kind, kit: KitID) -> String {
        lines[kind]?[kit] ?? "Bramble's curious what you'll bring to this one."
    }

    /// Stable string identifier for a recommendation kind. The first
    /// three cases mirror the per-rationale switch arms in
    /// ``KitMasteryRecommendation/Kind/rawValue`` (Practice with
    /// Bramble three-card surface). The fourth case
    /// (`.deeperChallengeOpener`) opens Bramble's reflection on a
    /// deeper-challenge tale — surfaced by ``AIMentor/BrambleMentor``
    /// when ``TaleRecordingContext/isDeeperChallenge`` is true.
    /// Catalog keys MUST match these exactly.
    public enum Kind: String, CaseIterable, Sendable, Hashable, Codable {
        case extend
        case consolidate
        case stretch
        case deeperChallengeOpener

        /// SF Symbol surfaced on the three-card practice surface +
        /// (for `.deeperChallengeOpener`) the Adventure-card affordance
        /// pill. The names are intentionally non-judgmental shapes —
        /// leaves / circle / sparkles — and NEVER trophies / stars /
        /// medals / rosettes / ratings. `.deeperChallengeOpener`
        /// reuses `sparkles` so the visual continuity carries from
        /// the affordance pill → reflection opener.
        public var symbolName: String {
            switch self {
            case .extend:                return "leaf.fill"           // growing
            case .consolidate:           return "arrow.clockwise.circle.fill" // revisit
            case .stretch:               return "sparkles"            // curiosity
            case .deeperChallengeOpener: return "sparkles"            // continuity with stretch
            }
        }
    }
}
