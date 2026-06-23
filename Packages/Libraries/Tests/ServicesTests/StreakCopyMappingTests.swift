import Testing
import Foundation
@testable import Services
import Models
import ForgeGamification

@Suite("GamificationService.streakCopy mapping")
struct StreakCopyMappingTests {
    @Test func continuedMapsToContinuing() {
        let copy = GamificationService.streakCopy(for: .continued(streak: 4))
        if case .continuing(let s) = copy {
            #expect(s == 4)
        } else {
            Issue.record("Expected .continuing, got \(copy)")
        }
    }

    @Test func frozenMapsToFrozen() {
        let copy = GamificationService.streakCopy(for: .frozenAndContinued(streak: 6, freezesRemaining: 1))
        if case .frozen(let streak, let remaining) = copy {
            #expect(streak == 6)
            #expect(remaining == 1)
        } else {
            Issue.record("Expected .frozen, got \(copy)")
        }
    }

    @Test func resetMapsToReset() {
        let copy = GamificationService.streakCopy(for: .reset(previousStreak: 9))
        if case .reset(let prev) = copy {
            #expect(prev == 9)
        } else {
            Issue.record("Expected .reset, got \(copy)")
        }
    }

    @Test func sameDayMapsToSameDay() {
        let copy = GamificationService.streakCopy(for: .sameDay(streak: 3))
        if case .sameDay(let s) = copy {
            #expect(s == 3)
        } else {
            Issue.record("Expected .sameDay, got \(copy)")
        }
    }

    @Test func heldUnderDistressMapsToHeldUnderDistress() {
        let copy = GamificationService.streakCopy(for: .heldUnderDistress(streak: 2))
        if case .heldUnderDistress(let s) = copy {
            #expect(s == 2)
        } else {
            Issue.record("Expected .heldUnderDistress, got \(copy)")
        }
    }
}
