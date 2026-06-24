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
    /// Retention-baseline anchor — the timestamp the kid first opened the
    /// app on this install. Pre-App-Store additive default-nil field per
    /// `@.claude/rules/swiftdata.md` § "Pre-App Store: don't create new
    /// VersionedSchema". Set on the first cold-launch; never reset for
    /// the lifetime of the install. D1 / D7 / D30 metrics derive from
    /// this anchor + the current `now`.
    public var installDate: Date?
    /// Timestamp the D1 retention milestone first fired (an `installDate
    /// + 1 calendar day` re-open). `nil` until hit. Categorical milestone
    /// only — the analytics emission is the wire surface, this field is
    /// the local "has it fired yet" gate.
    public var d1HitAt: Date?
    /// Timestamp the D7 retention milestone first fired.
    public var d7HitAt: Date?
    /// Timestamp the D30 retention milestone first fired.
    public var d30HitAt: Date?
    /// Phase 2 Tale Trial mode — count of trial walk-throughs the kid has
    /// played. Pre-App-Store additive default-zero field per
    /// `@.claude/rules/swiftdata.md`. Drives the `tale_trial_completed`
    /// achievement criterion (threshold ≥ 1).
    public var taleTrialPlays: Int = 0
    /// Delight & Polish phase — the timestamp the kid first hit all five
    /// beats in a single tale. `nil` until the inaugural success. Drives
    /// the proportional-celebration tier (`.epic` full-screen celebration)
    /// + the `first_five_beat_tale` achievement (XP 75). Pre-App-Store
    /// additive default-nil per `@.claude/rules/swiftdata.md`.
    public var firstFiveBeatTaleAt: Date?
    /// ForgeMasteryEngine Phase A — JSON-encoded
    /// `[KitID.RawValue: TopicMasteryState]` snapshot persisted via
    /// `KitMasteryStore.persist`. Pre-App-Store additive default-nil
    /// `Data?` field per `@.claude/rules/swiftdata.md` § "Pre-App Store:
    /// don't create new VersionedSchema for unreleased models — add
    /// new @Model classes / fields directly to the existing schema
    /// version." `Codable` value-type round-trip via `JSONEncoder` —
    /// `Optional` field is back-compat by Swift's `decodeIfPresent`
    /// per the same rule's CLAUDE.md gotcha. Per
    /// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase A.
    public var encodedMasteryState: Data?

    public init(
        xpTotal: Int = 0,
        currentStreakDays: Int = 0,
        maxStreakDays: Int = 0,
        availableStreakFreezes: Int = 2,
        lastSessionAt: Date? = nil,
        tutorialCompletedAt: Date? = nil,
        completedKitIDsRaw: [Int] = [],
        lastActiveDate: Date? = nil,
        installDate: Date? = nil,
        d1HitAt: Date? = nil,
        d7HitAt: Date? = nil,
        d30HitAt: Date? = nil,
        taleTrialPlays: Int = 0,
        firstFiveBeatTaleAt: Date? = nil,
        encodedMasteryState: Data? = nil
    ) {
        self.xpTotal = xpTotal
        self.currentStreakDays = currentStreakDays
        self.maxStreakDays = maxStreakDays
        self.availableStreakFreezes = availableStreakFreezes
        self.lastSessionAt = lastSessionAt
        self.tutorialCompletedAt = tutorialCompletedAt
        self.completedKitIDsRaw = completedKitIDsRaw
        self.lastActiveDate = lastActiveDate
        self.installDate = installDate
        self.d1HitAt = d1HitAt
        self.d7HitAt = d7HitAt
        self.d30HitAt = d30HitAt
        self.taleTrialPlays = taleTrialPlays
        self.firstFiveBeatTaleAt = firstFiveBeatTaleAt
        self.encodedMasteryState = encodedMasteryState
    }
}
