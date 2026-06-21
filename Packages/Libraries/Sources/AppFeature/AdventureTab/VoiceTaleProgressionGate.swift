import Foundation
import ForgeProgression

/// Centralized gate definitions for the Adventure tab's Word Workshop modes.
/// Each gate uses the `tales_saved` secondary metric (not session count) so
/// the unlock ladder advances per saved tale — matching the Phase-1 spec in
/// `@Docs/FEATURE_PLAN.md` § Adventure Mode + `@Docs/TECHNICAL_DESIGN.md`
/// § Adventure Mode Integration ("unlocks after N saved tales").
public enum VoiceTaleProgressionGate {
    public static let hookBuilderID       = "voicetale.adventure.hook_builder"
    public static let pacingWalkID        = "voicetale.adventure.pacing_walk"
    public static let turnDrillID         = "voicetale.adventure.turn_drill"
    public static let callbackRefrainID   = "voicetale.adventure.callback_refrain"

    /// The metric key the manager reads via `metricValue(for:)` — bumped each
    /// time a tale lands in the anthology.
    public static let talesSavedMetricKey = "tales_saved"

    /// All Phase-1 gates. Hook Builder is open from session zero; the rest
    /// gate behind 3 / 5 / 7 saved tales respectively.
    public static func allGates() -> [ContentGate] {
        [
            ContentGate(
                id: hookBuilderID,
                requiredSessions: 0,
                displayName: "Hook Builder",
                unlockHint: "Open from the start.",
                secondaryCriteria: []
            ),
            ContentGate(
                id: pacingWalkID,
                requiredSessions: 0,
                displayName: "Pacing Walk",
                unlockHint: "Unlocks after 3 saved tales.",
                secondaryCriteria: [
                    SecondaryCriterion(
                        metricKey: talesSavedMetricKey,
                        requiredValue: 3,
                        displayLabel: "3 saved tales"
                    )
                ]
            ),
            ContentGate(
                id: turnDrillID,
                requiredSessions: 0,
                displayName: "Turn Drill",
                unlockHint: "Unlocks after 5 saved tales.",
                secondaryCriteria: [
                    SecondaryCriterion(
                        metricKey: talesSavedMetricKey,
                        requiredValue: 5,
                        displayLabel: "5 saved tales"
                    )
                ]
            ),
            ContentGate(
                id: callbackRefrainID,
                requiredSessions: 0,
                displayName: "Callback Refrain",
                unlockHint: "Unlocks after 7 saved tales.",
                secondaryCriteria: [
                    SecondaryCriterion(
                        metricKey: talesSavedMetricKey,
                        requiredValue: 7,
                        displayLabel: "7 saved tales"
                    )
                ]
            ),
        ]
    }

    /// Build a fresh manager seeded with the current `talesSavedCount`. Used
    /// at view render time so the gate evaluation reflects live anthology
    /// state without persisting tale-count into a separate UserDefaults slot.
    public static func makeManager(talesSavedCount: Int) -> ForgeProgressionManager {
        var manager = ForgeProgressionManager(
            gates: allGates(),
            persistenceKey: "VoiceTaleAdventure"
        )
        manager.recordMetric(talesSavedMetricKey, value: talesSavedCount)
        return manager
    }
}
