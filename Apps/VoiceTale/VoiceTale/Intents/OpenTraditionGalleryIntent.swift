//
//  OpenTraditionGalleryIntent.swift
//  VoiceTale
//
//  AppIntent that opens VoiceTale to the tradition gallery (under
//  Adventure tab).
//

import AppIntents
import AppFeature

/// "Tradition gallery" — surfaces the Adventure tab where the tradition
/// gallery lives. Future PRs may route to a dedicated Tradition tab
/// without changing this intent's identity.
struct OpenTraditionGalleryIntent: AppIntent {
    static let title: LocalizedStringResource = "Tradition gallery"
    static let description = IntentDescription(
        "Open the VoiceTale tradition gallery — voices and lineages.",
        categoryName: "VoiceTale"
    )
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        IntentTabCoordinator.shared.request(destination: .tradition)
        return .result()
    }
}
