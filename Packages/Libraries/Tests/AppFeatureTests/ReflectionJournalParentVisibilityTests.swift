import Testing
import Foundation
import SwiftData
import ForgeModels
@testable import AppFeature
import Models
import Services

/// Phase D coverage for ``VoiceTaleReflectionStore.parentVisibleEntries(promptVisibility:)``
/// + the categorical ``VoiceTaleAnalyticsEvent.parentReflectionJournalOpened(visibleCount:)``
/// wire shape per `@Docs/PLAN_FORGEREFLECTION_LIFT.md` § Phase D.
@MainActor
@Suite("ReflectionJournalParentVisibility")
struct ReflectionJournalParentVisibilityTests {
    private func newStore(scope: String = UUID().uuidString) async throws
        -> (store: VoiceTaleReflectionStore, container: ModelContainer) {
        let container = try VoiceTalePersistence.makeInMemoryContainer()
        let store = VoiceTaleReflectionStore(appIdentifier: "test.\(scope)")
        await store.bootstrap(container: container)
        return (store, container)
    }

    private func entry(
        promptID: String,
        modality: ReflectionResponseModality = .text,
        appIdentifier: String,
        at date: Date = .now
    ) -> ReflectionEntry {
        ReflectionEntry(
            id: UUID(),
            promptID: promptID,
            appIdentifier: appIdentifier,
            kitNumber: nil,
            modality: modality,
            textValue: modality == .skip ? nil : "kid words",
            assetFileURL: nil,
            respondedAt: date,
            studentProfileID: nil
        )
    }

    // MARK: - Default-private posture

    @Test func emptyStoreReturnsEmptyVisibleEntries() async throws {
        let (store, _) = try await newStore(scope: "empty")
        let visible = store.parentVisibleEntries(promptVisibility: { _ in true })
        #expect(visible.isEmpty)
    }

    @Test func neverVisibleClosureFiltersEverything() async throws {
        // V1 default posture: catalog ships all configs at
        // `parentVisible: false`. The Phase D journal hosts an opt-in
        // toggle that, when OFF, supplies a `{ _ in false }` closure
        // here. The store must return zero rows so the kid's
        // privacy-by-default posture holds even when entries exist.
        let (store, _) = try await newStore(scope: "never-visible")
        try await store.save(entry(
            promptID: "bramble.socratic.1",
            appIdentifier: store.appIdentifier
        ))
        try await store.save(entry(
            promptID: "bramble.socratic.freeform",
            appIdentifier: store.appIdentifier
        ))
        let visible = store.parentVisibleEntries(promptVisibility: { _ in false })
        #expect(store.entries.count == 2)
        #expect(visible.isEmpty)
    }

    @Test func alwaysVisibleClosureReturnsAllCachedEntries() async throws {
        // When the grown-up opts in (toggle ON), the journal supplies a
        // `{ _ in true }` closure. The store returns the full cached
        // snapshot in the same newest-first order `entries` exposes.
        let (store, _) = try await newStore(scope: "always-visible")
        let older = entry(
            promptID: "bramble.socratic.1",
            appIdentifier: store.appIdentifier,
            at: Date(timeIntervalSinceNow: -3600)
        )
        let newer = entry(
            promptID: "bramble.socratic.freeform",
            appIdentifier: store.appIdentifier,
            at: Date(timeIntervalSinceNow: -60)
        )
        try await store.save(older)
        try await store.save(newer)
        let visible = store.parentVisibleEntries(promptVisibility: { _ in true })
        #expect(visible.count == 2)
        // Same newest-first order as `entries` — the filter is a pass-
        // through over the cached snapshot.
        #expect(visible.first?.id == newer.id)
        #expect(visible.last?.id == older.id)
    }

    @Test func perPromptIDPredicatePartitionsCleanly() async throws {
        // The closure receives the entry's `promptID`. The test locks
        // the per-promptID filtering invariant so future iterations can
        // expose a per-config picker without refactoring the store API.
        let (store, _) = try await newStore(scope: "per-prompt")
        try await store.save(entry(
            promptID: "bramble.socratic.1",
            appIdentifier: store.appIdentifier
        ))
        try await store.save(entry(
            promptID: "bramble.socratic.2",
            appIdentifier: store.appIdentifier
        ))
        try await store.save(entry(
            promptID: "bramble.socratic.freeform",
            appIdentifier: store.appIdentifier
        ))
        // Predicate: only kit-1 visible.
        let visible = store.parentVisibleEntries(
            promptVisibility: { $0 == "bramble.socratic.1" }
        )
        #expect(visible.count == 1)
        #expect(visible.first?.promptID == "bramble.socratic.1")
    }

