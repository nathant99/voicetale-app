import Testing
import Foundation
@testable import Models

/// Coverage for ``TaleRecordingContext`` per
/// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D second-half.
/// Locks the value-type defaults + the ``isDeeperChallenge`` predicate +
/// the ``TaleRecordingContext/none`` canonical empty value.
@Suite("TaleRecordingContext")
struct TaleRecordingContextTests {
    // MARK: - Default value

    @Test func defaultInitProducesNoneContext() {
        let ctx = TaleRecordingContext()
        #expect(ctx.deeperChallengeKit == nil)
        #expect(ctx.isDeeperChallenge == false)
        #expect(ctx == .none)
    }

    @Test func noneCanonicalValueHasNilKit() {
        #expect(TaleRecordingContext.none.deeperChallengeKit == nil)
        #expect(TaleRecordingContext.none.isDeeperChallenge == false)
    }

    // MARK: - Deeper-challenge predicate

    @Test func isDeeperChallengeFlipsWhenKitIsSet() {
        for kit in KitID.allCases {
            let ctx = TaleRecordingContext(deeperChallengeKit: kit)
            #expect(ctx.isDeeperChallenge == true,
                    "kit=\(kit) should mark the context as a deeper challenge")
            #expect(ctx.deeperChallengeKit == kit)
        }
    }

    // MARK: - Equality + hashing

    @Test func equalityComparesKitOnly() {
        let a = TaleRecordingContext(deeperChallengeKit: .hookCraft)
        let b = TaleRecordingContext(deeperChallengeKit: .hookCraft)
        let c = TaleRecordingContext(deeperChallengeKit: .pacingRhythm)
        #expect(a == b)
        #expect(a != c)
        #expect(b != c)
    }

    @Test func valueTypeRoundTrip() {
        var ctx = TaleRecordingContext(deeperChallengeKit: .closingGrace)
        let snapshot = ctx
        ctx = .none
        // Value-type copy semantics: mutating the original doesn't
        // disturb the snapshot.
        #expect(snapshot.deeperChallengeKit == .closingGrace)
        #expect(ctx.deeperChallengeKit == nil)
    }

    @Test func hashableConformsForSetMembership() {
        let set: Set<TaleRecordingContext> = [
            .none,
            TaleRecordingContext(deeperChallengeKit: .hookCraft),
            TaleRecordingContext(deeperChallengeKit: .hookCraft),
            TaleRecordingContext(deeperChallengeKit: .surprisePivot),
        ]
        // Duplicate `.hookCraft` collapses; .none + .hookCraft +
        // .surprisePivot = 3 distinct members.
        #expect(set.count == 3)
    }
}
