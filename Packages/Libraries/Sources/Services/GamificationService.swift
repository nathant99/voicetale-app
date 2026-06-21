import Foundation
import SwiftData
import Models
import ForgeModels
import ForgeGamification

/// Top-level gamification coordinator. Wires ``ForgeGamification.XPEngine`` +
/// ``ForgeGamification.StreakManager`` + ``ForgeGamification.AchievementEngine``
/// to VoiceTale's persistence layer (``PersistentPlayerProgress`` +
/// ``PersistentAchievement`` + ``PersistentAnthologyMood`` +
/// ``PersistentTraditionEntry``).
///
/// **State ownership**: this service holds the engines (value types + actor)
/// but does NOT cache progression state — every method takes a
/// ``ModelContext`` and snapshots the live persistent row. This keeps the
/// service stateless across view re-mounts.
///
/// Per `@.claude/rules/swiftdata.md` § "ModelContext injection — Pass from
/// view's onAppear to ViewModel, NOT in init", callers pass the context per
/// call rather than at init.
@MainActor
@Observable
public final class GamificationService {
    private let xpEngine: XPEngine
    private let streakManager: StreakManager
    private let achievementEngine: AchievementEngine

    public init(config: GamificationConfig = GamificationConfig()) {
        self.xpEngine = XPEngine(config: config)
        self.streakManager = StreakManager(currentStreak: 0, availableFreezes: config.streakFreezeCount)
        self.achievementEngine = AchievementEngine()
    }

    // MARK: - XP

    /// Award XP for a specific event. Returns the new XP total + level after
    /// the award. Also re-evaluates achievements + persists any newly-earned
    /// ones in the same transaction.
    @discardableResult
    public func awardXP(
        for event: XPEvent,
        in context: ModelContext
    ) -> XPAwardOutcome {
        var newTotal = 0
        var newLevel = 0
        VoiceTaleStore.updateProgress({ record in
            record.xpTotal = max(0, record.xpTotal + event.points)
            newTotal = record.xpTotal
            newLevel = self.xpEngine.level(for: newTotal)
        }, in: context)
        DebugLog.state("GamificationService.awardXP — event=\(event) +\(event.points) XP → total=\(newTotal) lvl=\(newLevel)")
        let newBadges = evaluateAchievements(in: context)
        return XPAwardOutcome(
            xpAwarded: event.points,
            newTotal: newTotal,
            newLevel: newLevel,
            newBadges: newBadges
        )
    }

    // MARK: - Streak

    /// Record that the player engaged today. Returns the streak result for
    /// celebration UI (`.continued`, `.frozenAndContinued`, `.reset`,
    /// `.sameDay`).
    public func recordSession(in context: ModelContext) async -> StreakResult {
        let snapshot = VoiceTaleStore.progressSnapshot(in: context)
        let manager = StreakManager(
            currentStreak: snapshot.currentStreakDays,
            availableFreezes: snapshot.availableStreakFreezes,
            lastSessionDate: snapshot.lastSessionAt
        )
        let result = await manager.recordSession()
        let now = Date()
        VoiceTaleStore.updateProgress({ record in
            switch result {
            case .continued(let streak):
                record.currentStreakDays = streak
                record.maxStreakDays = max(record.maxStreakDays, streak)
                record.lastSessionAt = now
            case .frozenAndContinued(let streak, let freezesRemaining):
                record.currentStreakDays = streak
                record.maxStreakDays = max(record.maxStreakDays, streak)
                record.availableStreakFreezes = freezesRemaining
                record.lastSessionAt = now
            case .reset:
                record.currentStreakDays = 1
                record.lastSessionAt = now
            case .sameDay(let streak):
                record.currentStreakDays = streak
                record.lastSessionAt = now
            case .heldUnderDistress(let streak):
                // ForgeKit 0.86 — streak held flat under distress; never
                // resets. lastSessionAt still bumps so the next session is
                // counted normally.
                record.currentStreakDays = streak
                record.lastSessionAt = now
            @unknown default:
                record.lastSessionAt = now
            }
        }, in: context)
        DebugLog.state("GamificationService.recordSession — result=\(result)")
        return result
    }

    // MARK: - Achievements

    /// Evaluate every Phase-1 achievement against the current persistent
    /// state. Returns newly-earned badges (display data) and persists their
    /// records in the same call.
    @discardableResult
    public func evaluateAchievements(in context: ModelContext) -> [BadgeDisplayData] {
        let snapshot = currentCriteriaSnapshot(in: context)
        let earnedIDs = fetchEarnedAchievementIDs(in: context)
        let definitions = VoiceTaleAchievementCatalog.phase1
        let newlyEarned = achievementEngine.evaluate(
            definitions: definitions,
            earnedIDs: earnedIDs
        ) { definition in
            snapshot.satisfies(definition.id)
        }
        guard !newlyEarned.isEmpty else { return [] }
        let now = Date()
        for definition in newlyEarned {
            let record = PersistentAchievement(id: definition.id, earnedAt: now)
            context.insert(record)
        }
        do {
            try context.save()
        } catch {
            DebugLog.data("GamificationService.evaluateAchievements — save failed", error: error)
        }
        DebugLog.state("GamificationService.evaluateAchievements — \(newlyEarned.count) new badge(s): \(newlyEarned.map(\.id))")
        return achievementEngine.displayData(
            for: newlyEarned.map { ($0, now) }
        )
    }

    /// All earned achievement IDs for the current install. Useful for
    /// rendering badge galleries.
    public func fetchEarnedAchievementIDs(in context: ModelContext) -> Set<String> {
        let descriptor = FetchDescriptor<PersistentAchievement>()
        let records: [PersistentAchievement]
        do {
            records = try context.fetch(descriptor)
        } catch {
            DebugLog.data("GamificationService.fetchEarnedAchievementIDs — fetch failed", error: error)
            return []
        }
        return Set(records.map(\.id))
    }

