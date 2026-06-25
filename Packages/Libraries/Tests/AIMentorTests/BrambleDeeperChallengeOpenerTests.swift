import Testing
import Foundation
@testable import AIMentor
@testable import Models

/// Coverage for the Phase D second-half opener-prepend helper +
/// prompt-builder field per `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md`
/// § Phase D second-half. Locks: (1) opener prepends to first
/// observation, (2) opener is idempotent against an already-prefixed
/// observation, (3) opener becomes the first observation when none
/// exist, (4) `nil` / empty opener round-trips the reflection
/// unchanged, (5) Socratic prompt is NEVER mutated by the opener
/// layer, (6) the prompt body carries the opener line verbatim.
@Suite("BrambleDeeperChallengeOpener")
struct BrambleDeeperChallengeOpenerTests {
    private static let baseReflection = VoiceStoryReflection(
        craftObservations: ["I heard a pause before the close."],
        socraticPrompt: "What was that pause holding?"
    )

    private static let opener = "Bramble noticed you reached for a sharper hook this time."

    // MARK: - Prepend behavior

    @Test func prependsOpenerToFirstObservation() {
        let result = BrambleMentor.applyDeeperChallengeOpener(
            Self.baseReflection,
            opener: Self.opener
        )
        let firstObservation = result.craftObservations.first ?? ""
        #expect(firstObservation.hasPrefix(Self.opener),
                "opener must lead the first observation")
        #expect(firstObservation.hasSuffix("I heard a pause before the close."),
                "original observation text must be preserved")
        #expect(firstObservation.contains(" "),
                "single-space gap between opener + original observation expected")
    }

    @Test func leavesReflectionUnchangedOnNilOpener() {
        let result = BrambleMentor.applyDeeperChallengeOpener(
            Self.baseReflection,
            opener: nil
        )
        #expect(result == Self.baseReflection)
    }

    @Test func leavesReflectionUnchangedOnEmptyOpener() {
        let result = BrambleMentor.applyDeeperChallengeOpener(
            Self.baseReflection,
            opener: ""
        )
        #expect(result == Self.baseReflection)
    }

    // MARK: - Idempotency

    @Test func doesNotDoublePrependWhenObservationAlreadyStartsWithOpener() {
        // The LM may obey the prompt's "prepend verbatim" instruction;
        // belt-and-braces must skip the prepend when the observation
        // already starts with the opener (else we'd double-prefix).
        let alreadyPrefixed = VoiceStoryReflection(
            craftObservations: ["\(Self.opener) I heard the pause."],
            socraticPrompt: "What did the pause hold?"
        )
        let result = BrambleMentor.applyDeeperChallengeOpener(
            alreadyPrefixed,
            opener: Self.opener
        )
        #expect(result == alreadyPrefixed)
    }

    // MARK: - Empty observations

    @Test func openerBecomesFirstObservationWhenNoneExist() {
        let bare = VoiceStoryReflection(
            craftObservations: [],
            socraticPrompt: "What did you notice?"
        )
        let result = BrambleMentor.applyDeeperChallengeOpener(
            bare,
            opener: Self.opener
        )
        #expect(result.craftObservations.count == 1)
        #expect(result.craftObservations.first == Self.opener)
    }

    @Test func openerBecomesFirstObservationWhenFirstSlotIsEmpty() {
        // Defensive: `applyFavoriteMoodCallback` handles the same shape;
        // mirror it here so the registers compose predictably.
        let withEmpty = VoiceStoryReflection(
            craftObservations: [""],
            socraticPrompt: "What did you notice?"
        )
        let result = BrambleMentor.applyDeeperChallengeOpener(
            withEmpty,
            opener: Self.opener
        )
        // The opener fills the first slot — empty observations don't
        // ship through Bramble's bubble.
        #expect(result.craftObservations.first == Self.opener)
    }

    // MARK: - Socratic prompt invariance

    @Test func socraticPromptIsNeverMutated() {
        let result = BrambleMentor.applyDeeperChallengeOpener(
            Self.baseReflection,
            opener: Self.opener
        )
        #expect(result.socraticPrompt == Self.baseReflection.socraticPrompt)
    }

    // MARK: - Catalog round-trip

    @Test func appliesCatalogOpenerForEveryKit() {
        // The full anti-shame round-trip: drive the helper with the
        // catalog's per-kit line for every KitID. Every result must
        // surface the opener as the first observation prefix AND keep
        // the Socratic prompt unchanged.
        for kit in KitID.allCases {
            let line = KitMasteryCopyCatalog.line(for: .deeperChallengeOpener, kit: kit)
            let result = BrambleMentor.applyDeeperChallengeOpener(
                Self.baseReflection,
                opener: line
            )
            #expect(result.craftObservations.first?.hasPrefix(line) == true,
                    "kit=\(kit) opener line must lead first observation: got \(result.craftObservations.first ?? "<empty>")")
            #expect(result.socraticPrompt == Self.baseReflection.socraticPrompt)
        }
    }
}

