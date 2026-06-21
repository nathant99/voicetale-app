import Testing
@testable import AppFeature
import ForgeProgression

@Suite("VoiceTaleProgressionGate")
struct VoiceTaleProgressionGateTests {
    @Test func allGatesPresent() {
        let gates = VoiceTaleProgressionGate.allGates()
        let ids = Set(gates.map(\.id))
        #expect(ids.contains(VoiceTaleProgressionGate.hookBuilderID))
        #expect(ids.contains(VoiceTaleProgressionGate.pacingWalkID))
        #expect(ids.contains(VoiceTaleProgressionGate.turnDrillID))
        #expect(ids.contains(VoiceTaleProgressionGate.callbackRefrainID))
        #expect(gates.count == 4)
    }

    @Test func hookBuilderIsOpenWithoutTales() {
        let manager = VoiceTaleProgressionGate.makeManager(talesSavedCount: 0)
        #expect(manager.isUnlocked(VoiceTaleProgressionGate.hookBuilderID))
    }

    @Test func pacingWalkLockedBelowThreeTales() {
        let manager = VoiceTaleProgressionGate.makeManager(talesSavedCount: 2)
        #expect(manager.isUnlocked(VoiceTaleProgressionGate.pacingWalkID) == false)
    }

    @Test func pacingWalkUnlocksAtThreeTales() {
        let manager = VoiceTaleProgressionGate.makeManager(talesSavedCount: 3)
        #expect(manager.isUnlocked(VoiceTaleProgressionGate.pacingWalkID))
    }

    @Test func turnDrillUnlocksAtFiveTales() {
        let belowThreshold = VoiceTaleProgressionGate.makeManager(talesSavedCount: 4)
        let atThreshold = VoiceTaleProgressionGate.makeManager(talesSavedCount: 5)
        #expect(belowThreshold.isUnlocked(VoiceTaleProgressionGate.turnDrillID) == false)
        #expect(atThreshold.isUnlocked(VoiceTaleProgressionGate.turnDrillID))
    }

    @Test func callbackRefrainUnlocksAtSevenTales() {
        let belowThreshold = VoiceTaleProgressionGate.makeManager(talesSavedCount: 6)
        let atThreshold = VoiceTaleProgressionGate.makeManager(talesSavedCount: 7)
        #expect(belowThreshold.isUnlocked(VoiceTaleProgressionGate.callbackRefrainID) == false)
        #expect(atThreshold.isUnlocked(VoiceTaleProgressionGate.callbackRefrainID))
    }

    @Test func unlockHintIsSurfacedForLockedGate() {
        let manager = VoiceTaleProgressionGate.makeManager(talesSavedCount: 0)
        let hint = manager.unlockHint(for: VoiceTaleProgressionGate.pacingWalkID)
        #expect(hint?.contains("3 saved tales") == true)
    }

    @Test func unlockHintReturnsNilForUnlockedGate() {
        let manager = VoiceTaleProgressionGate.makeManager(talesSavedCount: 10)
        #expect(manager.unlockHint(for: VoiceTaleProgressionGate.callbackRefrainID) == nil)
    }
}
