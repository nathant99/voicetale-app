import Testing
import Foundation
@testable import AppFeature
import Models
import ForgeAnalytics

@MainActor
@Suite("AnalyticsService")
struct AnalyticsServiceTests {
    @Test func sessionStartedEventHasNoProperties() {
        let event = VoiceTaleAnalyticsEvent.sessionStarted
        #expect(event.name == "session_started")
        #expect(event.properties.isEmpty)
    }

    @Test func taleRecordingStartedCarriesMood() {
        let event = VoiceTaleAnalyticsEvent.taleRecordingStarted(mood: .funny)
        #expect(event.name == "tale_recording_started")
        #expect(event.properties["mood"] == "funny")
    }

    @Test func taleRecordingCompletedBucketsDuration() {
        // 60-90s bucket
        let normal = VoiceTaleAnalyticsEvent.taleRecordingCompleted(durationSeconds: 75, mood: .tender)
        #expect(normal.properties["duration_bucket"] == "60_to_90s")
        #expect(normal.properties["mood"] == "tender")

        // Below 60s
        let short = VoiceTaleAnalyticsEvent.taleRecordingCompleted(durationSeconds: 30, mood: .scary)
        #expect(short.properties["duration_bucket"] == "under_60s")

        // Above 150s
        let long = VoiceTaleAnalyticsEvent.taleRecordingCompleted(durationSeconds: 200, mood: .wild)
        #expect(long.properties["duration_bucket"] == "over_150s")
    }

    @Test func taleSavedCarriesBeatHitFlag() {
        let saved = VoiceTaleAnalyticsEvent.taleSavedToAnthology(mood: .funny, hitAllBeats: true)
        #expect(saved.properties["mood"] == "funny")
        #expect(saved.properties["hit_all_beats"] == "true")
    }

    @Test func reflectionShownIncludesModelAvailabilityFlag() {
        let event = VoiceTaleAnalyticsEvent.reflectionShown(
            mood: .tender,
            beat: .close,
            modelAvailable: false
        )
        #expect(event.properties["mood"] == "tender")
        #expect(event.properties["beat"] == "close")
        #expect(event.properties["model_available"] == "false")
    }

    @Test func traditionExploredCarriesSlug() {
        let event = VoiceTaleAnalyticsEvent.traditionExplored(slug: "rakugo")
        #expect(event.properties["tradition_slug"] == "rakugo")
    }

    @Test func voiceRecordingSharedCarriesMoodAndBucketedDuration() {
        // Pillar Deepening C1 Phase D — categorical-only payload; no PII.
        let event = VoiceTaleAnalyticsEvent.voiceRecordingShared(
            mood: .tender,
            durationSeconds: 95
        )
        #expect(event.name == "voice_recording_shared")
        #expect(event.properties["mood"] == "tender")
        #expect(event.properties["duration_bucket"] == "90_to_120s")
        // Categorical-only: no raw seconds, no tale id, no transcript.
        #expect(event.properties["tale_id"] == nil)
        #expect(event.properties["transcript"] == nil)
        #expect(event.properties["duration_seconds"] == nil)
    }

    @Test func serviceTrackForwardsToEngine() async {
        // Build a fresh engine + service; track a single event; verify it
        // landed via the engine's eventCount accessor. Tasks fired by
        // service.track must drain before we read the count.
        let engine = AnalyticsEngine()
        let service = AnalyticsService(engine: engine)
        service.track(.sessionStarted)
        // Yield a Task tick so the fire-and-forget Task fired inside
        // service.track resolves before we sample eventCount.
        try? await Task.sleep(for: .milliseconds(50))
        let count = await engine.eventCount
        #expect(count >= 1)
    }

    // MARK: - kitCompleted (Phase 1.1)

    @Test func kitCompletedNameAndKitCarried() {
        let event = VoiceTaleAnalyticsEvent.kitCompleted(kit: 3, accuracy: 1.0)
        #expect(event.name == "kit_completed")
        #expect(event.properties["kit"] == "3")
    }

    @Test func kitCompletedAccuracyBuckets() {
        // 1.0 = perfect
        let perfect = VoiceTaleAnalyticsEvent.kitCompleted(kit: 1, accuracy: 1.0)
        #expect(perfect.properties["accuracy_bucket"] == "perfect")

        // 0.5..<1.0 = majority_correct
        let majority = VoiceTaleAnalyticsEvent.kitCompleted(kit: 2, accuracy: 0.75)
        #expect(majority.properties["accuracy_bucket"] == "majority_correct")

        // 0.0..<0.5 = minority_correct
        let minority = VoiceTaleAnalyticsEvent.kitCompleted(kit: 2, accuracy: 0.25)
        #expect(minority.properties["accuracy_bucket"] == "minority_correct")

        // Negative (sentinel) = no_choice_items
        let noChoice = VoiceTaleAnalyticsEvent.kitCompleted(kit: 4, accuracy: -1.0)
        #expect(noChoice.properties["accuracy_bucket"] == "no_choice_items")
    }

    @Test func kitCompletedEmitsNoRawAccuracy() {
        // Categorical-only payload — raw accuracy must never appear on the
        // wire (approaches fingerprint territory if combined with other
        // signals).
        let event = VoiceTaleAnalyticsEvent.kitCompleted(kit: 1, accuracy: 0.83)
        #expect(event.properties["accuracy"] == nil)
        #expect(event.properties["accuracy_raw"] == nil)
    }

    // MARK: - Event-vocabulary exhaustiveness / uniqueness audit

    @Test func everyDeclaredEventHasAUniqueNonEmptyName() {
        // Centralized name-collision audit. New event cases must add an
        // entry below; the test fails if the names collide OR if a case
        // returns an empty string (e.g., a stray `default` arm).
        let representativeEvents: [VoiceTaleAnalyticsEvent] = [
            .sessionStarted,
            .taleRecordingStarted(mood: .funny),
            .taleRecordingCompleted(durationSeconds: 60, mood: .funny),
            .taleSavedToAnthology(mood: .funny, hitAllBeats: false),
            .taleRetold,
            .reflectionShown(mood: .funny, beat: .hook, modelAvailable: true),
            .traditionExplored(slug: "griot"),
            .dailyPromptViewed,
            .avatarSheetOpened,
            .voiceRecordingShared(mood: .funny, durationSeconds: 60),
            .kitCompleted(kit: 1, accuracy: 1.0),
            .lapsedReturn(daysSinceActive: 5),
            .rarePromptSurfaced(category: "hidden_tradition"),
        ]
        let names = representativeEvents.map(\.name)
        // Uniqueness
        #expect(Set(names).count == names.count)
        // Non-empty
        #expect(names.allSatisfy { !$0.isEmpty })
        // snake_case (no uppercase, no spaces)
        for name in names {
            let hasUppercase = name.contains { $0.isUppercase }
            let hasSpace = name.contains { $0 == " " }
            #expect(!hasUppercase, "Event \(name) has uppercase characters; use snake_case")
            #expect(!hasSpace, "Event \(name) has spaces; use snake_case")
        }
    }
}
