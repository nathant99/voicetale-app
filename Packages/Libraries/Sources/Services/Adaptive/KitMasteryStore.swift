import Foundation
import Observation
import SwiftData
import ForgeGamification
import ForgeMasteryEngine
import Models

/// `@MainActor @Observable` wrapper around the per-(kid, kit)
/// ``ForgeMasteryEngine.TopicMasteryState`` map persisted as a
/// JSON-encoded payload on
/// ``Models/PersistentPlayerProgress/encodedMasteryState``. Phase A
/// scaffold per `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` — Phase B
/// wires `QuizMachine.answerChoice` to call ``record(_:for:)`` and
/// Phase C consumes ``state(for:)`` from
/// `QuestionKitLoader.loadKitForRotation(seed:)`.
///
/// The store is the canonical seam between the engine (which is
/// pure value types) and the SwiftData store (which is the only
/// persistence path VoiceTale ships). Views never traverse the
/// stored `Data` payload directly — they observe ``cachedStates``
/// per the zero-`@Query` value-type cache pattern in
/// `@.claude/rules/swiftdata.md` rule #3.
///
/// Engine wiring lives behind the existing
/// `ForgeGamification.SpacedRepetitionEngine` instance the app
/// already constructs; the store accepts a configured engine to
/// keep test injection straightforward.
@MainActor
@Observable
public final class KitMasteryStore {
    /// Snapshot map keyed by ``Models.KitID``. Views read this; the
    /// snapshot is updated immediately after every ``record(_:for:)``
    /// call. Missing keys default to fresh
    /// `TopicMasteryState()` when callers fetch via ``state(for:)``.
    public private(set) var cachedStates: [KitID: TopicMasteryState] = [:]

    /// FSRS engine + recent-window cap. The defaults match the
    /// portfolio convention (`desiredRetention: 0.9`,
    /// `recentWindowSize: 8`) per the engine's documented defaults.
    @ObservationIgnored private let srs: SpacedRepetitionEngine
    @ObservationIgnored private let updater: MasteryUpdater<KitID>

    /// The persistent progress row the store reads + writes against.
    /// Pass `nil` for previews / unbootstrapped tests; the API
    /// degrades to no-op writes in that case.
    @ObservationIgnored private var progress: PersistentPlayerProgress?

    public init(
        srs: SpacedRepetitionEngine = SpacedRepetitionEngine(desiredRetention: 0.9),
        recentWindowSize: Int = 8
    ) {
        self.srs = srs
        self.updater = MasteryUpdater<KitID>(recentWindowSize: recentWindowSize)
    }

    /// One-time bootstrap. Reads any prior payload off `progress` +
    /// hydrates ``cachedStates``. Replays cleanly when `nil` data
    /// (legacy rows pre-`encodedMasteryState`) is present — first
    /// write seeds the field.
    public func bootstrap(progress: PersistentPlayerProgress) {
        self.progress = progress
        cachedStates = decode(progress.encodedMasteryState)
    }

    /// Returns the cached state for `kit` — or a fresh
    /// `TopicMasteryState()` when no prior attempt has landed.
    /// Pure read; never mutates.
    public func state(for kit: KitID) -> TopicMasteryState {
        cachedStates[kit] ?? TopicMasteryState()
    }

    /// Records one attempt outcome on `kit` + persists the new
    /// state. Idempotent w.r.t. the input — passing the same
    /// outcome twice records two attempts (the engine's FSRS
    /// surface tracks attempt count, not deduped outcomes).
    @discardableResult
    public func record(
        _ outcome: AttemptOutcome,
        for kit: KitID,
        now: Date = .now
    ) -> TopicMasteryState {
        let prior = state(for: kit)
        let next = updater.recordAttempt(
            topic: kit,
            outcome: outcome,
            state: prior,
            srs: srs,
            now: now
        )
        cachedStates[kit] = next
        persist()
        return next
    }

    /// Encodes `cachedStates` to the persistent row's
    /// ``Models/PersistentPlayerProgress/encodedMasteryState`` field
    /// + saves. Logs decode failures but never throws — Phase A
    /// scaffold preserves the existing
    /// `try? modelContext.save()` semantics of sibling stores.
    public func persist() {
        guard let progress else { return }
        do {
            // Encode keyed by raw `Int` so a future enum rename
            // doesn't silently break the round-trip.
            let raw: [Int: TopicMasteryState] = Dictionary(
                uniqueKeysWithValues: cachedStates.map { ($0.key.rawValue, $0.value) }
            )
            let encoded = try JSONEncoder().encode(raw)
            progress.encodedMasteryState = encoded
        } catch {
            // Swallow per Phase A scaffold contract. Phase B
            // wires `DebugLog.data(...)` once a consumer surface
            // lands.
        }
    }

    // MARK: - Internals

    private func decode(_ data: Data?) -> [KitID: TopicMasteryState] {
        guard let data, !data.isEmpty else { return [:] }
        do {
            let raw = try JSONDecoder().decode([Int: TopicMasteryState].self, from: data)
            var map: [KitID: TopicMasteryState] = [:]
            for (rawKey, value) in raw {
                if let kit = KitID(rawValue: rawKey) {
                    map[kit] = value
                }
                // Unknown raw values are dropped — defensive against
                // a future rename that would otherwise crash decode.
            }
            return map
        } catch {
            // Corrupt payload — degrade to empty + let the next
            // write reseed the field. Same anti-shame fallback as
            // `VoiceTaleStore.fetchTales` per
            // `@.claude/rules/swiftdata.md` rule #25.
            return [:]
        }
    }
}
