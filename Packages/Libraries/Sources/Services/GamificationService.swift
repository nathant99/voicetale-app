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
        // Snapshot level BEFORE the award so call sites can detect level-up
        // transitions (e.g., to fire a ForgeCelebration overlay). Doing this
        // here — rather than at every call site — keeps the contract local.
        let previousLevel = xpEngine.level(for: VoiceTaleStore.progressSnapshot(in: context).xpTotal)
        var newTotal = 0
        var newLevel = 0
        VoiceTaleStore.updateProgress({ record in
            record.xpTotal = max(0, record.xpTotal + event.points)
            // Phase 1.1: `kitCompleted` events also record the kit number on
            // the persistent progress row so the
            // `voice_kit_05_completed` achievement (and any future kit-
            // milestone achievement) can evaluate against a stable Set.
            // Duplicate kit numbers are de-duplicated.
            if case .kitCompleted(let kit) = event,
               record.completedKitIDsRaw.contains(kit) == false {
                record.completedKitIDsRaw.append(kit)
            }
            newTotal = record.xpTotal
            newLevel = self.xpEngine.level(for: newTotal)
        }, in: context)
        DebugLog.state("GamificationService.awardXP — event=\(event) +\(event.points) XP → total=\(newTotal) lvl=\(previousLevel)→\(newLevel)")
        let newBadges = evaluateAchievements(in: context)
        return XPAwardOutcome(
            xpAwarded: event.points,
            newTotal: newTotal,
            previousLevel: previousLevel,
            newLevel: newLevel,
            newBadges: newBadges
        )
    }

    // MARK: - Streak

    /// Record that the app was opened today. Distinct from
    /// ``recordSession(in:)`` — `recordLastActive` bumps on every cold
    /// launch (including sessions where no tale is saved). Returns the
    /// number of whole days since the previous `lastActiveDate`, or
    /// `nil` for a fresh install.
    @discardableResult
    public func recordLastActive(now: Date = Date(), in context: ModelContext) -> Int? {
        let previousActive = VoiceTaleStore.progressSnapshot(in: context).lastActiveDate
        let lapsed = LapsedReturnDetector.daysLapsed(lastActive: previousActive, now: now)
        VoiceTaleStore.updateProgress({ record in
            record.lastActiveDate = now
        }, in: context)
        return lapsed
    }

    // MARK: - Retention metrics (D1 / D7 / D30)

    /// Seed the retention `installDate` if missing AND record any
    /// milestones the kid crossed on this cold-launch. Returns the
    /// milestones that fired this call so the App-shell can emit
    /// `VoiceTaleAnalyticsEvent.retentionMilestoneHit` per milestone.
    ///
    /// Pure on-device — the milestone wire-surface is the categorical
    /// `d1` / `d7` / `d30` string only; the install anchor never leaves.
    /// Per `@.claude/rules/age-assurance.md` § 2026 FTC COPPA: no PII,
    /// no third-party transmission, no opt-in needed (categorical use
    /// metric for on-device retention is a permitted operational
    /// signal).
    @discardableResult
    public func recordRetention(
        now: Date = Date(),
        in context: ModelContext
    ) -> [RetentionMetricsEvaluator.Milestone] {
        let snapshot = VoiceTaleStore.progressSnapshot(in: context)
        var milestonesToFire: [RetentionMetricsEvaluator.Milestone] = []
        // Snapshot for the evaluator runs against the about-to-be-seeded
        // installDate so the first launch's milestones (if any are
        // already crossed — e.g., a clock-skewed device or a debug
        // backdate) fire on the same call.
        let installAnchor = snapshot.installDate ?? now
        let stateAfterSeed = RetentionMetricsEvaluator.RetentionState(
            installDate: installAnchor,
            d1HitAt: snapshot.d1HitAt,
            d7HitAt: snapshot.d7HitAt,
            d30HitAt: snapshot.d30HitAt
        )
        milestonesToFire = RetentionMetricsEvaluator.newlyCrossed(
            state: stateAfterSeed, now: now
        )
        VoiceTaleStore.updateProgress({ record in
            if record.installDate == nil {
                record.installDate = installAnchor
            }
            for milestone in milestonesToFire {
                switch milestone {
                case .d1:  if record.d1HitAt == nil  { record.d1HitAt = now }
                case .d7:  if record.d7HitAt == nil  { record.d7HitAt = now }
                case .d30: if record.d30HitAt == nil { record.d30HitAt = now }
                }
            }
        }, in: context)
        if milestonesToFire.isEmpty == false {
            DebugLog.state("GamificationService.recordRetention — fired \(milestonesToFire.map(\.rawValue))")
        }
        return milestonesToFire
    }

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
        // Phase 1.1 — voice-character criteria. We pull the full set of saved
        // tales here so the criteria can inspect each tale's beatTimeline +
        // voiceCharacterSlug attributions. The fetch is bounded by the
        // fetchTales default (500) — for the foreseeable future every Phase 1
        // kid stays well under that cap.
        let allTales = VoiceTaleStore.fetchTales(in: context)
        let voiceSummary = CriteriaSnapshot.voiceCharacterSummary(from: allTales)
        let largestCollectionTaleCount = VoiceTaleStore.largestCollectionTaleCount(in: context)
        return CriteriaSnapshot(
            totalTales: totalTales,
            currentStreakDays: progress.currentStreakDays,
            traditionsExplored: traditionsExplored,
            funnyTales: moodCount(.funny),
            scaryTales: moodCount(.scary),
            tenderTales: moodCount(.tender),
            wildTales: moodCount(.wild),
            voiceSwapsEver: voiceSummary.voiceSwapsEver,
            presetsEverUsed: voiceSummary.presetsEverUsed,
            voiceVariationTalesCount: voiceSummary.voiceVariationTalesCount,
            completedKitIDs: progress.completedKitIDs,
            largestCollectionTaleCount: largestCollectionTaleCount,
            taleTrialPlays: progress.taleTrialPlays
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
    /// Phase 1.1 — a kit (01–04) was fully walked through in the QuizView.
    /// Points reward the kid for engaging with reflection prompts; the
    /// per-question accuracy (for `.choice` items) is tracked separately
    /// via `ForgePedagogy.PedagogySession`.
    case kitCompleted(kit: Int)

    public var points: Int {
        switch self {
        case .taleSaved:           return 25
        case .allFiveBeatsHit:     return 15
        case .transcriptReviewed:  return 10
        case .traditionExplored:   return 20
        case .kitCompleted:        return 15
        }
    }

    public var description: String {
        switch self {
        case .taleSaved:                  return "taleSaved"
        case .allFiveBeatsHit:            return "allFiveBeatsHit"
        case .transcriptReviewed:         return "transcriptReviewed"
        case .traditionExplored(let s):   return "traditionExplored(\(s))"
        case .kitCompleted(let k):        return "kitCompleted(\(k))"
        }
    }
}

