import Testing
import Foundation
@testable import AIMentor
@testable import Models

@Suite("BrambleFavoriteMoodCallback")
struct BrambleFavoriteMoodCallbackTests {
    private static let baseReflection = VoiceStoryReflection(
        craftObservations: ["I heard a pause before the close."],
        socraticPrompt: "What was that pause holding?"
    )

    @Test func prependsCallbackWhenMoodMatchesFavorite() {
        let result = BrambleMentor.applyFavoriteMoodCallback(
            Self.baseReflection,
            favoriteMood: .funny,
            todayMood: .funny
        )
        // The original observation is preserved AND prefixed.
        let first = try? #require(result.craftObservations.first)
        let firstObservation = result.craftObservations.first ?? ""
        #expect(firstObservation.hasSuffix("I heard a pause before the close."))
        #expect(firstObservation != "I heard a pause before the close.",
                "expected the callback line to land before the original observation")
        _ = first
    }

    @Test func leavesReflectionUnchangedWhenNoFavorite() {
        let result = BrambleMentor.applyFavoriteMoodCallback(
            Self.baseReflection,
            favoriteMood: nil,
            todayMood: .funny
        )
        #expect(result == Self.baseReflection)
    }

    @Test func leavesReflectionUnchangedWhenTodayDoesntMatch() {
        // Anti-shame contract: favorite=scary but today=funny → no
        // callback is layered in. The original reflection comes through
        // untouched.
        let result = BrambleMentor.applyFavoriteMoodCallback(
            Self.baseReflection,
            favoriteMood: .scary,
            todayMood: .funny
        )
        #expect(result == Self.baseReflection)
    }

    @Test func socraticPromptIsNeverMutated() {
        let result = BrambleMentor.applyFavoriteMoodCallback(
            Self.baseReflection,
            favoriteMood: .tender,
            todayMood: .tender
        )
        // Even on the matching path, the Socratic follow-up keeps the
        // original phrasing — Bramble's question doesn't get rewritten
        // by the callback layer.
        #expect(result.socraticPrompt == Self.baseReflection.socraticPrompt)
    }

    @Test func handlesEmptyObservationsByPrependingCallback() {
        let bare = VoiceStoryReflection(
            craftObservations: [],
            socraticPrompt: "What did you notice?"
        )
        let result = BrambleMentor.applyFavoriteMoodCallback(
            bare,
            favoriteMood: .wild,
            todayMood: .wild
        )
        // The callback inserts as the first observation so the surface
        // doesn't render an empty bubble.
        #expect(result.craftObservations.count == 1)
        let firstObservation = result.craftObservations.first ?? ""
        #expect(!firstObservation.isEmpty)
        #expect(firstObservation.lowercased().contains("wild"))
    }

    @Test func callbackOutputPassesAntiShameGuard() {
        // The same anti-shame guard from BrambleMoodMemoryTests carries
        // through the mentor surface — if a shame token slips into the
        // callback copy at the BramblePromptBuilder layer, this test
        // fails at the BrambleMentor surface too.
        let shameTokens = ["finally", "still", "always", "should", "missed"]
        for mood in VoiceTaleMood.allCases {
            let result = BrambleMentor.applyFavoriteMoodCallback(
                Self.baseReflection,
                favoriteMood: mood,
                todayMood: mood
            )
            let composed = (result.craftObservations.first ?? "").lowercased()
            for token in shameTokens {
                #expect(!composed.contains(token),
                "mentor-applied callback for \(mood) contains shame token '\(token)': \(composed)")
            }
        }
    }
}
