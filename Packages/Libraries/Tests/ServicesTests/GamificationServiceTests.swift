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

    @Test func phase1CatalogShipsFourteenAchievements() {
        // 10 Phase 1 + 4 Phase 1.1 voice-character = 14 total.
        #expect(VoiceTaleAchievementCatalog.phase1.count == 14)
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
            completedKitIDs: [5]
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
}
