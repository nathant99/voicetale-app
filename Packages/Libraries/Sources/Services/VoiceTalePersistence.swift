import Foundation
import SwiftData
import Models
import ForgePersistence

/// Factory for VoiceTale's SwiftData container. Uses the canonical
/// ``VoiceTaleSchemaV1`` + ``VoiceTaleMigrationPlan`` from the Models target.
///
/// Always pass ``cloudKitDatabase: .none`` — VoiceTale is local-only by default
/// (audio is never iCloud-synced per `@Docs/TECHNICAL_DESIGN.md` § Privacy)
/// AND the in-memory configuration MUST also pass `.none` per
/// `@.claude/rules/testing.md` Crash-Resilience Default #4.
///
/// The disk-backed entry point ``makeFailSafeContainer()`` delegates to
/// `ForgePersistence.forgeFailSafeContainer` so a corrupted store
/// auto-backs-up the `.store` / `.store-wal` / `.store-shm` triple to
/// Application Support and recreates a fresh container per
/// `@.claude/rules/swiftdata.md` § "Fail-Safe Recovery Pattern" (rules 25-27).
/// The legacy ``makeModelContainer()`` is preserved for callers that don't
/// want recovery metadata + want to keep the explicit `.none` cloudKit cue.
public enum VoiceTalePersistence {
    /// Canonical on-disk store location for VoiceTale's SwiftData container.
    /// Lives under Application Support so it survives across launches AND
    /// stays out of iCloud per `@Docs/TECHNICAL_DESIGN.md` § Privacy. The
    /// folder is created lazily if missing.
    public static var defaultStoreURL: URL {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let folder = appSupport.appendingPathComponent("VoiceTale", isDirectory: true)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("VoiceTale.store")
    }

    /// Disk-backed container with backup-and-recreate recovery. Returns the
    /// opened container plus optional ``ForgeContainerRecovery`` metadata
    /// describing the backup URL when the recovery path fires. Callers that
    /// want to observe corruption should log `recovery.backupURL`.
    @MainActor
    public static func makeFailSafeContainer() throws
        -> (container: ModelContainer, recovery: ForgeContainerRecovery?) {
        try forgeFailSafeContainer(
            for: VoiceTaleSchemaV1.models,
            at: defaultStoreURL,
            cloudKitIdentifier: nil,
            migrationPlan: VoiceTaleMigrationPlan.self
        )
    }

    /// Legacy disk-backed entry point — retained for callers that already
    /// own their own store-URL strategy AND want an explicit `.none`
    /// cloudKit cue surfaced in source rather than relying on
    /// `ModelConfiguration(url:)`'s default. New call sites prefer
    /// ``makeFailSafeContainer()``.
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

    /// In-memory container for tests + previews. Hand-rolled (not
    /// `forgeInMemoryContainer`) because the canonical pattern MUST pass
    /// `cloudKitDatabase: .none` alongside `isStoredInMemoryOnly: true`
    /// per `@.claude/rules/testing.md` Crash-Resilience Default #4 — the
    /// bare in-memory initializer silently fails with
    /// `SwiftDataError._Error.loadIssueModelContainer`.
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
