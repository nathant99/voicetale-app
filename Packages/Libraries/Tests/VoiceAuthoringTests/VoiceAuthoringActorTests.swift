import Testing
import Foundation
@testable import VoiceAuthoring
import Models

@Suite("VoiceAuthoringActor")
struct VoiceAuthoringActorTests {
    @Test func beatAtZeroIsHook() {
        #expect(VoiceAuthoringActor.beat(forElapsedSeconds: 0) == .hook)
    }

    @Test func beatAtFifteenIsSetup() {
        #expect(VoiceAuthoringActor.beat(forElapsedSeconds: 15) == .setup)
    }

    @Test func beatAtNinetyIsTurn() {
        #expect(VoiceAuthoringActor.beat(forElapsedSeconds: 90) == .turn)
    }

    @Test func beatBeyondTimelineIsNil() {
        #expect(VoiceAuthoringActor.beat(forElapsedSeconds: 200) == nil)
    }

    @Test func recordingLifecycle() async throws {
        let actor = VoiceAuthoringActor()
        try await actor.beginRecording(at: Date(timeIntervalSince1970: 0))
        let duration = try await actor.endRecording(at: Date(timeIntervalSince1970: 30))
        #expect(duration == 30)
    }

    @Test func doubleStartThrows() async throws {
        let actor = VoiceAuthoringActor()
        try await actor.beginRecording(at: Date(timeIntervalSince1970: 0))
        await #expect(throws: VoiceAuthoringActor.AuthoringError.self) {
            try await actor.beginRecording(at: Date(timeIntervalSince1970: 1))
        }
    }

    @Test func endWithoutStartThrows() async throws {
        let actor = VoiceAuthoringActor()
        await #expect(throws: VoiceAuthoringActor.AuthoringError.self) {
            _ = try await actor.endRecording(at: Date(timeIntervalSince1970: 1))
        }
    }
}

@Suite("BeatTimer")
struct BeatTimerTests {
    @Test func totalDurationIs110Seconds() {
        #expect(BeatTimer.totalSeconds == 110)
    }

    @Test func startOffsetForRisingIs30() {
        // Hook 10 + Setup 20 = 30 seconds before Rising begins.
        #expect(BeatTimer.startOffset(for: .rising) == 30)
    }

    @Test func startOffsetForCloseIs90() {
        #expect(BeatTimer.startOffset(for: .close) == 90)
    }

    @Test func progressMidwayThroughHook() throws {
        let progress = try #require(BeatTimer.progressWithinBeat(elapsedSeconds: 5))
        #expect(abs(progress - 0.5) < 0.0001)
    }

    @Test func toleranceAcceptsOnTarget() {
        #expect(BeatTimer.isWithinTolerance(actual: 10, beat: .hook))
        #expect(BeatTimer.isWithinTolerance(actual: 11.5, beat: .hook))
        #expect(BeatTimer.isWithinTolerance(actual: 8.5, beat: .hook))
    }

    @Test func toleranceRejectsOutOfBand() {
        #expect(BeatTimer.isWithinTolerance(actual: 14, beat: .hook) == false)
        #expect(BeatTimer.isWithinTolerance(actual: 5, beat: .hook) == false)
    }

    @Test func buildTimelineFillsDefaults() {
        let timeline = BeatTimer.buildTimeline(actualDurations: [.hook: 11, .turn: 28])
        #expect(timeline.count == 5)
        #expect(timeline.first { $0.beat == .hook }?.actualSeconds == 11)
        #expect(timeline.first { $0.beat == .setup }?.actualSeconds == ArcBeat.setup.targetSeconds)
        #expect(timeline.first { $0.beat == .turn }?.actualSeconds == 28)
    }
}

@Suite("RecordingMachine")
struct RecordingMachineTests {
    @Test func resetReturnsToIdle() {
        var machine = RecordingMachine()
        machine.beginRecording()
        machine.tick(elapsedSeconds: 5)
        machine.reset()
        #expect(machine.phase == .idle)
        #expect(machine.elapsedSeconds == 0)
        #expect(machine.actualDurations.isEmpty)
    }

    @Test func beginRecordingEntersHookBeat() {
        var machine = RecordingMachine()
        machine.beginRecording()
        #expect(machine.currentBeat == .hook)
        #expect(machine.isActivelyRecording)
    }

    @Test func tickAdvancesBeat() {
        var machine = RecordingMachine()
        machine.beginRecording()
        machine.tick(elapsedSeconds: 25)
        #expect(machine.currentBeat == .setup)
    }

    @Test func enterReviewSetsDuration() {
        var machine = RecordingMachine()
        machine.beginRecording()
        machine.enterReview(durationSeconds: 90)
        #expect(machine.phase == .reviewing(durationSeconds: 90))
        #expect(machine.isActivelyRecording == false)
    }

    @Test func captureBeatDurationAccumulates() {
        var machine = RecordingMachine()
        machine.captureBeatDuration(.hook, seconds: 9.5)
        machine.captureBeatDuration(.setup, seconds: 21.0)
        #expect(machine.actualDurations[.hook] == 9.5)
        #expect(machine.actualDurations[.setup] == 21.0)
    }
}

@Suite("PermissionGate")
struct PermissionGateTests {
    @Test func currentAuthorizationWhenDescriptionMissingIsUndetermined() {
        // In the SPM test target there is no Info.plist NSMicrophoneUsageDescription
        // by design — the gate must report `.undetermined` and avoid touching
        // AVAudioApplication, otherwise the test process hard-crashes.
        if !PermissionGate.hasMicrophoneUsageDescription {
            #expect(PermissionGate.currentMicrophoneAuthorization == .undetermined)
        }
    }

    @Test func requestRefusesWhenDescriptionMissing() async {
        if !PermissionGate.hasMicrophoneUsageDescription {
            let granted = await PermissionGate.requestMicrophonePermission()
            #expect(granted == false)
        }
    }
}
