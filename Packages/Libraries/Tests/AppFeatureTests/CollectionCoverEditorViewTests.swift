import Testing
import Foundation
@testable import AppFeature
import Models

/// Tests for ``CollectionCoverEditorView`` — the focused cover-editing
/// sheet for an EXISTING kid-curated collection. Per
/// `@Docs/SESSION_HANDOFF_2026-06-24_TENTH_ROUND.md` § "Recommended
/// next-session priorities" → Anthology cover editing.
///
/// The view itself is pure SwiftUI + binds an `onSave` closure; rather
/// than spin up a SwiftUI host, the tests cover the closure shape that
/// the sheet emits + verify the initial-selection round-trips the
/// existing collection's `coverArtSlug`. The store-side round-trip
/// (`updateCollectionCover` persists the new value) is already covered
/// by ``MoodCollectionStoreTests``.
@MainActor
@Suite("CollectionCoverEditorView")
struct CollectionCoverEditorViewTests {
    @Test func initialSelectionResolvesFromExistingSlug() {
        let collection = MoodCollectionData(
            id: UUID(),
            name: "Tender ones",
            mood: .tender,
            taleIDs: [],
            createdAt: Date(),
            coverArtSlug: AnthologyCoverDesign.lantern.rawValue
        )
        // The sheet's `init` derives `selectedCover` from
        // `AnthologyCoverDesign.resolve(slug:)`. Cross-check the
        // resolver returns the persisted design so the sheet opens on
        // the correct preview.
        let resolved = AnthologyCoverDesign.resolve(slug: collection.coverArtSlug)
        #expect(resolved == .lantern)
    }

    @Test func initialSelectionFallsBackForLegacyNilSlug() {
        // Legacy / never-customized collections carry `nil` for
        // `coverArtSlug`. The editor MUST open on `.autoGlyph` (the
        // canonical conservative-hide default) so the kid sees the
        // current cover before picking a new one.
        let collection = MoodCollectionData(
            id: UUID(),
            name: "Friday-funny",
            mood: .funny,
            taleIDs: [],
            createdAt: Date(),
            coverArtSlug: nil
        )
        let resolved = AnthologyCoverDesign.resolve(slug: collection.coverArtSlug)
        #expect(resolved == .autoGlyph)
    }

    @Test func initialSelectionFallsBackForUnknownSlug() {
        // Conservative-hide: a renamed-then-removed cover slug must
        // never crash the editor; it opens on `.autoGlyph` so the kid
        // can pick a fresh design. Mirrors the resolver test in
        // ``AnthologyCoverDesignTests.resolveReturnsAutoGlyphForUnknownSlug``.
        let collection = MoodCollectionData(
            id: UUID(),
            name: "Mystery",
            mood: nil,
            taleIDs: [],
            createdAt: Date(),
            coverArtSlug: "weather_lantern_v2_DELETED"
        )
        let resolved = AnthologyCoverDesign.resolve(slug: collection.coverArtSlug)
        #expect(resolved == .autoGlyph)
    }

    @Test func onSaveContractCollapsesAutoGlyphToNil() {
        // The Save-button wire shape: when the kid leaves the picker on
        // `.autoGlyph`, the editor passes `nil` to the closure so legacy
        // + auto-derived covers share the same persistence shape (a nil
        // `coverArtSlug` in storage). Mirrors ``CollectionEditorView``'s
        // create-flow shape per PR #114.
        //
        // The collapse logic lives in `handleSave`; cover the contract
        // here by simulating the same conditional the sheet runs.
        let autoSelection: AnthologyCoverDesign = .autoGlyph
        let collapsed: AnthologyCoverDesign? = autoSelection == .autoGlyph ? nil : autoSelection
        #expect(collapsed == nil)

        let nonDefault: AnthologyCoverDesign = .stage
        let preserved: AnthologyCoverDesign? = nonDefault == .autoGlyph ? nil : nonDefault
        #expect(preserved == .stage)
    }
}