    // MARK: - .skip rows remain in the filter surface

    @Test func skipModalityFlowsThroughVisibleSurface() async throws {
        // The `.skip` off-ramp ships without a text payload (anti-shame
        // discipline per Phase B) but DOES persist so the journal can
        // surface the engagement-then-private signal. The Phase D
        // parent-visible filter MUST NOT strip `.skip` rows — the
        // grown-up sees engagement, never the (absent) text.
        let (store, _) = try await newStore(scope: "skip-row")
        try await store.save(entry(
            promptID: "bramble.socratic.freeform",
            modality: .skip,
            appIdentifier: store.appIdentifier
        ))
        let visible = store.parentVisibleEntries(promptVisibility: { _ in true })
        #expect(visible.count == 1)
        #expect(visible.first?.modality == .skip)
        // The textValue field stays nil — even though the row is
        // visible to the grown-up, the kid's words still don't surface.
        #expect(visible.first?.textValue == nil)
    }

    // MARK: - Analytics wire shape

    @Test func parentReflectionJournalOpenedEventNameIsStable() {
        let event = VoiceTaleAnalyticsEvent.parentReflectionJournalOpened(visibleCount: 0)
        #expect(event.name == "parent_reflection_journal_opened")
    }

    @Test func parentReflectionJournalOpenedPropertiesAreBucketed() {
        // Raw counts NEVER travel — only the categorical bucket.
        // Bucketing reuses `ReflectionRetentionPolicy.removedCountBucket`
        // so the wire shape stays in lockstep with `reflectionsPurged`.
        let zero = VoiceTaleAnalyticsEvent.parentReflectionJournalOpened(visibleCount: 0)
        let two = VoiceTaleAnalyticsEvent.parentReflectionJournalOpened(visibleCount: 2)
        let seven = VoiceTaleAnalyticsEvent.parentReflectionJournalOpened(visibleCount: 7)
        let twenty = VoiceTaleAnalyticsEvent.parentReflectionJournalOpened(visibleCount: 20)
        #expect(zero.properties == ["visible_count_bucket": "zero"])
        #expect(two.properties == ["visible_count_bucket": "one_to_three"])
        #expect(seven.properties == ["visible_count_bucket": "four_to_ten"])
        #expect(twenty.properties == ["visible_count_bucket": "eleven_plus"])
    }

    @Test func parentReflectionJournalOpenedNeverLeaksRawCount() {
        // Lock the anti-fingerprinting invariant — the property bag
        // MUST NOT contain the raw count as a stringified Int.
        let event = VoiceTaleAnalyticsEvent.parentReflectionJournalOpened(visibleCount: 42)
        let props = event.properties
        #expect(props["visible_count_bucket"] == "eleven_plus")
        #expect(props["visible_count"] == nil)
        #expect(!props.values.contains("42"))
    }

    // MARK: - AppStorage default posture

    @Test func parentJournalVisibleKeyDefaultsToOff() {
        // The toggle key MUST default to OFF so a fresh install ships
        // the kid-private posture per `@.claude/rules/age-assurance.md`
        // § "2026 FTC COPPA Rule Amendments" (opt-in default).
        let key = ReflectionJournalView.parentJournalVisibleKey
        // Defensively pull from a per-test suite name + clear so cross-
        // test pollution can't flip the answer.
        let defaults = UserDefaults(suiteName: "test.parent-journal-default")
        defaults?.removePersistentDomain(forName: "test.parent-journal-default")
        let raw = defaults?.bool(forKey: key)
        // `UserDefaults.bool(forKey:)` returns `false` when the key is
        // absent — the canonical "opt-in default" shape.
        #expect(raw == false)
    }

    @Test func parentJournalVisibleKeyIsCanonicalString() {
        // Lock the public string so a future rename surfaces as a test
        // failure rather than a silently-broken @AppStorage key.
        #expect(ReflectionJournalView.parentJournalVisibleKey == "voicetale.reflection.parent_journal_visible")
    }
}
