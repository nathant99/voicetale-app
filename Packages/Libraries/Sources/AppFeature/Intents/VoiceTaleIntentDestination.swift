import Foundation

/// Typed deep-link destination for the future `AppIntent` registrations.
/// Sized so the cases map 1:1 to the kid-facing tab phases the kid might
/// land on from Siri / Spotlight / Shortcuts. Pure value enum +
/// `nonisolated` per `@.claude/rules/concurrency.md` so the type can be
/// constructed from any actor context (intent handlers run on the
/// platform-supplied executor — not necessarily `@MainActor`).
///
/// The destination is intentionally separate from ``VoiceTalePhase`` —
/// the latter is the router's full phase enum (which includes onboarding
/// gates + structural phases that wouldn't make sense as a Siri target).
/// The destination is the *subset* an intent can request; the router
/// maps it via ``VoiceTaleIntentRouter`` once the kid has cleared the
/// onboarding gate.
///
/// Conforms to the `ForgeIntents.ForgeOpenAppIntentProviding.Destination`
/// constraints (Sendable + Hashable) so future intent structs can declare
/// `var destination: VoiceTaleIntentDestination` without needing
/// `@retroactive` conformances.
nonisolated public enum VoiceTaleIntentDestination: String, Sendable, Hashable, Codable, CaseIterable {
    /// "Tell a tale" — opens the Tell tab in record-ready state.
    case tell
    /// "Show my tales" — opens the Anthology tab unfiltered.
    case anthology
    /// "Show my progress" — opens the Progress tab.
    case progress
    /// "Tradition gallery" — opens the Tradition tab.
    case tradition

    /// Kid-readable display label used in Siri Shortcuts UI + intent
    /// titles. Keep the register warm (no "View" / "Navigate to" verbs —
    /// the kid is doing a thing, not navigating).
    public var displayLabel: String {
        switch self {
        case .tell:      return "Tell a tale"
        case .anthology: return "My tales"
        case .progress:  return "My progress"
        case .tradition: return "Tradition gallery"
        }
    }
}
