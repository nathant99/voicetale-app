import Foundation
import Testing
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
        tracker.reset()
        #expect(tracker.talesSavedThisSession == 0)
        #expect(tracker.badgesEarnedThisSession.isEmpty)
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
