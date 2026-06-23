import Testing
import Foundation
@testable import Models

@Suite("BrambleMoodMemory")
struct BrambleMoodMemoryTests {
    // MARK: - Favorite-mood derivation

    @Test func brandNewKidHasNoFavorite() {
        // Below the 3-tale floor on every mood — no favorite earned.
        #expect(BrambleMoodMemory.favoriteMood(
            funny: 0, scary: 0, tender: 0, wild: 0
        ) == nil)
        #expect(BrambleMoodMemory.favoriteMood(
            funny: 2, scary: 1, tender: 0, wild: 0
        ) == nil)
    }

    @Test func reachingFloorYieldsFavorite() {
        // Exactly 3 tales in one mood — earns the callback floor.
        #expect(BrambleMoodMemory.favoriteMood(
            funny: 3, scary: 0, tender: 0, wild: 0
        ) == .funny)
    }

    @Test func highestQualifyingCountWins() {
        // 10 tender tales beat 4 funny tales (both above the floor).
        #expect(BrambleMoodMemory.favoriteMood(
            funny: 4, scary: 0, tender: 10, wild: 0
        ) == .tender)
    }

    @Test func canonicalOrderBreaksTies() {
        // funny + scary both at 5 — canonical declaration order wins.
        #expect(BrambleMoodMemory.favoriteMood(
            funny: 5, scary: 5, tender: 0, wild: 0
        ) == .funny)
        // tender + wild both at 5 — same tiebreaker; tender (earlier in
        // declaration order) wins.
        #expect(BrambleMoodMemory.favoriteMood(
            funny: 0, scary: 0, tender: 5, wild: 5
        ) == .tender)
    }

    @Test func favoriteIgnoresBelowFloorCounts() {
        // The wild count is highest (12) but funny (5) ALSO qualifies.
        // The wild mood STILL wins because it has the higher count.
        #expect(BrambleMoodMemory.favoriteMood(
            funny: 5, scary: 0, tender: 2, wild: 12
        ) == .wild)
    }

    // MARK: - Callback contract

    @Test func callbackFiresWhenTodayMatchesFavorite() {
        for mood in VoiceTaleMood.allCases {
            let callback = BrambleMoodMemory.callback(
                favoriteMood: mood,
                todayMood: mood
            )
            // Every mood has copy; never nil when matching.
            #expect(callback != nil, "callback for \(mood) should not be nil")
            #expect(!(callback ?? "").isEmpty)
        }
    }

    @Test func callbackSilentWhenNoFavorite() {
        for mood in VoiceTaleMood.allCases {
            #expect(BrambleMoodMemory.callback(
                favoriteMood: nil,
                todayMood: mood
            ) == nil)
        }
    }

    @Test func callbackSilentOnNonMatchingMood() {
        // Anti-shame contract: callback NEVER names a non-favorite mood.
        // Today's mood = funny, favorite = scary → silent.
        let nonMatchingPairs: [(VoiceTaleMood, VoiceTaleMood)] = [
            (.scary, .funny),
            (.tender, .funny),
            (.wild, .funny),
            (.funny, .scary),
            (.tender, .scary),
            (.funny, .tender),
            (.wild, .tender),
            (.funny, .wild),
            (.scary, .wild),
        ]
        for (favorite, today) in nonMatchingPairs {
            #expect(BrambleMoodMemory.callback(
                favoriteMood: favorite,
                todayMood: today
            ) == nil,
            "callback should be nil when today=\(today) ≠ favorite=\(favorite)")
        }
    }

    // MARK: - Copy anti-shame guard

    @Test func everyCallbackAvoidsShameTokens() {
        // Per `@.claude/rules/trauma-informed-content.md` § "Validate-then-
        // inform" + the existing MoodRetrospective / BrambleStreakCopy
        // discipline. Tokens that imply judgment / regret / comparison
        // never appear in the favorite-mood callback.
        let shameTokens = [
            "finally", "again", "still", "always",
            "missed", "skipped", "lazy", "supposed to",
            "should", "better than", "worse than", "instead of",
        ]
        for mood in VoiceTaleMood.allCases {
            let callback = BrambleMoodMemory.callback(
                favoriteMood: mood,
                todayMood: mood
            ) ?? ""
            let lowered = callback.lowercased()
            for token in shameTokens {
                #expect(!lowered.contains(token),
                "callback for \(mood) contains shame token '\(token)': \(callback)")
            }
        }
    }

    @Test func everyCallbackNamesTheRegisterButNotTheCount() {
        // The copy should reference the kid's voice register (funny/scary/
        // tender/wild) but NEVER name a count number — counts belong in
        // MoodRetrospective, callbacks belong to memory + recognition.
        let countTokens = ["3", "5", "10", "25", "tales", "times"]
        for mood in VoiceTaleMood.allCases {
            let callback = BrambleMoodMemory.callback(
                favoriteMood: mood,
                todayMood: mood
            ) ?? ""
            let lowered = callback.lowercased()
            #expect(lowered.contains(mood.displayLabel.lowercased()),
            "callback for \(mood) should name the register but reads: \(callback)")
            for token in countTokens {
                #expect(!lowered.contains(token),
                "callback for \(mood) contains count token '\(token)': \(callback)")
            }
        }
    }
}
