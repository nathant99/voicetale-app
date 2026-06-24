import Foundation
import Testing
import Models
@testable import AppFeature

/// Coverage for ``SessionTallyTracker`` — the in-memory counter feeding
/// ``SessionCloserView``'s recap. Verifies counter monotonicity, badge
/// de-duplication, and reset semantics.
@MainActor
@Suite("SessionTallyTracker")
struct SessionTallyTrackerTests {
    @Test func initialStateIsZeroed() {
        let tracker = SessionTallyTracker()
        #expect(tracker.talesSavedThisSession == 0)
        #expect(tracker.badgesEarnedThisSession.isEmpty)
        #expect(tracker.traditionRegisterSlugsSeen.isEmpty)
    }

    @Test func recordTaleSavedIncrementsCounter() {
        let tracker = SessionTallyTracker()
        tracker.recordTaleSaved()
        tracker.recordTaleSaved()
        tracker.recordTaleSaved()
        #expect(tracker.talesSavedThisSession == 3)
    }

    @Test func recordBadgeEarnedAppendsUnique() {
        let tracker = SessionTallyTracker()
        tracker.recordBadgeEarned(title: "First Tale")
        tracker.recordBadgeEarned(title: "Five Beats")
        #expect(tracker.badgesEarnedThisSession == ["First Tale", "Five Beats"])
    }

    @Test func recordBadgeEarnedDeduplicates() {
        let tracker = SessionTallyTracker()
        tracker.recordBadgeEarned(title: "First Tale")
        tracker.recordBadgeEarned(title: "First Tale")
        tracker.recordBadgeEarned(title: "First Tale")
        #expect(tracker.badgesEarnedThisSession == ["First Tale"])
    }

    @Test func resetClearsAllCounters() {
        let tracker = SessionTallyTracker()
        tracker.recordTaleSaved()
        tracker.recordTaleSaved()
        tracker.recordBadgeEarned(title: "First Tale")
        tracker.recordTraditionExpanded(slug: "griot")
        tracker.reset()
        #expect(tracker.talesSavedThisSession == 0)
        #expect(tracker.badgesEarnedThisSession.isEmpty)
        #expect(tracker.traditionRegisterSlugsSeen.isEmpty)
    }

    // MARK: - Tradition-echo cross-tab signal (PR-B 2026-06-24 NINTH-round)

    @Test func recordTraditionExpandedSeedsRegisterSlugs() {
        let tracker = SessionTallyTracker()
        tracker.recordTraditionExpanded(slug: "rakugo")
        #expect(tracker.traditionRegisterSlugsSeen == ["scary"])
    }

    @Test func recordTraditionExpandedUnionsAcrossSlugs() {
        let tracker = SessionTallyTracker()
        tracker.recordTraditionExpanded(slug: "griot")           // → tender
        tracker.recordTraditionExpanded(slug: "seanchai")        // → funny + wild
        #expect(tracker.traditionRegisterSlugsSeen == ["tender", "funny", "wild"])
    }

    @Test func recordTraditionExpandedUnknownSlugIsNoOp() {
        let tracker = SessionTallyTracker()
        tracker.recordTraditionExpanded(slug: "not-a-real-tradition")
        #expect(tracker.traditionRegisterSlugsSeen.isEmpty)
    }

    @Test func traditionEchoEligibleFiresOnMatch() {
        let tracker = SessionTallyTracker()
        tracker.recordTraditionExpanded(slug: "rakugo")          // → scary
        #expect(tracker.traditionEchoEligible(for: .scary))
        #expect(tracker.traditionEchoEligible(for: .funny) == false)
        #expect(tracker.traditionEchoEligible(for: .tender) == false)
        #expect(tracker.traditionEchoEligible(for: .wild) == false)
    }

    @Test func traditionEchoEligibleFalseWhenNoTraditionsExpanded() {
        let tracker = SessionTallyTracker()
        for mood in VoiceTaleMood.allCases {
            #expect(tracker.traditionEchoEligible(for: mood) == false)
        }
    }

    @Test func traditionEchoEligibleAfterMultipleExpansions() {
        let tracker = SessionTallyTracker()
        tracker.recordTraditionExpanded(slug: "seanchai")        // → funny + wild
        #expect(tracker.traditionEchoEligible(for: .funny))
        #expect(tracker.traditionEchoEligible(for: .wild))
        #expect(tracker.traditionEchoEligible(for: .tender) == false)
    }

    @Test func recordTraditionExpandedIdempotentOnRepeatTap() {
        // Kid taps Read more, Show less, Read more — the union should
        // still resolve to the same set (no duplicate growth surprises).
        let tracker = SessionTallyTracker()
        tracker.recordTraditionExpanded(slug: "griot")
        tracker.recordTraditionExpanded(slug: "griot")
        tracker.recordTraditionExpanded(slug: "griot")
        #expect(tracker.traditionRegisterSlugsSeen == ["tender"])
    }

    @Test func nextSessionInviteEscalatesWithStreak() {
        let day0 = AppRootView.nextSessionInvite(streakDays: 0)
        #expect(day0.contains("Bramble"))
        // Anti-shame on zero-streak: must not contain reset / fail / lost tokens.
        for token in ["broke", "fail", "lost", "lazy", "missed", "should"] {
            #expect(day0.lowercased().contains(token) == false)
        }
        let day1 = AppRootView.nextSessionInvite(streakDays: 1)
        #expect(day1.lowercased().contains("streak"))
        let day7 = AppRootView.nextSessionInvite(streakDays: 7)
        #expect(day7.lowercased().contains("real streak") || day7.lowercased().contains("streak"))
    }

    @Test func nextSessionInviteRendersForLargeStreaks() {
        let day30 = AppRootView.nextSessionInvite(streakDays: 30)
        #expect(day30.isEmpty == false)
    }
}
