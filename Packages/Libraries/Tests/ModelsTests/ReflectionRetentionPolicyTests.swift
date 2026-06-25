import Foundation
import Testing
@testable import Models

/// ForgeReflection Phase C — cadence + cutoff + clamp invariants on the
/// pure-function ``ReflectionRetentionPolicy``. The policy is the only
/// seam between the FTC-2026 COPPA-mandated retention requirement and
/// the consumer surface in `AppRootView.task`; locking these invariants
/// at the unit-test level keeps a future settings-key migration from
/// silently skipping the purge. Per
/// `@Docs/PLAN_FORGEREFLECTION_LIFT.md` § Phase C.
@Suite("Reflection retention policy")
struct ReflectionRetentionPolicyTests {

    /// `lastPurgeAt: nil` (first-launch eligibility) — the policy must
    /// always fire. Otherwise a kid's first reflection sits forever
    /// until the cadence window passes, which violates the FTC-2026
    /// retention-window requirement.
    @Test
    func nilLastPurgeAtTriggersImmediatePurge() {
        let inputs = ReflectionRetentionInputs(lastPurgeAt: nil, retentionDays: 180)
        #expect(ReflectionRetentionPolicy.shouldPurge(inputs: inputs))
    }

    /// Strictly within the 7-day cadence — must NOT fire. The kid
    /// relaunching the app on day 3 doesn't trigger the purge.
    @Test
    func recentLastPurgeAtSkipsCadence() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let lastPurge = now.addingTimeInterval(-3 * 24 * 60 * 60) // 3 days ago
        let inputs = ReflectionRetentionInputs(lastPurgeAt: lastPurge, retentionDays: 180)
        #expect(!ReflectionRetentionPolicy.shouldPurge(inputs: inputs, now: now))
    }

    /// Exactly 7 days since the last purge — fires. Boundary at exactly
    /// the cadence floor must trip the predicate (anti-shame: the
    /// COPPA-mandated retention window must not skip a day because the
    /// clock landed on the boundary).
    @Test
    func exactlySevenDaysSinceLastPurgeFires() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let lastPurge = now.addingTimeInterval(-7 * 24 * 60 * 60)
        let inputs = ReflectionRetentionInputs(lastPurgeAt: lastPurge, retentionDays: 180)
        #expect(ReflectionRetentionPolicy.shouldPurge(inputs: inputs, now: now))
    }

    /// Well past the 7-day cadence — fires unconditionally.
    @Test
    func longGapSinceLastPurgeFires() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let lastPurge = now.addingTimeInterval(-30 * 24 * 60 * 60)
        let inputs = ReflectionRetentionInputs(lastPurgeAt: lastPurge, retentionDays: 180)
        #expect(ReflectionRetentionPolicy.shouldPurge(inputs: inputs, now: now))
    }

    /// Cutoff is `now - retentionDays * 86400`. The 180-day default
    /// produces a cutoff exactly 180 days before `now`.
    @Test
    func cutoffForDefaultRetentionIs180DaysAgo() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let inputs = ReflectionRetentionInputs(lastPurgeAt: nil, retentionDays: 180)
        let cutoff = ReflectionRetentionPolicy.cutoff(inputs: inputs, now: now)
        let expected = now.addingTimeInterval(-180 * 24 * 60 * 60)
        #expect(abs(cutoff.timeIntervalSince(expected)) < 0.001)
    }

    /// 90-day picks shorten the retention window without changing the
    /// cadence. Cutoff is exactly 90 days before `now`.
    @Test
    func cutoffFor90DayRetention() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let inputs = ReflectionRetentionInputs(lastPurgeAt: nil, retentionDays: 90)
        let cutoff = ReflectionRetentionPolicy.cutoff(inputs: inputs, now: now)
        let expected = now.addingTimeInterval(-90 * 24 * 60 * 60)
        #expect(abs(cutoff.timeIntervalSince(expected)) < 0.001)
    }

    /// 365-day picks lengthen the retention window. Cutoff is exactly
    /// 365 days before `now`.
    @Test
    func cutoffFor365DayRetention() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let inputs = ReflectionRetentionInputs(lastPurgeAt: nil, retentionDays: 365)
        let cutoff = ReflectionRetentionPolicy.cutoff(inputs: inputs, now: now)
        let expected = now.addingTimeInterval(-365 * 24 * 60 * 60)
        #expect(abs(cutoff.timeIntervalSince(expected)) < 0.001)
    }

    /// Corrupt `@AppStorage` writes (0 / negative / extreme values) MUST
    /// degrade to the 180-day default cutoff, never skip the purge
    /// entirely. The COPPA-mandated retention window must not be
    /// defeated by a single corrupt value.
    @Test
    func corruptRetentionDaysDegradesToDefault() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        for bad in [0, -1, -180, 7, 30, 60, 730, 99999] {
            let inputs = ReflectionRetentionInputs(lastPurgeAt: nil, retentionDays: bad)
            let cutoff = ReflectionRetentionPolicy.cutoff(inputs: inputs, now: now)
            let expected = now.addingTimeInterval(
                -Double(ReflectionRetentionPolicy.defaultRetentionDays) * 24 * 60 * 60
            )
            #expect(
                abs(cutoff.timeIntervalSince(expected)) < 0.001,
                "Corrupt value \(bad) should degrade to defaultRetentionDays"
            )
        }
    }

    /// The clamp helper returns allowed values unchanged + everything
    /// else as the default. Invariant on the 3-pick allowed set.
    @Test
    func clampedRetentionDaysAllowsCanonicalPicks() {
        #expect(ReflectionRetentionPolicy.clampedRetentionDays(90) == 90)
        #expect(ReflectionRetentionPolicy.clampedRetentionDays(180) == 180)
        #expect(ReflectionRetentionPolicy.clampedRetentionDays(365) == 365)
    }

    @Test
    func clampedRetentionDaysCoercesUnknownToDefault() {
        #expect(ReflectionRetentionPolicy.clampedRetentionDays(0)
                == ReflectionRetentionPolicy.defaultRetentionDays)
        #expect(ReflectionRetentionPolicy.clampedRetentionDays(-1)
                == ReflectionRetentionPolicy.defaultRetentionDays)
        #expect(ReflectionRetentionPolicy.clampedRetentionDays(60)
                == ReflectionRetentionPolicy.defaultRetentionDays)
        #expect(ReflectionRetentionPolicy.clampedRetentionDays(450)
                == ReflectionRetentionPolicy.defaultRetentionDays)
    }

    /// The bucketing helper for the `reflectionsPurged(removed:)`
    /// analytics event partitions counts into 4 categorical buckets.
    /// Raw counts MUST NEVER travel — only the bucket. Anti-
    /// fingerprinting per `@Docs/PLAN_FORGEREFLECTION_LIFT.md` § Phase
    /// C + COPPA-2026 anti-PII discipline.
    @Test
    func removedCountBucketsPartitionCleanly() {
        // Zero — quiet steady-state for the active kid.
        #expect(ReflectionRetentionPolicy.removedCountBucket(0) == "zero")
        // Negative shouldn't happen but degrade safely into the zero
        // bucket (no analytic event ever fires negative deletes).
        #expect(ReflectionRetentionPolicy.removedCountBucket(-1) == "zero")
        // Low-volume — kid has 1-3 weeks-old reflections rolling off.
        #expect(ReflectionRetentionPolicy.removedCountBucket(1) == "one_to_three")
        #expect(ReflectionRetentionPolicy.removedCountBucket(3) == "one_to_three")
        // Mid-volume — kid sitting on dense reflection density.
        #expect(ReflectionRetentionPolicy.removedCountBucket(4) == "four_to_ten")
        #expect(ReflectionRetentionPolicy.removedCountBucket(10) == "four_to_ten")
        // High-volume — kid coming back to dense year-old payload.
        #expect(ReflectionRetentionPolicy.removedCountBucket(11) == "eleven_plus")
        #expect(ReflectionRetentionPolicy.removedCountBucket(100) == "eleven_plus")
    }

    /// The cadence + cutoff helpers are pure — same inputs produce same
    /// outputs. Determinism invariant.
    @Test
    func policyIsDeterministicAcrossRepeatedCalls() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let inputs = ReflectionRetentionInputs(lastPurgeAt: nil, retentionDays: 180)
        let cutoffA = ReflectionRetentionPolicy.cutoff(inputs: inputs, now: now)
        let cutoffB = ReflectionRetentionPolicy.cutoff(inputs: inputs, now: now)
        let cutoffC = ReflectionRetentionPolicy.cutoff(inputs: inputs, now: now)
        #expect(cutoffA == cutoffB)
        #expect(cutoffB == cutoffC)
    }
}
