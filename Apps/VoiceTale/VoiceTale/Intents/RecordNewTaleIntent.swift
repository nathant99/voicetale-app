//
//  RecordNewTaleIntent.swift
//  VoiceTale
//
//  AppIntent that opens VoiceTale to the Tell tab in record-ready state.
//  Sibling to the 3 other intents in this folder + the
//  `VoiceTaleShortcuts` AppShortcutsProvider.
//
//  Lives in the synchronized `Apps/VoiceTale/VoiceTale/Intents/` folder
//  (safe to author from disk per `@CLAUDE.md` § "Always safe to write").
//  Per `@Docs/HANDOFF_TO_USER_APP_INTENTS_REGISTRATION.md` Step 3 — the
//  Step 4 user-side runtime verification (Settings → Siri & Search) is
//  the only remaining gate.
//

import AppIntents
import AppFeature

/// "Tell a tale" — opens VoiceTale to the Tell tab. The actual recording
/// gesture is the kid's tap on the mic; the intent does not auto-start
/// recording (parental-gate-respecting per `@.claude/rules/age-assurance.md`
/// — microphone permission must be initiated by an in-app user gesture).
struct RecordNewTaleIntent: AppIntent {
    static let title: LocalizedStringResource = "Tell a tale"
    static let description = IntentDescription(
        "Open VoiceTale and get ready to tell a new tale.",
        categoryName: "VoiceTale"
    )
    static let openAppWhenRun: Bool = true

    /// `@MainActor` — App Intents runtime hops to MainActor before
    /// invoking `perform` when `openAppWhenRun = true`. The
    /// ``IntentTabCoordinator/shared`` write is therefore safe.
    @MainActor
    func perform() async throws -> some IntentResult {
        IntentTabCoordinator.shared.request(destination: .tell)
        return .result()
    }
}
