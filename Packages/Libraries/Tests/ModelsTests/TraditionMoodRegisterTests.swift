import Foundation
import Testing
@testable import Models

/// Coverage for the within-session tradition-echo helpers shipped in PR-B of
/// the 2026-06-24 NINTH-round wire-up: ``VoiceTaleMood.registerSlug`` +
/// ``TraditionEntry.moodRegisterSlugs(forSlug:)``. Both fuel
/// ``SessionTallyTracker.traditionEchoEligible(for:)`` (tested separately in
/// AppFeatureTests) which in turn drives the
/// ``SurpriseMoment.traditionEchoSameSession`` archetype.
@Suite("TraditionMoodRegister")
struct TraditionMoodRegisterTests {

    // MARK: - VoiceTaleMood.registerSlug

    @Test func everyMoodRegisterSlugIsLowercaseRawValue() {
        for mood in VoiceTaleMood.allCases {
            #expect(mood.registerSlug == mood.rawValue)
            #expect(mood.registerSlug == mood.registerSlug.lowercased())
        }
    }

    @Test func moodRegisterSlugsAreUniqueAcrossMoods() {
        let slugs = Set(VoiceTaleMood.allCases.map(\.registerSlug))
        #expect(slugs.count == VoiceTaleMood.allCases.count)
    }

    // MARK: - TraditionEntry.moodRegisterSlugs(forSlug:)

    @Test func griotMapsToTenderRegister() {
        #expect(TraditionEntry.moodRegisterSlugs(forSlug: "griot") == ["tender"])
    }

    @Test func indigenousAmericanMapsToTenderRegister() {
        #expect(
            TraditionEntry.moodRegisterSlugs(forSlug: "indigenous-american-oral-history")
                == ["tender"]
        )
    }

    @Test func seanchaiMapsToFunnyAndWildRegisters() {
        let slugs = TraditionEntry.moodRegisterSlugs(forSlug: "seanchai")
        #expect(slugs == ["funny", "wild"])
    }

    @Test func rakugoMapsToScaryRegister() {
        #expect(TraditionEntry.moodRegisterSlugs(forSlug: "rakugo") == ["scary"])
    }

    @Test func slamPoetryMapsToWildRegister() {
        #expect(TraditionEntry.moodRegisterSlugs(forSlug: "slam-poetry") == ["wild"])
    }

    @Test func unknownSlugReturnsEmptySet() {
        #expect(TraditionEntry.moodRegisterSlugs(forSlug: "unknown-tradition").isEmpty)
        #expect(TraditionEntry.moodRegisterSlugs(forSlug: "").isEmpty)
    }

    @Test func everyMappedSlugUsesCanonicalMoodRegisterTokens() {
        // Every register slug a tradition maps to MUST be one of the four
        // canonical VoiceTaleMood register slugs — drift-resistant.
        let canonical = Set(VoiceTaleMood.allCases.map(\.registerSlug))
        let mappedSlugs = ["griot", "indigenous-american-oral-history",
                           "seanchai", "rakugo", "slam-poetry"]
        for slug in mappedSlugs {
            let registers = TraditionEntry.moodRegisterSlugs(forSlug: slug)
            #expect(registers.isEmpty == false, "expected \(slug) to map to ≥1 register")
            #expect(registers.isSubset(of: canonical),
                    "tradition \(slug) maps to non-canonical register: \(registers)")
        }
    }

    @Test func entryComputedPropertyMatchesStaticHelper() {
        let entry = TraditionEntry(
            slug: "rakugo",
            displayName: "test",
            region: "test",
            summary: "test",
            craftPrimitive: "test",
            culturalCreditNote: "test"
        )
        #expect(entry.moodRegisterSlugs == TraditionEntry.moodRegisterSlugs(forSlug: "rakugo"))
    }
}
