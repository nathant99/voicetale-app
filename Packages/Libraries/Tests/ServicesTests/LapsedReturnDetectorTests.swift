import Testing
import Foundation
@testable import Services
import Models

@Suite("LapsedReturnDetector")
struct LapsedReturnDetectorTests {
    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.timeZone = TimeZone(identifier: "UTC")
        return calendar().date(from: components)!
    }

    @Test func freshInstallReturnsNil() {
        // A nil lastActive means the kid has never opened the app — the
        // welcome-back surface should NOT fire on the first session.
        #expect(LapsedReturnDetector.daysLapsed(lastActive: nil) == nil)
        #expect(LapsedReturnDetector.shouldSurfaceWelcomeBack(lastActive: nil) == false)
    }

    @Test func sameDayGapIsZeroDays() {
        let now = date(year: 2026, month: 6, day: 22)
        let last = date(year: 2026, month: 6, day: 22)
        let days = LapsedReturnDetector.daysLapsed(lastActive: last, now: now, calendar: calendar())
        #expect(days == 0)
        #expect(LapsedReturnDetector.shouldSurfaceWelcomeBack(
            lastActive: last,
            now: now,
            calendar: calendar()
        ) == false)
    }

    @Test func twoDayGapDoesNotTrigger() {
        let now = date(year: 2026, month: 6, day: 22)
        let last = date(year: 2026, month: 6, day: 20)
        let days = LapsedReturnDetector.daysLapsed(lastActive: last, now: now, calendar: calendar())
        #expect(days == 2)
        #expect(LapsedReturnDetector.shouldSurfaceWelcomeBack(
            lastActive: last,
            now: now,
            calendar: calendar()
        ) == false)
    }

    @Test func threeDayGapTriggers() {
        let now = date(year: 2026, month: 6, day: 22)
        let last = date(year: 2026, month: 6, day: 19)
        let days = LapsedReturnDetector.daysLapsed(lastActive: last, now: now, calendar: calendar())
        #expect(days == 3)
        #expect(LapsedReturnDetector.shouldSurfaceWelcomeBack(
            lastActive: last,
            now: now,
            calendar: calendar()
        ))
    }

    @Test func futureLastActiveReturnsNil() {
        // Defensive clock-skew case — a lastActive in the future suggests
        // a clock change or restore-from-backup; we don't want to fire
        // the welcome-back surface in that case.
        let now = date(year: 2026, month: 6, day: 22)
        let future = date(year: 2026, month: 6, day: 25)
        #expect(LapsedReturnDetector.daysLapsed(
            lastActive: future,
            now: now,
            calendar: calendar()
        ) == nil)
    }

    @Test func longLapseTriggers() {
        let now = date(year: 2026, month: 6, day: 22)
        let last = date(year: 2026, month: 1, day: 1)
        let days = LapsedReturnDetector.daysLapsed(
            lastActive: last,
            now: now,
            calendar: calendar()
        )
        #expect(days != nil)
        #expect(days! >= 100)
        #expect(LapsedReturnDetector.shouldSurfaceWelcomeBack(
            lastActive: last,
            now: now,
            calendar: calendar()
        ))
    }
}
