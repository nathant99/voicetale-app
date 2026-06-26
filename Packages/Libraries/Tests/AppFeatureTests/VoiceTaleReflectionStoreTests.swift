import Testing
import Foundation
import SwiftData
import ForgeModels
@testable import AppFeature
import Services
import Models

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

    // MARK: - Phase D second-half polish — weekly engagement digest

    /// Empty store → empty week — no entries, total bucket "zero",
    /// `isEmpty` true.
    @Test func weeklyEngagementOnEmptyStoreIsEmpty() async throws {
        let (store, _) = try await newStore(scope: "weekly-empty")
        let digest = store.weeklyEngagement(now: .now)
        #expect(digest.isEmpty)
        #expect(digest.totalBucket == "zero")
    }

    /// Two entries inside the 7-day window flow into the digest;
    /// entries strictly older than 7 days are excluded.
    @Test func weeklyEngagementIncludesOnlyEntriesInWindow() async throws {
        let (store, _) = try await newStore(scope: "weekly-window")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let inside1 = entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-2 * 24 * 60 * 60)
        )
        let inside2 = entry(
            modality: .voice,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-5 * 24 * 60 * 60)
        )
        let outside = entry(
            modality: .drawing,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-30 * 24 * 60 * 60)
        )
        try await store.save(inside1)
        try await store.save(inside2)
        try await store.save(outside)
        #expect(store.entries.count == 3)

        let weekly = store.weeklyEntries(now: now)
        #expect(weekly.count == 2)
        let modalities = Set(weekly.map { $0.modality })
        #expect(modalities == [.text, .voice])

        let digest = store.weeklyEngagement(now: now)
        #expect(digest.totalBucket == "one_to_three")
        #expect(digest.perModalityBucket[.text] == "one_to_three")
        #expect(digest.perModalityBucket[.voice] == "one_to_three")
        #expect(digest.perModalityBucket[.drawing] == nil)
    }

    /// 7-day boundary: an entry at exactly `now - 7 days` is INCLUDED
    /// (same boundary semantics as ``ReflectionRetentionPolicy.cutoff`` —
    /// entries at the boundary are kept; strictly older entries are
    /// dropped).
    @Test func weeklyEngagementIncludesBoundaryEntry() async throws {
        let (store, _) = try await newStore(scope: "weekly-boundary")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let boundary = entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-7 * 24 * 60 * 60)
        )
        try await store.save(boundary)
        let weekly = store.weeklyEntries(now: now)
        #expect(weekly.count == 1)
    }

    /// 7-day boundary minus a millisecond: an entry strictly older
    /// than 7 days is EXCLUDED. Locks the cutoff polarity (`>=` cutoff
    /// includes; `<` cutoff excludes).
    @Test func weeklyEngagementExcludesEntryStrictlyOlderThanBoundary() async throws {
        let (store, _) = try await newStore(scope: "weekly-strict")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let justOutside = entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-7 * 24 * 60 * 60 - 0.001)
        )
        try await store.save(justOutside)
        let weekly = store.weeklyEntries(now: now)
        #expect(weekly.isEmpty)
    }

    /// 11+ entries in the window produce the `"eleven_plus"` total
    /// bucket — confirms the digest factory and store wiring agree on
    /// bucket boundaries.
    @Test func weeklyEngagementBucketsAtElevenPlus() async throws {
        let (store, _) = try await newStore(scope: "weekly-many")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        for offset in 0..<11 {
            let payload = entry(
                modality: .text,
                appIdentifier: store.appIdentifier,
                at: now.addingTimeInterval(-Double(offset) * 60)
            )
            try await store.save(payload)
        }
        let digest = store.weeklyEngagement(now: now)
        #expect(digest.totalBucket == "eleven_plus")
        #expect(digest.perModalityBucket[.text] == "eleven_plus")
    }
}
