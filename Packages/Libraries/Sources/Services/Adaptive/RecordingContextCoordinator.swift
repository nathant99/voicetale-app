import Foundation
import Observation
import Models

/// Cross-tab coordinator carrying the pending ``TaleRecordingContext``
/// from the Adventure mode-card affordance pill (Phase D first-half;
/// PR #136) into the Tell-tab recording → reflection flow (Phase D
/// second-half; this round). Mirrors the pattern
/// ``IntentTabCoordinator`` establishes in ``AppFeature/Intents`` —
/// process-wide singleton + one-shot consume semantics so the next
/// recording reads the context exactly once + the affordance can be
/// re-armed cleanly on the next ``AdventureTabView`` appearance.
///
/// Why a process-singleton: SwiftUI environment values don't survive
/// tab switches cleanly when the source tab is dismantled by the
/// `TabView`. Storing the pending context on a shared `@MainActor
/// @Observable` class is the canonical way to bridge the affordance-
/// pill tap (Adventure tab) into the recording flow (Tell tab) without
/// adding a new state-machine surface.
///
/// Idempotent + safe under cold launch: the default value is
/// ``TaleRecordingContext/none``; ``consumePendingContext()`` returns
/// `.none` when nothing is pending. The Tell-tab reflection path
/// branches on ``TaleRecordingContext/isDeeperChallenge`` so the
/// non-deeper-challenge flow stays byte-for-byte unchanged.
@MainActor
@Observable
public final class RecordingContextCoordinator {
    /// Process-wide singleton. The Adventure pill posts to this;
    /// ``TellView`` consumes from this. Initialized lazily on first
    /// read (Swift `static let` semantics).
    public static let shared = RecordingContextCoordinator()

    /// Last-posted pending context. Non-`.none` from the moment an
    /// Adventure pill tap posts until ``TellView`` consumes it (which
    /// flips the value back to `.none`). Always written on `@MainActor`
    /// (every consumer is MainActor-isolated). Reads are observation-
    /// tracked so SwiftUI can react in the rare case a view binds
    /// directly (current consumers consume imperatively in `.task`,
    /// not via binding).
    public private(set) var pendingContext: TaleRecordingContext = .none

    /// `private` initializer enforces the singleton contract — call
    /// ``RecordingContextCoordinator/shared`` instead. Allows zero-
    /// state construction for tests via `@testable import` if needed.
    private init() {}

    /// Post a pending context from an Adventure mode-card affordance
    /// pill tap. The most recent post wins (one tap supersedes a
    /// stale prior one — e.g., the kid taps Hook Builder, doesn't go
    /// record, returns to Adventure, taps Pacing Walk: the second
    /// post replaces the first). Idempotent against equal contexts.
    public func setPendingContext(_ context: TaleRecordingContext) {
        guard context != pendingContext else { return }
        pendingContext = context
    }

    /// Consume the pending context — returns the current value AND
    /// resets to ``TaleRecordingContext/none``. Callers that consume
    /// then immediately re-post are explicitly supported (TellView
    /// reads on `.task` then runs reflection; the next Adventure
    /// pill tap re-arms the coordinator independently).
    public func consumePendingContext() -> TaleRecordingContext {
        let consumed = pendingContext
        pendingContext = .none
        return consumed
    }

    /// Clear without returning. Useful for `TellMachine.reset()` /
    /// `.cancel()` paths where the pending context should be dropped
    /// without consuming (e.g., the kid taps Pacing Walk, then taps
    /// Cancel Recording instead of going through with the tale).
    public func clearPendingContext() {
        pendingContext = .none
    }
}
