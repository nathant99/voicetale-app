import Foundation

/// Maps each Phase-1 Adventure mode-card to its dominant ``KitID`` for
/// the Phase D mastery-driven "deeper challenge" affordance per
/// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D.
///
/// Mapping rationale (per `Docs/TECHNICAL_DESIGN.md` § Adventure Mode +
/// the Word Workshop primitives the mode-cards exercise):
///
/// | Mode card        | Dominant kit       | Why                                                |
/// |------------------|--------------------|----------------------------------------------------|
/// | Hook Builder     | `.hookCraft`       | 30-second openers — pure hook-craft surface        |
/// | Pacing Walk      | `.pacingRhythm`    | Pacing matches a walking cadence                   |
/// | Turn Drill       | `.surprisePivot`   | Beat 4 rotates the meaning — the canonical pivot   |
/// | Callback Refrain | `.closingGrace`    | Phrase-at-open repeated at close — closing surface |
/// | Tale Trial       | (intentionally unmapped) | Blind-judged surface; a mastery hint here would defeat the rubric |
///
/// **Tale Trial is intentionally unmapped.** The trial's whole register
/// is "60 seconds, blind judging, no scaffolding" — surfacing a
/// "Bramble's curious about your next pivot" pill would break the
/// register. Future mastery-axis tale-trial coupling would happen
/// inside the trial flow itself, not on the mode-card.
public nonisolated enum ModeMasteryMapping {
    /// Stable mode-card identifiers. These are the same strings as
    /// ``VoiceTaleProgressionGate``'s public constants; co-located here
    /// as raw values so the mapping table can be defined as a static
    /// dictionary without an `import AppFeature` cycle (Models → no
    /// AppFeature dep).
    public enum ModeCard: String, CaseIterable, Sendable, Hashable {
        case hookBuilder      = "voicetale.adventure.hook_builder"
        case pacingWalk       = "voicetale.adventure.pacing_walk"
        case turnDrill        = "voicetale.adventure.turn_drill"
        case callbackRefrain  = "voicetale.adventure.callback_refrain"
        case taleTrial        = "voicetale.adventure.tale_trial"
    }

    /// The dominant kit each mode-card exercises. Tale Trial is
    /// deliberately omitted (`nil` lookup) — a "deeper challenge" pill
    /// on a blind-judged surface would defeat the rubric.
    public static let dominantKit: [ModeCard: KitID] = [
        .hookBuilder:     .hookCraft,
        .pacingWalk:      .pacingRhythm,
        .turnDrill:       .surprisePivot,
        .callbackRefrain: .closingGrace,
        // .taleTrial — intentionally not in the table.
    ]

    /// String-based convenience for ``VoiceTaleProgressionGate`` call
    /// sites that already carry the gate-id string. Returns `nil` for
    /// any id outside the canonical mapping (Tale Trial, unknown gates).
    public static func dominantKit(forGateID id: String) -> KitID? {
        ModeCard(rawValue: id).flatMap { dominantKit[$0] }
    }
}
