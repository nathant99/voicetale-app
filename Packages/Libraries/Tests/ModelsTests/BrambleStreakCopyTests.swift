import Testing
import Foundation
@testable import Models

@Suite("BrambleStreakCopy")
struct BrambleStreakCopyTests {
    @Test func continuingVariantSurfacesEncouragingHeadline() {
        let copy = BrambleStreakCopy.continuing(streak: 2)
        #expect(copy.headline == "Two days running.")
        #expect(copy.body.isEmpty == false)
        #expect(copy.trailingCTA != nil)
        #expect(copy.isQuiet == false)
    }

    @Test func continuingMilestonesHaveDedicatedHeadlines() {
        let one = BrambleStreakCopy.continuing(streak: 1).headline
        let seven = BrambleStreakCopy.continuing(streak: 7).headline
        let thirty = BrambleStreakCopy.continuing(streak: 30).headline
        #expect(one == "First spark of a streak.")
        #expect(seven == "A full week of tales.")
        #expect(thirty == "A month of warm fires.")
    }

    @Test func resetVariantIsWarmAndQuiet() {
        let copy = BrambleStreakCopy.reset(previousStreak: 6)
        // The reset copy MUST stay warm — no shame tokens allowed. This
        // test asserts the negative space + the relational framing.
        let shameTokens = ["broke", "fail", "lost", "lazy", "missed", "should"]
        for token in shameTokens {
            #expect(copy.headline.localizedCaseInsensitiveContains(token) == false,
                    "Reset headline contains shame token: \(token)")
            #expect(copy.body.localizedCaseInsensitiveContains(token) == false,
                    "Reset body contains shame token: \(token)")
        }
        #expect(copy.isQuiet)
    }

    @Test func resetFromZeroSurfacesFreshStartCopy() {
        let copy = BrambleStreakCopy.reset(previousStreak: 0)
        #expect(copy.headline == "A fresh start.")
    }

    @Test func frozenSurfacesRemainingFreezeCount() {
        let copy = BrambleStreakCopy.frozen(streak: 5, freezesRemaining: 1)
        #expect(copy.headline.contains("5"))
        #expect(copy.body.contains("one mercy day"))
    }

    @Test func frozenZeroFreezesRemainingTellsTomorrowIsFresh() {
        let copy = BrambleStreakCopy.frozen(streak: 7, freezesRemaining: 0)
        #expect(copy.body.contains("last mercy day"))
    }

    @Test func heldUnderDistressVariantIsQuietWithNoCTA() {
        let copy = BrambleStreakCopy.heldUnderDistress(streak: 4)
        #expect(copy.isQuiet)
        #expect(copy.trailingCTA == nil)
    }

    @Test func sameDayVariantDoesNotEscalate() {
        let copy = BrambleStreakCopy.sameDay(streak: 3)
        #expect(copy.headline == "Today is still today.")
        #expect(copy.isQuiet == false)
        #expect(copy.trailingCTA != nil)
    }

    @Test func codableRoundTrips() throws {
        let originals: [BrambleStreakCopy] = [
            .continuing(streak: 4),
            .frozen(streak: 6, freezesRemaining: 1),
            .reset(previousStreak: 5),
            .sameDay(streak: 2),
            .heldUnderDistress(streak: 3),
        ]
        for original in originals {
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(BrambleStreakCopy.self, from: encoded)
            #expect(decoded == original)
        }
    }
}
