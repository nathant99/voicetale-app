import Testing
import Foundation
@testable import Models

@Suite("MoodRetrospective")
struct MoodRetrospectiveTests {
    // MARK: - Tier mapping

    @Test func belowThreeTalesReturnsNoTier() {
        #expect(MoodRetrospective.tier(for: 0) == nil)
        #expect(MoodRetrospective.tier(for: 1) == nil)
        #expect(MoodRetrospective.tier(for: 2) == nil)
    }

    @Test func threeThroughNineMapsToFirstTier() {
        #expect(MoodRetrospective.tier(for: 3) == .threeToNine)
        #expect(MoodRetrospective.tier(for: 9) == .threeToNine)
    }

    @Test func tenThroughTwentyFourMapsToSecondTier() {
        #expect(MoodRetrospective.tier(for: 10) == .tenToTwentyFour)
        #expect(MoodRetrospective.tier(for: 24) == .tenToTwentyFour)
    }

    @Test func twentyFiveAndAboveMapsToThirdTier() {
        #expect(MoodRetrospective.tier(for: 25) == .twentyFivePlus)
        #expect(MoodRetrospective.tier(for: 100) == .twentyFivePlus)
    }

    // MARK: - Copy presence (every mood × every above-floor tier)

    @Test func everyModeAtEveryAboveFloorTierHasHeadlineAndBody() {
        let countsByTier: [Int] = [3, 10, 25]
        for mood in VoiceTaleMood.allCases {
            for count in countsByTier {
                let headline = MoodRetrospective.headline(mood: mood, count: count)
                let body = MoodRetrospective.body(mood: mood, count: count)
                #expect(headline != nil, "missing headline for \(mood) × \(count)")
                #expect(body != nil, "missing body for \(mood) × \(count)")
                #expect(headline?.isEmpty == false)
                #expect(body?.isEmpty == false)
            }
        }
    }

    @Test func belowFloorReturnsNilForBothHeadlineAndBody() {
        let headline = MoodRetrospective.headline(mood: .funny, count: 2)
        let body = MoodRetrospective.body(mood: .funny, count: 2)
        #expect(headline == nil)
        #expect(body == nil)
    }

    // MARK: - Anti-shame guard

    /// The retrospective must NEVER contain shame-coded tokens. Same
    /// anti-shame discipline as the rest of the Bramble surface per
    /// `@.claude/rules/trauma-informed-content.md`.
    @Test func everyMoodAtEveryTierAvoidsShameCodedTokens() {
        let shameTokens = ["only", "just", "barely", "finally", "took you", "at last", "should have", "could have"]
        let countsByTier: [Int] = [5, 15, 30]
        for mood in VoiceTaleMood.allCases {
            for count in countsByTier {
                let combined = ((MoodRetrospective.headline(mood: mood, count: count) ?? "")
                                + " "
                                + (MoodRetrospective.body(mood: mood, count: count) ?? ""))
                    .lowercased()
                for token in shameTokens {
                    #expect(!combined.contains(token),
                            "shame token \"\(token)\" surfaced for \(mood) × \(count): \(combined)")
                }
            }
        }
    }

    // MARK: - Count interpolation

    @Test func bodyInterpolatesActualCountForSecondAndThirdTier() {
        let body10 = MoodRetrospective.body(mood: .tender, count: 10)
        let body42 = MoodRetrospective.body(mood: .tender, count: 42)
        #expect(body10?.contains("10") == true)
        #expect(body42?.contains("42") == true)
    }
}
