import Foundation

/// Delight & Polish "Character personality" — derives the kid's "favorite
/// mood" from their per-mood saved-tale counts so Bramble can offer a
/// warm callback line when today's mood matches the favorite. Per
/// `@Docs/FEATURE_PLAN.md` § Delight & Polish → "Character personality —
/// callbacks to player's favorite moods + recurring prompts".
///
/// Register: Bramble grandmother per `@.claude/rules/distributed-
/// narrative.md` § "Pattern B — hero mascot stays primary". The callback
/// celebrates recurrence without comparing the kid to anyone else and
/// NEVER calls out a NON-favorite mood as "still the funny one?" or
/// similar regret-coded framing.
///
/// Pure-value + `nonisolated` so view code can derive the callback line
/// without crossing an actor boundary. Returns `nil` when no mood has
/// crossed the 3-tale floor — matching the ``MoodRetrospective`` floor
/// for register cohesion + ensuring the callback only fires when there's
/// genuine recurrence to celebrate.
///
/// **Anti-shame contract** (locked by unit tests):
/// - ``favoriteMood(funny:scary:tender:wild:)`` returns `nil` when no
///   mood reaches 3 tales. Brand-new kids never see the callback.
/// - ``callback(favoriteMood:todayMood:)`` returns `nil` when
///   `todayMood != favoriteMood`. The callback never points OUT a non-
///   favorite mood — silence is the canonical no-op.
/// - The copy never names the count, never compares moods, never frames
///   non-favorites as deficient.
nonisolated public enum BrambleMoodMemory: Sendable, Hashable {
    /// Minimum saved-tale count for a mood to qualify as a favorite.
    /// Matches the ``MoodRetrospective`` floor so the two surfaces share
    /// the same "have we earned a moment of looking back?" threshold.
    public static let favoriteFloor: Int = 3

    /// Derive the kid's favorite mood from the per-mood saved-tale
    /// counts. Tiebreaker is the canonical mood declaration order
    /// (funny → scary → tender → wild) so the result is deterministic
    /// across launches. Returns `nil` when no mood reaches the floor —
    /// the callback simply doesn't fire.
    public static func favoriteMood(
        funny: Int,
        scary: Int,
        tender: Int,
        wild: Int
    ) -> VoiceTaleMood? {
        let pairs: [(VoiceTaleMood, Int)] = [
            (.funny, funny),
            (.scary, scary),
            (.tender, tender),
            (.wild, wild),
        ]
        let qualifying = pairs.filter { $0.1 >= favoriteFloor }
        guard let topCount = qualifying.map(\.1).max() else { return nil }
        // First-declared-wins tiebreaker — `first(where:)` walks in the
        // canonical mood order.
        return qualifying.first(where: { $0.1 == topCount })?.0
    }

    /// Build the one-line Bramble-register callback to surface alongside
    /// today's reflection. Returns `nil` when today's mood doesn't match
    /// the favorite OR when no favorite has been earned — silence is the
    /// canonical no-op per the anti-shame contract above. Never names a
    /// non-favorite, never compares moods, never names the count.
    public static func callback(
        favoriteMood: VoiceTaleMood?,
        todayMood: VoiceTaleMood
    ) -> String? {
        guard let favorite = favoriteMood, favorite == todayMood else {
            return nil
        }
        switch favorite {
        case .funny:
            return "Your funny voice — I was hoping you'd come back to it."
        case .scary:
            return "Your scary voice — that one really pulls me in."
        case .tender:
            return "Your tender voice — that one I keep close."
        case .wild:
            return "Your wild voice — I love hearing it."
        }
    }
}
