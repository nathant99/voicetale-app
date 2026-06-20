import Testing
@testable import AIMentor
import Models

@Suite("BrambleMentor")
struct BrambleMentorTests {
    @Test func staticFallbackForFunnyHook() {
        let mentor = BrambleMentor()
        let reflection = mentor.staticFallback(for: .funny, beat: .hook)
        #expect(reflection.craftObservations.isEmpty == false)
        #expect(reflection.socraticPrompt != nil)
    }

    @Test func staticFallbackCoversAllMoodBeatCombinations() {
        let mentor = BrambleMentor()
        for mood in VoiceTaleMood.allCases {
            for beat in ArcBeat.allCases {
                let reflection = mentor.staticFallback(for: mood, beat: beat)
                #expect(reflection.craftObservations.isEmpty == false, "Missing fallback for \(mood) × \(beat)")
            }
        }
    }
}
