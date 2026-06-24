//
//  OpenAnthologyIntent.swift
//  VoiceTale
//
//  AppIntent that opens VoiceTale to the anthology (saved-tales) surface.
//

import AppIntents
import AppFeature

/// "Show my tales" — surfaces the anthology gallery. Today the router
/// maps `.anthology` to the `.tell` tab because the anthology lives inside
/// the Tell-tab sibling-navigation surface; future PRs may route to a
/// dedicated tab without changing this intent's identity.
struct OpenAnthologyIntent: AppIntent {
    static let title: LocalizedStringResource = "Show my tales"
    static let description = IntentDescription(
        "Open the VoiceTale anthology — your saved tales.",
        categoryName: "VoiceTale"
    )
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        IntentTabCoordinator.shared.request(destination: .anthology)
        return .result()
    }
}
