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

    @Test func schemaV1ContainsAllExpectedModels() {
        let names = Set(VoiceTaleSchemaV1.models.map { String(describing: $0) })
        #expect(names.contains("PersistentVoiceTaleEntry"))
        #expect(names.contains("PersistentTraditionEntry"))
        #expect(names.contains("PersistentPlayerProgress"))
        #expect(names.contains("PersistentAnthologyMood"))
    }

    @Test func migrationPlanStartsWithV1Only() {
        #expect(VoiceTaleMigrationPlan.schemas.count == 1)
        #expect(VoiceTaleMigrationPlan.stages.isEmpty)
    }

    @Test func anthologyMoodDataPrefersCustomLabel() {
        let custom = AnthologyMoodData(mood: .scary, customLabel: "Spooky stories")
        #expect(custom.displayLabel == "Spooky stories")
        let defaulted = AnthologyMoodData(mood: .scary)
        #expect(defaulted.displayLabel == "Scary")
    }

    @Test func traditionExploreDataIsCodable() throws {
        let value = TraditionExploreData(
            slug: "griot",
            firstExploredAt: Date(timeIntervalSince1970: 1_700_000_000),
            lastListenedAt: Date(timeIntervalSince1970: 1_700_001_000),
            listenCount: 3
        )
        let encoded = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(TraditionExploreData.self, from: encoded)
        #expect(decoded.slug == "griot")
        #expect(decoded.listenCount == 3)
    }
}
