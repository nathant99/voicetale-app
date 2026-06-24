import Testing
import Foundation
@testable import Models

@Suite("AnthologyCoverDesign")
struct AnthologyCoverDesignTests {
    // MARK: - Slug stability (wire format)

    @Test func rawValuesAreStableForPersistence() {
        // Locks the raw values — these are the persisted slugs on
        // PersistentMoodCollection.coverArtSlug. Reordering / renaming
        // a case must NOT silently change the persistence wire format.
        #expect(AnthologyCoverDesign.autoGlyph.rawValue == "auto_glyph")
        #expect(AnthologyCoverDesign.concentric.rawValue == "concentric")
        #expect(AnthologyCoverDesign.quilt.rawValue == "quilt")
        #expect(AnthologyCoverDesign.lantern.rawValue == "lantern")
        #expect(AnthologyCoverDesign.stage.rawValue == "stage")
    }

    @Test func everyCaseHasDistinctRawValue() {
        let raws = Set(AnthologyCoverDesign.allCases.map(\.rawValue))
        #expect(raws.count == AnthologyCoverDesign.allCases.count,
                "duplicate raw values would break persistence resolution")
    }

    // MARK: - resolve(slug:) — conservative fallback

    @Test func resolveNilSlugReturnsAutoGlyph() {
        #expect(AnthologyCoverDesign.resolve(slug: nil) == .autoGlyph)
    }

    @Test func resolveUnknownSlugReturnsAutoGlyph() {
        // Conservative fallback: a renamed-then-removed slug never crashes
        // the gallery — same pattern as TraditionUnlockEvaluator's
        // unknown-identifier handling (PR #107).
        #expect(AnthologyCoverDesign.resolve(slug: "weather_lantern_v2_DELETED") == .autoGlyph)
        #expect(AnthologyCoverDesign.resolve(slug: "") == .autoGlyph)
    }

    @Test func everyKnownSlugRoundTripsThroughResolve() {
        for design in AnthologyCoverDesign.allCases {
            #expect(AnthologyCoverDesign.resolve(slug: design.rawValue) == design,
                    "slug \(design.rawValue) failed round-trip")
        }
    }

    // MARK: - coverTitle helpers

    @Test func coverTitleTrimsAndCaps() {
        #expect(AnthologyCoverDesign.coverTitle(forCollectionName: "Bedtime spooks") == "Bedtime spooks")
        // 24-char cap matches PR #109's certificate headline cap.
        let longName = String(repeating: "x", count: 40)
        let result = AnthologyCoverDesign.coverTitle(forCollectionName: longName)
        #expect(result.count == 24)
    }

    @Test func coverTitleFallsBackForEmpty() {
        // Anti-shame: never blank. The fallback "Tales" reads warm.
        #expect(AnthologyCoverDesign.coverTitle(forCollectionName: "") == "Tales")
        #expect(AnthologyCoverDesign.coverTitle(forCollectionName: "   ") == "Tales")
        #expect(AnthologyCoverDesign.coverTitle(forCollectionName: "\n\t") == "Tales")
    }

    // MARK: - coverSubtitle helpers

    @Test func coverSubtitleFromFirstTale() {
        #expect(AnthologyCoverDesign.coverSubtitle(firstTaleTitle: "The Whisper") == "The Whisper")
    }

    @Test func coverSubtitleCapsLongTitlesWithEllipsis() {
        let longTitle = String(repeating: "A", count: 50)
        let result = AnthologyCoverDesign.coverSubtitle(firstTaleTitle: longTitle)
        #expect(result.hasSuffix("…"))
        #expect(result.count == 29)  // 28-char prefix + 1-char ellipsis
    }

    @Test func coverSubtitleFallsBackForNilOrEmpty() {
        // Anti-shame: empty collections still read warm.
        let nilSubtitle = AnthologyCoverDesign.coverSubtitle(firstTaleTitle: nil)
        let emptySubtitle = AnthologyCoverDesign.coverSubtitle(firstTaleTitle: "")
        let whitespaceSubtitle = AnthologyCoverDesign.coverSubtitle(firstTaleTitle: "   ")
        #expect(nilSubtitle == "Held by your collection")
        #expect(emptySubtitle == "Held by your collection")
        #expect(whitespaceSubtitle == "Held by your collection")
    }

    // MARK: - Codable round-trip

    @Test func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for design in AnthologyCoverDesign.allCases {
            let data = try encoder.encode(design)
            let decoded = try decoder.decode(AnthologyCoverDesign.self, from: data)
            #expect(decoded == design)
        }
    }

    @Test func legacyJsonDecodesToDefaultWhenSlugIsNil() throws {
        // Pre-PR-C collections may have been encoded without
        // coverArtSlug. MoodCollectionData's Codable synthesis uses
        // decodeIfPresent for the Optional — confirm a JSON shape
        // missing coverArtSlug decodes cleanly.
        let legacyJson = """
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "name": "Legacy",
            "taleIDs": [],
            "createdAt": -978307200
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MoodCollectionData.self, from: legacyJson)
        #expect(decoded.coverArtSlug == nil)
        // Resolves to autoGlyph downstream — the conservative default.
        #expect(AnthologyCoverDesign.resolve(slug: decoded.coverArtSlug) == .autoGlyph)
    }
}
