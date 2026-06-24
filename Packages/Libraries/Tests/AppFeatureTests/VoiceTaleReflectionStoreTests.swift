import Testing
import Foundation
import SwiftData
import ForgeModels
@testable import AppFeature
import Services

/// Phase A coverage for ``VoiceTaleReflectionStore`` per
/// `@Docs/PLAN_FORGEREFLECTION_LIFT.md` § Phase A. Exercises the
/// observable wrapper end-to-end against an in-memory SwiftData
/// container so the round-trip (save → snapshot → fetch → purge)
/// stays honest.
@MainActor
@Suite("VoiceTaleReflectionStore")
struct VoiceTaleReflectionStoreTests {
    private func newStore(scope: String = UUID().uuidString) async throws
        -> (store: VoiceTaleReflectionStore, container: ModelContainer) {
        let container = try VoiceTalePersistence.makeInMemoryContainer()
        let store = VoiceTaleReflectionStore(appIdentifier: "test.\(scope)")
        await store.bootstrap(container: container)
        return (store, container)
    }

    private func entry(
        modality: ReflectionResponseModality = .text,
        text: String? = "It surprised me.",
        prompt: String = "What surprised you?",
        appIdentifier: String,
        at date: Date = .now
    ) -> ReflectionEntry {
        ReflectionEntry(
            id: UUID(),
            promptID: "bramble.socratic.freeform",
            appIdentifier: appIdentifier,
            kitNumber: nil,
            modality: modality,
            textValue: text,
            assetFileURL: nil,
            respondedAt: date,
            studentProfileID: nil
        )
    }

    // MARK: - Bootstrap

    @Test func freshStoreHasEmptyEntries() async throws {
        let (store, _) = try await newStore()
        #expect(store.entries.isEmpty)
    }

    @Test func storeWithoutBootstrapIsNoOp() async throws {
        // Defensive — calls before bootstrap shouldn't crash; they
        // degrade to no-op + empty cache. Lets previews use the
        // type without a container.
        let store = VoiceTaleReflectionStore(appIdentifier: "test.noboot")
        await store.refresh()
        #expect(store.entries.isEmpty)
    }

    // MARK: - Save → snapshot round-trip

    @Test func saveAppendsToCache() async throws {
        let (store, _) = try await newStore(scope: "save-1")
        let payload = entry(appIdentifier: store.appIdentifier)
        try await store.save(payload)
        #expect(store.entries.count == 1)
        #expect(store.entries.first?.id == payload.id)
        #expect(store.entries.first?.textValue == "It surprised me.")
    }

    @Test func saveMultipleSortsNewestFirst() async throws {
        let (store, _) = try await newStore(scope: "save-sort")
        let older = entry(
            text: "older",
            appIdentifier: store.appIdentifier,
            at: Date(timeIntervalSinceNow: -3600)
        )
        let newer = entry(
            text: "newer",
            appIdentifier: store.appIdentifier,
            at: Date(timeIntervalSinceNow: -60)
        )
        try await store.save(older)
        try await store.save(newer)
        #expect(store.entries.count == 2)
        // Storage actor sorts newest-first.
        #expect(store.entries.first?.textValue == "newer")
        #expect(store.entries.last?.textValue == "older")
    }

    @Test func saveFiltersByAppIdentifier() async throws {
        // Bootstrap two stores against the SAME container with
        // different appIdentifiers; saves to one MUST NOT show up in
        // the other's snapshot. Locks the cross-app journal-isolation
        // invariant the catalog appIdentifier was designed for.
        let container = try VoiceTalePersistence.makeInMemoryContainer()
        let alpha = VoiceTaleReflectionStore(appIdentifier: "test.alpha")
        let beta = VoiceTaleReflectionStore(appIdentifier: "test.beta")
        await alpha.bootstrap(container: container)
        await beta.bootstrap(container: container)

        try await alpha.save(entry(text: "alpha-1", appIdentifier: "test.alpha"))
        try await beta.save(entry(text: "beta-1", appIdentifier: "test.beta"))

        await alpha.refresh()
        await beta.refresh()
        #expect(alpha.entries.count == 1)
        #expect(beta.entries.count == 1)
        #expect(alpha.entries.first?.textValue == "alpha-1")
        #expect(beta.entries.first?.textValue == "beta-1")
    }

    // MARK: - Skip modality semantics

    @Test func skipModalityPersistsWithoutTextPayload() async throws {
        // The `.skip` off-ramp MUST persist (so the parent dashboard
        // can show "kid engaged with the prompt") but MUST NOT carry
        // a text payload — anti-shame surface per the planning doc
        // § Phase B "anti-shame fallback: skipped entries DO persist
        // but DO NOT travel any text payload."
        let (store, _) = try await newStore(scope: "skip")
        let skipped = entry(
            modality: .skip,
            text: nil,
            appIdentifier: store.appIdentifier
        )
        try await store.save(skipped)
        #expect(store.entries.count == 1)
        #expect(store.entries.first?.modality == .skip)
        #expect(store.entries.first?.textValue == nil)
    }

    // MARK: - Purge

    @Test func purgeRemovesEntriesStrictlyOlderThanCutoff() async throws {
        let (store, _) = try await newStore(scope: "purge")
        let ancient = entry(
            text: "ancient",
            appIdentifier: store.appIdentifier,
            at: Date(timeIntervalSinceNow: -86400 * 365)
        )
        let recent = entry(
            text: "recent",
            appIdentifier: store.appIdentifier,
            at: Date(timeIntervalSinceNow: -3600)
        )
        try await store.save(ancient)
        try await store.save(recent)
        #expect(store.entries.count == 2)

        // Cutoff between the two — should drop the ancient one.
        let cutoff = Date(timeIntervalSinceNow: -86400 * 30)
        let purged = try await store.purgeOlderThan(cutoff)
        #expect(purged == 1)
        #expect(store.entries.count == 1)
        #expect(store.entries.first?.textValue == "recent")
    }

    @Test func purgeWithoutBootstrapReturnsZero() async throws {
        let store = VoiceTaleReflectionStore(appIdentifier: "test.purge-noboot")
        let purged = try await store.purgeOlderThan(.now)
        #expect(purged == 0)
    }
}
