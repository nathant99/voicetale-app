//
//  ShowProgressIntent.swift
//  VoiceTale
//
//  AppIntent that opens VoiceTale to the Progress tab.
//

import AppIntents
import AppFeature

/// "Show my progress" — surfaces the Progress tab where the kid sees
/// their XP / level / streak / achievement badges.
struct ShowProgressIntent: AppIntent {
    static let title: LocalizedStringResource = "Show my progress"
    static let description = IntentDescription(
        "Open VoiceTale to your progress — XP, streak, and badges.",
        categoryName: "VoiceTale"
    )
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        IntentTabCoordinator.shared.request(destination: .progress)
        return .result()
    }
}
