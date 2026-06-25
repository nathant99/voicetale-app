import Testing
import Foundation
@testable import Models

/// Coverage for ``ModeMasteryMapping`` per
/// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D. Locks the
/// mode-card → dominant-kit table + the Tale Trial exclusion invariant.
@Suite("ModeMasteryMapping")
struct ModeMasteryMappingTests {
    // MARK: - Table completeness + correctness

    @Test func everyNonTrialModeMapsToAKit() {
        let trialOmitted: [ModeMasteryMapping.ModeCard] = [
            .hookBuilder, .pacingWalk, .turnDrill, .callbackRefrain,
        ]
        for mode in trialOmitted {
            #expect(ModeMasteryMapping.dominantKit[mode] != nil,
                    "Mode-card \(mode) MUST map to a dominant kit")
        }
    }

    @Test func canonicalMappingMatchesPlannedTopology() {
        #expect(ModeMasteryMapping.dominantKit[.hookBuilder] == .hookCraft)
        #expect(ModeMasteryMapping.dominantKit[.pacingWalk] == .pacingRhythm)
        #expect(ModeMasteryMapping.dominantKit[.turnDrill] == .surprisePivot)
        #expect(ModeMasteryMapping.dominantKit[.callbackRefrain] == .closingGrace)
    }

    @Test func taleTrialIsIntentionallyUnmapped() {
        // Surfacing a mastery hint on a blind-judged surface would
        // defeat the trial's rubric. Lock the exclusion.
        #expect(ModeMasteryMapping.dominantKit[.taleTrial] == nil)
    }

    // MARK: - String-based lookup (consumer-side ergonomics)

    @Test func dominantKitForGateIDMatchesEnumLookup() {
        let pairs: [(ModeMasteryMapping.ModeCard, KitID)] = [
            (.hookBuilder, .hookCraft),
            (.pacingWalk, .pacingRhythm),
            (.turnDrill, .surprisePivot),
            (.callbackRefrain, .closingGrace),
        ]
        for (mode, expectedKit) in pairs {
            #expect(ModeMasteryMapping.dominantKit(forGateID: mode.rawValue) == expectedKit)
        }
    }

    @Test func dominantKitForGateIDReturnsNilForTaleTrial() {
        let id = ModeMasteryMapping.ModeCard.taleTrial.rawValue
        #expect(ModeMasteryMapping.dominantKit(forGateID: id) == nil)
    }

    @Test func dominantKitForGateIDReturnsNilForUnknownID() {
        #expect(ModeMasteryMapping.dominantKit(forGateID: "voicetale.adventure.unknown") == nil)
        #expect(ModeMasteryMapping.dominantKit(forGateID: "") == nil)
    }

    // MARK: - Stable raw values

    @Test func gateIDRawValuesMatchProgressionGateConstants() {
        // Lock the strings — VoiceTaleProgressionGate co-locates the
        // same constants in AppFeature; the two MUST stay in lockstep.
        #expect(ModeMasteryMapping.ModeCard.hookBuilder.rawValue     == "voicetale.adventure.hook_builder")
        #expect(ModeMasteryMapping.ModeCard.pacingWalk.rawValue      == "voicetale.adventure.pacing_walk")
        #expect(ModeMasteryMapping.ModeCard.turnDrill.rawValue       == "voicetale.adventure.turn_drill")
        #expect(ModeMasteryMapping.ModeCard.callbackRefrain.rawValue == "voicetale.adventure.callback_refrain")
        #expect(ModeMasteryMapping.ModeCard.taleTrial.rawValue       == "voicetale.adventure.tale_trial")
    }

    @Test func enumExposesFiveCases() {
        #expect(ModeMasteryMapping.ModeCard.allCases.count == 5)
    }

    // MARK: - One-to-one mapping invariant

    @Test func noTwoModesShareTheSameDominantKit() {
        // Future expansion (e.g., adding a new mode that targets
        // hookCraft) should ship its own mapping decision; locking the
        // one-to-one invariant guards against an accidental double-
        // mapping that would surface the same Bramble copy on two
        // mode-cards.
        let kits = ModeMasteryMapping.dominantKit.values
        #expect(Set(kits).count == kits.count)
    }
}
