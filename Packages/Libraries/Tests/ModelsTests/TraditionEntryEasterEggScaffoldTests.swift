import Foundation
import Testing
@testable import Models

/// Coverage for the Easter Eggs Phase A schema scaffold shipped in PR-C of
/// the 2026-06-24 NINTH-round wire-up. Locks the additive Optional contract
/// (legacy JSON decodes with `nil` tier / unlockCondition / reviewerSignoff
/// per the pre-App-Store rule + the synthesized `decodeIfPresent` path), the
/// ``TraditionEntry/effectiveTier`` legacy-base interpretation, the
/// ``TraditionEntry/isEasterEgg`` convenience, and the
/// ``TraditionTier`` / ``ReviewerSignoff`` value-type shapes.
///
/// Per `@Docs/PLAN_EASTER_EGGS_TRADITION_UNLOCKS.md` § Schema additions.
@Suite("TraditionEntryEasterEggScaffold")
struct TraditionEntryEasterEggScaffoldTests {

    // MARK: - Legacy-JSON back-compat

    @Test func legacyJSONDecodesWithNilTier() throws {
        // Verbatim shape of an existing griot entry as committed in
        // traditions.json BEFORE the Phase A additions. Decoder MUST land
        // tier = nil + unlockCondition = nil + reviewerSignoff = nil.
        let legacyJSON = """
        {
            "slug": "griot",
            "displayName": "Griot",
            "region": "West Africa",
            "summary": "summary",
            "craftPrimitive": "memory + responsibility",
            "culturalCreditNote": "credit",
            "audioSampleFilename": null,
            "contentWarning": null
        }
        """.data(using: .utf8)!
        let entry = try JSONDecoder().decode(TraditionEntry.self, from: legacyJSON)
        #expect(entry.slug == "griot")
        #expect(entry.tier == nil)
        #expect(entry.unlockCondition == nil)
        #expect(entry.reviewerSignoff == nil)
        // Legacy entries are effectively base-tier.
        #expect(entry.effectiveTier == .base)
        #expect(entry.isEasterEgg == false)
    }

    @Test func minimalLegacyJSONOmittingOptionalKeys() throws {
        // Even if a legacy entry author omitted audioSampleFilename +
        // contentWarning entirely, the decoder MUST still land all Phase
        // A optionals as nil (no spurious decode errors).
        let json = """
        {
            "slug": "rakugo",
            "displayName": "Rakugo",
            "region": "Japan",
            "summary": "summary",
            "craftPrimitive": "economy + control",
            "culturalCreditNote": "credit"
        }
        """.data(using: .utf8)!
        let entry = try JSONDecoder().decode(TraditionEntry.self, from: json)
        #expect(entry.tier == nil)
        #expect(entry.unlockCondition == nil)
        #expect(entry.reviewerSignoff == nil)
    }

    // MARK: - Easter-egg JSON shape

