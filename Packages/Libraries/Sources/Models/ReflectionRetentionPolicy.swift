import Foundation

/// Input snapshot for the reflection-purge cadence check. Pure value type
/// so the cadence logic is unit-testable without a SwiftData host. Per
/// `@Docs/PLAN_FORGEREFLECTION_LIFT.md` § Phase C ("retention policy +
/// purge wiring") + `@.claude/rules/age-assurance.md` § "2026 FTC COPPA
/// Rule Amendments" (defined retention period requirement).
public nonisolated struct ReflectionRetentionInputs: Sendable, Hashable {
    /// `nil` when the kid has never landed a purge yet — first-launch
    /// install with no prior history. Treated as "long enough ago" so
    /// the first launch eligible for a purge triggers one.
    public let lastPurgeAt: Date?

    /// Grown-up-overridable retention horizon. Clamped to the policy's
    /// `clampedRetentionDays(...)` range so a corrupt `@AppStorage` value
    /// (e.g., zero / negative / extreme) degrades to the 180-day default.
    public let retentionDays: Int

    public init(lastPurgeAt: Date?, retentionDays: Int) {
        self.lastPurgeAt = lastPurgeAt
        self.retentionDays = retentionDays
    }
}

/// Cadence + cutoff computation for the ForgeReflection Phase C retention
/// purge. Stateless; every method is pure-function so cadence + cutoff
/// invariants are unit-testable without spinning up a SwiftData host.
///
/// Default retention horizon = 180 days ("around half a year") per
/// `@Docs/PLAN_FORGEREFLECTION_LIFT.md` § Phase C + open-question Q3
/// verdict. Allowed range: 90 / 180 / 365 days — the grown-up picker
/// in ``SettingsView`` exposes these three points. Out-of-range values
/// degrade to the default rather than skipping the purge entirely
/// (anti-shame: a grown-up tweaking `@AppStorage` to a corrupt value
/// must not block the COPPA-mandated purge from firing).
///
/// Cadence: weekly — purge fires no more than once every 7 days, even
/// when the kid relaunches the app many times per day. Idempotent in
/// the no-op case (when nothing crosses the cutoff).
public nonisolated enum ReflectionRetentionPolicy {
    /// Canonical kid-readable default — "around half a year".
    public static let defaultRetentionDays: Int = 180

    /// Allowed retention picks the grown-up settings surface exposes.
    /// Centralized so a future expansion (e.g., 30-day picky-mode) is a
    /// single-line table edit + the policy + tests still hold.
    public static let allowedRetentionDays: [Int] = [90, 180, 365]

    /// Minimum cadence between purge runs. The purge is cheap (one
    /// SwiftData predicate fetch + delete) but firing on every launch
    /// would flood analytics with `reflectionsPurged(removed: 0)` events.
    public static let purgeCadenceSeconds: TimeInterval = 7 * 24 * 60 * 60

    /// Clamp `requested` to the allowed set; values outside the set
    /// degrade to ``defaultRetentionDays``. This guards against corrupt
    /// `@AppStorage` writes (e.g., a future migration that changes the
    /// key shape) without raising — the kid's reflections still purge
    /// on the safe default.
    public static func clampedRetentionDays(_ requested: Int) -> Int {
        allowedRetentionDays.contains(requested) ? requested : defaultRetentionDays
    }

    /// Returns `true` when enough time has elapsed since the last purge
    /// (or no prior purge has happened) to fire another run.
    /// `lastPurgeAt: nil` → always fire (first-launch eligibility).
    public static func shouldPurge(
        inputs: ReflectionRetentionInputs,
        now: Date = .now
    ) -> Bool {
        guard let last = inputs.lastPurgeAt else { return true }
        let elapsed = now.timeIntervalSince(last)
        return elapsed >= purgeCadenceSeconds
    }

    /// The Date strictly before which entries are eligible for deletion.
    /// Entries with `createdAt < cutoff` are purged; entries at the
    /// boundary (`createdAt == cutoff`) are kept (defensive choice — at
    /// the boundary the COPPA clock has not yet rolled over).
    public static func cutoff(
        inputs: ReflectionRetentionInputs,
        now: Date = .now
    ) -> Date {
        let clamped = clampedRetentionDays(inputs.retentionDays)
        return now.addingTimeInterval(-Double(clamped) * 24 * 60 * 60)
    }

    /// Categorical bucket for the `reflectionsPurged(removed:)` analytics
    /// event. Bucketed counts never leak the actual run-by-run delete
    /// count (which could fingerprint kid-by-kid engagement patterns)
    /// while still surfacing cohort signal of "the purge ran and removed
    /// some / many / no entries".
    public static func removedCountBucket(_ count: Int) -> String {
        switch count {
        case ..<1:    return "zero"
        case 1...3:   return "one_to_three"
        case 4...10:  return "four_to_ten"
        default:      return "eleven_plus"
        }
    }
}
