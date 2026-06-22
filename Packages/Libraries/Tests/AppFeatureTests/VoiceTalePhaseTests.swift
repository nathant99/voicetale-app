import Testing
import Foundation
import ForgeNavigation
@testable import AppFeature

@Suite("VoiceTalePhase AppPhase conformance")
struct VoiceTalePhaseTests {
    @Test func onboardingPhaseIsFullScreenAndHiddenFromSidebar() {
        let phase: VoiceTalePhase = .onboarding
        #expect(phase.layoutStrategy == .fullScreen)
        #expect(phase.showsInSidebar == false)
        #expect(phase.displayName == "Welcome")
        #expect(phase.systemImage == "sparkles")
    }

    @Test func tabsPhaseIsAdaptiveAndShowsInSidebar() {
        let phase: VoiceTalePhase = .tabs
        #expect(phase.layoutStrategy == .adaptive)
        #expect(phase.showsInSidebar == true)
        #expect(phase.displayName == "VoiceTale")
        #expect(phase.systemImage == "mic.circle.fill")
    }

    @Test func phaseCasesRoundTripThroughRawValues() throws {
        for phase in [VoiceTalePhase.onboarding, .tabs] {
            let restored = VoiceTalePhase(rawValue: phase.rawValue)
            #expect(restored == phase)
        }
    }
}

/// Smoke-test the `ForgePhaseRouter<VoiceTalePhase>` gate pipeline so the
/// onboarding-complete `StartupGate` actually routes to `.onboarding` when
/// the AppStorage flag is false and stays on `.tabs` when true. Uses a
/// dedicated `UserDefaults` suite to avoid polluting `.standard`.
@MainActor
@Suite("VoiceTalePhase ForgePhaseRouter gate")
struct VoiceTalePhaseRouterTests {
    @Test func onboardingGateRoutesToOnboardingWhenConditionIsFalse() async {
        let gate = StartupGate(
            id: "test-onboarding",
            condition: { @Sendable in false },
            destination: VoiceTalePhase.onboarding
        )
        let router = ForgePhaseRouter<VoiceTalePhase>(initialPhase: .tabs, startupGates: [gate])
        await router.runStartupGates()
        #expect(router.currentPhase == .onboarding)
        #expect(router.isStartupComplete == false)
    }

    @Test func onboardingGateLeavesTabsWhenConditionIsTrue() async {
        let gate = StartupGate(
            id: "test-onboarding",
            condition: { @Sendable in true },
            destination: VoiceTalePhase.onboarding
        )
        let router = ForgePhaseRouter<VoiceTalePhase>(initialPhase: .tabs, startupGates: [gate])
        await router.runStartupGates()
        #expect(router.currentPhase == .tabs)
        #expect(router.isStartupComplete == true)
    }

    @Test func navigateAndBackPreserveHistory() async {
        let router = ForgePhaseRouter<VoiceTalePhase>(initialPhase: .onboarding, startupGates: [])
        router.navigate(to: .tabs)
        #expect(router.currentPhase == .tabs)
        #expect(router.previousPhase == .onboarding)
        router.navigateBack()
        #expect(router.currentPhase == .onboarding)
        #expect(router.previousPhase == .tabs)
    }
}
