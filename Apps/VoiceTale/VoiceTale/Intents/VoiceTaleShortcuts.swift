//
//  VoiceTaleShortcuts.swift
//  VoiceTale
//
//  Declares the four canonical AppShortcut phrases for Siri / Spotlight /
//  Shortcuts.app. The App Intents runtime auto-discovers this provider —
//  no Info.plist registration is required for an `AppShortcutsProvider`
//  (per `@Docs/HANDOFF_TO_USER_APP_INTENTS_REGISTRATION.md` Step 3).
//
//  Phrase shape mirrors the canonical
//  `VoiceTaleShortcutPhrases.build()` builder from
//  `Packages/Libraries/Sources/AppFeature/Intents/VoiceTaleIntentRouter.swift`
//  so the runtime phrases the kid sees in Settings → Siri & Search match
//  the in-app "Try saying" hint surface.
//

import AppIntents

/// Single AppShortcutsProvider for VoiceTale. The runtime scans the app
/// binary for `AppShortcutsProvider` conformers — declaring one struct is
/// sufficient; no additional registration code in `@main` is required.
struct VoiceTaleShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordNewTaleIntent(),
            phrases: [
                "Tell a tale in \(.applicationName)",
                "Tell a new tale with \(.applicationName)",
                "Start a tale in \(.applicationName)"
            ],
            shortTitle: "Tell a tale",
            systemImageName: "mic.circle.fill"
        )
        AppShortcut(
            intent: OpenAnthologyIntent(),
            phrases: [
                "Show my tales in \(.applicationName)",
                "Open my anthology in \(.applicationName)"
            ],
            shortTitle: "My tales",
            systemImageName: "books.vertical.fill"
        )
        AppShortcut(
            intent: ShowProgressIntent(),
            phrases: [
                "Show my progress in \(.applicationName)",
                "How am I doing in \(.applicationName)"
            ],
            shortTitle: "My progress",
            systemImageName: "chart.bar.fill"
        )
        AppShortcut(
            intent: OpenTraditionGalleryIntent(),
            phrases: [
                "Tradition gallery in \(.applicationName)",
                "Show the traditions in \(.applicationName)"
            ],
            shortTitle: "Tradition gallery",
            systemImageName: "globe"
        )
    }
}
