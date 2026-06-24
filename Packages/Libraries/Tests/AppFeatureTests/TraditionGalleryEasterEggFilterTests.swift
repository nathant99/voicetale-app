import Foundation
import Testing
import Models
import Services
@testable import AppFeature

/// Coverage for the easter-eggs Phase C gallery filter shipped in PR-E of
/// the 2026-06-24 NINTH-round wire-up. Locks the pure-function
/// ``TraditionGalleryView.filteredVisibleEntries(in:snapshot:)`` against
/// every interesting boundary: base-tier always visible, easter-eggs hidden
/// without unlock, easter-eggs surfaced when predicate fires, and the
/// defensive nil-condition gate-failed default.
///
/// Per `@Docs/PLAN_EASTER_EGGS_TRADITION_UNLOCKS.md` § Phase C.
@Suite("TraditionGalleryEasterEggFilter")
struct TraditionGalleryEasterEggFilterTests {

    // MARK: - Base-tier always visible

    @Test func baseTierEntriesAlwaysVisible() {
        let catalog = TraditionCatalog(
            version: 1,
            entries: [
                makeBaseEntry(slug: "griot"),
                makeBaseEntry(slug: "rakugo"),
                makeBaseEntry(slug: "seanchai"),
            ]
        )
        let snapshot = TraditionUnlockSnapshot()  // empty — kid has done nothing
        let visible = TraditionGalleryView.filteredVisibleEntries(
            in: catalog, snapshot: snapshot
        )
        #expect(visible.map(\.slug) == ["griot", "rakugo", "seanchai"])
    }

    @Test func legacyJSONEntriesWithNilTierTreatedAsBase() {
        // Entries that pre-date the schema additions have tier = nil →
        // effectiveTier = .base → always visible. Locks the
        // legacy-JSON back-compat contract.
        let catalog = TraditionCatalog(
            version: 1,
            entries: [
                TraditionEntry(
                    slug: "legacy",
                    displayName: "Legacy",
                    region: "Test",
                    summary: "summary",
                    craftPrimitive: "test",
                    culturalCreditNote: "credit"
                    // tier explicitly omitted → nil → effective .base
                )
            ]
        )
        let visible = TraditionGalleryView.filteredVisibleEntries(
            in: catalog, snapshot: TraditionUnlockSnapshot()
        )
        #expect(visible.count == 1)
        #expect(visible.first?.slug == "legacy")
    }

    // MARK: - Easter-egg hidden when predicate fails

    @Test func easterEggHiddenWhenPredicateFails() {
        let catalog = TraditionCatalog(
            version: 1,
            entries: [
                makeBaseEntry(slug: "griot"),
                makeEasterEgg(slug: "secret", condition: "deep_listener"),
            ]
        )
        let snapshot = TraditionUnlockSnapshot()  // empty — deep_listener fails
        let visible = TraditionGalleryView.filteredVisibleEntries(
            in: catalog, snapshot: snapshot
        )
        #expect(visible.map(\.slug) == ["griot"])
    }

    // MARK: - Easter-egg surfaced when predicate fires

    @Test func easterEggSurfacedWhenPredicateFires() {
        let catalog = TraditionCatalog(
            version: 1,
            entries: [
                makeBaseEntry(slug: "griot"),
                makeEasterEgg(slug: "secret", condition: "deep_listener"),
            ]
        )
        let snapshot = TraditionUnlockSnapshot(
            expandedBaseTraditions: ["griot", "indigenous-american-oral-history",
                                     "seanchai", "rakugo", "slam-poetry"],
            savedTales: 10
        )
        let visible = TraditionGalleryView.filteredVisibleEntries(
            in: catalog, snapshot: snapshot
        )
        #expect(visible.map(\.slug) == ["griot", "secret"])
    }

    // MARK: - Easter-egg with nil condition stays hidden (defensive default)

    @Test func easterEggWithNilConditionStaysHidden() {
        // Catalog authors MUST always set unlockCondition on easter-egg
        // entries. If they don't, the filter defends by keeping the
        // entry hidden (rather than over-surfacing).
        let catalog = TraditionCatalog(
            version: 1,
            entries: [
                makeBaseEntry(slug: "griot"),
                TraditionEntry(
                    slug: "broken-easter",
                    displayName: "Broken",
                    region: "Test",
                    summary: "summary",
                    craftPrimitive: "test",
                    culturalCreditNote: "credit",
                    tier: .easterEgg,
                    unlockCondition: nil  // forgotten by the catalog author
                )
            ]
        )
        // Even with a maxed-out snapshot, the broken-easter entry stays hidden.
        let richSnapshot = TraditionUnlockSnapshot(
            expandedBaseTraditions: ["griot", "indigenous-american-oral-history",
                                     "seanchai", "rakugo", "slam-poetry"],
            savedTales: 99,
            moodsCovered: [.funny, .scary, .tender, .wild],
            kitsCompleted: Set(1...9),
            traditionRevisitCount: ["griot": 20, "rakugo": 20]
        )
        let visible = TraditionGalleryView.filteredVisibleEntries(
            in: catalog, snapshot: richSnapshot
        )
        #expect(visible.map(\.slug) == ["griot"])
    }

