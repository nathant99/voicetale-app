import Foundation
import SwiftData

/// Persistent record of an earned Phase-1 achievement. One row per badge per
/// install; `id` matches the catalog entry in
/// ``VoiceTaleAchievementCatalog/Phase1``. Per
/// `@.claude/rules/swiftdata.md` § "Pre-App Store: don't create new
/// VersionedSchema for unreleased models — add new @Model classes directly
/// to the existing schema version", this type is registered in
/// ``VoiceTaleSchemaV1``.
@Model
public final class PersistentAchievement {
    @Attribute(.unique) public var id: String = ""
    public var earnedAt: Date = Date()

    public init(id: String = "", earnedAt: Date = Date()) {
        self.id = id
        self.earnedAt = earnedAt
    }
}
