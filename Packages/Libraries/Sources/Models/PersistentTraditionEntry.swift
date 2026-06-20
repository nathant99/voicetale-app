import Foundation
import SwiftData

/// Persistent record of the kid's exploration state for a single tradition.
/// The tradition catalog itself is bundled JSON; this entity tracks per-user
/// interaction (first explored, last listened, listen count) so the anthology
/// UI can surface progress.
@Model
public final class PersistentTraditionEntry {
    public var slug: String = ""
    public var firstExploredAt: Date?
    public var lastListenedAt: Date?
    public var listenCount: Int = 0

    public init(
        slug: String = "",
        firstExploredAt: Date? = nil,
        lastListenedAt: Date? = nil,
        listenCount: Int = 0
    ) {
        self.slug = slug
        self.firstExploredAt = firstExploredAt
        self.lastListenedAt = lastListenedAt
        self.listenCount = listenCount
    }
}
