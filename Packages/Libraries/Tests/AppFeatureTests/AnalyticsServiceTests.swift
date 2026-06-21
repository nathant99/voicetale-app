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
}
