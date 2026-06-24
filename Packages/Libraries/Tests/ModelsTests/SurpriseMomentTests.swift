import Testing
import Foundation
@testable import Models

@Suite("SurpriseMoment")
struct SurpriseMomentTests {
    // MARK: - Derivation priority

    @Test func firstNewMoodWinsHighestPriority() {
        // Even when voice-preset-fresh and tradition-echo would also
        // qualify, the first-new-mood archetype is the most emotionally
        // legible and wins.
        let inputs = SurpriseMomentInputs(
            todayMood: .scary,
            moodsEverTold: [.funny, .tender],
            traditionEchoEligibleThisSession: true,
            todayPresets: ["narrator", "hero"],
            priorNonNarratorPresets: []
        )
        #expect(SurpriseMoment.derive(from: inputs) == .firstNewMoodExplored)
    }

    @Test func firstNewMoodSilentForBrandNewKid() {
        // A kid who has never told a tale (moodsEverTold is empty)
        // doesn't get a "fresh mood" surprise — the recognition lives
        // at the EDGE of an existing pattern.
        let inputs = SurpriseMomentInputs(
            todayMood: .funny,
            moodsEverTold: [],
            traditionEchoEligibleThisSession: false,
            todayPresets: ["narrator"],
            priorNonNarratorPresets: []
        )
        #expect(SurpriseMoment.derive(from: inputs) == nil)
    }

    @Test func firstNewMoodSilentWhenMoodIsKnown() {
        // Kid has told funny tales before; today's funny tale doesn't
        // trigger the surprise.
        let inputs = SurpriseMomentInputs(
            todayMood: .funny,
            moodsEverTold: [.funny, .tender],
            traditionEchoEligibleThisSession: false,
            todayPresets: ["narrator"],
            priorNonNarratorPresets: []
        )
        #expect(SurpriseMoment.derive(from: inputs) == nil)
    }

    @Test func voicePresetFreshUseFiresOnFirstNonNarrator() {
        // Kid used a hero preset today; has never used any non-narrator
        // preset before. Their mood is known (no new-mood priority
        // takeover).
        let inputs = SurpriseMomentInputs(
            todayMood: .funny,
            moodsEverTold: [.funny],
            traditionEchoEligibleThisSession: false,
            todayPresets: ["narrator", "hero"],
            priorNonNarratorPresets: []
        )
        #expect(SurpriseMoment.derive(from: inputs) == .voicePresetFreshUse)
    }

    @Test func voicePresetFreshUseSilentAfterFirstEncounter() {
        // Kid has used a hero preset before — the surprise is spent.
        let inputs = SurpriseMomentInputs(
            todayMood: .funny,
            moodsEverTold: [.funny],
            traditionEchoEligibleThisSession: false,
            todayPresets: ["narrator", "sage"],
            priorNonNarratorPresets: ["hero"]
        )
        #expect(SurpriseMoment.derive(from: inputs) == nil)
    }

    @Test func voicePresetFreshUseSilentWhenOnlyNarrator() {
        // Kid used only the narrator preset today — no fresh non-
        // narrator to recognize.
        let inputs = SurpriseMomentInputs(
            todayMood: .funny,
            moodsEverTold: [.funny],
            traditionEchoEligibleThisSession: false,
            todayPresets: ["narrator"],
            priorNonNarratorPresets: []
        )
        #expect(SurpriseMoment.derive(from: inputs) == nil)
    }

    @Test func traditionEchoFiresWhenEligible() {
        // Mood is known + voice-preset history is full; only the
        // tradition-echo archetype qualifies.
        let inputs = SurpriseMomentInputs(
            todayMood: .funny,
            moodsEverTold: [.funny, .scary],
            traditionEchoEligibleThisSession: true,
            todayPresets: ["narrator"],
            priorNonNarratorPresets: ["hero", "sage"]
        )
        #expect(SurpriseMoment.derive(from: inputs) == .traditionEchoSameSession)
    }

    @Test func neutralTaleProducesNoMoment() {
        let inputs = SurpriseMomentInputs(
            todayMood: .funny,
            moodsEverTold: [.funny],
            traditionEchoEligibleThisSession: false,
            todayPresets: ["narrator"],
            priorNonNarratorPresets: ["hero"]
        )
        #expect(SurpriseMoment.derive(from: inputs) == nil)
    }

    // MARK: - Copy anti-shame guard

    @Test func everyArchetypeCopyAvoidsShameTokens() {
        // Per `@.claude/rules/trauma-informed-content.md` § "Validate-
        // then-inform" — surprise recognition never frames the absence
        // of variety as deficient. Each archetype's copy celebrates the
        // PRESENCE of the fresh pattern.
        let shameTokens = [
            "finally", "still", "always", "never tried",
            "should", "lazy", "missed", "didn't", "again",
            "supposed to",
        ]
        for archetype in SurpriseMoment.allCases {
            let combined = (archetype.headline + " " + archetype.body).lowercased()
            for token in shameTokens {
                #expect(!combined.contains(token),
                "archetype \(archetype) copy contains shame token '\(token)': \(combined)")
            }
        }
    }

    @Test func everyArchetypeHasNonEmptyCopyAndIcon() {
        for archetype in SurpriseMoment.allCases {
            #expect(!archetype.headline.isEmpty)
            #expect(!archetype.body.isEmpty)
            #expect(!archetype.systemImage.isEmpty)
        }
    }

    @Test func archetypeRawValuesAreSnakeCase() {
        for archetype in SurpriseMoment.allCases {
            let raw = archetype.rawValue
            #expect(!raw.isEmpty)
            #expect(raw == raw.lowercased(),
            "raw value should be lowercase: \(raw)")
            #expect(!raw.contains(" "),
            "raw value should not contain spaces: \(raw)")
            #expect(!raw.contains("-"),
            "raw value should use underscores not hyphens: \(raw)")
        }
    }

    @Test func narratorSlugIsLowercaseConstant() {
        // The narrator-slug constant is shared with VoiceCharacterCatalog
        // and used by the derivation function to exclude the default
        // preset from the "fresh non-narrator" check. Lock the spelling.
        #expect(SurpriseMoment.narratorSlug == "narrator")
    }
}
