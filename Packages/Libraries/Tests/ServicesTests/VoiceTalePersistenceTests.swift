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

@Suite("TraditionCatalogLoader")
struct TraditionCatalogLoaderTests {
    @Test func loadsAllFiveBundledEntries() throws {
        let catalog = try TraditionCatalogLoader.loadBundled()
        #expect(catalog.version == 1)
        #expect(catalog.entries.count == 5)
        let slugs = Set(catalog.entries.map(\.slug))
        let expected: Set<String> = [
            "griot",
            "indigenous-american-oral-history",
            "seanchai",
            "rakugo",
            "slam-poetry",
        ]
        #expect(slugs == expected)
    }

    @Test func everyEntryCarriesACulturalCreditNote() throws {
        let catalog = try TraditionCatalogLoader.loadBundled()
        for entry in catalog.entries {
            #expect(entry.culturalCreditNote.isEmpty == false,
                    "Missing cultural-credit note for slug=\(entry.slug)")
        }
    }

    @Test func indigenousEntryHasContentWarning() throws {
        let catalog = try TraditionCatalogLoader.loadBundled()
        let entry = catalog.entries.first { $0.slug == "indigenous-american-oral-history" }
        #expect(entry?.contentWarning?.isEmpty == false)
    }

    @Test func crisisResourcesArePresent() throws {
        let catalog = try TraditionCatalogLoader.loadBundled()
        let resources = catalog.crisisResources?.us ?? []
        #expect(resources.contains { $0.name.contains("988") })
        #expect(resources.contains { $0.name.contains("Crisis Text Line") })
        #expect(resources.contains { $0.name.contains("Childhelp") })
    }
}

@Suite("CompanionPackLoader")
struct CompanionPackLoaderTests {
    @Test func manifestLoadsCleanly() throws {
        let manifest = try CompanionPackLoader.loadManifest()
        #expect(manifest.app == "voicetale")
        #expect(manifest.format == "pdf")
        #expect(manifest.pdfs.isEmpty == false)
        #expect(manifest.count == manifest.pdfs.count)
    }

    @Test func everyManifestPDFExists() throws {
        let manifest = try CompanionPackLoader.loadManifest()
        for fileName in manifest.pdfs {
            let url = try CompanionPackLoader.url(forPDF: fileName)
            #expect(FileManager.default.fileExists(atPath: url.path))
        }
    }

    @Test func loadEntriesReturnsUIShape() throws {
        let entries = try CompanionPackLoader.loadEntries()
        #expect(entries.isEmpty == false)
        for entry in entries {
            #expect(entry.title.isEmpty == false)
            #expect(entry.summary.isEmpty == false)
            #expect(entry.systemImage.isEmpty == false)
        }
    }

    @Test func missingPDFThrows() {
        #expect(throws: CompanionPackLoader.LoaderError.self) {
            _ = try CompanionPackLoader.url(forPDF: "does_not_exist.pdf")
        }
    }
}

@Suite("QuestionKitLoader")
struct QuestionKitLoaderTests {
    @Test func loadsAllFourPhase1Kits() throws {
        let kits = try QuestionKitLoader.loadAllPhase1Kits()
        #expect(kits.count == 4)
        #expect(kits.map(\.kit) == [1, 2, 3, 4])
    }

    @Test func kit1IsAnchoredToLean() throws {
        let kit = try QuestionKitLoader.loadKit(named: "kit_01_hook")
        #expect(kit.anchorCharacterSlug == "lean")
        #expect(kit.questions.isEmpty == false)
        #expect(kit.castCameos.count == 4)
    }

    @Test func everyKitHasAllFourCastCameos() throws {
        let kits = try QuestionKitLoader.loadAllPhase1Kits()
        let expected: Set<String> = ["lean", "pivot", "refrain", "slow"]
        for kit in kits {
            let slugs = Set(kit.castCameos.map(\.slug))
            #expect(slugs == expected, "Kit \(kit.kit) missing one of the 4 cameos: \(slugs.symmetricDifference(expected))")
        }
    }

    @Test func choiceQuestionsHaveCorrectIndex() throws {
        let kits = try QuestionKitLoader.loadAllPhase1Kits()
        for kit in kits {
            for question in kit.questions where question.kind == .choice {
                #expect(question.options != nil)
                #expect(question.correctIndex != nil)
                if let options = question.options, let index = question.correctIndex {
                    #expect(index >= 0)
                    #expect(index < options.count)
                }
            }
        }
    }

    @Test func missingResourceThrows() {
        #expect(throws: QuestionKitLoader.LoaderError.self) {
            _ = try QuestionKitLoader.loadKit(named: "does_not_exist")
        }
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
