import Foundation
import Observation

/// Tracks per-sitting engagement counters so ``SessionCloserView`` can render
/// an honest recap when the session soft-cap fires. Lives at AppRootView
/// scope; reset implicitly on cold launch (the `@State` storage starts fresh
/// every time the app process boots) and explicitly when the kid dismisses
/// the closer sheet.
///
/// Per `@Docs/FEATURE_PLAN.md` § Engagement Foundation → "Session targeting:
/// 10-15 minute sessions with gentle ending summary".
///
/// Anti-shame guard: the tally NEVER scolds — zero-tale sittings are valid;
/// the recap copy in ``SessionCloserView.openingLine(for:)`` honors them.
@Observable @MainActor
public final class SessionTallyTracker {
    public private(set) var talesSavedThisSession: Int = 0
    public private(set) var badgesEarnedThisSession: [String] = []

    public init() {}

    public func recordTaleSaved() {
        talesSavedThisSession += 1
    }

    public func recordBadgeEarned(title: String) {
        // De-dup — a single celebration session may re-fire identical badges
        // when the kid trips multiple thresholds in one save. Keep the recap
        // honest: one line per unique badge.
        guard badgesEarnedThisSession.contains(title) == false else { return }
        badgesEarnedThisSession.append(title)
    }

    public func reset() {
        talesSavedThisSession = 0
        badgesEarnedThisSession.removeAll()
    }
}
