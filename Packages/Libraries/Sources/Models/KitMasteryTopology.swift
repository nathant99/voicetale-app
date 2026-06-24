import Foundation
import ForgeMasteryEngine
import ForgeModels

/// Identifier for VoiceTale's 9 craft kits, raw-value-coupled to the
/// existing `kit_0N` JSON filenames bundled under
/// `Services/Resources/QuestionKits/`. The kit JSON filenames are the
/// canonical source; this enum mirrors them so the
/// ``ForgeMasteryEngine.MasteryGraph`` can key per-topic state without
/// stringly-typed identifiers.
///
/// Phase A of the ForgeMasteryEngine integration per
/// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md`. Phase B wires
/// `QuizMachine.answerChoice` to `MasteryUpdater.recordAttempt(...)`;
/// Phase C consumes `NextProblemPicker.recommendations(...)` from
/// `QuestionKitLoader.loadKitForRotation(seed:)`; Phase D surfaces
/// mastery-driven "deeper challenge" affordances on Adventure
/// mode-cards.
public nonisolated enum KitID: Int, CaseIterable, Sendable, Codable, Hashable {
    case hookCraft = 1
    case sensoryDetail = 2
    case arcCompleteness = 3
    case mood = 4
    case voiceCharacter = 5
    case moodReprise = 6
    case pacingRhythm = 7
    case surprisePivot = 8
    case closingGrace = 9

    /// Human-readable name surfaced in the `MasteryGraph.Node.displayName`.
    /// Used by future affordance copy ("Bramble noticed you nail
    /// `displayName`-style turns") so the topology is the single
    /// source of truth for both data + display.
    public var displayName: String {
        switch self {
        case .hookCraft:        return "Hook craft"
        case .sensoryDetail:    return "Sensory detail"
        case .arcCompleteness:  return "Arc completeness"
        case .mood:             return "Mood anchor"
        case .voiceCharacter:   return "Voice character"
        case .moodReprise:      return "Mood reprise"
        case .pacingRhythm:     return "Pacing rhythm"
        case .surprisePivot:    return "Surprise pivot"
        case .closingGrace:     return "Closing grace"
        }
    }
}

/// Canonical 9-node DAG describing VoiceTale's craft-kit prerequisite
/// chain. Matches the proposal in
/// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § "Proposed topology":
///
/// ```
///                          arc_completeness  ──┐
///                                             ├──► closing_grace
///                        mood         ────► surprise_pivot
///                        ↑                    │
/// hook_craft  ────► sensory_detail            │
///                        │                    │
///                        └─► voice_character ─┘
///                        │
///                        └─► pacing_rhythm
///                        │
///                        └─► mood_reprise
/// ```
///
/// The graph is **statically validated at module load**: cycle-free,
/// no duplicate topics, every prerequisite is a registered node. A
/// programming error here surfaces as a `fatalError` at first access
/// (and a `KitMasteryTopologyTests` unit-test failure long before
/// shipping) per the `MasteryGraph.GraphError` contract.
public nonisolated enum KitMasteryTopology {
    /// The frozen DAG. Built once + cached as a value-type for the
    /// lifetime of the process. Pure value type; safe to capture from
    /// any isolation context.
    public static let graph: MasteryGraph<KitID> = makeGraph()

    private static func makeGraph() -> MasteryGraph<KitID> {
        let nodes: [MasteryGraph<KitID>.Node] = [
            // Roots — no prerequisites.
            .init(
                topic: .hookCraft,
                prerequisites: [],
                bloomLevel: .apply,
                displayName: KitID.hookCraft.displayName
            ),
            .init(
                topic: .mood,
                prerequisites: [],
                bloomLevel: .apply,
                displayName: KitID.mood.displayName
            ),
            // Depth-1 — built on the two roots.
            .init(
                topic: .sensoryDetail,
                prerequisites: [.hookCraft],
                bloomLevel: .apply,
                displayName: KitID.sensoryDetail.displayName
            ),
            // Depth-2 — built on sensory detail.
            .init(
                topic: .arcCompleteness,
                prerequisites: [.sensoryDetail],
                bloomLevel: .analyze,
                displayName: KitID.arcCompleteness.displayName
            ),
            .init(
                topic: .voiceCharacter,
                prerequisites: [.sensoryDetail],
                bloomLevel: .analyze,
                displayName: KitID.voiceCharacter.displayName
            ),
            .init(
                topic: .pacingRhythm,
                prerequisites: [.sensoryDetail],
                bloomLevel: .analyze,
                displayName: KitID.pacingRhythm.displayName
            ),
            .init(
                topic: .moodReprise,
                prerequisites: [.sensoryDetail, .mood],
                bloomLevel: .analyze,
                displayName: KitID.moodReprise.displayName
            ),
            // Depth-3 — surprise pivots from mood + voice character.
            .init(
                topic: .surprisePivot,
                prerequisites: [.mood, .voiceCharacter],
                bloomLevel: .evaluate,
                displayName: KitID.surprisePivot.displayName
            ),
            // Depth-4 — closing grace, the capstone.
            .init(
                topic: .closingGrace,
                prerequisites: [.arcCompleteness, .surprisePivot],
                bloomLevel: .evaluate,
                displayName: KitID.closingGrace.displayName
            ),
        ]

        do {
            return try MasteryGraph<KitID>(nodes: nodes)
        } catch {
            // A programmer error — surface immediately. The
            // `KitMasteryTopologyTests` suite catches this before
            // any ship.
            fatalError(
                "KitMasteryTopology.graph failed to build: \(error). "
                + "Fix the topology declaration; do not catch."
            )
        }
    }
}
