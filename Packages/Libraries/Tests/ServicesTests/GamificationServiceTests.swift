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

    @Test func phase1CatalogShipsTenAchievements() {
        #expect(VoiceTaleAchievementCatalog.phase1.count == 10)
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
            wildTales: 2
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
}
