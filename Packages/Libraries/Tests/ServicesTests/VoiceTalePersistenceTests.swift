import Testing
import Foundation
import SwiftData
@testable import Services
import Models

@MainActor
@Suite("VoiceTalePersistence")
struct VoiceTalePersistenceTests {
    @Test func inMemoryContainerInitializes() throws {
        let container = try VoiceTalePersistence.makeInMemoryContainer()
        #expect(container.schema.entities.isEmpty == false)
    }

    @Test func schemaContainsAllFourModels() throws {
        let container = try VoiceTalePersistence.makeInMemoryContainer()
        let entityNames = Set(container.schema.entities.map(\.name))
        #expect(entityNames.contains("PersistentVoiceTaleEntry"))
        #expect(entityNames.contains("PersistentTraditionEntry"))
        #expect(entityNames.contains("PersistentPlayerProgress"))
        #expect(entityNames.contains("PersistentAnthologyMood"))
    }
}

@MainActor
@Suite("VoiceTaleStore")
struct VoiceTaleStoreTests {
    private func newContext() throws -> ModelContext {
        let container = try VoiceTalePersistence.makeInMemoryContainer()
        return ModelContext(container)
    }

    @Test func insertAndFetchRoundtrip() throws {
        let context = try newContext()
        let entry = VoiceTaleEntry(
            title: "Hook test",
            mood: .funny,
            durationSeconds: 65,
            beatTimeline: [BeatSegment(beat: .hook, targetSeconds: 10, actualSeconds: 10)],
            transcript: "Once upon"
        )
        try VoiceTaleStore.insertTale(entry, audioFileRelativePath: "tales/1.m4a", in: context)
        let fetched = VoiceTaleStore.fetchTales(in: context)
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Hook test")
        #expect(fetched.first?.mood == .funny)
    }

    @Test func fetchFilteredByMood() throws {
        let context = try newContext()
        try VoiceTaleStore.insertTale(
            VoiceTaleEntry(title: "A", mood: .funny, durationSeconds: 60, beatTimeline: [], transcript: ""),
            audioFileRelativePath: "a.m4a",
            in: context
        )
        try VoiceTaleStore.insertTale(
            VoiceTaleEntry(title: "B", mood: .scary, durationSeconds: 60, beatTimeline: [], transcript: ""),
            audioFileRelativePath: "b.m4a",
            in: context
        )
        let scary = VoiceTaleStore.fetchTales(mood: .scary, in: context)
        #expect(scary.count == 1)
        #expect(scary.first?.title == "B")
    }

    @Test func moodCounterIncrementsOnInsert() throws {
        let context = try newContext()
        try VoiceTaleStore.insertTale(
            VoiceTaleEntry(title: "Wild one", mood: .wild, durationSeconds: 60, beatTimeline: [], transcript: ""),
            audioFileRelativePath: "w.m4a",
            in: context
        )
        let moods = VoiceTaleStore.fetchAnthologyMoods(in: context)
        let wild = moods.first(where: { $0.mood == .wild })
        #expect(wild?.taleCount == 1)
    }

    @Test func progressFetchOrCreateReturnsSingleton() throws {
        let context = try newContext()
        let first = VoiceTaleStore.progressSnapshot(in: context)
        let second = VoiceTaleStore.progressSnapshot(in: context)
        #expect(first.xpTotal == 0)
        #expect(second.xpTotal == 0)
        VoiceTaleStore.updateProgress({ $0.xpTotal = 50 }, in: context)
        let third = VoiceTaleStore.progressSnapshot(in: context)
        #expect(third.xpTotal == 50)
    }

    @Test func traditionExplorationRecordsListen() throws {
        let context = try newContext()
        VoiceTaleStore.recordTraditionExplored(slug: "griot", in: context)
        VoiceTaleStore.recordTraditionExplored(slug: "griot", in: context)
        let exploration = VoiceTaleStore.fetchTraditionExploration(in: context)
        #expect(exploration.count == 1)
        #expect(exploration.first?.listenCount == 2)
        #expect(exploration.first?.firstExploredAt != nil)
    }

    @Test func anthologyMoodCustomLabel() throws {
        let context = try newContext()
        VoiceTaleStore.setMoodCustomLabel(.scary, label: "Spooky stories", in: context)
        let moods = VoiceTaleStore.fetchAnthologyMoods(in: context)
        let scary = moods.first(where: { $0.mood == .scary })
        #expect(scary?.displayLabel == "Spooky stories")
        VoiceTaleStore.setMoodCustomLabel(.scary, label: "", in: context)
        let resetMoods = VoiceTaleStore.fetchAnthologyMoods(in: context)
        let reset = resetMoods.first(where: { $0.mood == .scary })
        #expect(reset?.displayLabel == "Scary")
    }
}
