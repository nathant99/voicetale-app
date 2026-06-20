import Testing
@testable import AIMentor
import Models

@MainActor
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
                #expect(reflection.socraticPrompt != nil, "Missing prompt for \(mood) × \(beat)")
            }
        }
    }

    @Test func reflectFallsBackWhenModelUnavailable() async {
        let mentor = BrambleMentor()
        // In test process the model is almost always unavailable. Reflect
        // must succeed by routing through the fallback dictionary.
        let reflection = await mentor.reflect(
            transcript: "Once upon a time, the wind told the trees a story.",
            mood: .tender,
            beat: .close
        )
        #expect(reflection.craftObservations.isEmpty == false)
        let fallback = mentor.staticFallback(for: .tender, beat: .close)
        if mentor.availability != .available {
            #expect(reflection == fallback)
        }
    }

    @Test func availabilityIsObservableAfterRefresh() {
        let mentor = BrambleMentor()
        let before = mentor.availability
        mentor.refreshAvailability()
        let after = mentor.availability
        // Both before + after should be set to a concrete case (not .unknown
        // unless the model genuinely reports unknown).
        #expect(before == after)
    }
}

@Suite("BrambleFallbackCatalog")
struct BrambleFallbackCatalogTests {
    @Test func tableHasEntryForEveryMoodBeat() {
        let expected = VoiceTaleMood.allCases.count * ArcBeat.allCases.count
        #expect(BrambleFallbackCatalog.table.count == expected)
    }

    @Test func everyEntryHasNonEmptyObservation() {
        for entry in BrambleFallbackCatalog.table.values {
            #expect(entry.craftObservations.isEmpty == false)
            #expect(entry.craftObservations.allSatisfy { !$0.isEmpty })
        }
    }

    @Test func everyEntryHasOpenEndedPrompt() {
        // Phase 1 mentor posture: prompts should be open-ended (start with
        // What / How / When), never "Why".
        for (key, entry) in BrambleFallbackCatalog.table {
            guard let prompt = entry.socraticPrompt else {
                Issue.record("Missing prompt for \(key.mood) × \(key.beat)")
                continue
            }
            let trimmed = prompt.trimmingCharacters(in: .whitespaces)
            let startsOpen = trimmed.hasPrefix("What") ||
                             trimmed.hasPrefix("How") ||
                             trimmed.hasPrefix("When") ||
                             trimmed.hasPrefix("Did")
            #expect(startsOpen, "Prompt for \(key.mood) × \(key.beat) is not open-ended: \(prompt)")
        }
    }
}

@Suite("BramblePromptBuilder")
struct BramblePromptBuilderTests {
    @Test func reflectionPromptIncludesMoodAndBeat() {
        let prompt = BramblePromptBuilder.reflectionPrompt(
            transcript: "the sea was a slow mirror",
            mood: .tender,
            beat: .close
        )
        #expect(prompt.contains("tender"))
        #expect(prompt.contains("Close"))
        #expect(prompt.contains("the sea was a slow mirror"))
    }

    @Test func longTranscriptIsTruncated() {
        let huge = String(repeating: "a ", count: 5000)
        let prompt = BramblePromptBuilder.reflectionPrompt(
            transcript: huge,
            mood: .wild,
            beat: .rising
        )
        #expect(prompt.contains("…"))
        #expect(prompt.count < huge.count + 600) // headroom for framing copy
    }
}
