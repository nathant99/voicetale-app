//
//  VoiceTaleApp.swift
//  VoiceTale
//
//  Created by Nghi Tran on 6/19/26.
//

import SwiftUI
import SwiftData
import AppFeature
import Models

@main
struct VoiceTaleApp: App {
    private let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for: Schema(versionedSchema: VoiceTaleSchemaV1.self),
                migrationPlan: VoiceTaleMigrationPlan.self,
                configurations: []
            )
        } catch {
            // Per `.claude/rules/swiftdata.md` § "Fail-Safe Recovery Pattern" —
            // production code would back up the store + recreate fresh. For
            // Phase 0 close-out we hard-fail so the misconfiguration is
            // surfaced loudly during development.
            fatalError("Failed to initialize VoiceTale ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(modelContainer)
    }
}