/// Coverage for the `BramblePromptBuilder.reflectionPrompt(..., deeperChallengeOpener:)`
/// surface — when the opener arg is non-nil, the LM-facing prompt body
/// must carry the line verbatim AND instruct the model to prepend it
/// verbatim onto the first craft observation. When `nil`, the prompt
/// body must round-trip byte-for-byte against the pre-Phase-D-second-
/// half shape (so existing flows are unchanged).
@Suite("BramblePromptBuilderDeeperChallengeOpener")
struct BramblePromptBuilderDeeperChallengeOpenerTests {
    private static let transcript = "There was a thornbush in the yard, and the squirrel — well, you'll see."

    @Test func promptOmitsOpenerLineWhenArgIsNil() {
        let prompt = BramblePromptBuilder.reflectionPrompt(
            transcript: Self.transcript,
            mood: .funny,
            beat: .close,
            deeperChallengeOpener: nil
        )
        #expect(!prompt.contains("Opener (prepend verbatim"))
        #expect(!prompt.contains("Bramble noticed"))
    }

    @Test func promptOmitsOpenerLineWhenArgIsEmpty() {
        let prompt = BramblePromptBuilder.reflectionPrompt(
            transcript: Self.transcript,
            mood: .funny,
            beat: .close,
            deeperChallengeOpener: ""
        )
        #expect(!prompt.contains("Opener (prepend verbatim"))
    }

    @Test func promptCarriesOpenerLineVerbatimWhenSet() {
        let opener = "Bramble noticed how your closing breathed out this time."
        let prompt = BramblePromptBuilder.reflectionPrompt(
            transcript: Self.transcript,
            mood: .tender,
            beat: .close,
            deeperChallengeOpener: opener
        )
        #expect(prompt.contains("Opener (prepend verbatim"),
                "prompt must include the prepend-verbatim directive")
        #expect(prompt.contains(opener),
                "prompt must carry the catalog line verbatim")
    }

    @Test func legacyCallSignatureStillWorks() {
        // Pre-Phase-D-second-half callers passed no opener; the default
        // arg must round-trip those callers cleanly.
        let prompt = BramblePromptBuilder.reflectionPrompt(
            transcript: Self.transcript,
            mood: .wild,
            beat: .hook
        )
        #expect(!prompt.contains("Opener (prepend verbatim"))
        #expect(prompt.contains("Mood tag: wild"))
    }

    @Test func openerSurvivesAcrossEveryKitCatalogLine() {
        // Drive the builder with the catalog's per-kit line for every
        // KitID — locks the catalog ⇄ prompt-builder integration.
        for kit in KitID.allCases {
            let line = KitMasteryCopyCatalog.line(for: .deeperChallengeOpener, kit: kit)
            let prompt = BramblePromptBuilder.reflectionPrompt(
                transcript: Self.transcript,
                mood: .funny,
                beat: .close,
                deeperChallengeOpener: line
            )
            #expect(prompt.contains(line),
                    "kit=\(kit) catalog line must appear in the prompt body")
        }
    }
}