/// Return shape of ``GamificationService/awardXP(for:in:)``. Surfaces both
/// the XP delta + the (possibly empty) list of badges that just unlocked.
public nonisolated struct XPAwardOutcome: Sendable {
    public let xpAwarded: Int
    public let newTotal: Int
    public let previousLevel: Int
    public let newLevel: Int
    public let newBadges: [BadgeDisplayData]

    /// True when the award crossed a level threshold. Call sites use this
    /// to trigger a ForgeCelebration level-up overlay.
    public var leveledUp: Bool { newLevel > previousLevel }

    public init(
        xpAwarded: Int,
        newTotal: Int,
        previousLevel: Int,
        newLevel: Int,
        newBadges: [BadgeDisplayData]
    ) {
        self.xpAwarded = xpAwarded
        self.newTotal = newTotal
        self.previousLevel = previousLevel
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

/// Snapshot of the persistent state needed to evaluate every Phase-1 +
/// Phase-1.1 achievement criterion. Pure value type so the criteria check
/// is trivially testable without a `ModelContext`.
nonisolated struct CriteriaSnapshot: Sendable, Equatable {
    let totalTales: Int
    let currentStreakDays: Int
    let traditionsExplored: Int
    let funnyTales: Int
    let scaryTales: Int
    let tenderTales: Int
    let wildTales: Int
    /// Phase 1.1 — number of saved tales that contain at least one
    /// non-narrator voice-character attribution across the timeline.
    let voiceSwapsEver: Int
    /// Phase 1.1 — distinct non-narrator slugs the kid has ever used.
    let presetsEverUsed: Set<String>
    /// Phase 1.1 — count of saved tales whose timeline carries ≥ 2
    /// distinct non-narrator slugs (the "single-tale voice variation"
    /// experience the achievement rewards).
    let voiceVariationTalesCount: Int
    /// Phase 1.1 — kit IDs the kid has fully walked through. Sourced
    /// from ``PersistentPlayerProgress.completedKitIDsRaw``.
    let completedKitIDs: Set<Int>
    /// Phase 2 anthology curation — largest tale count across the kid's
    /// mood collections. Backs the `mood_collection_curator` achievement
    /// (threshold ≥ 3). 0 when no collections exist.
    let largestCollectionTaleCount: Int
    /// Phase 2 Tale Trial — count of trial walk-throughs the kid has
    /// played. Backs the `tale_trial_completed` achievement criterion.
    let taleTrialPlays: Int

    init(
        totalTales: Int,
        currentStreakDays: Int,
        traditionsExplored: Int,
        funnyTales: Int,
        scaryTales: Int,
        tenderTales: Int,
        wildTales: Int,
        voiceSwapsEver: Int = 0,
        presetsEverUsed: Set<String> = [],
        voiceVariationTalesCount: Int = 0,
        completedKitIDs: Set<Int> = [],
        largestCollectionTaleCount: Int = 0,
        taleTrialPlays: Int = 0
    ) {
        self.totalTales = totalTales
        self.currentStreakDays = currentStreakDays
        self.traditionsExplored = traditionsExplored
        self.funnyTales = funnyTales
        self.scaryTales = scaryTales
        self.tenderTales = tenderTales
        self.wildTales = wildTales
        self.voiceSwapsEver = voiceSwapsEver
        self.presetsEverUsed = presetsEverUsed
        self.voiceVariationTalesCount = voiceVariationTalesCount
        self.completedKitIDs = completedKitIDs
        self.largestCollectionTaleCount = largestCollectionTaleCount
        self.taleTrialPlays = taleTrialPlays
    }

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
        // Phase 1.1 — voice-character chooser
        case "voice_first_swap":          return voiceSwapsEver >= 1
        case "voice_all_five_presets":    return presetsEverUsed.count >= 4
        case "voice_kit_05_completed":    return completedKitIDs.contains(5)
        case "voice_variation_tale":      return voiceVariationTalesCount >= 1
        // Phase 2 — kits 06-09 + mood breadth
        case "mood_explorer_all_four":
            return funnyTales >= 1 && scaryTales >= 1
                && tenderTales >= 1 && wildTales >= 1
        case "kit_06_mood_completed":     return completedKitIDs.contains(6)
        case "kit_07_pacing_completed":   return completedKitIDs.contains(7)
        case "kit_08_surprise_completed": return completedKitIDs.contains(8)
        case "kit_09_closing_completed":  return completedKitIDs.contains(9)
        case "phase2_complete_set":
            return completedKitIDs.isSuperset(of: [6, 7, 8, 9])
        case "mood_collection_curator":
            return largestCollectionTaleCount >= 3
        case "tale_trial_completed":
            return taleTrialPlays >= 1
        default:                          return false
        }
    }

    /// Compute the voice-character summary fields from a flat list of saved
    /// tales. Pure function so the achievement criteria are testable
    /// without a `ModelContext` — the GamificationService passes the
    /// tales it fetches from the store.
    ///
    /// Note on `voice_all_five_presets`: there are 5 presets total
    /// (narrator + hero + sage + sprite + ogre), but `narrator` is the
    /// natural baseline ("no override") — the achievement rewards
    /// breadth across the 4 ALTERNATIVE presets (hero/sage/sprite/ogre).
    /// So the criterion is `presetsEverUsed.count >= 4`, not 5.
    static func voiceCharacterSummary(
        from tales: [VoiceTaleEntry]
    ) -> (voiceSwapsEver: Int, presetsEverUsed: Set<String>, voiceVariationTalesCount: Int) {
        var swapsEver = 0
        var presetsEverUsed: Set<String> = []
        var variationTales = 0
        for tale in tales {
            let nonNarratorSlugs = Set(
                tale.beatTimeline.compactMap { $0.voiceCharacterSlug }
                    .filter { $0 != VoiceCharacterPreset.narrator.rawValue }
            )
            if nonNarratorSlugs.isEmpty == false {
                swapsEver += 1
                presetsEverUsed.formUnion(nonNarratorSlugs)
                if nonNarratorSlugs.count >= 2 {
                    variationTales += 1
                }
            }
        }
        return (swapsEver, presetsEverUsed, variationTales)
    }
}
