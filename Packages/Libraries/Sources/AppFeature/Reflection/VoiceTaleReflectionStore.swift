import Foundation
import Observation
import SwiftData
import ForgeModels
import ForgePersistence
import Models

/// `@MainActor @Observable` wrapper around the actor-isolated
/// `ForgePersistence.ReflectionPromptStorage`. Mirrors the
/// "zero-`@Query` value-type cache" pattern from `VoiceTaleStore`
/// per `@.claude/rules/swiftdata.md` rule #3 — views read the cached
/// `[ReflectionEntry]` array, never traverse the SwiftData store
/// inside `body`.
///
/// Phase A of the ForgeReflection lift per `@Docs/PLAN_FORGEREFLECTION_LIFT.md`.
/// Phase B wires this into `BrambleReflectionView.actionRow`; Phase C
/// adds the retention purge on `AppRootView.task`; Phase D adds the
/// parent-dashboard read-back surface.
///
/// Bootstrap flow:
/// 1. `AppRootView` resolves the `ModelContainer` from environment
/// 2. Calls `bootstrap(container:)` once during `.task`
/// 3. From then on, every consumer goes through the `@Observable`
///    surface — no direct `ReflectionPromptStorage` access from views
@MainActor
@Observable
public final class VoiceTaleReflectionStore {
    /// Cached snapshot of entries for `appIdentifier`. Newest-first
    /// (matches the storage actor's sort). Views read this; the cache
    /// is invalidated + re-fetched on every `save` + `refresh` call.
    public private(set) var entries: [ReflectionEntry] = []

    /// `nil` until `bootstrap(container:)` is called. Calls into the
    /// store before bootstrap are no-ops (defensive — keeps the
    /// store usable in previews without a container).
    @ObservationIgnored private var storage: ReflectionPromptStorage?

    /// Stable `appIdentifier` the store filters on. Defaults to the
    /// catalog's canonical value; the parameter exists so tests can
    /// scope to a unique id and not collide with the real journal.
    @ObservationIgnored public let appIdentifier: String

    public init(appIdentifier: String = VoiceTaleReflectionConfigCatalog.appIdentifier) {
        self.appIdentifier = appIdentifier
    }

    /// One-time bootstrap. Subsequent calls replace the storage actor
    /// (test affordance) but in production the call is once-per-launch
    /// from `AppRootView.task`.
    public func bootstrap(container: ModelContainer) async {
        let storage = ReflectionPromptStorage(container: container)
        self.storage = storage
        await refresh()
    }

    /// Persist a single entry + refresh the cached snapshot. The
    /// snapshot refresh is the observable change that drives view
    /// re-evaluation.
    public func save(_ entry: ReflectionEntry) async throws {
        guard let storage else { return }
        try await storage.save(entry)
        await refresh()
    }

    /// Re-fetch the full entry list from the storage actor + replace
    /// the cached snapshot. Idempotent.
    public func refresh() async {
        guard let storage else {
            entries = []
            return
        }
        let fetched: [ReflectionEntry]
        do {
            fetched = try await storage.entries(forApp: appIdentifier)
        } catch {
            // Per `@.claude/rules/debug-logging.md` § "Replace silent
            // try? with logged catches" — surface failures via the
            // canonical iOS DebugLog when one ships into Services /
            // AppFeature. For now we degrade to empty + keep going.
            fetched = []
        }
        entries = fetched
    }

    /// Purge entries strictly older than `cutoff`. Phase C wires this
    /// into the weekly `AppRootView.task` cadence with a 180-day floor
    /// per `@.claude/rules/age-assurance.md` § "2026 FTC COPPA Rule
    /// Amendments" (defined retention period requirement). Returns
    /// the number of records deleted.
    @discardableResult
    public func purgeOlderThan(_ cutoff: Date) async throws -> Int {
        guard let storage else { return 0 }
        let count = try await storage.purge(olderThan: cutoff)
        await refresh()
        return count
    }

    /// Phase D — parent-dashboard read-back filter.
    ///
    /// Returns the cached snapshot filtered by the supplied
    /// `(promptID) -> Bool` predicate. The closure is the seam where the
    /// grown-up opt-in lives — the catalog ships every prompt at
    /// `parentVisible: false` in V1, and ``ReflectionJournalView``
    /// supplies a constant `{ _ in showAll }` closure driven by an
    /// `@AppStorage` toggle so the kid's privacy posture is the default
    /// and the grown-up has to explicitly flip it on. The COPPA-2026
    /// "opt-in default" requirement (per `@.claude/rules/age-
    /// assurance.md`) lives in this seam.
    ///
    /// Pure value-type pass-through over the cached snapshot — never
    /// re-queries the storage actor (zero-`@Query` discipline per
    /// `@.claude/rules/swiftdata.md` rule #3). The view that renders the
    /// list reads this value; the snapshot underneath is the same one
    /// `entries` exposes.
    public func parentVisibleEntries(
        promptVisibility: @Sendable (String) -> Bool
    ) -> [ReflectionEntry] {
        entries.filter { promptVisibility($0.promptID) }
    }

