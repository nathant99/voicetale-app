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

    // MARK: - Monthly engagement (EIGHTEENTH-round polish sibling)

    /// Empty store → empty monthly digest. Sanity baseline mirroring
    /// the weekly baseline at the 30-day boundary.
    @Test func monthlyEngagementOnEmptyStoreIsEmpty() async throws {
        let (store, _) = try await newStore(scope: "monthly-empty")
        let digest = store.monthlyEngagement(now: .now)
        #expect(digest.isEmpty)
        #expect(digest.totalBucket == "zero")
        #expect(digest.perModalityBucket.isEmpty)
    }

    /// Entries inside the 30-day window count; entries outside do not.
    /// Mirrors ``weeklyEngagementIncludesOnlyEntriesInWindow`` at the
    /// monthly boundary.
    @Test func monthlyEngagementIncludesOnlyEntriesInWindow() async throws {
        let (store, _) = try await newStore(scope: "monthly-window")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        // Three inside the 30-day window.
        try await store.save(entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-1 * 24 * 60 * 60)
        ))
        try await store.save(entry(
            modality: .voice,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-15 * 24 * 60 * 60)
        ))
        try await store.save(entry(
            modality: .drawing,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-29 * 24 * 60 * 60)
        ))
        // One strictly outside the 30-day window.
        try await store.save(entry(
            modality: .emoji,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-45 * 24 * 60 * 60)
        ))
        let monthly = store.monthlyEntries(now: now)
        #expect(monthly.count == 3,
                "30-day window MUST include only the 3 in-window entries; got \(monthly.count)")
        let digest = store.monthlyEngagement(now: now)
        #expect(digest.totalBucket == "one_to_three")
        #expect(digest.perModalityBucket[.text] == "one_to_three")
        #expect(digest.perModalityBucket[.voice] == "one_to_three")
        #expect(digest.perModalityBucket[.drawing] == "one_to_three")
        // `.emoji` lives strictly outside the window — MUST NOT appear.
        #expect(digest.perModalityBucket[.emoji] == nil)
    }

    /// Boundary entry at exactly `now - 30 days` lands inside the
    /// window (`>= cutoff` inclusive — mirrors the weekly boundary
    /// semantics + `ReflectionRetentionPolicy.cutoff`).
    @Test func monthlyEngagementIncludesBoundaryEntry() async throws {
        let (store, _) = try await newStore(scope: "monthly-boundary")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let boundary = entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-30 * 24 * 60 * 60)
        )
        try await store.save(boundary)
        let monthly = store.monthlyEntries(now: now)
        #expect(monthly.count == 1,
                "Boundary entry at `now - 30d` MUST be inclusive")
    }

    /// Entry strictly older than the 30-day boundary is dropped.
    @Test func monthlyEngagementExcludesEntryStrictlyOlderThanBoundary() async throws {
        let (store, _) = try await newStore(scope: "monthly-outside")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let justOutside = entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-30 * 24 * 60 * 60 - 0.001)
        )
        try await store.save(justOutside)
        let monthly = store.monthlyEntries(now: now)
        #expect(monthly.isEmpty)
    }

    /// Per-modality breadth matches: 4 modalities engaged in the
    /// month → 4 entries in the per-modality bucket map (no `.zero`
    /// buckets leak). Locks the `make(from:)` zero-drop convention at
    /// the monthly window.
    @Test func monthlyEngagementDropsZeroModalityBuckets() async throws {
        let (store, _) = try await newStore(scope: "monthly-modality-breadth")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        // Two text + one voice in the window. NO drawing / emoji /
        // skip — those modalities MUST NOT appear in the digest.
        try await store.save(entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-1 * 24 * 60 * 60)
        ))
        try await store.save(entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-2 * 24 * 60 * 60)
        ))
        try await store.save(entry(
            modality: .voice,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-3 * 24 * 60 * 60)
        ))
        let digest = store.monthlyEngagement(now: now)
        #expect(digest.totalBucket == "one_to_three")
        #expect(digest.perModalityBucket.count == 2,
                "Only modalities with attempts MUST appear; .zero buckets MUST drop")
        #expect(digest.perModalityBucket[.text] == "one_to_three")
        #expect(digest.perModalityBucket[.voice] == "one_to_three")
        #expect(digest.perModalityBucket[.drawing] == nil)
        #expect(digest.perModalityBucket[.emoji] == nil)
        #expect(digest.perModalityBucket[.skip] == nil)
    }

    /// Weekly + monthly digests share the same `ReflectionWeeklyEngagement`
    /// type — the type name is window-neutral. The same factory shape
    /// returns both digests; they differ only by which window the
    /// store's `*Entries(now:)` filter selects. Locks the factory reuse
    /// invariant.
    @Test func monthlyDigestReusesFactoryShape() async throws {
        let (store, _) = try await newStore(scope: "factory-reuse")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        // 5 entries — all inside both the 7-day and 30-day window.
        for offset in 0..<5 {
            try await store.save(entry(
                modality: .text,
                appIdentifier: store.appIdentifier,
                at: now.addingTimeInterval(-Double(offset) * 24 * 60 * 60)
            ))
        }
        let weekly = store.weeklyEngagement(now: now)
        let monthly = store.monthlyEngagement(now: now)
        // Both buckets should report `four_to_ten` (5 entries) and
        // the same per-modality breakdown.
        #expect(weekly.totalBucket == monthly.totalBucket)
        #expect(weekly.perModalityBucket == monthly.perModalityBucket)
    }

    // MARK: - Quarterly engagement (NINETEENTH-round polish sibling)

    /// Empty store → empty quarterly digest. Sanity baseline mirroring
    /// the weekly + monthly baselines at the 90-day boundary.
    @Test func quarterlyEngagementOnEmptyStoreIsEmpty() async throws {
        let (store, _) = try await newStore(scope: "quarterly-empty")
        let digest = store.quarterlyEngagement(now: .now)
        #expect(digest.isEmpty)
        #expect(digest.totalBucket == "zero")
        #expect(digest.perModalityBucket.isEmpty)
    }

    /// Entries inside the 90-day window count; entries outside do not.
    /// Mirrors ``monthlyEngagementIncludesOnlyEntriesInWindow`` at the
    /// quarterly boundary.
    @Test func quarterlyEngagementIncludesOnlyEntriesInWindow() async throws {
        let (store, _) = try await newStore(scope: "quarterly-window")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        // Three inside the 90-day window — one inside the weekly band,
        // one inside the monthly band, one strictly outside the monthly
        // band but inside the quarterly band.
        try await store.save(entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-1 * 24 * 60 * 60)
        ))
        try await store.save(entry(
            modality: .voice,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-20 * 24 * 60 * 60)
        ))
        try await store.save(entry(
            modality: .drawing,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-80 * 24 * 60 * 60)
        ))
        // One strictly outside the 90-day window.
        try await store.save(entry(
            modality: .emoji,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-120 * 24 * 60 * 60)
        ))
        let quarterly = store.quarterlyEntries(now: now)
        #expect(quarterly.count == 3,
                "90-day window MUST include only the 3 in-window entries; got \(quarterly.count)")
        let digest = store.quarterlyEngagement(now: now)
        #expect(digest.totalBucket == "one_to_three")
        #expect(digest.perModalityBucket[.text] == "one_to_three")
        #expect(digest.perModalityBucket[.voice] == "one_to_three")
        #expect(digest.perModalityBucket[.drawing] == "one_to_three")
        // `.emoji` lives strictly outside the window — MUST NOT appear.
        #expect(digest.perModalityBucket[.emoji] == nil)
    }

    /// Boundary entry at exactly `now - 90 days` lands inside the
    /// window (`>= cutoff` inclusive — mirrors the weekly + monthly
    /// boundary semantics + `ReflectionRetentionPolicy.cutoff`).
    @Test func quarterlyEngagementIncludesBoundaryEntry() async throws {
        let (store, _) = try await newStore(scope: "quarterly-boundary")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let boundary = entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-90 * 24 * 60 * 60)
        )
        try await store.save(boundary)
        let quarterly = store.quarterlyEntries(now: now)
        #expect(quarterly.count == 1,
                "Boundary entry at `now - 90d` MUST be inclusive")
    }

    /// Entry strictly older than the 90-day boundary is dropped.
    @Test func quarterlyEngagementExcludesEntryStrictlyOlderThanBoundary() async throws {
        let (store, _) = try await newStore(scope: "quarterly-outside")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let justOutside = entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-90 * 24 * 60 * 60 - 0.001)
        )
        try await store.save(justOutside)
        let quarterly = store.quarterlyEntries(now: now)
        #expect(quarterly.isEmpty)
    }

    /// `.zero` per-modality buckets MUST drop at the quarterly window,
    /// same convention as the weekly + monthly windows.
    @Test func quarterlyEngagementDropsZeroModalityBuckets() async throws {
        let (store, _) = try await newStore(scope: "quarterly-modality-breadth")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        // Two text + one voice in the window. NO drawing / emoji /
        // skip — those modalities MUST NOT appear in the digest.
        try await store.save(entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-10 * 24 * 60 * 60)
        ))
        try await store.save(entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-45 * 24 * 60 * 60)
        ))
        try await store.save(entry(
            modality: .voice,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-75 * 24 * 60 * 60)
        ))
        let digest = store.quarterlyEngagement(now: now)
        #expect(digest.totalBucket == "one_to_three")
        #expect(digest.perModalityBucket.count == 2,
                "Only modalities with attempts MUST appear; .zero buckets MUST drop")
        #expect(digest.perModalityBucket[.text] == "one_to_three")
        #expect(digest.perModalityBucket[.voice] == "one_to_three")
        #expect(digest.perModalityBucket[.drawing] == nil)
        #expect(digest.perModalityBucket[.emoji] == nil)
        #expect(digest.perModalityBucket[.skip] == nil)
    }

    /// Weekly + monthly + quarterly digests share the same
    /// `ReflectionWeeklyEngagement` type. When every entry lands inside
    /// the weekly window (and therefore inside the monthly + quarterly
    /// windows too), all three digests MUST return identical bucket
    /// shapes. Locks the factory reuse invariant across all three
    /// window siblings.
    @Test func quarterlyDigestReusesFactoryShape() async throws {
        let (store, _) = try await newStore(scope: "quarterly-factory-reuse")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        // 5 entries — all inside the 7-day window (and therefore inside
        // the 30-day + 90-day windows too).
        for offset in 0..<5 {
            try await store.save(entry(
                modality: .text,
                appIdentifier: store.appIdentifier,
                at: now.addingTimeInterval(-Double(offset) * 24 * 60 * 60)
            ))
        }
        let weekly = store.weeklyEngagement(now: now)
        let monthly = store.monthlyEngagement(now: now)
        let quarterly = store.quarterlyEngagement(now: now)
        // All three buckets should report identical shape.
        #expect(weekly.totalBucket == quarterly.totalBucket)
        #expect(monthly.totalBucket == quarterly.totalBucket)
        #expect(weekly.perModalityBucket == quarterly.perModalityBucket)
        #expect(monthly.perModalityBucket == quarterly.perModalityBucket)
    }

    // MARK: - Yearly engagement (TWENTIETH-round polish)

    /// Empty store → empty yearly digest. Sanity baseline mirroring
    /// the weekly + monthly + quarterly empty-store invariants.
    @Test func yearlyEngagementOnEmptyStoreIsEmpty() async throws {
        let (store, _) = try await newStore(scope: "yearly-empty")
        let digest = store.yearlyEngagement(now: .now)
        #expect(digest.isEmpty)
        #expect(digest.totalBucket == "zero")
        #expect(digest.perModalityBucket.isEmpty)
    }

    /// Three entries inside the 365-day window + one strictly outside
    /// MUST report exactly three entries on `yearlyEntries(now:)` and
    /// a `one_to_three` total bucket — locks the 365-day boundary.
    @Test func yearlyEngagementIncludesOnlyEntriesInWindow() async throws {
        let (store, _) = try await newStore(scope: "yearly-window")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        try await store.save(entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-30 * 24 * 60 * 60)
        ))
        try await store.save(entry(
            modality: .voice,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-180 * 24 * 60 * 60)
        ))
        try await store.save(entry(
            modality: .drawing,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-330 * 24 * 60 * 60)
        ))
        // One strictly outside the 365-day window.
        try await store.save(entry(
            modality: .emoji,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-400 * 24 * 60 * 60)
        ))
        let yearly = store.yearlyEntries(now: now)
        #expect(yearly.count == 3,
                "365-day window MUST include only the 3 in-window entries; got \(yearly.count)")
        let digest = store.yearlyEngagement(now: now)
        #expect(digest.totalBucket == "one_to_three")
        #expect(digest.perModalityBucket[.text] == "one_to_three")
        #expect(digest.perModalityBucket[.voice] == "one_to_three")
        #expect(digest.perModalityBucket[.drawing] == "one_to_three")
        // `.emoji` lives strictly outside the window — MUST NOT appear.
        #expect(digest.perModalityBucket[.emoji] == nil)
    }

    /// Boundary entry at exactly `now - 365 days` lands inside the
    /// window (`>= cutoff` inclusive — mirrors the weekly + monthly +
    /// quarterly boundary semantics + `ReflectionRetentionPolicy.cutoff`).
    @Test func yearlyEngagementIncludesBoundaryEntry() async throws {
        let (store, _) = try await newStore(scope: "yearly-boundary")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let boundary = entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-365 * 24 * 60 * 60)
        )
        try await store.save(boundary)
        let yearly = store.yearlyEntries(now: now)
        #expect(yearly.count == 1,
                "Boundary entry at `now - 365d` MUST be inclusive")
    }

    /// Entry strictly older than the 365-day boundary is dropped.
    @Test func yearlyEngagementExcludesEntryStrictlyOlderThanBoundary() async throws {
        let (store, _) = try await newStore(scope: "yearly-outside")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let justOutside = entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-365 * 24 * 60 * 60 - 0.001)
        )
        try await store.save(justOutside)
        let yearly = store.yearlyEntries(now: now)
        #expect(yearly.isEmpty)
    }

    /// `.zero` per-modality buckets MUST drop at the yearly window,
    /// same convention as the weekly + monthly + quarterly windows.
    @Test func yearlyEngagementDropsZeroModalityBuckets() async throws {
        let (store, _) = try await newStore(scope: "yearly-modality-breadth")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        // Two text + one voice in the window. NO drawing / emoji /
        // skip — those modalities MUST NOT appear in the digest.
        try await store.save(entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-30 * 24 * 60 * 60)
        ))
        try await store.save(entry(
            modality: .text,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-200 * 24 * 60 * 60)
        ))
        try await store.save(entry(
            modality: .voice,
            appIdentifier: store.appIdentifier,
            at: now.addingTimeInterval(-300 * 24 * 60 * 60)
        ))
        let digest = store.yearlyEngagement(now: now)
        #expect(digest.totalBucket == "one_to_three")
        #expect(digest.perModalityBucket.count == 2,
                "Only modalities with attempts MUST appear; .zero buckets MUST drop")
        #expect(digest.perModalityBucket[.text] == "one_to_three")
        #expect(digest.perModalityBucket[.voice] == "one_to_three")
        #expect(digest.perModalityBucket[.drawing] == nil)
        #expect(digest.perModalityBucket[.emoji] == nil)
        #expect(digest.perModalityBucket[.skip] == nil)
    }

    /// Weekly + monthly + quarterly + yearly digests share the same
    /// `ReflectionWeeklyEngagement` type. When every entry lands inside
    /// the weekly window (and therefore inside the monthly + quarterly
    /// + yearly windows too), all four digests MUST return identical
    /// bucket shapes. Locks the factory reuse invariant across all four
    /// window siblings.
    @Test func yearlyDigestReusesFactoryShape() async throws {
        let (store, _) = try await newStore(scope: "yearly-factory-reuse")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        // 5 entries — all inside the 7-day window (and therefore inside
        // the 30-day + 90-day + 365-day windows too).
        for offset in 0..<5 {
            try await store.save(entry(
                modality: .text,
                appIdentifier: store.appIdentifier,
                at: now.addingTimeInterval(-Double(offset) * 24 * 60 * 60)
            ))
        }
        let weekly = store.weeklyEngagement(now: now)
        let monthly = store.monthlyEngagement(now: now)
        let quarterly = store.quarterlyEngagement(now: now)
        let yearly = store.yearlyEngagement(now: now)
        // All four buckets should report identical shape.
        #expect(weekly.totalBucket == yearly.totalBucket)
        #expect(monthly.totalBucket == yearly.totalBucket)
        #expect(quarterly.totalBucket == yearly.totalBucket)
        #expect(weekly.perModalityBucket == yearly.perModalityBucket)
        #expect(monthly.perModalityBucket == yearly.perModalityBucket)
        #expect(quarterly.perModalityBucket == yearly.perModalityBucket)
    }
}
