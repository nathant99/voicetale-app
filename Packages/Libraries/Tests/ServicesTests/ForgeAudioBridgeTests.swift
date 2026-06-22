import Testing
@testable import Services
import ForgeAudio

@MainActor
@Suite("ForgeAudioBridge")
struct ForgeAudioBridgeTests {
    @Test func initialStateHasNoActiveDuck() {
        let bridge = ForgeAudioBridge()
        #expect(bridge.hasActiveDuck == false)
    }

    @Test func duckIsIdempotent() {
        let bridge = ForgeAudioBridge()
        bridge.duckForSpeechIfNeeded()
        #expect(bridge.hasActiveDuck == true)
        // A second call must not re-duck — the engine would no-op anyway,
        // but the bridge guards via hasActiveDuck.
        bridge.duckForSpeechIfNeeded()
        #expect(bridge.hasActiveDuck == true)
    }

    @Test func unduckClearsTheActiveDuck() {
        let bridge = ForgeAudioBridge()
        bridge.duckForSpeechIfNeeded()
        #expect(bridge.hasActiveDuck == true)
        bridge.unduckIfNeeded()
        #expect(bridge.hasActiveDuck == false)
    }

    @Test func unduckBeforeDuckIsNoOp() {
        let bridge = ForgeAudioBridge()
        bridge.unduckIfNeeded()
        #expect(bridge.hasActiveDuck == false)
    }

    @Test func refreshAccessibilityModeDoesNotTrap() {
        // The accessibility mode resolves from UIAccessibility runtime
        // state; calling it in a unit-test environment should still be
        // safe + leave the engine in a valid state.
        let bridge = ForgeAudioBridge()
        bridge.refreshAccessibilityMode()
        #expect(bridge.engine.isEnabled)
    }
}
