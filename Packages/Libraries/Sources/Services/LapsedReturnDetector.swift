import Foundation
import Models

/// Engagement-Foundation pure-function helper. Computes whether the kid
/// has been gone long enough to warrant the welcome-back flow.
///
/// Per `@Docs/FEATURE_PLAN.md` § Phase: Onboarding & Child Safety §
/// "Return loop — Welcome-back flow for 3+ day lapsed users". The
/// detector is the seam between `PersistentPlayerProgress.lastActiveDate`
/// and the `WelcomeBackView` overlay surface. Pure value type so the
/// threshold logic is unit-testable without a `ModelContext`.
public enum LapsedReturnDetector {
    /// Canonical lapsed-return threshold. 3 days mirrors the
    /// `Docs/FEATURE_PLAN.md` § "3+ day lapsed users" framing — short
    /// enough that the warm greeting catches genuine drift, long enough
    /// that everyday users don't see the surface every session.
    public static let lapsedDayThreshold: Int = 3

    /// Number of WHOLE calendar days between `lastActive` and `now`.
    /// Returns `nil` when `lastActive` is missing (fresh install — the
    /// welcome-back flow shouldn't fire for a kid's first session) or
    /// when `lastActive` is in the future (clock skew defensive case).
    public static func daysLapsed(
        lastActive: Date?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int? {
        guard let lastActive else { return nil }
        let startOfNow = calendar.startOfDay(for: now)
        let startOfLast = calendar.startOfDay(for: lastActive)
        guard startOfLast <= startOfNow else { return nil }
        let components = calendar.dateComponents([.day], from: startOfLast, to: startOfNow)
        return components.day
    }

    /// Convenience: is the kid lapsed enough to warrant the welcome-back
    /// surface? `false` for fresh installs (`lastActive == nil`) and
    /// same-day reopens.
    public static func shouldSurfaceWelcomeBack(
        lastActive: Date?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard let days = daysLapsed(lastActive: lastActive, now: now, calendar: calendar) else {
            return false
        }
        return days >= lapsedDayThreshold
    }
}