    /// All earned badges as display structs (id + title + icon + earnedAt).
    public func fetchEarnedBadges(in context: ModelContext) -> [EarnedBadgeData] {
        let descriptor = FetchDescriptor<PersistentAchievement>(
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]
        )
        let records: [PersistentAchievement]
        do {
            records = try context.fetch(descriptor)
        } catch {
            DebugLog.data("GamificationService.fetchEarnedBadges — fetch failed", error: error)
            return []
        }
        let definitionByID = Dictionary(
            uniqueKeysWithValues: VoiceTaleAchievementCatalog.phase1.map { ($0.id, $0) }
        )
        return records.compactMap { record in
            guard let definition = definitionByID[record.id] else { return nil }
            return EarnedBadgeData(
                id: record.id,
                title: definition.title,
                description: definition.description,
                iconAssetName: definition.iconAssetName,
                earnedAt: record.earnedAt
            )
        }
    }

    // MARK: - Criteria evaluation

    private func currentCriteriaSnapshot(in context: ModelContext) -> CriteriaSnapshot {
        let moods = VoiceTaleStore.fetchAnthologyMoods(in: context)
        let traditions = VoiceTaleStore.fetchTraditionExploration(in: context)
        let progress = VoiceTaleStore.progressSnapshot(in: context)
        let totalTales = moods.reduce(0) { $0 + $1.taleCount }
        let traditionsExplored = traditions.filter { $0.firstExploredAt != nil }.count
        let moodCount: (VoiceTaleMood) -> Int = { mood in
            moods.first { $0.mood == mood }?.taleCount ?? 0
        }
        return CriteriaSnapshot(
            totalTales: totalTales,
            currentStreakDays: progress.currentStreakDays,
            traditionsExplored: traditionsExplored,
            funnyTales: moodCount(.funny),
            scaryTales: moodCount(.scary),
            tenderTales: moodCount(.tender),
            wildTales: moodCount(.wild)
        )
    }
}

// MARK: - Supporting value types

/// Every XP-awarding event. Values are pure points (the curve is applied
/// when reading the level, not when banking the XP). Per portfolio
/// convention, big-deal events (first save, anthology milestones) get
/// proportionally higher rewards than routine ones (transcript review).
public enum XPEvent: Equatable, Sendable, CustomStringConvertible {
    case taleSaved
    case allFiveBeatsHit
    case transcriptReviewed
    case traditionExplored(slug: String)

    public var points: Int {
        switch self {
        case .taleSaved:           return 25
        case .allFiveBeatsHit:     return 15
        case .transcriptReviewed:  return 10
        case .traditionExplored:   return 20
        }
    }

    public var description: String {
        switch self {
        case .taleSaved:                  return "taleSaved"
        case .allFiveBeatsHit:            return "allFiveBeatsHit"
        case .transcriptReviewed:         return "transcriptReviewed"
        case .traditionExplored(let s):   return "traditionExplored(\(s))"
        }
    }
}

/// Return shape of ``GamificationService/awardXP(for:in:)``. Surfaces both
/// the XP delta + the (possibly empty) list of badges that just unlocked.
public nonisolated struct XPAwardOutcome: Sendable {
    public let xpAwarded: Int
    public let newTotal: Int
    public let newLevel: Int
    public let newBadges: [BadgeDisplayData]

    public init(
        xpAwarded: Int,
        newTotal: Int,
        newLevel: Int,
        newBadges: [BadgeDisplayData]
    ) {
        self.xpAwarded = xpAwarded
        self.newTotal = newTotal
        self.newLevel = newLevel
        self.newBadges = newBadges
    }
}

/// Earned-badge display struct. Independent of ``BadgeDisplayData`` so
/// app-side surfaces can render either fresh-earn celebrations OR the
/// historical badge gallery from the same data shape.
public nonisolated struct EarnedBadgeData: Sendable, Identifiable, Equatable {
    public let id: String
    public let title: String
    public let description: String
    public let iconAssetName: String
    public let earnedAt: Date

    public init(
        id: String,
        title: String,
        description: String,
        iconAssetName: String,
        earnedAt: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconAssetName = iconAssetName
        self.earnedAt = earnedAt
    }
}

/// Snapshot of the persistent state needed to evaluate every Phase-1
/// achievement criterion. Pure value type so the criteria check is
/// trivially testable without a `ModelContext`.
nonisolated struct CriteriaSnapshot: Sendable, Equatable {
    let totalTales: Int
    let currentStreakDays: Int
    let traditionsExplored: Int
    let funnyTales: Int
    let scaryTales: Int
    let tenderTales: Int
    let wildTales: Int

    /// Map from catalog ID → predicate. New IDs added to
    /// ``VoiceTaleAchievementCatalog`` must add an arm here OR they'll
    /// always evaluate to `false`. Tested in
    /// ``GamificationServiceTests.everyCatalogEntryHasACriteria``.
    func satisfies(_ id: String) -> Bool {
        switch id {
        case "first_tale":                return totalTales >= 1
        case "prolific_storyteller_5":    return totalTales >= 5
        case "prolific_storyteller_10":   return totalTales >= 10
        case "mood_funny":                return funnyTales >= 1
        case "mood_scary":                return scaryTales >= 1
        case "mood_tender":               return tenderTales >= 1
        case "mood_wild":                 return wildTales >= 1
        case "tradition_explorer":        return traditionsExplored >= 1
        case "tradition_world_traveler":  return traditionsExplored >= 5
        case "streak_three_days":         return currentStreakDays >= 3
        default:                          return false
        }
    }
}
