import Testing
@testable import AppFeature

/// Coverage for the pure-function copy helpers on ``SessionCloserView``.
/// The recap view itself is a SwiftUI surface that's tested visually via
/// XCUITest; this suite locks the Bramble-grandmother register on the
/// stringified outputs so the recap never scolds a "zero tales" sitting.
@Suite("SessionCloserView.Copy")
struct SessionCloserViewTests {
    @Test func openingLineForZeroTalesHonorsTheSilentSitting() {
        let line = SessionCloserView.openingLine(for: 0)
        // Per `@.claude/rules/trauma-informed-content.md` § "anti-shame"
        // register — never call out the kid for NOT telling a tale.
        let lowered = line.lowercased()
        #expect(lowered.contains("counts") || lowered.contains("here"))
        // Must NOT contain shame-coded vocabulary.
        let shameTokens = ["didn't", "no tale", "missed", "lazy", "skipped"]
        for token in shameTokens {
            #expect(line.lowercased().contains(token) == false,
                    "Opening line shouldn't shame zero-tale sittings; found \"\(token)\"")
        }
    }

    @Test func openingLineForOneTaleNamesTheSpecific() {
        let line = SessionCloserView.openingLine(for: 1)
        #expect(line.lowercased().contains("one"))
    }

    @Test func openingLineForManyTalesEscalatesWarmly() {
        let line4 = SessionCloserView.openingLine(for: 4)
        #expect(line4.lowercased().contains("armful") || line4.lowercased().contains("full"))
    }

    @Test func taleCountPhraseHandlesEdgeCases() {
        #expect(SessionCloserView.taleCountPhrase(0) == "No tales saved this sitting")
        #expect(SessionCloserView.taleCountPhrase(1) == "One tale saved this sitting")
        #expect(SessionCloserView.taleCountPhrase(7) == "7 tales saved this sitting")
    }

    @Test func streakPhraseHonorsFreshStart() {
        let line = SessionCloserView.streakPhrase(days: 0)
        #expect(line.lowercased().contains("fresh"))
    }

    @Test func streakPhraseEscalatesAcrossThresholds() {
        let one = SessionCloserView.streakPhrase(days: 1)
        let three = SessionCloserView.streakPhrase(days: 3)
        let many = SessionCloserView.streakPhrase(days: 12)
        #expect(one != three)
        #expect(three != many)
        // Escalation must include the literal day count for ≥ 3 days so
        // VoiceOver reads back the milestone the kid is at.
        #expect(three.contains("3"))
        #expect(many.contains("12"))
    }
}
