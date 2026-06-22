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
import Services

@main
struct VoiceTaleApp: App {
    private let modelContainer: ModelContainer

    init() {
        // Delegate to `VoiceTalePersistence.makeFailSafeContainer()` so a
        // corrupted store auto-backs-up the `.store` / `.store-wal` /
        // `.store-shm` triple to Application Support and recreates a fresh
        // container per `.claude/rules/swiftdata.md` § "Fail-Safe Recovery
        // Pattern". The recovery URL would normally surface in a parental
        // log, but VoiceTale is on-device-only — we just continue on the
        // fresh store rather than block the kid from telling a tale.
        do {
            let opened = try VoiceTalePersistence.makeFailSafeContainer()
            self.modelContainer = opened.container
        } catch {
            // The fail-safe path itself failed — usually a schema
            // misconfiguration during development. Hard-fail so it's loud.
            fatalError("Failed to initialize VoiceTale ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(modelContainer)
    }
}
