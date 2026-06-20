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
}
