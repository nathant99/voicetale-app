import Testing
import Foundation
@testable import AppFeature

/// Coverage for the Discovery-micro-delight expansion shipped Round
/// 2026-06-24 PR-D:
/// 1. Rare-prompt pool grows 5 → 8 entries
/// 2. ``TraditionGalleryView/discoveryCalloutCopy(unexploredCount:)``
///    resolver
///
/// Pure-function tests — no SwiftUI host needed.
@Suite("DiscoveryExpansion")
struct DiscoveryExpansionTests {
    // MARK: - Rare-prompt pool

    @Test func rarePromptPoolHasEightEntries() {
        // Pool grew 5 → 8 per PR-D. Lock the count so future regressions
        // surface in CI.
        #expect(DailyPromptView.rarePrompts.count == 8)
    }

    @Test func rarePromptPoolCategoriesAreUnique() {
        let categories = DailyPromptView.rarePrompts.map(\.category)
        #expect(Set(categories).count == categories.count,
            "rare-prompt categories must be unique for analytics dedup")
    }

    @Test func rarePromptPoolContainsNewArchetypes() {
        // The 3 new entries shipped PR-D: voice_passport / mood_echo /
        // family_tradition. Lock their presence by category slug.
        let categories = Set(DailyPromptView.rarePrompts.map(\.category))
        #expect(categories.contains("voice_passport"))
        #expect(categories.contains("mood_echo"))
        #expect(categories.contains("family_tradition"))
    }

    @Test func rarePromptPoolEntriesHaveNonEmptyText() {
        for entry in DailyPromptView.rarePrompts {
            #expect(!entry.text.isEmpty,
                "rare prompt '\(entry.category)' has empty text")
            #expect(!entry.category.isEmpty)
        }
    }

    @Test func rarePromptResolverWalksAllEightWithoutEarlyWrap() {
        // Resolve at sessionCount 5, 10, 15, 20, 25, 30, 35, 40 — should
        // surface 8 distinct rare prompts (one per pool entry) before
        // wrapping. session 45 wraps back to the first rare entry.
        let sessionCounts = stride(from: 5, through: 40, by: 5).map { $0 }
        let resolved = sessionCounts.map { count in
            DailyPromptView.resolved(sessionCount: count).rareCategory
        }
        let distinct = Set(resolved.compactMap { $0 })
        #expect(distinct.count == 8,
            "resolver should walk all 8 rare entries before wrapping; got \(distinct)")
    }

    @Test func nonRareSessionsReturnNilCategory() {
        for session in [1, 2, 3, 4, 6, 7, 8, 9] {
            let resolved = DailyPromptView.resolved(sessionCount: session)
            #expect(resolved.rareCategory == nil,
                "session \(session) should be non-rare")
        }
    }

    // MARK: - Discovery callout copy resolver

    @Test func discoveryCalloutSilentWhenAllExplored() {
        // Kid has explored every tradition — no callout needed; nil is
        // the canonical no-op.
        #expect(TraditionGalleryView.discoveryCalloutCopy(unexploredCount: 0) == nil)
    }

    @Test func discoveryCalloutSingularCopyAtOneRemaining() {
        let copy = TraditionGalleryView.discoveryCalloutCopy(unexploredCount: 1)
        #expect(copy != nil)
        #expect(copy?.contains("One") == true || copy?.contains("one") == true)
    }

    @Test func discoveryCalloutPluralCopyAtMultipleRemaining() {
        for unexplored in [2, 3, 4, 5, 10] {
            let copy = TraditionGalleryView.discoveryCalloutCopy(unexploredCount: unexplored)
            #expect(copy != nil)
            #expect(copy?.contains("waiting") == true,
                "plural copy at unexplored=\(unexplored) should name the waiting framing")
        }
    }

    @Test func discoveryCalloutNeverShamesAbsence() {
        // Per `@.claude/rules/trauma-informed-content.md` § "Validate-
        // then-inform". The callout never names how many traditions the
        // kid has skipped / missed / ignored.
        let shameTokens = [
            "missed", "skipped", "ignored", "still", "always",
            "should", "didn't", "haven't", "lazy",
        ]
        for unexplored in 0...10 {
            guard let copy = TraditionGalleryView.discoveryCalloutCopy(unexploredCount: unexplored) else {
                continue
            }
            let lowered = copy.lowercased()
            for token in shameTokens {
                #expect(!lowered.contains(token),
                "callout copy at unexplored=\(unexplored) contains shame token '\(token)': \(copy)")
            }
        }
    }

    @Test func discoveryCalloutCopyNeverNamesTheCount() {
        // The callout names "one" for the singular variant + "more" for
        // the plural — never an exact count (anti-grading per the
        // anti-shame contract).
        for unexplored in 2...10 {
            guard let copy = TraditionGalleryView.discoveryCalloutCopy(unexploredCount: unexplored) else {
                continue
            }
            #expect(!copy.contains(String(unexplored)),
                "plural copy at unexplored=\(unexplored) should not name the count: \(copy)")
        }
    }
}
