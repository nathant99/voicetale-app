import Testing
@testable import SharedUI
import Foundation

@Suite("CastPortraitCatalog")
struct CastPortraitCatalogTests {
    @Test func slugExposesStableIdentifier() {
        #expect(CastPortraitCatalog.Slug.lean.id == "lean")
        #expect(CastPortraitCatalog.Slug.pivot.id == "pivot")
        #expect(CastPortraitCatalog.Slug.refrain.id == "refrain")
        #expect(CastPortraitCatalog.Slug.slow.id == "slow")
    }

    @Test func slugDisplayNamesAreCapitalized() {
        #expect(CastPortraitCatalog.Slug.lean.displayName == "Lean")
        #expect(CastPortraitCatalog.Slug.pivot.displayName == "Pivot")
        #expect(CastPortraitCatalog.Slug.refrain.displayName == "Refrain")
        #expect(CastPortraitCatalog.Slug.slow.displayName == "Slow")
    }

    @Test func slugInitFromStringResolvesKnownAndIgnoresUnknown() {
        #expect(CastPortraitCatalog.Slug(slug: "lean") == .lean)
        #expect(CastPortraitCatalog.Slug(slug: "pivot") == .pivot)
        #expect(CastPortraitCatalog.Slug(slug: "refrain") == .refrain)
        #expect(CastPortraitCatalog.Slug(slug: "slow") == .slow)
        // Unknown / empty / nil should all resolve to nil so the consumer
        // surfaces the fallback SF Symbol rather than crashing.
        #expect(CastPortraitCatalog.Slug(slug: nil) == nil)
        #expect(CastPortraitCatalog.Slug(slug: "") == nil)
        #expect(CastPortraitCatalog.Slug(slug: "unknown") == nil)
        #expect(CastPortraitCatalog.Slug(slug: "LEAN") == nil, "Slugs are case-sensitive — must match the chapter MD filename exactly")
    }

    @Test func portraitURLResolvesAllFourSlugs() throws {
        // All four WebPs were copied into SharedUI/Resources/Cast/ by the
        // PR-2 wiring step; the bundle must surface each via the catalog so
        // the BrambleReflectionView cast-voicing chip renders the portrait
        // instead of the SF Symbol fallback. Per R-CAST-PORTRAIT-SLUG.
        for slug in CastPortraitCatalog.Slug.allCases {
            let url = try #require(
                CastPortraitCatalog.portraitURL(for: slug),
                "Missing portrait WebP for slug \(slug.rawValue) — verify Resources/Cast/\(slug.rawValue).webp landed in the SharedUI bundle"
            )
            #expect(FileManager.default.fileExists(atPath: url.path))
            #expect(url.lastPathComponent == "\(slug.rawValue).webp")
        }
    }

    @Test func availablePortraitsListsAllFourInCanonicalOrder() throws {
        let portraits = CastPortraitCatalog.availablePortraits()
        #expect(portraits.count == 4)
        // Canonical order matches Slug.allCases — Lean / Pivot / Refrain / Slow.
        #expect(portraits[0].slug == .lean)
        #expect(portraits[1].slug == .pivot)
        #expect(portraits[2].slug == .refrain)
        #expect(portraits[3].slug == .slow)
    }
}
