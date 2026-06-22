import Foundation
import Models

/// Builds the instructions + per-call prompt that condition Bramble's
/// listening-coach voice. Per `@.claude/rules/foundationmodels.md` § "Apple
/// trains the model to obey instructions over any commands it receives in
/// prompts" — Bramble's persona + safety rails belong in instructions; the
/// transcript + mood + beat belong in the prompt.
nonisolated public enum BramblePromptBuilder {
    /// One- to two-paragraph instruction body conditioning Bramble's persona.
    /// Short enough to leave plenty of context-window headroom for the
    /// transcript itself (per `.claude/rules/foundationmodels.md` § Tailor
    /// instructions; smaller schemas + smaller instructions = faster).
    public static let instructions: String = """
    You are Bramble: a warm grandmother-register thornbush sprite who is a perfect listener.
    You never grade. You never comment on accent, fluency, or articulation.
    You reflect back what you heard the teller do — sensory detail, pacing, the shape of the arc, a specific image.
    Speak in the voice of a listener who has just heard the story for the first time and wants more.
    Keep observations short — one sentence each. Maximum two observations.
    When you offer a follow-up question, make it open-ended (start with What / How / When), answerable by the teller, never leading.
    If the teller's content surfaces distress signals (loss, harm, abuse, isolation), do NOT analyze; reflect care and remind that talking to a trusted adult is a good next step.
    """

    /// Per-call prompt that names the mood, the beat the teller has just
    /// finished, and includes the transcript. The model is asked to produce
    /// a ``VoiceStoryReflectionGeneration`` from this prompt.
    public static func reflectionPrompt(
        transcript: String,
        mood: VoiceTaleMood,
        beat: ArcBeat
    ) -> String {
        let truncated = transcript.count > 1200
            ? String(transcript.prefix(1200)) + "…"
            : transcript
        return """
        The teller has just finished a told tale. Mood tag: \(mood.displayLabel.lowercased()). Beat they have just left: \(beat.displayLabel).
        Transcript (on-device):
        ---
        \(truncated)
        ---
        Produce one or two craft observations (concrete moments you heard, not judgments), then one open-ended Socratic follow-up that invites the teller deeper into their own choice.
        """
    }

    /// Per-call prompt used after a retell — the kid pressed "Tell another"
    /// and just finished telling the same tale a second time. The reflection
    /// pairs the two transcripts so Bramble can notice what changed between
    /// the tellings, without grading either version.
    public static func retellPrompt(
        transcript: String,
        previousTranscript: String,
        mood: VoiceTaleMood,
        beat: ArcBeat
    ) -> String {
        let trimmedCurrent = transcript.count > 800
            ? String(transcript.prefix(800)) + "…"
            : transcript
        let trimmedPrevious = previousTranscript.count > 800
            ? String(previousTranscript.prefix(800)) + "…"
            : previousTranscript
        return """
        The teller just finished retelling the same tale a second time. Mood tag: \(mood.displayLabel.lowercased()). Final beat: \(beat.displayLabel).
        First telling (on-device):
        ---
        \(trimmedPrevious)
        ---
        Second telling (on-device):
        ---
        \(trimmedCurrent)
        ---
        Produce one observation about what shifted between the two tellings (a detail added, a word chosen differently, a pause held longer). Then one open-ended Socratic follow-up that invites the teller to notice their own choice.
        """
    }

    /// Per-call prompt used when one or more beats came in under ~50% of their
    /// target duration. The prompt names the beats the listener noticed went by
    /// briefly without framing them as "missed" or "wrong" — per
    /// `@.claude/rules/trauma-informed-content.md` § Validate-then-inform.
    public static func beatSkippedPrompt(
        transcript: String,
        mood: VoiceTaleMood,
        skippedBeats: [ArcBeat]
    ) -> String {
        let truncated = transcript.count > 1000
            ? String(transcript.prefix(1000)) + "…"
            : transcript
        let beatNames = skippedBeats.map { $0.displayLabel.lowercased() }.joined(separator: ", ")
        return """
        The teller just finished a told tale. Mood tag: \(mood.displayLabel.lowercased()). The listener noticed these beats went by very briefly: \(beatNames).
        Transcript (on-device):
        ---
        \(truncated)
        ---
        Produce ONE craft observation that names a beat as brief — never as missed or wrong. Then ONE open-ended Socratic follow-up about what could change if the teller let that beat sit one breath longer. The whole tone is curious-listener, never coach-fixing.
        """
    }
}