    /// Phase D second-half polish — parent-dashboard "This week" digest.
    ///
    /// Returns the cached snapshot sliced to entries whose
    /// `respondedAt` is on or after `now - 7 days` — same boundary
    /// semantics as ``ReflectionRetentionPolicy/cutoff(inputs:now:)``
    /// (entries at the boundary are kept; strictly older entries are
    /// dropped). Pure value-type pass-through; never re-queries the
    /// storage actor (zero-`@Query` discipline per
    /// `@.claude/rules/swiftdata.md` rule #3).
    ///
    /// The view that hosts the digest gates the call behind the same
    /// opt-in toggle ``ReflectionJournalView`` already wires for the
    /// per-entry list — so the kid's reflections stay kid-private until
    /// the grown-up explicitly opts in.
    public func weeklyEntries(now: Date = .now) -> [ReflectionEntry] {
        let cutoff = now.addingTimeInterval(-7 * 24 * 60 * 60)
        return entries.filter { $0.respondedAt >= cutoff }
    }

    /// Phase D second-half polish — bucketed engagement snapshot for the
    /// "This week" digest row. Walks ``weeklyEntries(now:)`` once and
    /// emits a ``ReflectionWeeklyEngagement`` with bucketed totals.
    ///
    /// Wire-shape lockstep with the sibling
    /// ``parentReflectionJournalOpened(visibleCount:)`` /
    /// ``reflectionsPurged(removed:)`` analytics events — all three use
    /// ``Models/ReflectionRetentionPolicy/removedCountBucket(_:)`` so the
    /// cohort signal is comparable across surfaces without leaking
    /// per-kid raw counts.
    public func weeklyEngagement(now: Date = .now) -> ReflectionWeeklyEngagement {
        ReflectionWeeklyEngagement.make(from: weeklyEntries(now: now))
    }

    /// EIGHTEENTH-round polish sibling — entries whose `respondedAt`
    /// lands on or after `now - 30 days`. Same boundary semantics as
    /// ``weeklyEntries(now:)`` — entries at the boundary are kept;
    /// strictly older entries are dropped. Pure value-type
    /// pass-through; never re-queries the storage actor (zero-`@Query`
    /// discipline per `@.claude/rules/swiftdata.md` rule #3).
    ///
    /// The view that hosts the monthly digest gates the call behind
    /// the same opt-in toggle ``ReflectionJournalView`` already wires
    /// for the per-entry list + weekly digest — so the kid's
    /// reflections stay kid-private until the grown-up explicitly
    /// opts in.
    public func monthlyEntries(now: Date = .now) -> [ReflectionEntry] {
        let cutoff = now.addingTimeInterval(-30 * 24 * 60 * 60)
        return entries.filter { $0.respondedAt >= cutoff }
    }

    /// EIGHTEENTH-round polish sibling — bucketed engagement snapshot
    /// for the "This month" digest row. Walks ``monthlyEntries(now:)``
    /// once and emits a ``ReflectionWeeklyEngagement`` (the type's
    /// name is window-neutral; the factory ``ReflectionWeeklyEngagement/make(from:)``
    /// just buckets whatever entries it gets).
    ///
    /// Wire-shape lockstep with the existing ``weeklyEngagement(now:)``
    /// + ``parentReflectionJournalOpened(visibleCount:)`` +
    /// ``reflectionsPurged(removed:)`` family — all four reuse
    /// ``Models/ReflectionRetentionPolicy/removedCountBucket(_:)`` so
    /// cross-window cohort signal is comparable without leaking per-kid
    /// raw counts.
    public func monthlyEngagement(now: Date = .now) -> ReflectionWeeklyEngagement {
        ReflectionWeeklyEngagement.make(from: monthlyEntries(now: now))
    }

    /// NINETEENTH-round polish sibling — entries whose `respondedAt`
    /// lands on or after `now - 90 days`. Identical boundary semantics
    /// to ``weeklyEntries(now:)`` + ``monthlyEntries(now:)`` — entries
    /// at the boundary are kept; strictly older entries are dropped.
    /// Pure value-type pass-through; never re-queries the storage actor
    /// (zero-`@Query` discipline per `@.claude/rules/swiftdata.md` rule
    /// #3).
    ///
    /// The view that hosts the quarterly digest gates the call behind
    /// the same opt-in toggle ``ReflectionJournalView`` already wires
    /// for the per-entry list + weekly + monthly digests — so the kid's
    /// reflections stay kid-private until the grown-up explicitly
    /// opts in.
    public func quarterlyEntries(now: Date = .now) -> [ReflectionEntry] {
        let cutoff = now.addingTimeInterval(-90 * 24 * 60 * 60)
        return entries.filter { $0.respondedAt >= cutoff }
    }

    /// NINETEENTH-round polish sibling — bucketed engagement snapshot
    /// for the "Past 90 days" digest row. Walks ``quarterlyEntries(now:)``
    /// once and emits a ``ReflectionWeeklyEngagement`` (the type's name
    /// is window-neutral; the factory ``ReflectionWeeklyEngagement/make(from:)``
    /// just buckets whatever entries it gets).
    ///
    /// Wire-shape lockstep with the existing ``weeklyEngagement(now:)`` +
    /// ``monthlyEngagement(now:)`` +
    /// ``parentReflectionJournalOpened(visibleCount:)`` +
    /// ``reflectionsPurged(removed:)`` family — all five reuse
    /// ``Models/ReflectionRetentionPolicy/removedCountBucket(_:)`` so
    /// cross-window cohort signal is comparable across surfaces without
    /// leaking per-kid raw counts.
    public func quarterlyEngagement(now: Date = .now) -> ReflectionWeeklyEngagement {
        ReflectionWeeklyEngagement.make(from: quarterlyEntries(now: now))
    }
}
