import Foundation

/// Phase 2 Tale Trial mode — bundled fast-fire prompt catalog. Each prompt is
/// a single sentence designed for a 60-second tell with NO 5-beat scaffolding;
/// the kid's task is to land an opener + a turn + a close in 60s flat, then
/// hand the tale to Bramble for blind-judging reflection.
///
/// Prompts are categorical (stable `slug` for analytics + per-prompt rotation)
/// + kid-readable (Magic Tree House / Wimpy Kid register per
/// `@.claude/rules/distributed-narrative.md` § "Audience register").
nonisolated public struct TaleTrialPrompt: Sendable, Hashable, Identifiable, Codable {
    public let slug: String
    public let text: String

    public var id: String { slug }

    public init(slug: String, text: String) {
        self.slug = slug
        self.text = text
    }
}

nonisolated public enum TaleTrialPromptCatalog {
    /// Phase 2 bundled prompts. 8 entries gives ~7-day variety with a
    /// shuffle that never lands the same prompt twice in a row (the
    /// machine enforces the last-slug guard). Cast names + tradition
    /// references stay OUT of trial prompts — trial is intentionally a
    /// scaffolding-free surface so the kid plays with shape, not lore.
    public static let phase2: [TaleTrialPrompt] = [
        TaleTrialPrompt(
            slug: "hungry_clock",
            text: "Tell us about a time you got SO hungry you noticed every clock."
        ),
        TaleTrialPrompt(
            slug: "new_color",
            text: "Pretend you've just discovered a color nobody else can see. What's the first thing you paint with it?"
        ),
        TaleTrialPrompt(
            slug: "lost_thing_speaks",
            text: "The lost thing you've been looking for has finally found its voice. What's it say?"
        ),
        TaleTrialPrompt(
            slug: "door_in_floor",
            text: "There's a door in your floor that wasn't there yesterday. You open it. Now what?"
        ),
        TaleTrialPrompt(
            slug: "small_brave_thing",
            text: "Tell us about the smallest brave thing you've ever done."
        ),
        TaleTrialPrompt(
            slug: "stubborn_animal",
            text: "An animal you've never met before refuses to move out of your way. Tell us about the standoff."
        ),
        TaleTrialPrompt(
            slug: "weather_changed_plans",
            text: "The weather did something weird and your whole day changed shape because of it."
        ),
        TaleTrialPrompt(
            slug: "thing_in_pocket",
            text: "There's something in your pocket you didn't put there. Tell us how it got there."
        ),
    ]

    /// Look up a prompt by slug. Returns `nil` for unknown slugs so
    /// legacy persisted state (e.g., older trial-play records) never
    /// crashes the trial surface.
    public static func prompt(forSlug slug: String) -> TaleTrialPrompt? {
        phase2.first { $0.slug == slug }
    }
}
