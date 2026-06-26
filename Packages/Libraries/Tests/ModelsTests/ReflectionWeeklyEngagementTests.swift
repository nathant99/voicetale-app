import Foundation
import Testing
import ForgeModels
@testable import Models

/// ForgeReflection Phase D second-half polish — bucket factory invariants
/// on the pure-function ``ReflectionWeeklyEngagement``. The factory is
/// the only seam between the cached `[ReflectionEntry]` snapshot and the
/// parent-dashboard "This week" digest row; locking these invariants at
/// the unit-test level guards the anti-fingerprinting + COPPA-2026
/// anti-PII discipline (raw counts NEVER travel — only bucketed labels).
@Suite("Reflection weekly engagement")
struct ReflectionWeeklyEngagementTests {

    private func entry(
        modality: ReflectionResponseModality = .text,
        at date: Date = .now
    ) -> ReflectionEntry {
        ReflectionEntry(
            id: UUID(),
            promptID: "bramble.socratic.freeform",
            appIdentifier: "test.weekly",
            kitNumber: nil,
            modality: modality,
            textValue: nil,
            assetFileURL: nil,
            respondedAt: date,
            studentProfileID: nil
        )
    }

    // MARK: - Empty + isEmpty

    @Test
    func emptySliceProducesZeroBucket() {
        let digest = ReflectionWeeklyEngagement.make(from: [])
        #expect(digest.totalBucket == "zero")
        #expect(digest.perModalityBucket.isEmpty)
        #expect(digest.isEmpty)
    }

    @Test
    func nonEmptySliceIsNotEmpty() {
        let digest = ReflectionWeeklyEngagement.make(from: [entry()])
        #expect(digest.isEmpty == false)
    }

    // MARK: - Per-modality bucket fidelity

    @Test
    func singleEntryFlowsIntoCorrectModalityBucket() {
        let digest = ReflectionWeeklyEngagement.make(from: [entry(modality: .voice)])
        #expect(digest.totalBucket == "one_to_three")
        #expect(digest.perModalityBucket[.voice] == "one_to_three")
        #expect(digest.perModalityBucket[.text] == nil)
        #expect(digest.perModalityBucket[.drawing] == nil)
        #expect(digest.perModalityBucket[.emoji] == nil)
        #expect(digest.perModalityBucket[.skip] == nil)
    }

    @Test
    func twoModalitiesSplitIntoTwoBuckets() {
        let entries: [ReflectionEntry] = [
            entry(modality: .text),
            entry(modality: .text),
            entry(modality: .voice),
        ]
        let digest = ReflectionWeeklyEngagement.make(from: entries)
        #expect(digest.totalBucket == "one_to_three")
        #expect(digest.perModalityBucket[.text] == "one_to_three")
        #expect(digest.perModalityBucket[.voice] == "one_to_three")
    }

    /// `.zero` per-modality buckets MUST be dropped. The view doesn't
    /// render rows for modalities the kid didn't engage with — surfacing
    /// "0 voice / 0 drawing / 0 emoji" would invite the grown-up to
    /// pressure breadth that's none of their business.
    @Test
    func zeroBucketModalitiesAreDropped() {
        let entries = (0..<4).map { _ in entry(modality: .text) }
        let digest = ReflectionWeeklyEngagement.make(from: entries)
        #expect(digest.totalBucket == "four_to_ten")
        #expect(digest.perModalityBucket[.text] == "four_to_ten")
        for modality in ReflectionResponseModality.allCases where modality != .text {
            #expect(digest.perModalityBucket[modality] == nil)
        }
    }

    // MARK: - Total-bucket fidelity at bucket boundaries

    /// Confirms the factory inherits ``ReflectionRetentionPolicy.removedCountBucket``
    /// boundaries — the wire-shape lockstep guarantee that lets the
    /// parent-dashboard digest sit next to ``reflectionsPurged(removed:)``
    /// + ``parentReflectionJournalOpened(visibleCount:)`` analytics
    /// events without leaking finer-grained signal.
    @Test
    func totalBucketBoundariesMatchPolicy() {
        let zero = ReflectionWeeklyEngagement.make(from: [])
        #expect(zero.totalBucket == "zero")

        let three = ReflectionWeeklyEngagement.make(from: (0..<3).map { _ in entry() })
        #expect(three.totalBucket == "one_to_three")

        let four = ReflectionWeeklyEngagement.make(from: (0..<4).map { _ in entry() })
        #expect(four.totalBucket == "four_to_ten")

        let ten = ReflectionWeeklyEngagement.make(from: (0..<10).map { _ in entry() })
        #expect(ten.totalBucket == "four_to_ten")

        let eleven = ReflectionWeeklyEngagement.make(from: (0..<11).map { _ in entry() })
        #expect(eleven.totalBucket == "eleven_plus")
    }

    /// Same boundary check applied at the per-modality slot — confirms
    /// the factory doesn't accidentally swap totals + per-modality
    /// counts.
    @Test
    func perModalityBoundariesMatchPolicy() {
        let entries = (0..<11).map { _ in entry(modality: .drawing) }
        let digest = ReflectionWeeklyEngagement.make(from: entries)
        #expect(digest.perModalityBucket[.drawing] == "eleven_plus")
        #expect(digest.totalBucket == "eleven_plus")
    }

    // MARK: - .skip preserves engagement signal

    /// `.skip` entries (engaged-then-private off-ramp) DO count toward
    /// the weekly total + their own modality slot. The view-layer
    /// summary intentionally drops `.skip` from the per-modality
    /// short-phrase (a grown-up second-guessing the kid's privacy
    /// choice is the anti-shame failure mode), but the digest carries
    /// the bucket so callers can choose how to surface it.
    @Test
    func skipModalityFlowsIntoBucket() {
        let digest = ReflectionWeeklyEngagement.make(from: [entry(modality: .skip)])
        #expect(digest.totalBucket == "one_to_three")
        #expect(digest.perModalityBucket[.skip] == "one_to_three")
    }
}