    @Test func easterEggJSONDecodesAllFields() throws {
        let json = """
        {
            "slug": "test-easter",
            "displayName": "Test",
            "region": "Test",
            "summary": "summary",
            "craftPrimitive": "test",
            "culturalCreditNote": "credit",
            "tier": "easter_egg",
            "unlockCondition": "deep_listener",
            "reviewerSignoff": {
                "reviewerName": "Dr. Test Reviewer",
                "reviewedAt": "2026-06-24T00:00:00Z",
                "scope": "Test scope line."
            }
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entry = try decoder.decode(TraditionEntry.self, from: json)
        #expect(entry.effectiveTier == .easterEgg)
        #expect(entry.isEasterEgg)
        #expect(entry.unlockCondition == "deep_listener")
        #expect(entry.reviewerSignoff?.reviewerName == "Dr. Test Reviewer")
        #expect(entry.reviewerSignoff?.scope == "Test scope line.")
    }

    @Test func easterEggTierWithoutReviewerSignoffStillDecodes() throws {
        // Schema doesn't enforce reviewerSignoff at decode time — Phase D
        // submission gates on it. Decode MUST still succeed so the test
        // surface can exercise unlock + filter logic without reviewer
        // metadata yet.
        let json = """
        {
            "slug": "test-easter",
            "displayName": "Test",
            "region": "Test",
            "summary": "summary",
            "craftPrimitive": "test",
            "culturalCreditNote": "credit",
            "tier": "easter_egg",
            "unlockCondition": "tradition_revisitor"
        }
        """.data(using: .utf8)!
        let entry = try JSONDecoder().decode(TraditionEntry.self, from: json)
        #expect(entry.isEasterEgg)
        #expect(entry.unlockCondition == "tradition_revisitor")
        #expect(entry.reviewerSignoff == nil)
    }

    // MARK: - TraditionTier raw-value contract

    @Test func traditionTierRawValuesAreSnakeCase() {
        // Critical for JSON wire-format stability: raw values are
        // `lowercase_snake_case`. The catalog JSON authors will write
        // "easter_egg", not "easterEgg".
        #expect(TraditionTier.base.rawValue == "base")
        #expect(TraditionTier.easterEgg.rawValue == "easter_egg")
    }

    @Test func traditionTierIsCaseIterableAndHashable() {
        let allCases = TraditionTier.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.base))
        #expect(allCases.contains(.easterEgg))
        // Hashable conformance — needed for use as Set element / Dictionary key.
        let setOfTiers: Set<TraditionTier> = [.base, .easterEgg, .base]
        #expect(setOfTiers.count == 2)
    }

    // MARK: - ReviewerSignoff round-trip

    @Test func reviewerSignoffRoundTripsThroughJSON() throws {
        let signoff = ReviewerSignoff(
            reviewerName: "Dr. Example",
            reviewedAt: Date(timeIntervalSince1970: 1_780_000_000),
            scope: "Round-trip scope."
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(signoff)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ReviewerSignoff.self, from: data)
        #expect(decoded == signoff)
    }

    // MARK: - effectiveTier + isEasterEgg helpers

    @Test func effectiveTierMatchesExplicitBase() {
        let entry = makeEntry(tier: .base)
        #expect(entry.effectiveTier == .base)
        #expect(entry.isEasterEgg == false)
    }

    @Test func effectiveTierMatchesExplicitEasterEgg() {
        let entry = makeEntry(tier: .easterEgg, unlockCondition: "deep_listener")
        #expect(entry.effectiveTier == .easterEgg)
        #expect(entry.isEasterEgg)
    }

    @Test func effectiveTierTreatsNilAsBase() {
        let entry = makeEntry(tier: nil)
        #expect(entry.effectiveTier == .base)
        #expect(entry.isEasterEgg == false)
    }

    // MARK: - Encode then decode preserves Phase A fields

    @Test func encodedEntryRoundTripsAllFields() throws {
        let signoff = ReviewerSignoff(
            reviewerName: "Dr. Test",
            reviewedAt: Date(timeIntervalSince1970: 1_780_000_000),
            scope: "Encode test."
        )
        let entry = TraditionEntry(
            slug: "rt",
            displayName: "rt",
            region: "rt",
            summary: "rt",
            craftPrimitive: "rt",
            culturalCreditNote: "rt",
            tier: .easterEgg,
            unlockCondition: "cross_mood_explorer",
            reviewerSignoff: signoff
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entry)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TraditionEntry.self, from: data)
        #expect(decoded == entry)
    }

    // MARK: - Helpers

    private func makeEntry(
        tier: TraditionTier?,
        unlockCondition: String? = nil,
        reviewerSignoff: ReviewerSignoff? = nil
    ) -> TraditionEntry {
        TraditionEntry(
            slug: "test",
            displayName: "test",
            region: "test",
            summary: "test",
            craftPrimitive: "test",
            culturalCreditNote: "test",
            tier: tier,
            unlockCondition: unlockCondition,
            reviewerSignoff: reviewerSignoff
        )
    }
}
