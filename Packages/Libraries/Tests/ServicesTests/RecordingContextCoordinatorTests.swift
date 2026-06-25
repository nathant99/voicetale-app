import Testing
import Foundation
@testable import Services
@testable import Models

/// Coverage for ``RecordingContextCoordinator`` per
/// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D second-half.
/// Locks the set / consume / clear cycle + the one-shot consume
/// semantics + the equal-context idempotency invariant. The singleton
/// shared instance is used (mirroring ``IntentTabCoordinator`` testing
/// in the AppFeature suite) so the test surface matches the production
/// wiring. Each test clears the singleton on entry + exit so
/// suite-level parallel execution stays isolated.
@MainActor
@Suite("RecordingContextCoordinator")
struct RecordingContextCoordinatorTests {
    private let coordinator = RecordingContextCoordinator.shared

    init() {
        coordinator.clearPendingContext()
    }

    // MARK: - Default state

    @Test func startsWithNonePendingContext() {
        #expect(coordinator.pendingContext == .none)
    }

    // MARK: - Set + consume cycle

    @Test func setPendingContextStoresAndExposesValue() {
        let ctx = TaleRecordingContext(deeperChallengeKit: .hookCraft)
        coordinator.setPendingContext(ctx)
        #expect(coordinator.pendingContext == ctx)
        #expect(coordinator.pendingContext.isDeeperChallenge == true)
        coordinator.clearPendingContext()
    }

    @Test func consumePendingContextReturnsThenResetsToNone() {
        let ctx = TaleRecordingContext(deeperChallengeKit: .pacingRhythm)
        coordinator.setPendingContext(ctx)
        let consumed = coordinator.consumePendingContext()
        #expect(consumed == ctx)
        #expect(coordinator.pendingContext == .none,
                "consume must one-shot reset the pending context")
    }

    @Test func consumeOnNoneReturnsNone() {
        // Cold-launch parity — consuming nothing returns nothing.
        let consumed = coordinator.consumePendingContext()
        #expect(consumed == .none)
        #expect(coordinator.pendingContext == .none)
    }

    // MARK: - Clear

    @Test func clearPendingContextResetsWithoutReturning() {
        coordinator.setPendingContext(TaleRecordingContext(deeperChallengeKit: .closingGrace))
        coordinator.clearPendingContext()
        #expect(coordinator.pendingContext == .none)
    }

    // MARK: - Idempotency

    @Test func setSamePendingContextIsAnIdempotentNoOp() {
        let ctx = TaleRecordingContext(deeperChallengeKit: .surprisePivot)
        coordinator.setPendingContext(ctx)
        let before = coordinator.pendingContext
        coordinator.setPendingContext(ctx)
        let after = coordinator.pendingContext
        #expect(before == after)
        coordinator.clearPendingContext()
    }

    @Test func mostRecentSetWins() {
        let first = TaleRecordingContext(deeperChallengeKit: .hookCraft)
        let second = TaleRecordingContext(deeperChallengeKit: .pacingRhythm)
        coordinator.setPendingContext(first)
        coordinator.setPendingContext(second)
        #expect(coordinator.pendingContext == second,
                "second set must supersede the first")
        coordinator.clearPendingContext()
    }

    // MARK: - One-shot consume guarantees the next set re-arms

    @Test func consumeThenSetReArmsCleanly() {
        coordinator.setPendingContext(TaleRecordingContext(deeperChallengeKit: .voiceCharacter))
        _ = coordinator.consumePendingContext()
        #expect(coordinator.pendingContext == .none)

        let next = TaleRecordingContext(deeperChallengeKit: .mood)
        coordinator.setPendingContext(next)
        #expect(coordinator.pendingContext == next)
        coordinator.clearPendingContext()
    }
}
