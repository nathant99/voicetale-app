import Testing
import Foundation
@testable import Services

@Suite("DifficultyController")
struct DifficultyControllerTests {
    @Test func zeroTalesIsGentleTier() {
        #expect(DifficultyController.tier(forTalesCount: 0) == .gentle)
    }

    @Test func threeTalesStillGentle() {
        #expect(DifficultyController.tier(forTalesCount: 3) == .gentle)
    }

    @Test func fourTalesIsStandard() {
        #expect(DifficultyController.tier(forTalesCount: 4) == .standard)
    }

    @Test func twelveTalesStillStandard() {
        #expect(DifficultyController.tier(forTalesCount: 12) == .standard)
    }

    @Test func thirteenTalesIsDeep() {
        #expect(DifficultyController.tier(forTalesCount: 13) == .deep)
    }

    @Test func largeCountStaysDeep() {
        #expect(DifficultyController.tier(forTalesCount: 250) == .deep)
    }

    @Test func tierThresholdsAreSorted() {
        // Sanity-check that the constants relate correctly — a future
        // reordering would surface here before a kid lands in an
        // inverted tier.
        #expect(DifficultyController.gentleToStandardThreshold
                < DifficultyController.standardToDeepThreshold)
    }

    @Test func everyTierHasACanonicalCase() {
        let allTiers = Set(DifficultyController.DifficultyTier.allCases)
        #expect(allTiers == [.gentle, .standard, .deep])
    }
}
