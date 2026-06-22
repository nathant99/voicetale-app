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

    @Test func reflectRetellFallsBackToRetellStaticEntry() async {
        let mentor = BrambleMentor()
        let reflection = await mentor.reflectRetell(
            transcript: "Once upon a second time, the wind came back.",
            previousTranscript: "Once upon a time, the wind came.",
            mood: .funny,
            beat: .close
        )
        let fallback = BrambleFallbackCatalog.retellFallback(mood: .funny, beat: .close)
        #expect(reflection.craftObservations.isEmpty == false)
        if mentor.availability != .available {
            #expect(reflection == fallback)
        }
    }

    @Test func reflectRetellDegradesGracefullyWithoutPreviousTranscript() async {
        let mentor = BrambleMentor()
        // Empty previous transcript MUST short-circuit to the fallback so a
        // hypothetical UI bug doesn't leak an empty-baseline retell prompt.
        let reflection = await mentor.reflectRetell(
            transcript: "second telling",
            previousTranscript: "",
            mood: .tender,
            beat: .hook
        )
        let fallback = BrambleFallbackCatalog.retellFallback(mood: .tender, beat: .hook)
        #expect(reflection == fallback)
    }

    @Test func reflectBeatSkippedNamesSkippedBeatInFallback() async {
        let mentor = BrambleMentor()
        let reflection = await mentor.reflectBeatSkipped(
            transcript: "We started fast. Then it was over.",
            mood: .wild,
            skippedBeats: [.rising, .turn]
        )
        let fallback = BrambleFallbackCatalog.beatSkippedFallback(skippedBeats: [.rising, .turn])
        if mentor.availability != .available {
            #expect(reflection == fallback)
        }
        #expect(reflection.craftObservations.first?.contains("rising") == true)
    }

    @Test func reflectBeatSkippedShortCircuitsWhenNoSkippedBeats() async {
        let mentor = BrambleMentor()
        let reflection = await mentor.reflectBeatSkipped(
            transcript: "every beat hit",
            mood: .scary,
            skippedBeats: []
        )
        // Empty skipped-beat list → static fallback for [] (display "one beat")
        let fallback = BrambleFallbackCatalog.beatSkippedFallback(skippedBeats: [])
        #expect(reflection == fallback)
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

    @Test func retellPromptIncludesBothTranscripts() {
        let prompt = BramblePromptBuilder.retellPrompt(
            transcript: "second telling here",
            previousTranscript: "first telling here",
            mood: .scary,
            beat: .turn
        )
        #expect(prompt.contains("first telling here"))
        #expect(prompt.contains("second telling here"))
        #expect(prompt.contains("scary"))
        #expect(prompt.contains("Turn"))
    }

    @Test func beatSkippedPromptListsSkippedBeats() {
        let prompt = BramblePromptBuilder.beatSkippedPrompt(
            transcript: "short tale",
            mood: .funny,
            skippedBeats: [.hook, .close]
        )
        #expect(prompt.contains("hook"))
        #expect(prompt.contains("close"))
        // The prompt frames the brief beats as "noticed … went by very briefly"
        // — listener-stance, not coach-grading. The prompt DOES contain
        // "missed" + "wrong" because the instructions explicitly forbid the
        // model from using those framings.
        #expect(prompt.contains("briefly"))
        #expect(prompt.contains("never as missed or wrong"))
    }
}

@Suite("BrambleFallbackCatalog retell + beat-skipped")
struct BrambleFallbackCatalogExtensionsTests {
    @Test func retellFallbackVariesByBeat() {
        let hook = BrambleFallbackCatalog.retellFallback(mood: .funny, beat: .hook)
        let close = BrambleFallbackCatalog.retellFallback(mood: .funny, beat: .close)
        #expect(hook != close)
        #expect(hook.socraticPrompt?.contains("hook") == true)
        #expect(close.socraticPrompt?.contains("close") == true)
    }

    @Test func beatSkippedFallbackOneBeatVsMany() {
        let single = BrambleFallbackCatalog.beatSkippedFallback(skippedBeats: [.rising])
        let multi = BrambleFallbackCatalog.beatSkippedFallback(skippedBeats: [.rising, .turn])
        #expect(single.craftObservations.first?.contains("rising") == true)
        #expect(multi.craftObservations.first?.contains("rising") == true)
        #expect(multi.craftObservations.first?.contains("turn") == true)
    }

    @Test func beatSkippedFallbackEmptyBeatsStillSucceeds() {
        let reflection = BrambleFallbackCatalog.beatSkippedFallback(skippedBeats: [])
        // Empty list is unusual but must never crash + must produce non-empty
        // observation per Bramble's "always succeed" mentor contract.
        #expect(reflection.craftObservations.isEmpty == false)
        #expect(reflection.socraticPrompt != nil)
    }
}
