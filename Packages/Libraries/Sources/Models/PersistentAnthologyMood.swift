import Foundation
import SwiftData

/// Persistent record of per-mood anthology curation. One row per mood the kid
/// has at least one tale tagged with; ``customLabel`` lets the kid rename a
/// mood folder ("scary" → "spooky stories"). ``taleCount`` is a cached count
/// updated by the persistence layer on insert/delete.
@Model
public final class PersistentAnthologyMood {
    public var mood: String = ""
    public var customLabel: String?
    public var taleCount: Int = 0
    public var lastTaleAt: Date?

    public init(
        mood: String = "",
        customLabel: String? = nil,
        taleCount: Int = 0,
        lastTaleAt: Date? = nil
    ) {
        self.mood = mood
        self.customLabel = customLabel
        self.taleCount = taleCount
        self.lastTaleAt = lastTaleAt
    }
}
