import Foundation
import ForgeModels

/// Bucketed week-level engagement snapshot for the parent-dashboard
/// "This week" digest row. Returned by
/// ``VoiceTaleReflectionStore.weeklyEngagement(now:)`` for consumption
/// by ``ReflectionJournalView`` per the Phase D second-half polish ship.
///
/// Categorical bucket strings reuse
/// ``ReflectionRetentionPolicy.removedCountBucket(_:)`` so the digest
/// wire shape stays in lockstep with the sibling
/// ``reflectionsPurged(removed:)`` /
/// ``parentReflectionJournalOpened(visibleCount:)`` analytics events.
/// Raw counts NEVER travel — they live only inside this in-process
/// value, never on a wire / analytics surface (anti-fingerprinting per
/// `@.claude/rules/age-assurance.md` § "2026 FTC COPPA Rule Amendments").
///
/// Per-modality entries appear ONLY when the modality saw at least one
/// engagement in the window — `.zero` buckets are dropped so the view
/// doesn't render a row of "0 voice / 0 drawing / 0 emoji" for kids who
/// only typed. The digest is therefore visually proportional to actual
/// engagement breadth.
public nonisolated struct ReflectionWeeklyEngagement: Sendable, Hashable {
    /// Bucketed total count across all modalities in the 7-day window.
    /// One of `"zero"` / `"one_to_three"` / `"four_to_ten"` /
    /// `"eleven_plus"` per ``ReflectionRetentionPolicy/removedCountBucket(_:)``.
    public let totalBucket: String

    /// Bucketed per-modality counts. Only carries modalities with
    /// at least one entry in the window; `.zero` buckets are dropped.
    public let perModalityBucket: [ReflectionResponseModality: String]

    /// Sugar — `true` when no entries landed in the window.
    public var isEmpty: Bool { totalBucket == "zero" }

    public init(
        totalBucket: String,
        perModalityBucket: [ReflectionResponseModality: String]
    ) {
        self.totalBucket = totalBucket
        self.perModalityBucket = perModalityBucket
    }

    /// Pure factory over a `[ReflectionEntry]` slice. Walks each entry
    /// once and tallies per-modality + total counts, then runs every
    /// count through ``ReflectionRetentionPolicy/removedCountBucket(_:)``.
    /// `.zero` per-modality buckets are dropped so consumers don't
    /// render "0 voice" rows.
    public static func make(
        from entries: [ReflectionEntry]
    ) -> ReflectionWeeklyEngagement {
        var modalityCounts: [ReflectionResponseModality: Int] = [:]
        for entry in entries {
            modalityCounts[entry.modality, default: 0] += 1
        }
        let total = entries.count
        let totalBucket = ReflectionRetentionPolicy.removedCountBucket(total)
        var modalityBuckets: [ReflectionResponseModality: String] = [:]
        for (modality, count) in modalityCounts where count > 0 {
            modalityBuckets[modality] = ReflectionRetentionPolicy.removedCountBucket(count)
        }
        return ReflectionWeeklyEngagement(
            totalBucket: totalBucket,
            perModalityBucket: modalityBuckets
        )
    }
}
