import Testing
import Foundation
@testable import Services
import Models

@Suite("RetentionMetricsEvaluator")
struct RetentionMetricsEvaluatorTests {
    private let cal = Calendar(identifier: .gregorian)

    @Test func freshInstallReturnsEmpty() {
        let state = RetentionMetricsEvaluator.RetentionState(installDate: nil)
        let result = RetentionMetricsEvaluator.newlyCrossed(state: state)
        #expect(result.isEmpty)
    }

    @Test func sameDayInstallReturnsEmpty() {
        let now = Date(timeIntervalSince1970: 1_900_000_000)
        let state = RetentionMetricsEvaluator.RetentionState(installDate: now)
        let result = RetentionMetricsEvaluator.newlyCrossed(state: state, now: now, calendar: cal)
        #expect(result.isEmpty)
    }

    @Test func day1ReopenFiresD1Only() {
        let install = Date(timeIntervalSince1970: 1_900_000_000)
        let day1 = install.addingTimeInterval(86_400 + 60) // +1 day + 1 minute
        let state = RetentionMetricsEvaluator.RetentionState(installDate: install)
        let result = RetentionMetricsEvaluator.newlyCrossed(state: state, now: day1, calendar: cal)
        #expect(result == [.d1])
    }

    @Test func day7ReopenFiresD1AndD7WhenD1NotYetRecorded() {
        // Edge case: kid skipped D1 and opens on day 7. Both fire on the
        // same call so the persistence layer records each.
        let install = Date(timeIntervalSince1970: 1_900_000_000)
        let day7 = install.addingTimeInterval(7 * 86_400 + 60)
        let state = RetentionMetricsEvaluator.RetentionState(installDate: install)
        let result = RetentionMetricsEvaluator.newlyCrossed(state: state, now: day7, calendar: cal)
        #expect(result == [.d1, .d7])
    }

    @Test func day30ReopenFiresAllThreeWhenNoneYetRecorded() {
        let install = Date(timeIntervalSince1970: 1_900_000_000)
        let day30 = install.addingTimeInterval(30 * 86_400 + 60)
        let state = RetentionMetricsEvaluator.RetentionState(installDate: install)
        let result = RetentionMetricsEvaluator.newlyCrossed(state: state, now: day30, calendar: cal)
        #expect(result == [.d1, .d7, .d30])
    }

    @Test func alreadyFiredMilestonesDoNotRefire() {
        let install = Date(timeIntervalSince1970: 1_900_000_000)
        let day8 = install.addingTimeInterval(8 * 86_400)
        let state = RetentionMetricsEvaluator.RetentionState(
            installDate: install,
            d1HitAt: install.addingTimeInterval(86_400),
            d7HitAt: install.addingTimeInterval(7 * 86_400)
        )
        let result = RetentionMetricsEvaluator.newlyCrossed(state: state, now: day8, calendar: cal)
        // D1 + D7 already recorded; D30 still in the future.
        #expect(result.isEmpty)
    }

    @Test func futureNowReturnsEmpty() {
        // Clock-skew defensive — install is 5 days ahead of "now".
        let install = Date(timeIntervalSince1970: 1_900_000_000 + 5 * 86_400)
        let now = Date(timeIntervalSince1970: 1_900_000_000)
        let state = RetentionMetricsEvaluator.RetentionState(installDate: install)
        let result = RetentionMetricsEvaluator.newlyCrossed(state: state, now: now, calendar: cal)
        #expect(result.isEmpty)
    }

    @Test func milestoneDayThresholdsMatchSpec() {
        #expect(RetentionMetricsEvaluator.Milestone.d1.dayThreshold == 1)
        #expect(RetentionMetricsEvaluator.Milestone.d7.dayThreshold == 7)
        #expect(RetentionMetricsEvaluator.Milestone.d30.dayThreshold == 30)
        // Iteration order matters — the persistence layer iterates in
        // ascending threshold order so multi-fire calls record D1 → D7 → D30.
        #expect(RetentionMetricsEvaluator.Milestone.allCases == [.d1, .d7, .d30])
    }
}
