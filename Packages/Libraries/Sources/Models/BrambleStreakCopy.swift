import Foundation

/// Phase 2 streak polish — kid-readable warm Bramble copy for each
/// ``ForgeGamification.StreakManager.StreakResult`` outcome. Per
/// `@.claude/rules/distributed-narrative.md` § "Pattern B — hero mascot
/// stays primary": Bramble holds the relational register on every streak
/// transition, including breaks. Per
/// `@.claude/rules/trauma-informed-content.md` § "Validate, then inform",
/// the reset variant NEVER shames the kid for breaking — it names the
/// pause + invites the next telling.
///
/// The enum is pure-value + `nonisolated` so view code can pattern-match
/// without crossing an actor boundary. Views render the headline + body
/// directly + optionally surface the trailing CTA copy.
nonisolated public enum BrambleStreakCopy: Sendable, Hashable, Codable {
    case continuing(streak: Int)
    case frozen(streak: Int, freezesRemaining: Int)
    case reset(previousStreak: Int)
    case sameDay(streak: Int)
    case heldUnderDistress(streak: Int)

    public var headline: String {
        switch self {
        case .continuing(let streak):
            switch streak {
            case 1:  return "First spark of a streak."
            case 2:  return "Two days running."
            case 3:  return "Three nights at the fire."
            case 7:  return "A full week of tales."
            case 14: return "Two weeks of telling."
            case 30: return "A month of warm fires."
            default: return "\(streak) days running."
            }
        case .frozen(let streak, _):
            return "Streak held by a freeze — still at \(streak)."
        case .reset(let previousStreak):
            if previousStreak == 0 {
                return "A fresh start."
            }
            return "Bramble held your seat by the fire."
        case .sameDay(let streak):
            return "Today is still today."
        case .heldUnderDistress(let streak):
            return "Bramble noticed today was heavy. Streak stays at \(streak)."
        }
    }

    public var body: String {
        switch self {
        case .continuing:
            return "Another night at the fire. The room is leaning closer."
        case .frozen(_, let freezesRemaining):
            switch freezesRemaining {
            case 0:  return "Your last mercy day caught the gap. Tomorrow's telling is fresh."
            case 1:  return "Mercy day used — one mercy day left for the week."
            default: return "Mercy day used — \(freezesRemaining) mercy days left for the week."
            }
        case .reset(let previousStreak):
            if previousStreak == 0 {
                return "Welcome back. The first tale begins your streak today."
            }
            return "A pause is just a pause. Bramble's still listening. Today's telling begins a new run."
        case .sameDay:
            return "You're already counted. Tell another if you'd like; today's tally won't change."
        case .heldUnderDistress:
            return "Some nights are for resting. The streak holds; nothing is asked of you tomorrow that isn't kind."
        }
    }

    public var trailingCTA: String? {
        switch self {
        case .continuing, .frozen, .reset:
            return "Tell tonight's tale?"
        case .sameDay:
            return "Tell another if the room asks?"
        case .heldUnderDistress:
            return nil
        }
    }

    /// Returns true for transitions whose visual treatment should be
    /// warm + non-celebratory. The reset + held-under-distress variants
    /// stay quiet (no confetti, no chime); the continuing + freeze
    /// variants can carry a small celebration.
    public var isQuiet: Bool {
        switch self {
        case .reset, .heldUnderDistress:
            return true
        case .continuing, .frozen, .sameDay:
            return false
        }
    }
}
