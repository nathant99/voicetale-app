import Testing
import Foundation
import ForgeMasteryEngine
@testable import Models

/// Phase A coverage for ``KitMasteryTopology`` per
/// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase A. The static
/// graph is built at module load — failures here surface as
/// `fatalError` at first access, so this suite is the gate that
/// catches a bad topology declaration before ship.
@Suite("KitMasteryTopology")
struct KitMasteryTopologyTests {
    // MARK: - Graph integrity

    @Test func graphRegistersEveryKitID() {
        // Every case of `KitID` must have a corresponding node.
        // A missed case would silently drop the kit from
        // `NextProblemPicker.recommendations(...)` (Phase C).
        let topics = Set(KitMasteryTopology.graph.nodes.keys)
        let allKits = Set(KitID.allCases)
        #expect(topics == allKits)
    }

    @Test func graphHasNineNodes() {
        #expect(KitMasteryTopology.graph.nodes.count == 9)
    }

    @Test func topologicalOrderContainsEveryKit() {
        let order = KitMasteryTopology.graph.topologicalOrder
        #expect(order.count == 9)
        #expect(Set(order) == Set(KitID.allCases))
    }

    // MARK: - Prerequisite chain locks

    @Test func hookCraftAndMoodAreRoots() {
        // Both root topics carry zero prerequisites — the
        // catch-anywhere entry kit for new players is
        // `hookCraft`; `mood` is the second root supporting the
        // mood-reprise + surprise-pivot depth-2 nodes.
        let hook = KitMasteryTopology.graph.nodes[.hookCraft]
        let mood = KitMasteryTopology.graph.nodes[.mood]
        #expect(hook?.prerequisites.isEmpty == true)
        #expect(mood?.prerequisites.isEmpty == true)
    }

    @Test func sensoryDetailDependsOnHookCraft() {
        let sensory = KitMasteryTopology.graph.nodes[.sensoryDetail]
        #expect(sensory?.prerequisites == [.hookCraft])
    }

    @Test func depth2KitsAllDependOnSensoryDetail() {
        // arcCompleteness / voiceCharacter / pacingRhythm each
        // depend solely on sensoryDetail per the proposed
        // topology. moodReprise additionally depends on mood.
        let arc = KitMasteryTopology.graph.nodes[.arcCompleteness]
        let voice = KitMasteryTopology.graph.nodes[.voiceCharacter]
        let pacing = KitMasteryTopology.graph.nodes[.pacingRhythm]
        let reprise = KitMasteryTopology.graph.nodes[.moodReprise]
        #expect(arc?.prerequisites == [.sensoryDetail])
        #expect(voice?.prerequisites == [.sensoryDetail])
        #expect(pacing?.prerequisites == [.sensoryDetail])
        #expect(reprise?.prerequisites == [.sensoryDetail, .mood])
    }

    @Test func surprisePivotDependsOnMoodAndVoiceCharacter() {
        let pivot = KitMasteryTopology.graph.nodes[.surprisePivot]
        #expect(pivot?.prerequisites == [.mood, .voiceCharacter])
    }

    @Test func closingGraceDependsOnArcCompletenessAndSurprisePivot() {
        // The capstone kit. Locks the deepest depth-4 path.
        let close = KitMasteryTopology.graph.nodes[.closingGrace]
        #expect(close?.prerequisites == [.arcCompleteness, .surprisePivot])
    }

    @Test func topologicalOrderRespectsAllPrerequisites() {
        // Every node MUST appear in the topological order AFTER
        // all its prerequisites. Generic check that catches a
        // future topology error even if the per-pair locks
        // above pass.
        let order = KitMasteryTopology.graph.topologicalOrder
        var seen: Set<KitID> = []
        for kit in order {
            if let node = KitMasteryTopology.graph.nodes[kit] {
                for prereq in node.prerequisites {
                    #expect(seen.contains(prereq),
                        "\(kit) appeared before its prerequisite \(prereq)")
                }
            }
            seen.insert(kit)
        }
    }

    @Test func freshStateFrontierIsRoots() {
        // With no per-topic state, the frontier (= topics whose
        // prereqs are met but who aren't yet mastered) is exactly
        // the root set.
        let frontier = KitMasteryTopology.graph.frontierTopics(
            masteredAtOrAbove: 0.8,
            state: [:]
        )
        #expect(frontier == [.hookCraft, .mood])
    }

    // MARK: - KitID raw-value pinning

    @Test func kitRawValuesMatchExpectedNumbering() {
        // The raw values 1...9 mirror the existing `kit_0N` JSON
        // filenames bundled in `Services/Resources/QuestionKits/`.
        // A rename here would silently break the
        // `QuestionKitLoader.loadKitForRotation(seed:)` integration
        // path in Phase C.
        #expect(KitID.hookCraft.rawValue == 1)
        #expect(KitID.sensoryDetail.rawValue == 2)
        #expect(KitID.arcCompleteness.rawValue == 3)
        #expect(KitID.mood.rawValue == 4)
        #expect(KitID.voiceCharacter.rawValue == 5)
        #expect(KitID.moodReprise.rawValue == 6)
        #expect(KitID.pacingRhythm.rawValue == 7)
        #expect(KitID.surprisePivot.rawValue == 8)
        #expect(KitID.closingGrace.rawValue == 9)
    }

    @Test func displayNamesAreNonEmpty() {
        for kit in KitID.allCases {
            #expect(!kit.displayName.isEmpty)
        }
    }
}
