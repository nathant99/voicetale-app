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
    /// stable string (one of `"extend" / "consolidate" / "stretch"`)
    /// emitted by ``KitMasteryRecommendation/Kind``; the per-`KitID`
    /// table inside each kind keys the per-kit line so each of the 9
    /// craft kits has a vetted Bramble line per rationale.
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
    ]

    /// Look up the kid-readable Bramble line for a given recommendation
    /// kind + kit. Returns a generic anti-shame fallback ("Bramble's
    /// curious what you'll bring to this one.") if the per-kit entry is
    /// somehow missing — the fallback still passes the anti-shame token
    /// blocklist invariants.
    public static func line(for kind: Kind, kit: KitID) -> String {
        lines[kind]?[kit] ?? "Bramble's curious what you'll bring to this one."
    }

    /// Stable string identifier for a recommendation kind. Mirrors the
    /// per-rationale switch arms in
    /// ``KitMasteryRecommendation/Kind/rawValue``. Catalog keys MUST
    /// match these exactly.
    public enum Kind: String, CaseIterable, Sendable, Hashable, Codable {
        case extend
        case consolidate
        case stretch

        /// SF Symbol surfaced on the three-card practice surface. The
        /// names are intentionally non-judgmental shapes — leaves /
        /// circle / sparkles — and NEVER trophies / stars / ratings.
        public var symbolName: String {
            switch self {
            case .extend:      return "leaf.fill"           // growing
            case .consolidate: return "arrow.clockwise.circle.fill" // revisit
            case .stretch:     return "sparkles"            // curiosity
            }
        }
    }
}
