import Testing
import Foundation
import SwiftData
@testable import Services
import Models
import ForgeModels

/// Tests for ``GamificationService`` — XP awards, achievement evaluation,
/// catalog completeness, and the streak rollover behavior surfaced by
/// ``ForgeGamification.StreakManager``. Per `@.claude/rules/testing.md` §
/// Crash-Resilience Defaults #4, every in-memory container passes
/// `cloudKitDatabase: .none` (already done in ``VoiceTalePersistence``).
@MainActor
@Suite("GamificationService")
struct GamificationServiceTests {
    private func newContext() throws -> ModelContext {
        let container = try VoiceTalePersistence.makeInMemoryContainer()
        return ModelContext(container)
    }

    // MARK: - Catalog completeness

    @Test func phase1CatalogShipsTwentyTwoAchievements() {
        // 10 Phase 1 + 4 Phase 1.1 voice-character + 6 Phase 2 kits/breadth
        // + 1 Phase 2 anthology-curation + 1 Phase 2 Tale Trial = 22 total.
        // The catalog stays in the `phase1` array (single source) — the
        // name is a historical artifact, but the test asserts the running
        // total so future additions cascade through this gate.
        #expect(VoiceTaleAchievementCatalog.phase1.count == 22)
    }

    @Test func catalogIDsAreUnique() {
        let ids = VoiceTaleAchievementCatalog.phase1.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func everyCatalogEntryHasACriteria() {
        // The internal CriteriaSnapshot.satisfies(_:) switch must have an
        // arm for every catalog id; new entries without an arm always
        // evaluate to false. We test by seeding a snapshot that should
        // unlock every catalog entry and checking it returns true for all.
        let snapshot = CriteriaSnapshot(
            totalTales: 10,
            currentStreakDays: 3,
            traditionsExplored: 5,
            funnyTales: 3,
            scaryTales: 3,
            tenderTales: 2,
            wildTales: 2,
            voiceSwapsEver: 5,
            presetsEverUsed: ["hero", "sage", "sprite", "ogre"],
            voiceVariationTalesCount: 2,
            // Phase 2 catalog adds kits 6-9 milestones + a complete-set
            // recognition; seed all four so the satisfies() arm coverage
            // gate stays at 100%.
            completedKitIDs: [5, 6, 7, 8, 9],
            // Phase 2 mood-collection curator — seeded with the threshold
            // tale count so the arm gate stays at 100%.
            largestCollectionTaleCount: 3,
            // Phase 2 Tale Trial — seeded with the threshold count so the
            // arm gate stays at 100%.
            taleTrialPlays: 1
        )
        for definition in VoiceTaleAchievementCatalog.phase1 {
            #expect(snapshot.satisfies(definition.id),
                    "Catalog id=\(definition.id) has no criteria arm in CriteriaSnapshot.satisfies(_:)")
        }
    }

    // MARK: - XP awards

    @Test func awardXPBumpsTotal() throws {
        let context = try newContext()
        let service = GamificationService()
        let outcome = service.awardXP(for: .taleSaved, in: context)
        #expect(outcome.xpAwarded == 25)
        #expect(outcome.newTotal == 25)
        let snapshot = VoiceTaleStore.progressSnapshot(in: context)
        #expect(snapshot.xpTotal == 25)
    }

    @Test func multipleXPAwardsAccumulate() throws {
        let context = try newContext()
        let service = GamificationService()
        _ = service.awardXP(for: .taleSaved, in: context)
        _ = service.awardXP(for: .traditionExplored(slug: "griot"), in: context)
        _ = service.awardXP(for: .transcriptReviewed, in: context)
        let snapshot = VoiceTaleStore.progressSnapshot(in: context)
        #expect(snapshot.xpTotal == 25 + 20 + 10)
    }

