import Testing
import Foundation
@testable import Models

@Suite("MasteryMoment")
struct MasteryMomentTests {
    // MARK: - Derivation priority

    @Test func inauguralFiveBeatWinsHighestPriority() {
        // Even when sustained-streak + voice-variation would also qualify,
        // the inaugural five-beat tale is the lifetime recognition that
        // wins.
        let inputs = MasteryMomentInputs(
            isFiveBeatTale: true,
            priorInToleranceTaleStreak: 5,
            isCurrentTaleInTolerance: true,
            distinctNonNarratorVoices: 4,
            isInauguralFiveBeatTale: true
        )
        #expect(MasteryMoment.derive(from: inputs) == .firstFiveBeat)
    }

    @Test func sustainedStreakFiresAtThreeInARow() {
        // Current tale in tolerance + 2 prior streak = 3 in a row.
        let inputs = MasteryMomentInputs(
            isFiveBeatTale: false,
            priorInToleranceTaleStreak: 2,
            isCurrentTaleInTolerance: true,
            distinctNonNarratorVoices: 0,
            isInauguralFiveBeatTale: false
        )
        #expect(MasteryMoment.derive(from: inputs) == .sustainedArcStreak)
    }

    @Test func sustainedStreakSilentBelowThreshold() {
        // 1 prior + current = only 2 in a row — not yet a streak.
        let inputs = MasteryMomentInputs(
            isFiveBeatTale: false,
            priorInToleranceTaleStreak: 1,
            isCurrentTaleInTolerance: true,
            distinctNonNarratorVoices: 0,
            isInauguralFiveBeatTale: false
        )
        #expect(MasteryMoment.derive(from: inputs) == nil)
    }

    @Test func sustainedStreakSilentWhenCurrentBreaksStreak() {
        // Prior streak high, but current tale didn't hit ≥ 4 of 5.
        let inputs = MasteryMomentInputs(
            isFiveBeatTale: false,
            priorInToleranceTaleStreak: 5,
            isCurrentTaleInTolerance: false,
            distinctNonNarratorVoices: 0,
            isInauguralFiveBeatTale: false
        )
        #expect(MasteryMoment.derive(from: inputs) == nil)
    }

    @Test func voiceVariationMasteryAtThreshold() {
        // 3 distinct non-narrator voices — the recognition threshold.
        let inputs = MasteryMomentInputs(
            isFiveBeatTale: false,
            priorInToleranceTaleStreak: 0,
            isCurrentTaleInTolerance: false,
            distinctNonNarratorVoices: 3,
            isInauguralFiveBeatTale: false
        )
        #expect(MasteryMoment.derive(from: inputs) == .voiceVariationMastery)
    }

    @Test func voiceVariationSilentBelowThreshold() {
        // 2 voices — Phase 1.1 voice-variation reflection threshold, but
        // not the mastery-moment threshold (which is more selective).
        let inputs = MasteryMomentInputs(
            isFiveBeatTale: false,
            priorInToleranceTaleStreak: 0,
            isCurrentTaleInTolerance: false,
            distinctNonNarratorVoices: 2,
            isInauguralFiveBeatTale: false
        )
        #expect(MasteryMoment.derive(from: inputs) == nil)
    }

    @Test func neutralTaleProducesNoMoment() {
        let inputs = MasteryMomentInputs(
            isFiveBeatTale: false,
            priorInToleranceTaleStreak: 0,
            isCurrentTaleInTolerance: false,
            distinctNonNarratorVoices: 0,
            isInauguralFiveBeatTale: false
        )
        #expect(MasteryMoment.derive(from: inputs) == nil)
    }

    // MARK: - Copy anti-shame guard

    @Test func everyArchetypeCopyAvoidsShameTokens() {
        // Per `@.claude/rules/trauma-informed-content.md` § "Validate-then-
        // inform" — mastery recognition never frames the moment as
        // "finally" / "still" / "almost". Each archetype's headline + body
        // celebrates the pattern without judgment.
        let shameTokens = [
            "finally", "still", "almost", "supposed to",
            "should", "lazy", "missed", "didn't",
        ]
        for archetype in MasteryMoment.allCases {
            let combined = (archetype.headline + " " + archetype.body).lowercased()
            for token in shameTokens {
                #expect(!combined.contains(token),
                "archetype \(archetype) copy contains shame token '\(token)': \(combined)")
            }
        }
    }

    @Test func everyArchetypeHasNonEmptyCopyAndIcon() {
        for archetype in MasteryMoment.allCases {
            #expect(!archetype.headline.isEmpty)
            #expect(!archetype.body.isEmpty)
            #expect(!archetype.systemImage.isEmpty)
        }
    }

    @Test func archetypeRawValuesAreSnakeCase() {
        // Locks the analytics-friendly snake_case identifier convention
        // so future archetypes don't drift to camelCase / hyphen-case.
        for archetype in MasteryMoment.allCases {
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
}
