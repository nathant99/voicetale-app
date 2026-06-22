import Testing
import ForgeAccessibility
@testable import SharedUI

@Suite("SessionTimerCoordinator defaults")
@MainActor
struct SessionTimerCoordinatorTests {
    @Test func voiceTaleConfigUsesCanonicalCaps() {
        let config = SessionTimerCoordinator.voiceTaleConfig
        #expect(config.maxSessionMinutes == 15)
        #expect(config.dailyTimeLimitMinutes == 30)
        #expect(config.warningAtMinutesRemaining == [5, 1])
        #expect(config.dailyWarningThresholdMinutes == 2)
    }

    @Test func newCoordinatorIsNotStartedAndPauseIsIdempotent() async {
        let coordinator = SessionTimerCoordinator()
        #expect(coordinator.hasStarted == false)
        // pause / resume / end before start must not throw or change state.
        await coordinator.pause()
        await coordinator.resume()
        await coordinator.end()
        #expect(coordinator.hasStarted == false)
    }

    @Test func startIfNeededFlipsHasStartedAndIsIdempotent() async {
        let coordinator = SessionTimerCoordinator()
        await coordinator.startIfNeeded()
        #expect(coordinator.hasStarted == true)
        // Second call is a no-op — does NOT zero the elapsed counter.
        await coordinator.startIfNeeded()
        #expect(coordinator.hasStarted == true)
        await coordinator.end()
        #expect(coordinator.hasStarted == false)
    }
}
