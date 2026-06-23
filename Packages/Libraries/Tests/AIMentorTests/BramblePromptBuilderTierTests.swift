import Testing
import Foundation
@testable import AIMentor

@Suite("BramblePromptBuilder DDA tier")
struct BramblePromptBuilderTierTests {
    @Test func legacyStaticInstructionsMatchStandardTier() {
        let legacy = BramblePromptBuilder.instructions
        let standard = BramblePromptBuilder.instructions(for: .standard)
        #expect(legacy == standard)
    }

    @Test func gentleTierFramesFollowUpAsWonder() {
        let body = BramblePromptBuilder.instructions(for: .gentle)
        #expect(body.contains("I wonder"))
    }

    @Test func deepTierAsksForTwoObservations() {
        let body = BramblePromptBuilder.instructions(for: .deep)
        #expect(body.contains("TWO short observations"))
    }

    @Test func everyTierShipsTheBaselineSafetyClause() {
        // The baseline distress-signal clause MUST survive every tier
        // variant. Per `@.claude/rules/trauma-informed-content.md` §
        // "Validate-then-inform" + "refer up": the talking-to-an-adult
        // line is load-bearing safety copy, not a per-tier choice.
        for tier in BramblePromptBuilder.DifficultyTier.allCases {
            let body = BramblePromptBuilder.instructions(for: tier)
            #expect(body.contains("distress signals"),
                    "Tier \(tier) missing the baseline distress-signal clause")
            #expect(body.contains("trusted adult"),
                    "Tier \(tier) missing the trusted-adult referral")
        }
    }

    @Test func tierBodiesAreDistinct() {
        let gentle = BramblePromptBuilder.instructions(for: .gentle)
        let standard = BramblePromptBuilder.instructions(for: .standard)
        let deep = BramblePromptBuilder.instructions(for: .deep)
        #expect(gentle != standard)
        #expect(standard != deep)
        #expect(gentle != deep)
    }
}

@MainActor
@Suite("BrambleMentor tier wiring")
struct BrambleMentorTierTests {
    @Test func newMentorDefaultsToStandardTier() {
        let mentor = BrambleMentor()
        #expect(mentor.activeTier == .standard)
    }

    @Test func setTierUpdatesActiveTier() {
        let mentor = BrambleMentor()
        mentor.setTier(.gentle)
        #expect(mentor.activeTier == .gentle)
    }

    @Test func setTierIsIdempotent() {
        let mentor = BrambleMentor()
        mentor.setTier(.deep)
        // Repeating the same tier is a no-op + must not crash. Cheap
        // safety check that ensures the guard short-circuit holds.
        mentor.setTier(.deep)
        #expect(mentor.activeTier == .deep)
    }
}
