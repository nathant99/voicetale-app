import Foundation
import Observation
import SwiftData
import ForgeModels
import ForgePersistence

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
}
