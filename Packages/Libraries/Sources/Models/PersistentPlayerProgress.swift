import Foundation
import SwiftData

/// Persistent record of overall player progression. Designed to be a single
/// row per install (the persistence layer enforces singleton semantics via
/// fetch-or-create).
@Model
public final class PersistentPlayerProgress {
    public var xpTotal: Int = 0
    public var currentStreakDays: Int = 0
    public var maxStreakDays: Int = 0
    public var availableStreakFreezes: Int = 2
    public var lastSessionAt: Date?
    public var tutorialCompletedAt: Date?
    /// Phase 1.1 — kit IDs the kid has fully walked through in the
    /// QuizView. Pre-App-Store additive default-empty field per
    /// `@.claude/rules/swiftdata.md` § "Pre-App Store: don't create new
    /// VersionedSchema for unreleased models — add new @Model classes
    /// directly to the existing schema version." Stored as `[Int]` for
    /// SwiftData compatibility; ``PlayerProgressData`` exposes it as
    /// `Set<Int>` for the value-type cache.
    public var completedKitIDsRaw: [Int] = []
    /// Engagement-Foundation phase — most recent timestamp the kid opened
    /// the app. Drives the welcome-back / "we missed you" flow when the
    /// gap is ≥ 3 days. Distinct from ``lastSessionAt`` (which tracks the
    /// most recent tale-save / kit-completion) — `lastActiveDate` bumps
    /// on every cold launch, even sessions where no tale lands.
    public var lastActiveDate: Date?

    public init(
        xpTotal: Int = 0,
        currentStreakDays: Int = 0,
        maxStreakDays: Int = 0,
        availableStreakFreezes: Int = 2,
        lastSessionAt: Date? = nil,
        tutorialCompletedAt: Date? = nil,
        completedKitIDsRaw: [Int] = [],
        lastActiveDate: Date? = nil
    ) {
        self.xpTotal = xpTotal
        self.currentStreakDays = currentStreakDays
        self.maxStreakDays = maxStreakDays
        self.availableStreakFreezes = availableStreakFreezes
        self.lastSessionAt = lastSessionAt
        self.tutorialCompletedAt = tutorialCompletedAt
        self.completedKitIDsRaw = completedKitIDsRaw
        self.lastActiveDate = lastActiveDate
    }
}
