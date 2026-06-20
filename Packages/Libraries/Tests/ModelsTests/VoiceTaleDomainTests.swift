import Testing
import Foundation
@testable import Models

@Suite("VoiceTaleDomain")
struct VoiceTaleDomainTests {
    @Test func arcBeatTargetSecondsMatchSpec() {
        #expect(ArcBeat.hook.targetSeconds == 10)
        #expect(ArcBeat.setup.targetSeconds == 20)
        #expect(ArcBeat.rising.targetSeconds == 30)
        #expect(ArcBeat.turn.targetSeconds == 30)
        #expect(ArcBeat.close.targetSeconds == 20)
    }

    @Test func beatTimelineSumIs110Seconds() {
        let total = ArcBeat.allCases.map(\.targetSeconds).reduce(0, +)
        #expect(total == 110)
    }

    @Test func beatSegmentToleranceCheck() {
        let onTarget = BeatSegment(beat: .hook, targetSeconds: 10, actualSeconds: 11, tolerance: 0.20)
        let outOfTolerance = BeatSegment(beat: .hook, targetSeconds: 10, actualSeconds: 14, tolerance: 0.20)
        #expect(onTarget.isWithinTolerance == true)
        #expect(outOfTolerance.isWithinTolerance == false)
    }

    @Test func entryIsCodable() throws {
        let entry = VoiceTaleEntry(
            title: "Test",
            mood: .funny,
            durationSeconds: 60,
            beatTimeline: [BeatSegment(beat: .hook, targetSeconds: 10, actualSeconds: 10)],
            transcript: "Hello",
            reflection: nil
        )
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(VoiceTaleEntry.self, from: data)
        #expect(decoded.title == "Test")
        #expect(decoded.mood == .funny)
    }
}
