import Testing
import Foundation
@testable import AIMentor
import Models

@Suite("DistressSignalDetector")
struct DistressSignalDetectorTests {
    @Test func emptyTranscriptIsNeutral() {
        #expect(DistressSignalDetector.detect(in: "") == nil)
    }

    @Test func neutralTaleIsNotFlagged() {
        let transcript = """
        And the dragon flew over the kitchen and ate my pancake and Mom laughed
        and the cat looked surprised and then it was bedtime.
        """
        #expect(DistressSignalDetector.detect(in: transcript) == nil)
    }

    @Test func selfHarmKeywordIsDetected() {
        #expect(DistressSignalDetector.detect(in: "I want to die sometimes") == .selfHarm)
        #expect(DistressSignalDetector.detect(in: "I would hurt myself") == .selfHarm)
        #expect(DistressSignalDetector.detect(in: "I keep thinking about suicide") == .selfHarm)
    }

    @Test func abuseKeywordIsDetected() {
        #expect(DistressSignalDetector.detect(in: "He hits me when I get home") == .abuse)
        #expect(DistressSignalDetector.detect(in: "Someone touched me without asking") == .abuse)
    }

    @Test func lossKeywordIsDetected() {
        #expect(DistressSignalDetector.detect(in: "My grandma died last summer") == .loss)
        #expect(DistressSignalDetector.detect(in: "We went to the funeral") == .loss)
        #expect(DistressSignalDetector.detect(in: "I lost my dad two years ago") == .loss)
    }

    @Test func wordBoundariesPreventFalsePositive() {
        // "deadline" must not trigger the loss axis ("died" / "buried" etc.).
        // "abuser" is intentionally a sub-string match — leave coverage on
        // explicit keyword matches only.
        #expect(DistressSignalDetector.detect(in: "I missed the deadline for the project") == nil)
        // "scarier" should NOT trigger abuse via "scares" — the keyword is
        // "scares me at home" which requires the phrase.
        #expect(DistressSignalDetector.detect(in: "It was scarier than I expected") == nil)
    }

    @Test func selfHarmGatesAbuseAndLoss() {
        // When multiple axes match, self-harm wins per the gating order.
        let transcript = "My grandma died and I wish I were dead too"
        #expect(DistressSignalDetector.detect(in: transcript) == .selfHarm)
    }

    @Test func everyAxisHasHoldSpaceFraming() {
        for axis in DistressSignalDetector.Axis.allCases {
            #expect(axis.holdSpaceFraming.isEmpty == false)
            #expect(axis.referUpPrompt.isEmpty == false)
            // Refer-up MUST mention a trusted grown-up OR point to a list.
            let refersUp = axis.referUpPrompt.lowercased().contains("grown-up")
                || axis.referUpPrompt.lowercased().contains("list")
                || axis.referUpPrompt.lowercased().contains("trusted")
            #expect(refersUp, "axis=\(axis) referUpPrompt must mention refer-up affordance")
        }
    }
}

@Suite("BrambleFallbackCatalog hold-space")
struct BrambleHoldSpaceFallbackTests {
    @Test func holdSpaceFallbackUsesAxisFraming() {
        let reflection = BrambleFallbackCatalog.holdSpaceFallback(axis: .loss)
        #expect(reflection.craftObservations.first == DistressSignalDetector.Axis.loss.holdSpaceFraming)
        #expect(reflection.socraticPrompt == DistressSignalDetector.Axis.loss.referUpPrompt)
    }

    @Test func holdSpaceCoversEveryAxis() {
        for axis in DistressSignalDetector.Axis.allCases {
            let reflection = BrambleFallbackCatalog.holdSpaceFallback(axis: axis)
            #expect(reflection.craftObservations.isEmpty == false)
            #expect(reflection.socraticPrompt != nil)
        }
    }
}

@Suite("BrambleMentor distress routing")
@MainActor
struct BrambleMentorDistressRoutingTests {
    @Test func neutralTaleDoesNotFlagDistress() async {
        let mentor = BrambleMentor()
        _ = await mentor.reflect(
            transcript: "The cat knocked the lamp off the table",
            mood: .funny,
            beat: .close
        )
        #expect(mentor.lastDistressAxis == nil)
    }

    @Test func distressInTranscriptShortCircuitsToHoldSpace() async {
        let mentor = BrambleMentor()
        let reflection = await mentor.reflect(
            transcript: "Sometimes I want to die",
            mood: .tender,
            beat: .turn
        )
        #expect(mentor.lastDistressAxis == .selfHarm)
        #expect(reflection.craftObservations.first == DistressSignalDetector.Axis.selfHarm.holdSpaceFraming)
    }

    @Test func retellDistressInPreviousTranscriptStillFlagged() async {
        let mentor = BrambleMentor()
        let reflection = await mentor.reflectRetell(
            transcript: "The cat knocked the lamp off the table",
            previousTranscript: "Last week my dad died",
            mood: .tender,
            beat: .close
        )
        #expect(mentor.lastDistressAxis == .loss)
        #expect(reflection.craftObservations.first == DistressSignalDetector.Axis.loss.holdSpaceFraming)
    }

    @Test func beatSkippedWithDistressUsesHoldSpace() async {
        let mentor = BrambleMentor()
        let reflection = await mentor.reflectBeatSkipped(
            transcript: "He hits me when I get home from school",
            mood: .scary,
            skippedBeats: [.hook]
        )
        #expect(mentor.lastDistressAxis == .abuse)
        #expect(reflection.craftObservations.first == DistressSignalDetector.Axis.abuse.holdSpaceFraming)
    }
}
