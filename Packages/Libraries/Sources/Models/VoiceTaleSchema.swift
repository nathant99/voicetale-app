import Foundation
import SwiftData
import ForgePersistence

/// Canonical schema definition for VoiceTale. Per `@.claude/rules/swiftdata.md`
/// § "Start with VersionedSchema from day one" + "One VersionedSchema per app
/// version" — every SwiftData `@Model` class in the app belongs here.
///
/// ``versionIdentifier`` MUST be `static let` (rule #10 + concurrency
/// requirement). New versions ship as `VoiceTaleSchemaV2`, etc., and a
/// matching ``MigrationStage`` lives next to them in ``VoiceTaleMigrationPlan``.
///
/// ``ReflectionEntryRecord`` is the ForgeKit-owned `@Model` storage class
/// for `ForgeReflection` journal entries — registered here per
/// `@Docs/PLAN_FORGEREFLECTION_LIFT.md` § Phase A so the canonical schema
/// stays a single source of truth.
public enum VoiceTaleSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [
            PersistentVoiceTaleEntry.self,
            PersistentTraditionEntry.self,
            PersistentPlayerProgress.self,
            PersistentAnthologyMood.self,
            PersistentAchievement.self,
            PersistentMoodCollection.self,
            ReflectionEntryRecord.self,
        ]
    }
}

/// Migration plan stub — chronological order; new versions append, never
/// reorder. Until a V2 ships, the plan is V1-only with no stages.
public enum VoiceTaleMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [VoiceTaleSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}

/// Type aliases shielding app code from version-specific names. Per
/// `@.claude/rules/swiftdata.md` § "typealias for current models".
public typealias CurrentSchema = VoiceTaleSchemaV1
