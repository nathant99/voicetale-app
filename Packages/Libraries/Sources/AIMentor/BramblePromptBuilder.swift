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
}
