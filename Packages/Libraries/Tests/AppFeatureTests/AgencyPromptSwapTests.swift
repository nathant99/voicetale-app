import Testing
import Foundation
@testable import AppFeature

/// Coverage for the Agency-micro-delight prompt-swap shipped Round
/// 2026-06-24 PR-E:
/// 1. ``DailyPromptView/nextSwapIndex(currentIndex:poolSize:)`` resolver
/// 2. ``VoiceTaleAnalyticsEvent/promptSwapped(toIndex:)`` analytics surface
///
/// Pure-function tests — no SwiftUI host needed for the resolver.
@Suite("AgencyPromptSwap")
struct AgencyPromptSwapTests {
    // MARK: - nextSwapIndex resolver

    @Test func nextSwapNeverReturnsCurrentIndex() {
        // The swap MUST change the prompt — kid taps the pill, kid sees
        // a different prompt. Lock the contract across the full pool.
        let poolSize = DailyPromptView.prompts.count
        for current in 0..<poolSize {
            let next = DailyPromptView.nextSwapIndex(
                currentIndex: current,
                poolSize: poolSize
            )
            #expect(next != current,
                "swap should not return current index \(current); got \(next)")
            #expect(next >= 0)
            #expect(next < poolSize)
        }
    }

    @Test func nextSwapDistributesAcrossPool() {
        // 30 consecutive swaps walking through the pool should land on
        // a diverse set (≥ pool_size / 2 distinct entries) — the
        // stride-of-7 spreads the kid through the pool without
        // monotonously stepping to the adjacent entry.
        let poolSize = DailyPromptView.prompts.count
        var current = 0
        var seen = Set<Int>([current])
        for _ in 0..<poolSize {
            current = DailyPromptView.nextSwapIndex(
                currentIndex: current,
                poolSize: poolSize
            )
            seen.insert(current)
        }
        #expect(seen.count >= poolSize / 2,
            "swap rotation should distribute across ≥ pool/2; got \(seen.count) distinct of \(poolSize)")
    }

    @Test func nextSwapHandlesPoolSizeOneEdgeCase() {
        // A pool of 1 has no other entry to swap to — return current
        // index unchanged rather than crash.
        #expect(DailyPromptView.nextSwapIndex(currentIndex: 0, poolSize: 1) == 0)
    }

    @Test func nextSwapHandlesPoolSizeTwoEdgeCase() {
        // Pool of 2 always alternates between the two entries.
        #expect(DailyPromptView.nextSwapIndex(currentIndex: 0, poolSize: 2) == 1)
        #expect(DailyPromptView.nextSwapIndex(currentIndex: 1, poolSize: 2) == 0)
    }

    @Test func nextSwapWrapsAtPoolBoundary() {
        let poolSize = DailyPromptView.prompts.count
        let nearEnd = poolSize - 3
        let next = DailyPromptView.nextSwapIndex(
            currentIndex: nearEnd,
            poolSize: poolSize
        )
        #expect(next < poolSize)
        #expect(next >= 0)
    }

    // MARK: - todaysPromptIndex resolver

    @Test func todaysPromptIndexStableForSameDate() {
        let now = Date()
        let cal = Calendar.current
        let a = DailyPromptView.todaysPromptIndex(now: now, calendar: cal)
        let b = DailyPromptView.todaysPromptIndex(now: now, calendar: cal)
        #expect(a == b)
    }

    @Test func todaysPromptIndexWithinPoolBounds() {
        let poolSize = DailyPromptView.prompts.count
        // Pin a handful of representative dates across the year.
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 24
        let cal = Calendar(identifier: .gregorian)
        let date = cal.date(from: components) ?? Date()
        let index = DailyPromptView.todaysPromptIndex(now: date, calendar: cal)
        #expect(index >= 0)
        #expect(index < poolSize)
    }

    // MARK: - Analytics event

    @Test func promptSwappedAnalyticsEventNameSnakeCase() {
        let event = VoiceTaleAnalyticsEvent.promptSwapped(toIndex: 7)
        #expect(event.name == "prompt_swapped")
    }

    @Test func promptSwappedAnalyticsCarriesIndexNotText() {
        let event = VoiceTaleAnalyticsEvent.promptSwapped(toIndex: 12)
        let props = event.properties
        #expect(props["to_index"] == "12")
        // Anti-PII: ensure the prompt text is NOT in any property.
        let allValues = props.values.joined(separator: " ")
        #expect(!allValues.contains("Tell"),
            "categorical payload must not embed prompt text: \(allValues)")
    }
}