    @Test func awardOutcomeCapturesPreviousAndNewLevel() throws {
        // First award starts at level 0 (xpTotal = 0). The default XP curve
        // (`.standard`: level = sqrt(xp/100)) crosses to level 1 at xp >= 100.
        // Drive enough awards to cross at least one threshold so we can assert
        // `previousLevel < newLevel` somewhere in the sequence.
        let context = try newContext()
        let service = GamificationService()
        var sawLevelUp = false
        for _ in 0..<8 {
            let outcome = service.awardXP(for: .taleSaved, in: context)
            #expect(outcome.previousLevel <= outcome.newLevel,
                    "previousLevel must not exceed newLevel")
            if outcome.leveledUp { sawLevelUp = true }
        }
        #expect(sawLevelUp,
                "8 × 25-XP awards should cross at least one level threshold")
    }

    @Test func awardOutcomeReportsNoLevelUpBelowThreshold() throws {
        // A single 25-XP award starts at xpTotal 0 (level 0) and ends at 25
        // (still level 0). `leveledUp` must be false here so call sites don't
        // fire spurious level-up celebrations.
        let context = try newContext()
        let service = GamificationService()
        let outcome = service.awardXP(for: .taleSaved, in: context)
        #expect(outcome.previousLevel == outcome.newLevel)
        #expect(outcome.leveledUp == false)
    }

    // MARK: - Achievement evaluation

    @Test func firstTaleSavedUnlocksFirstTaleBadge() throws {
        let context = try newContext()
        let entry = VoiceTaleEntry(
            title: "First", mood: .funny, durationSeconds: 60,
            beatTimeline: [], transcript: "ok"
        )
        try VoiceTaleStore.insertTale(entry, audioFileRelativePath: "f.m4a", in: context)
        let service = GamificationService()
        let outcome = service.awardXP(for: .taleSaved, in: context)
        let badgeIDs = Set(outcome.newBadges.map(\.id))
        #expect(badgeIDs.contains("first_tale"))
        #expect(badgeIDs.contains("mood_funny"))
    }

    @Test func achievementsDoNotDoubleAward() throws {
        let context = try newContext()
        let entry = VoiceTaleEntry(
            title: "First", mood: .scary, durationSeconds: 60,
            beatTimeline: [], transcript: "ok"
        )
        try VoiceTaleStore.insertTale(entry, audioFileRelativePath: "s.m4a", in: context)
        let service = GamificationService()
        _ = service.awardXP(for: .taleSaved, in: context)
        let secondOutcome = service.awardXP(for: .taleSaved, in: context)
        // Second award: no NEW badges, even though criteria still pass.
        #expect(secondOutcome.newBadges.isEmpty)
    }

    @Test func allFiveTraditionsUnlocksWorldTraveler() throws {
        let context = try newContext()
        for slug in ["griot", "indigenous-american-oral-history", "seanchai", "rakugo", "slam-poetry"] {
            VoiceTaleStore.recordTraditionExplored(slug: slug, in: context)
        }
        let service = GamificationService()
        let badges = service.evaluateAchievements(in: context)
        let badgeIDs = Set(badges.map(\.id))
        #expect(badgeIDs.contains("tradition_explorer"))
        #expect(badgeIDs.contains("tradition_world_traveler"))
    }

    @Test func fetchEarnedBadgesReturnsPersistedBadges() throws {
        let context = try newContext()
        let entry = VoiceTaleEntry(
            title: "T", mood: .tender, durationSeconds: 60,
            beatTimeline: [], transcript: "ok"
        )
        try VoiceTaleStore.insertTale(entry, audioFileRelativePath: "t.m4a", in: context)
        let service = GamificationService()
        _ = service.awardXP(for: .taleSaved, in: context)
        let earned = service.fetchEarnedBadges(in: context)
        let ids = Set(earned.map(\.id))
        #expect(ids.contains("first_tale"))
        #expect(ids.contains("mood_tender"))
    }

    // MARK: - Streak

    @Test func firstRecordedSessionStartsAOneDayStreak() async throws {
        let context = try newContext()
        let service = GamificationService()
        let result = await service.recordSession(in: context)
        if case .continued(let streak) = result {
            #expect(streak == 1)
        } else {
            Issue.record("Expected .continued(streak: 1); got \(result)")
        }
        let snapshot = VoiceTaleStore.progressSnapshot(in: context)
        #expect(snapshot.currentStreakDays == 1)
        #expect(snapshot.maxStreakDays == 1)
    }

    @Test func awardXPOutcomeReportsLevelFromXPEngine() throws {
        let context = try newContext()
        let service = GamificationService()
        let outcome = service.awardXP(for: .taleSaved, in: context)
        // XPEngine .standard curve: level = sqrt(xp/100); 25 XP → 0.
        #expect(outcome.newLevel == 0)
        // Bump to 100 XP and re-check.
        for _ in 0..<3 {
            _ = service.awardXP(for: .taleSaved, in: context) // +25 each
        }
        let later = service.awardXP(for: .traditionExplored(slug: "x"), in: context) // +20 → 120 total
        #expect(later.newTotal == 120)
        #expect(later.newLevel >= 1)
    }

    // MARK: - Phase 1.1 — voice-character achievements

    @Test func voiceCharacterSummaryFromEmptyTalesIsZero() {
        let summary = CriteriaSnapshot.voiceCharacterSummary(from: [])
        #expect(summary.voiceSwapsEver == 0)
        #expect(summary.presetsEverUsed.isEmpty)
        #expect(summary.voiceVariationTalesCount == 0)
    }

    @Test func voiceCharacterSummaryCountsTalesWithAnyOverride() {
        let timeline = [
            BeatSegment(beat: .hook, targetSeconds: 10, actualSeconds: 10, voiceCharacterSlug: "hero"),
            BeatSegment(beat: .setup, targetSeconds: 20, actualSeconds: 20),
        ]
        let tale = VoiceTaleEntry(
            title: "T", mood: .funny, durationSeconds: 30,
            beatTimeline: timeline, transcript: "t"
        )
        let summary = CriteriaSnapshot.voiceCharacterSummary(from: [tale])
        #expect(summary.voiceSwapsEver == 1)
        #expect(summary.presetsEverUsed == ["hero"])
        // Only 1 distinct non-narrator slug → not a variation tale.
        #expect(summary.voiceVariationTalesCount == 0)
    }

    @Test func voiceCharacterSummaryDetectsVariationTale() {
        let timeline = [
            BeatSegment(beat: .hook, targetSeconds: 10, actualSeconds: 10, voiceCharacterSlug: "hero"),
            BeatSegment(beat: .turn, targetSeconds: 30, actualSeconds: 30, voiceCharacterSlug: "ogre"),
        ]
        let tale = VoiceTaleEntry(
            title: "T", mood: .wild, durationSeconds: 60,
            beatTimeline: timeline, transcript: "t"
        )
        let summary = CriteriaSnapshot.voiceCharacterSummary(from: [tale])
        #expect(summary.voiceSwapsEver == 1)
        #expect(summary.voiceVariationTalesCount == 1)
        #expect(summary.presetsEverUsed == ["hero", "ogre"])
    }

    @Test func voiceCharacterSummaryIgnoresNarratorOnlyTales() {
        let timeline = [
            BeatSegment(beat: .hook, targetSeconds: 10, actualSeconds: 10, voiceCharacterSlug: "narrator"),
            BeatSegment(beat: .setup, targetSeconds: 20, actualSeconds: 20, voiceCharacterSlug: nil),
        ]
        let tale = VoiceTaleEntry(
            title: "T", mood: .tender, durationSeconds: 30,
            beatTimeline: timeline, transcript: "t"
        )
        let summary = CriteriaSnapshot.voiceCharacterSummary(from: [tale])
        #expect(summary.voiceSwapsEver == 0)
        #expect(summary.presetsEverUsed.isEmpty)
    }

    @Test func voiceFirstSwapBadgeUnlocksOnFirstVoiceTale() throws {
        let context = try newContext()
        let timeline = [
            BeatSegment(beat: .hook, targetSeconds: 10, actualSeconds: 10, voiceCharacterSlug: "hero")
        ]
        let entry = VoiceTaleEntry(
            title: "Voice tale", mood: .wild, durationSeconds: 30,
            beatTimeline: timeline, transcript: "ok"
        )
        try VoiceTaleStore.insertTale(entry, audioFileRelativePath: "v.m4a", in: context)
        let service = GamificationService()
        let outcome = service.awardXP(for: .taleSaved, in: context)
        let badgeIDs = Set(outcome.newBadges.map(\.id))
        #expect(badgeIDs.contains("voice_first_swap"))
    }

    @Test func voiceVariationTaleBadgeUnlocksOnMultiVoiceTale() throws {
        let context = try newContext()
        let timeline = [
            BeatSegment(beat: .hook, targetSeconds: 10, actualSeconds: 10, voiceCharacterSlug: "hero"),
            BeatSegment(beat: .turn, targetSeconds: 30, actualSeconds: 30, voiceCharacterSlug: "ogre"),
        ]
        let entry = VoiceTaleEntry(
            title: "Variation", mood: .wild, durationSeconds: 60,
            beatTimeline: timeline, transcript: "ok"
        )
        try VoiceTaleStore.insertTale(entry, audioFileRelativePath: "var.m4a", in: context)
        let service = GamificationService()
        let outcome = service.awardXP(for: .taleSaved, in: context)
        let badgeIDs = Set(outcome.newBadges.map(\.id))
        #expect(badgeIDs.contains("voice_first_swap"))
        #expect(badgeIDs.contains("voice_variation_tale"))
    }

    @Test func voiceAllFivePresetsBadgeUnlocksAfterUsingAllFour() throws {
        let context = try newContext()
        // Insert 4 separate tales, each using a different non-narrator preset.
        for (i, slug) in ["hero", "sage", "sprite", "ogre"].enumerated() {
            let timeline = [
                BeatSegment(
                    beat: .hook,
                    targetSeconds: 10,
                    actualSeconds: 10,
                    voiceCharacterSlug: slug
                )
            ]
            let entry = VoiceTaleEntry(
                title: "Tale \(i)", mood: .funny, durationSeconds: 30,
                beatTimeline: timeline, transcript: "ok"
            )
            try VoiceTaleStore.insertTale(entry, audioFileRelativePath: "t\(i).m4a", in: context)
        }
        let service = GamificationService()
        let outcome = service.awardXP(for: .taleSaved, in: context)
        let badgeIDs = Set(outcome.newBadges.map(\.id))
        #expect(badgeIDs.contains("voice_all_five_presets"))
    }

    @Test func voiceKit05CompletedBadgeUnlocksOnKitCompletion() throws {
        let context = try newContext()
        let service = GamificationService()
        // Awarding the kit 5 completion event must:
        // (1) bump xpTotal by 15 (kitCompleted points)
        // (2) append 5 to PersistentPlayerProgress.completedKitIDsRaw
        // (3) trigger evaluateAchievements → voice_kit_05_completed earns.
        let outcome = service.awardXP(for: .kitCompleted(kit: 5), in: context)
        let badgeIDs = Set(outcome.newBadges.map(\.id))
        #expect(badgeIDs.contains("voice_kit_05_completed"))
        let snapshot = VoiceTaleStore.progressSnapshot(in: context)
        #expect(snapshot.completedKitIDs.contains(5))
    }

    @Test func kitCompletionIsDedupedAcrossMultipleAwards() throws {
        let context = try newContext()
        let service = GamificationService()
        _ = service.awardXP(for: .kitCompleted(kit: 5), in: context)
        _ = service.awardXP(for: .kitCompleted(kit: 5), in: context)
        let snapshot = VoiceTaleStore.progressSnapshot(in: context)
        // Set semantics — only one 5 retained.
        #expect(snapshot.completedKitIDs == [5])
    }

    // MARK: - Engagement Foundation — lapsed-return

    @Test func recordLastActiveOnFreshInstallReturnsNil() throws {
        let context = try newContext()
        let service = GamificationService()
        let lapsed = service.recordLastActive(now: Date(), in: context)
        #expect(lapsed == nil)
        let snapshot = VoiceTaleStore.progressSnapshot(in: context)
        #expect(snapshot.lastActiveDate != nil)
    }

    @Test func recordLastActiveReturnsDaysSincePreviousActive() throws {
        let context = try newContext()
        let service = GamificationService()
        let earlier = Date(timeIntervalSinceNow: -5 * 86400)
        _ = service.recordLastActive(now: earlier, in: context)
        let lapsed = service.recordLastActive(now: Date(), in: context)
        // Calendar-day math depends on local time zone but for a 5-day
        // delta on a non-DST boundary should always be 4 or 5.
        #expect(lapsed != nil)
        #expect((4...5).contains(lapsed!))
    }

    // MARK: - Phase 2 — kit milestones + mood-breadth recognition

    @Test func phase2KitMilestoneBadgesUnlockOnIndividualKitCompletion() throws {
        // Each kit 06-09 has its own milestone badge — awarding the
        // matching `kitCompleted` event must unlock just that one.
        let context = try newContext()
        let service = GamificationService()
        let outcome = service.awardXP(for: .kitCompleted(kit: 6), in: context)
        let ids = Set(outcome.newBadges.map(\.id))
        #expect(ids.contains("kit_06_mood_completed"))
        // Other kit milestones should NOT fire yet.
        #expect(ids.contains("kit_07_pacing_completed") == false)
        #expect(ids.contains("kit_08_surprise_completed") == false)
        #expect(ids.contains("kit_09_closing_completed") == false)
        #expect(ids.contains("phase2_complete_set") == false)
    }

    @Test func phase2CompleteSetBadgeUnlocksAfterAllFourKitsCompleted() throws {
        let context = try newContext()
        let service = GamificationService()
        for kit in [6, 7, 8] {
            _ = service.awardXP(for: .kitCompleted(kit: kit), in: context)
        }
        let finalOutcome = service.awardXP(for: .kitCompleted(kit: 9), in: context)
        let ids = Set(finalOutcome.newBadges.map(\.id))
        // The catch-all + the kit-9 milestone both fire on the last award.
        #expect(ids.contains("kit_09_closing_completed"))
        #expect(ids.contains("phase2_complete_set"))
        let snapshot = VoiceTaleStore.progressSnapshot(in: context)
        #expect(snapshot.completedKitIDs.isSuperset(of: [6, 7, 8, 9]))
    }

    @Test func moodExplorerAllFourBadgeUnlocksAfterAllFourMoodsTold() throws {
        let context = try newContext()
        for mood in VoiceTaleMood.allCases {
            let entry = VoiceTaleEntry(
                title: "T-\(mood.rawValue)", mood: mood, durationSeconds: 60,
                beatTimeline: [], transcript: "ok"
            )
            try VoiceTaleStore.insertTale(entry, audioFileRelativePath: "m-\(mood.rawValue).m4a", in: context)
        }
        let service = GamificationService()
        let outcome = service.awardXP(for: .taleSaved, in: context)
        let ids = Set(outcome.newBadges.map(\.id))
        #expect(ids.contains("mood_explorer_all_four"))
    }

    @Test func moodExplorerAllFourDoesNotUnlockWithMissingMood() throws {
        // Three of the four moods → still locked.
        let context = try newContext()
        for mood: VoiceTaleMood in [.funny, .scary, .tender] {
            let entry = VoiceTaleEntry(
                title: "T-\(mood.rawValue)", mood: mood, durationSeconds: 60,
                beatTimeline: [], transcript: "ok"
            )
            try VoiceTaleStore.insertTale(entry, audioFileRelativePath: "m-\(mood.rawValue).m4a", in: context)
        }
        let service = GamificationService()
        let outcome = service.awardXP(for: .taleSaved, in: context)
        let ids = Set(outcome.newBadges.map(\.id))
        #expect(ids.contains("mood_explorer_all_four") == false)
    }

    @Test func phase2CompleteSetCriterionRequiresAllFourKits() {
        // Direct CriteriaSnapshot test — verify the satisfies() arm only
        // returns true with all of {6, 7, 8, 9}.
        let partial = CriteriaSnapshot(
            totalTales: 0, currentStreakDays: 0, traditionsExplored: 0,
            funnyTales: 0, scaryTales: 0, tenderTales: 0, wildTales: 0,
            completedKitIDs: [6, 7, 8] // missing 9
        )
        #expect(partial.satisfies("phase2_complete_set") == false)

        let complete = CriteriaSnapshot(
            totalTales: 0, currentStreakDays: 0, traditionsExplored: 0,
            funnyTales: 0, scaryTales: 0, tenderTales: 0, wildTales: 0,
            completedKitIDs: [6, 7, 8, 9]
        )
        #expect(complete.satisfies("phase2_complete_set") == true)
    }

    // MARK: - Retention metrics (D1 / D7 / D30)

    @Test func recordRetentionOnFreshInstallSeedsInstallDateWithoutFiringMilestones() throws {
        let context = try newContext()
        let service = GamificationService()
        let fired = service.recordRetention(in: context)
        #expect(fired.isEmpty)
        let snapshot = VoiceTaleStore.progressSnapshot(in: context)
        #expect(snapshot.installDate != nil)
        #expect(snapshot.d1HitAt == nil)
        #expect(snapshot.d7HitAt == nil)
        #expect(snapshot.d30HitAt == nil)
    }

    @Test func recordRetentionAtDay1FiresD1Milestone() throws {
        let context = try newContext()
        let service = GamificationService()
        let installDay = Date(timeIntervalSinceNow: -86_400 - 60) // ≈ 1 day ago
        _ = service.recordRetention(now: installDay, in: context)
        let fired = service.recordRetention(now: Date(), in: context)
        #expect(fired == [.d1])
        let snapshot = VoiceTaleStore.progressSnapshot(in: context)
        #expect(snapshot.d1HitAt != nil)
    }

    @Test func recordRetentionAtDay30FiresEveryMissingMilestone() throws {
        let context = try newContext()
        let service = GamificationService()
        let install = Date(timeIntervalSinceNow: -30 * 86_400 - 60)
        _ = service.recordRetention(now: install, in: context)
        let fired = service.recordRetention(now: Date(), in: context)
        // No D1 / D7 yet — kid was gone the whole window — so all 3 fire.
        #expect(fired == [.d1, .d7, .d30])
    }

    @Test func recordRetentionIsIdempotentAfterMilestoneFires() throws {
        let context = try newContext()
        let service = GamificationService()
        let install = Date(timeIntervalSinceNow: -2 * 86_400)
        _ = service.recordRetention(now: install, in: context)
        let first = service.recordRetention(now: Date(), in: context)
        let second = service.recordRetention(now: Date(), in: context)
        #expect(first == [.d1])
        // Same-day re-launch — D1 already fired; nothing new.
        #expect(second.isEmpty)
    }
}
