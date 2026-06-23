import Foundation

/// Delight & Polish "Share-worthy moments" — kid-readable per-mood
/// retrospective phrase surfaced in ``AnthologyView`` when the kid has
/// saved at least 3 tales of a given mood AND is currently filtering to
/// that mood. Per `@Docs/FEATURE_PLAN.md` § Delight & Polish →
/// "Share-worthy moments — mood-tag retrospectives".
///
/// Register: Bramble grandmother per `@.claude/rules/distributed-
/// narrative.md` § "Pattern B — hero mascot stays primary". The copy
/// celebrates breadth + recurrence without comparing the kid to anyone
/// else — anti-shame baseline matches the rest of the Bramble surface
/// (e.g., ``BrambleStreakCopy``).
///
/// Pure-value + `nonisolated` so view code can render the headline +
/// body without crossing an actor boundary. Returns `nil` below the
/// 3-tale floor — the retrospective only fires when there's actually
/// something to look back on.
nonisolated public enum MoodRetrospective: Sendable, Hashable {
    /// Bucket the count into one of three tiers. Each tier reads
    /// differently so the retrospective gains weight as the count
    /// climbs. Returns `nil` below the 3-tale floor.
    public enum Tier: String, Sendable, Hashable, Codable {
        /// 3-9 tales of this mood. The shape is starting to repeat.
        case threeToNine = "three_to_nine"
        /// 10-24 tales of this mood. Recurrence has weight now.
        case tenToTwentyFour = "ten_to_twentyfour"
        /// 25+ tales of this mood. The voice has a rhythm.
        case twentyFivePlus = "twentyfive_plus"
    }

    /// Map a raw count of saved tales for a given mood into its tier.
    /// Returns `nil` below 3 — no retrospective surfaces until there
    /// are at least 3 tales of the same mood to reflect on.
    public static func tier(for count: Int) -> Tier? {
        switch count {
        case 3..<10:    return .threeToNine
        case 10..<25:   return .tenToTwentyFour
        case 25...:     return .twentyFivePlus
        default:        return nil
        }
    }

    /// One-line headline that reads above the body. Mood-specific so
    /// the copy honors what kind of voice the kid has been finding.
    /// Pure function — testable without a SwiftUI host.
    public static func headline(mood: VoiceTaleMood, count: Int) -> String? {
        guard let tier = tier(for: count) else { return nil }
        switch (mood, tier) {
        case (.funny, .threeToNine):       return "Your funny voice is finding its rhythm."
        case (.funny, .tenToTwentyFour):   return "Funny is a register you've made your own."
        case (.funny, .twentyFivePlus):    return "Your room knows how you land a laugh."
        case (.scary, .threeToNine):       return "Your scary voice is learning the dark."
        case (.scary, .tenToTwentyFour):   return "Scary tales sit comfortably with you now."
        case (.scary, .twentyFivePlus):    return "The dark is a room you can hold."
        case (.tender, .threeToNine):      return "Your tender voice is finding the small things."
        case (.tender, .tenToTwentyFour):  return "Tender tales are part of your shape."
        case (.tender, .twentyFivePlus):   return "Tenderness is a craft you carry."
        case (.wild, .threeToNine):        return "Your wild voice is stretching its lungs."
        case (.wild, .tenToTwentyFour):    return "Wild tales sit in your bones now."
        case (.wild, .twentyFivePlus):     return "The wild is yours to summon."
        }
    }

    /// Body copy under the headline — kid-readable, anti-shame, no
    /// comparison to peers or to past selves' "worse" runs. The body
    /// names the recurrence + invites the next telling.
    public static func body(mood: VoiceTaleMood, count: Int) -> String? {
        guard let tier = tier(for: count) else { return nil }
        let moodLabel = mood.displayLabel.lowercased()
        switch tier {
        case .threeToNine:
            return "\(count) \(moodLabel) tales now. The shape is starting to repeat — and a shape that repeats is yours."
        case .tenToTwentyFour:
            return "\(count) \(moodLabel) tales told. The room knows what to expect when you choose this mood — and it leans in anyway."
        case .twentyFivePlus:
            return "\(count) \(moodLabel) tales. Your \(moodLabel) voice has weight now — the kind that other tellers recognize."
        }
    }
}
