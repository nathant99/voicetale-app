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

    @Test func schemaContainsAllFiveModels() throws {
        let container = try VoiceTalePersistence.makeInMemoryContainer()
        let entityNames = Set(container.schema.entities.map(\.name))
        #expect(entityNames.contains("PersistentVoiceTaleEntry"))
        #expect(entityNames.contains("PersistentTraditionEntry"))
        #expect(entityNames.contains("PersistentPlayerProgress"))
        #expect(entityNames.contains("PersistentAnthologyMood"))
        #expect(entityNames.contains("PersistentAchievement"))
    }

    @Test func defaultStoreURLLivesUnderApplicationSupport() {
        let url = VoiceTalePersistence.defaultStoreURL
        // The path must end at "VoiceTale.store" inside a "VoiceTale" folder
        // — the canonical layout per @Docs/TECHNICAL_DESIGN.md § Privacy.
        #expect(url.lastPathComponent == "VoiceTale.store")
        #expect(url.deletingLastPathComponent().lastPathComponent == "VoiceTale")
        // Application Support folder must exist at this point — the
        // accessor creates it lazily on first read.
        let parent = url.deletingLastPathComponent()
        #expect(FileManager.default.fileExists(atPath: parent.path))
    }

    @Test func legacyDiskContainerStillInitializes() throws {
        // Smoke-test the legacy disk-backed entry point so callers that
        // can't yet adopt the fail-safe helper (e.g., headless test
        // contexts) still get a valid container.
        let container = try VoiceTalePersistence.makeModelContainer()
        #expect(container.schema.entities.isEmpty == false)
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

    /// Phase 1 ship-blocker per `Docs/FEATURE_PLAN.md` lines 28 + 62: each
    /// entry MUST eventually carry an `audioSampleFilename` pointing to a
    /// bundled CAF. Until the labsmith handoff
    /// (`Docs/HANDOFF_FROM_APP_TRADITION_AUDIO_SAMPLES.md`) lands the audio,
    /// the field stays `nil` and the gallery view shows "Audio coming soon."
    /// This test pins the contract so future PRs that bundle audio also
    /// update the manifest correctly (verified by changing this test to
    /// `expect != nil` once the audio ships).
    @Test func audioSampleFilenamesFollowExpectedSchema() throws {
        let catalog = try TraditionCatalogLoader.loadBundled()
        for entry in catalog.entries {
            if let filename = entry.audioSampleFilename {
                #expect(filename.hasSuffix(".caf"),
                        "Audio samples must be CAF per .claude/rules/audio-pipeline.md; \(entry.slug) ships \(filename)")
            }
        }
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

    @Test func rotationSeedIsStableAndCoversAllKits() throws {
        // Rotation must be deterministic for the same seed AND must cover the
        // full 4-kit space across consecutive seeds so the cast cameo strip
        // surfaces variety per `@Docs/HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` Move B.
        let kit0 = try QuestionKitLoader.loadKitForRotation(seed: 0)
        let kit0Again = try QuestionKitLoader.loadKitForRotation(seed: 0)
        #expect(kit0.kit == kit0Again.kit)

        let kitNumbers = try (0..<4).map { try QuestionKitLoader.loadKitForRotation(seed: $0).kit }
        #expect(Set(kitNumbers) == Set([1, 2, 3, 4]))
    }

    @Test func rotationHandlesNegativeSeeds() throws {
        // Hash-style seeds can be negative — `loadKitForRotation` MUST use
        // `abs(_)` (verified by ensuring a negative seed doesn't throw).
        let kit = try QuestionKitLoader.loadKitForRotation(seed: -17)
        #expect((1...4).contains(kit.kit))
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

    // MARK: - Phase 1.1 — Kit 05 (voice character)

    @Test func phase11ShipsKit05() throws {
        let kits = try QuestionKitLoader.loadAllPhase11Kits()
        #expect(kits.count == 1)
        #expect(kits.first?.kit == 5)
        #expect(kits.first?.title == "Voice Character")
    }

    @Test func kit05IsAnchoredToPivot() throws {
        let kit = try QuestionKitLoader.loadKit(named: "kit_05_voice_character")
        #expect(kit.anchorCharacterSlug == "pivot")
        #expect(kit.questions.count == 4)
        // Voice-character craft kit must include at least one rewrite + one
        // choice question — same shape contract as Phase 1 kits.
        let kinds = Set(kit.questions.map(\.kind))
        #expect(kinds.contains(.reflection))
        #expect(kinds.contains(.choice))
        #expect(kinds.contains(.rewrite))
    }

    @Test func kit05IncludesAllFourCastCameos() throws {
        let kit = try QuestionKitLoader.loadKit(named: "kit_05_voice_character")
        let expected: Set<String> = ["lean", "pivot", "refrain", "slow"]
        let slugs = Set(kit.castCameos.map(\.slug))
        #expect(slugs == expected)
    }

    // MARK: - Phase 2 — Kits 06-09 (mood / pacing / surprise / closing)

    @Test func phase2ShipsKits06Through09() throws {
        let kits = try QuestionKitLoader.loadAllPhase2Kits()
        #expect(kits.count == 4)
        #expect(kits.map(\.kit) == [6, 7, 8, 9])
        // Title sanity — each kit gets a distinct name so the kid sees the
        // craft surface, not a generic "kit N" label.
        let titles = kits.map(\.title)
        #expect(Set(titles).count == titles.count)
    }

    @Test func phase2KitAnchorsRotateAcrossTheFourListenerCast() throws {
        // Per `@.claude/rules/distributed-narrative.md` § "Hero mascot vs.
        // cast" + the kit-05 precedent — every cast member anchors at least
        // one Phase-2 kit so the rotation surfaces all four voices.
        let kits = try QuestionKitLoader.loadAllPhase2Kits()
        let anchors = Set(kits.map(\.anchorCharacterSlug))
        #expect(anchors == ["lean", "slow", "pivot", "refrain"])
    }

    @Test func phase2KitsAllHaveFourQuestionsWithCanonicalShape() throws {
        let kits = try QuestionKitLoader.loadAllPhase2Kits()
        for kit in kits {
            #expect(kit.questions.count == 4, "Kit \(kit.kit) should ship 4 questions")
            let kinds = Set(kit.questions.map(\.kind))
            // Same shape contract as Phase 1 / 1.1 kits: at least one of each
            // canonical kind so QuizView's three render paths exercise.
            #expect(kinds.contains(.reflection), "Kit \(kit.kit) missing reflection")
            #expect(kinds.contains(.choice), "Kit \(kit.kit) missing choice")
            #expect(kinds.contains(.rewrite), "Kit \(kit.kit) missing rewrite")
        }
    }

    @Test func phase2KitsEachIncludeAllFourListenerCastCameos() throws {
        let kits = try QuestionKitLoader.loadAllPhase2Kits()
        let expected: Set<String> = ["lean", "pivot", "refrain", "slow"]
        for kit in kits {
            let slugs = Set(kit.castCameos.map(\.slug))
            #expect(slugs == expected, "Kit \(kit.kit) cast cameo set drift: \(slugs)")
        }
    }

    @Test func phase2KitChoiceQuestionsCarryCorrectIndexAndRationale() throws {
        // Choice items must have a correctIndex inside the options range
        // AND a non-empty rationale — drift here breaks QuizView's
        // feedback path silently.
        let kits = try QuestionKitLoader.loadAllPhase2Kits()
        for kit in kits {
            let choices = kit.questions.filter { $0.kind == .choice }
            for choice in choices {
                let options = try #require(choice.options, "Kit \(kit.kit) choice missing options")
                let index = try #require(choice.correctIndex, "Kit \(kit.kit) choice missing correctIndex")
                #expect((0..<options.count).contains(index),
                       "Kit \(kit.kit) correctIndex \(index) out of range \(options.count)")
                let rationale = try #require(choice.rationale, "Kit \(kit.kit) choice missing rationale")
                #expect(!rationale.isEmpty, "Kit \(kit.kit) rationale is empty")
            }
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
