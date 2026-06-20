import Foundation
import SwiftData
import Models

/// Factory for VoiceTale's SwiftData container. Uses the canonical
/// ``VoiceTaleSchemaV1`` + ``VoiceTaleMigrationPlan`` from the Models target.
///
/// Always pass ``cloudKitDatabase: .none`` — VoiceTale is local-only by default
/// (audio is never iCloud-synced per `@Docs/TECHNICAL_DESIGN.md` § Privacy)
/// AND the in-memory configuration MUST also pass `.none` per
/// `@.claude/rules/testing.md` Crash-Resilience Default #4.
public enum VoiceTalePersistence {
    public static func makeModelContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: VoiceTaleSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: VoiceTaleMigrationPlan.self,
            configurations: [configuration]
        )
    }

    public static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: VoiceTaleSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: VoiceTaleMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