    // MARK: - Easter-egg with unknown condition stays hidden

    @Test func easterEggWithUnknownConditionStaysHidden() {
        // A catalog with a typo'd condition string ("dep_listener" vs
        // "deep_listener") → evaluator returns false → entry hidden.
        let catalog = TraditionCatalog(
            version: 1,
            entries: [
                makeBaseEntry(slug: "griot"),
                makeEasterEgg(slug: "typo", condition: "dep_listener"),
            ]
        )
        let richSnapshot = TraditionUnlockSnapshot(
            expandedBaseTraditions: ["griot", "indigenous-american-oral-history",
                                     "seanchai", "rakugo", "slam-poetry"],
            savedTales: 99
        )
        let visible = TraditionGalleryView.filteredVisibleEntries(
            in: catalog, snapshot: richSnapshot
        )
        #expect(visible.map(\.slug) == ["griot"])
    }

    // MARK: - Multiple easter-eggs with different predicates

    @Test func multipleEasterEggsFilteredIndependently() {
        // Three easter-eggs with three different predicates. Snapshot
        // satisfies cross_mood_explorer + tradition_revisitor but NOT
        // deep_listener. Result: 2 of 3 surface.
        let catalog = TraditionCatalog(
            version: 1,
            entries: [
                makeBaseEntry(slug: "griot"),
                makeEasterEgg(slug: "deep", condition: "deep_listener"),
                makeEasterEgg(slug: "cross", condition: "cross_mood_explorer"),
                makeEasterEgg(slug: "revisit", condition: "tradition_revisitor"),
            ]
        )
        let snapshot = TraditionUnlockSnapshot(
            expandedBaseTraditions: ["griot"],            // only 1 base — deep_listener fails
            savedTales: 4,                                 // < 5 — deep_listener fails
            moodsCovered: [.funny, .scary, .tender, .wild],  // cross fires
            traditionRevisitCount: ["griot": 5, "rakugo": 3]  // revisit fires
        )
        let visible = TraditionGalleryView.filteredVisibleEntries(
            in: catalog, snapshot: snapshot
        )
        #expect(visible.map(\.slug) == ["griot", "cross", "revisit"])
    }

    // MARK: - Catalog ordering preserved

    @Test func filterPreservesCatalogOrdering() {
        // Filter must not reorder entries — base entries' authored
        // ordering carries the kid's reading-flow intent.
        let catalog = TraditionCatalog(
            version: 1,
            entries: [
                makeBaseEntry(slug: "first"),
                makeBaseEntry(slug: "second"),
                makeBaseEntry(slug: "third"),
            ]
        )
        let visible = TraditionGalleryView.filteredVisibleEntries(
            in: catalog, snapshot: TraditionUnlockSnapshot()
        )
        #expect(visible.map(\.slug) == ["first", "second", "third"])
    }

    @Test func emptyCatalogReturnsEmpty() {
        let catalog = TraditionCatalog(version: 1, entries: [])
        let visible = TraditionGalleryView.filteredVisibleEntries(
            in: catalog, snapshot: TraditionUnlockSnapshot()
        )
        #expect(visible.isEmpty)
    }

    // MARK: - Helpers

    private func makeBaseEntry(slug: String) -> TraditionEntry {
        TraditionEntry(
            slug: slug,
            displayName: "Test \(slug)",
            region: "Test region",
            summary: "Test summary",
            craftPrimitive: "test primitive",
            culturalCreditNote: "test credit",
            tier: .base
        )
    }

    private func makeEasterEgg(slug: String, condition: String) -> TraditionEntry {
        TraditionEntry(
            slug: slug,
            displayName: "Test \(slug)",
            region: "Test region",
            summary: "Test summary",
            craftPrimitive: "test primitive",
            culturalCreditNote: "test credit",
            tier: .easterEgg,
            unlockCondition: condition,
            reviewerSignoff: ReviewerSignoff(
                reviewerName: "Dr. Test",
                reviewedAt: Date(timeIntervalSince1970: 1_780_000_000),
                scope: "Test scope."
            )
        )
    }
}
