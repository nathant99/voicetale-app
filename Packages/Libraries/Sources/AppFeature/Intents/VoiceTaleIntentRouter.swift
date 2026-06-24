import Foundation
import ForgeIntents

/// Maps a ``VoiceTaleIntentDestination`` (the typed deep-link target a Siri
/// shortcut / Spotlight invocation would request) onto the steady-state
/// tab the app should land on once the kid has cleared the onboarding
/// gate. Pure-function + `nonisolated` so it can run from any actor
/// context — App Intent handlers are not guaranteed to run on `@MainActor`.
///
/// The actual `AppIntent` struct registrations + the `@main` shell wire-up
/// are deferred to a future Xcode-UI handoff. Per
/// `@.claude/rules/xcode-agent-safety.md` the agent cannot author
/// Info.plist entries from disk, and full Intent registration typically
/// requires an `INIntentsSupported` array OR an `AppShortcutsProvider`
/// declaration that the app-shell `@main` struct registers. This
/// foundation drop ships the typed plumbing so the future PR is a thin
/// wrap.
nonisolated public enum VoiceTaleIntentRouter {
    /// Map a destination onto the canonical tab. Pure; no side effects.
    public static func tab(for destination: VoiceTaleIntentDestination) -> AppRootView.AppTab {
        switch destination {
        case .tell:      return .tell
        case .anthology: return .tell    // anthology lives inside the Tell tab's tab-sibling navigation; route to .tell until a dedicated tab ships
        case .progress:  return .progress
        case .tradition: return .adventure
        }
    }

    /// Canonical Siri shortcut phrases. Built from
    /// ``ForgeIntents.ForgeShortcutPhraseBuilder`` so all portfolio apps
    /// share the same invocation register. Apps display the phrases in a
    /// "Try saying" hint surface during onboarding + in Settings.
    public static let shortcutPhrases: VoiceTaleShortcutPhrases = .build()
}

/// Materialized struct of the canonical kid-readable Siri phrases. Kept
/// as plain `String` fields (instead of an enum) so consuming views can
/// concatenate them into a localized "Try saying" hint string without
/// going back through ``ForgeShortcutPhraseBuilder`` at render time.
///
/// One field per shipped ``AppShortcut`` in the app-shell
/// `VoiceTaleShortcuts.appShortcuts` array (PR #113). Adding a new
/// AppShortcut means adding a new field here so the in-app "Try saying"
/// hint surface (``SettingsView`` Siri section) stays in lockstep with
/// what the runtime registers.
nonisolated public struct VoiceTaleShortcutPhrases: Sendable, Hashable {
    public let openApp: String
    public let tellATale: String
    public let showMyTales: String
    public let showMyProgress: String
    /// Tradition gallery phrase. Mirrors
    /// ``Apps/VoiceTale/VoiceTale/Intents/VoiceTaleShortcuts``'s
    /// `OpenTraditionGalleryIntent` AppShortcut so the in-app "Try
    /// saying" hint surface lists every registered phrase.
    public let showTraditionGallery: String

    /// Build the canonical set from the portfolio's phrase builder. The
    /// app-name is hardcoded "VoiceTale" — matches the kid-readable
    /// brand register (no marketing-suffix interpolation per
    /// `@.claude/rules/localization.md` § Brand names).
    public static func build() -> VoiceTaleShortcutPhrases {
        let builder = ForgeShortcutPhraseBuilder(appName: "VoiceTale")
        return VoiceTaleShortcutPhrases(
            openApp: builder.openPhrase(),
            tellATale: builder.customPhrase("Tell a tale"),
            showMyTales: builder.customPhrase("Show my tales"),
            showMyProgress: builder.showProgress(),
            showTraditionGallery: builder.customPhrase("Show the traditions")
        )
    }
}
