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

    // MARK: - BeatSegment voice-character (Phase 1.1)

    @Test func beatSegmentDefaultsVoiceCharacterSlugToNil() {
        let segment = BeatSegment(beat: .hook, targetSeconds: 10, actualSeconds: 10)
        #expect(segment.voiceCharacterSlug == nil)
        #expect(segment.voiceCharacterPreset == .narrator)
    }

    @Test func beatSegmentRoundTripsVoiceCharacterSlug() throws {
        let segment = BeatSegment(
            beat: .turn,
            targetSeconds: 30,
            actualSeconds: 28,
            voiceCharacterSlug: VoiceCharacterPreset.ogre.rawValue
        )
        let encoded = try JSONEncoder().encode(segment)
        let decoded = try JSONDecoder().decode(BeatSegment.self, from: encoded)
        #expect(decoded.voiceCharacterSlug == "ogre")
        #expect(decoded.voiceCharacterPreset == .ogre)
    }

    @Test func beatSegmentDecodesOldJSONWithoutVoiceCharacterField() throws {
        // Old persisted JSON predates Phase 1.1; the `voiceCharacterSlug`
        // field MUST be optional + additive so existing tales decode with
        // slug == nil (no override → natural narrator).
        let legacyJSON = """
        {
            "beat": "hook",
            "targetSeconds": 10,
            "actualSeconds": 9.5,
            "tolerance": 0.20
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(BeatSegment.self, from: legacyJSON)
        #expect(decoded.beat == .hook)
        #expect(decoded.actualSeconds == 9.5)
        #expect(decoded.voiceCharacterSlug == nil)
        #expect(decoded.voiceCharacterPreset == .narrator)
    }

    @Test func beatSegmentResolvesUnknownSlugAsNarrator() {
        let segment = BeatSegment(
            beat: .close,
            targetSeconds: 20,
            actualSeconds: 18,
            voiceCharacterSlug: "this-slug-does-not-exist"
        )
        // Slug survives encoding (we preserve it verbatim so the kid's
        // choice isn't silently dropped) but resolution falls back safely.
        #expect(segment.voiceCharacterPreset == .narrator)
    }

    @Test func beatSegmentWithVoiceCharacterPreservesTiming() {
        let original = BeatSegment(beat: .rising, targetSeconds: 30, actualSeconds: 27, tolerance: 0.20)
        let updated = original.withVoiceCharacter("hero")
        #expect(updated.beat == .rising)
        #expect(updated.targetSeconds == 30)
        #expect(updated.actualSeconds == 27)
        #expect(updated.tolerance == 0.20)
        #expect(updated.voiceCharacterSlug == "hero")
        #expect(updated.voiceCharacterPreset == .hero)
    }
}
