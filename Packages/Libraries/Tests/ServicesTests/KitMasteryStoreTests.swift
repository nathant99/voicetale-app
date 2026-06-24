import Testing
import Foundation
import SwiftData
import ForgeGamification
import ForgeMasteryEngine
import Models
@testable import Services

/// Phase A coverage for ``KitMasteryStore`` per
/// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase A. Exercises
/// the bootstrap-from-progress / record-attempt / persist-round-trip
/// path against an in-memory SwiftData container so the
/// `Codable` JSON-encoded payload on `PersistentPlayerProgress` stays
/// honest.
@MainActor
@Suite("KitMasteryStore")
struct KitMasteryStoreTests {
    private func newContext() throws -> ModelContext {
        let container = try VoiceTalePersistence.makeInMemoryContainer()
        return ModelContext(container)
    }

    private func newProgress(in context: ModelContext) -> PersistentPlayerProgress {
        let progress = PersistentPlayerProgress()
        context.insert(progress)
        try? context.save()
        return progress
    }

    // MARK: - Fresh + bootstrap

    @Test func freshStoreHasEmptyCache() throws {
        let store = KitMasteryStore()
        #expect(store.cachedStates.isEmpty)
    }

    @Test func bootstrapWithLegacyProgressKeepsEmptyCache() throws {
        // Legacy rows pre-`encodedMasteryState` should bootstrap
        // cleanly to an empty cache, no decode crash.
        let context = try newContext()
        let progress = newProgress(in: context)
        #expect(progress.encodedMasteryState == nil)

        let store = KitMasteryStore()
        store.bootstrap(progress: progress)
        #expect(store.cachedStates.isEmpty)
    }

    @Test func stateForUnseenKitReturnsFreshState() throws {
        let store = KitMasteryStore()
        let state = store.state(for: .hookCraft)
        #expect(state.attemptCount == 0)
        #expect(state.recentOutcomes.isEmpty)
        #expect(state.masteryScore == 0)
    }

    // MARK: - Record + persist round-trip

    @Test func recordCorrectAttemptIncrementsCountAndPersists() throws {
        let context = try newContext()
        let progress = newProgress(in: context)
        let store = KitMasteryStore()
        store.bootstrap(progress: progress)

        let new = store.record(
            .correctFirstTry(elapsedSeconds: 4.0),
            for: .hookCraft
        )
        #expect(new.attemptCount == 1)
        #expect(new.recentOutcomes.count == 1)
        #expect(progress.encodedMasteryState != nil)
    }

    @Test func recordIncorrectAttemptUpdatesRecentOutcomes() throws {
        let context = try newContext()
        let progress = newProgress(in: context)
        let store = KitMasteryStore()
        store.bootstrap(progress: progress)

        store.record(.incorrect(elapsedSeconds: 35.0), for: .sensoryDetail)
        store.record(.incorrect(elapsedSeconds: 40.0), for: .sensoryDetail)
        store.record(.incorrect(elapsedSeconds: 45.0), for: .sensoryDetail)

        let state = store.state(for: .sensoryDetail)
        #expect(state.attemptCount == 3)
        #expect(state.recentOutcomes.count == 3)
        // Engine's `isStuck` heuristic: 3 consecutive incorrect = stuck.
        #expect(state.isStuck == true)
    }

    @Test func recordPersistedRoundTripsAcrossNewStore() throws {
        let context = try newContext()
        let progress = newProgress(in: context)

        let writer = KitMasteryStore()
        writer.bootstrap(progress: progress)
        writer.record(.correctFirstTry(elapsedSeconds: 3.5), for: .voiceCharacter)
        writer.record(.correctFirstTry(elapsedSeconds: 4.0), for: .voiceCharacter)
        let priorScore = writer.state(for: .voiceCharacter).masteryScore

        // New store reads the same row — must observe the prior
        // attempts. Locks the Codable round-trip surface. The mastery
        // score derives partly from `Date().timeIntervalSince(fsrs.lastReview)`,
        // so it drifts by a few microseconds between the two reads —
        // use a tolerance band rather than bit-equality.
        let reader = KitMasteryStore()
        reader.bootstrap(progress: progress)
        let restored = reader.state(for: .voiceCharacter)
        #expect(restored.attemptCount == 2)
        #expect(restored.recentOutcomes.count == 2)
        #expect(abs(restored.masteryScore - priorScore) < 1e-6)
    }

    @Test func recordWithoutBootstrapDoesNotCrash() throws {
        // Pre-bootstrap calls are tolerated by the Phase A
        // scaffold contract — cache mutates, but the persist call
        // is a no-op (no `progress` to write into).
        let store = KitMasteryStore()
        store.record(.correctFirstTry(elapsedSeconds: 5.0), for: .hookCraft)
        #expect(store.state(for: .hookCraft).attemptCount == 1)
    }

    // MARK: - Decode resilience

    @Test func corruptPayloadDecodesToEmpty() throws {
        let context = try newContext()
        let progress = newProgress(in: context)
        progress.encodedMasteryState = Data([0xFF, 0xFE, 0xFD]) // garbage
        try? context.save()

        let store = KitMasteryStore()
        store.bootstrap(progress: progress)
        // Anti-shame fallback: degrade-to-empty instead of crashing.
        #expect(store.cachedStates.isEmpty)
    }

    @Test func unknownKitRawValueInPayloadIsSkipped() throws {
        // Future-proofing: a payload containing a kit raw value
        // that no longer exists in the enum (e.g., after a rename)
        // must NOT crash decode. Locks the "drop unknown keys"
        // behaviour at the store surface.
        let context = try newContext()
        let progress = newProgress(in: context)
        let raw: [Int: TopicMasteryState] = [
            KitID.hookCraft.rawValue: TopicMasteryState(attemptCount: 1),
            99: TopicMasteryState(attemptCount: 1), // bogus
        ]
        progress.encodedMasteryState = try JSONEncoder().encode(raw)
        try? context.save()

        let store = KitMasteryStore()
        store.bootstrap(progress: progress)
        #expect(store.cachedStates.count == 1)
        #expect(store.cachedStates[.hookCraft]?.attemptCount == 1)
    }
}
