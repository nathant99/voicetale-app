import Foundation
import Models

/// Engagement-Foundation pure-function helper. Computes which retention
/// milestone (D1 / D7 / D30) the kid just crossed, based on the install
/// anchor + the current `now` + which milestones have already fired.
///
/// Per `@Docs/FEATURE_PLAN.md` § Phase: Onboarding & Child Safety →
/// "Retention metrics baseline — D1 / D7 / D30 (on-device, privacy-first)".
/// Pure value type so the threshold logic is unit-testable without a
/// `ModelContext` and so the analytics emission can be tested in isolation.
///
/// **Privacy posture**: every milestone is categorical-only on the wire.
/// The analytics emission carries the milestone name (`d1` / `d7` / `d30`);
/// it never carries the raw `installDate`, the raw `now`, or any duration
/// in seconds — the install-anchor stays on-device.
public enum RetentionMetricsEvaluator {
    /// Canonical retention milestones VoiceTale tracks. Listed in
    /// ascending day-threshold order so callers can `for-in` iterate
    /// without re-deriving the order.
    public enum Milestone: String, Sendable, CaseIterable, Hashable {
        case d1
        case d7
        case d30

        /// Whole-day threshold the kid must reach (≥) for the milestone
        /// to fire. D1 is the day-after-install re-open; D7 is the
        /// week-anniversary re-open; D30 is the month-anniversary.
        public var dayThreshold: Int {
            switch self {
            case .d1:  return 1
            case .d7:  return 7
            case .d30: return 30
            }
        }
    }

    /// Snapshot of the milestone state on the persistent row. Pure value
    /// type so `evaluate(...)` can be tested without a `ModelContext`.
    public struct RetentionState: Sendable, Equatable {
        public let installDate: Date?
        public let d1HitAt: Date?
        public let d7HitAt: Date?
        public let d30HitAt: Date?

        public init(
            installDate: Date?,
            d1HitAt: Date? = nil,
            d7HitAt: Date? = nil,
            d30HitAt: Date? = nil
        ) {
            self.installDate = installDate
            self.d1HitAt = d1HitAt
            self.d7HitAt = d7HitAt
            self.d30HitAt = d30HitAt
        }

        public func hasFired(_ milestone: Milestone) -> Bool {
            switch milestone {
            case .d1:  return d1HitAt != nil
            case .d7:  return d7HitAt != nil
            case .d30: return d30HitAt != nil
            }
        }
    }

    /// Returns every milestone the kid crossed on the current cold-launch
    /// that hasn't already fired. Returns an empty array for fresh
    /// installs (no `installDate`), for same-day re-opens before D1, and
    /// for cases where every milestone has already been recorded.
    ///
    /// Why a list (not a single Optional): in rare cases — a kid who's
    /// been gone for 30+ days — a single launch can cross D1, D7, AND
    /// D30 at once. The persistence layer records each in the same call.
    public static func newlyCrossed(
        state: RetentionState,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [Milestone] {
        guard let installDate = state.installDate else { return [] }
        let startOfNow = calendar.startOfDay(for: now)
        let startOfInstall = calendar.startOfDay(for: installDate)
        guard startOfInstall <= startOfNow else { return [] }
        guard let elapsedDays = calendar.dateComponents(
            [.day], from: startOfInstall, to: startOfNow
        ).day else {
            return []
        }
        return Milestone.allCases.compactMap { milestone in
            guard elapsedDays >= milestone.dayThreshold else { return nil }
            guard state.hasFired(milestone) == false else { return nil }
            return milestone
        }
    }
}
