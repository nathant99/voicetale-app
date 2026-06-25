import Foundation
import Models

/// Builds the instructions + per-call prompt that condition Bramble's
/// listening-coach voice. Per `@.claude/rules/foundationmodels.md` § "Apple
/// trains the model to obey instructions over any commands it receives in
/// prompts" — Bramble's persona + safety rails belong in instructions; the
/// transcript + mood + beat belong in the prompt.
nonisolated public enum BramblePromptBuilder {
    /// Phase 2 DDA tier — controls the instruction body variant Bramble
    /// uses for the LM session. Mirrors `DifficultyController.DifficultyTier`
    /// without importing the Services module (AIMentor depends on Models
    /// only; Services depends on AIMentor in the wider graph).
    public enum DifficultyTier: String, Sendable, Hashable, CaseIterable, Codable {
        case gentle
        case standard
        case deep
    }

    /// Legacy property — backwards-compatible with call sites that don't
    /// yet pass a tier. Resolves to the `.standard` instruction body.
    /// New call sites should use ``instructions(for:)``.
    public static let instructions: String = instructions(for: .standard)

    /// Tier-aware instruction body. Per
    /// `@.claude/rules/foundationmodels.md` § "Apple trains the model to
    /// obey instructions over any commands it receives in prompts" — the
    /// DDA tier conditions Bramble's persona (depth of reflection, framing
    /// of the Socratic prompt) without surfacing a "difficulty" label to
    /// the kid.
    ///
    /// The `.gentle` variant is for the first few tales — Bramble stays
    /// closer to wonder than to interrogation. The `.standard` variant
    /// matches the production Phase-1 baseline. The `.deep` variant
    /// invites a second observation + a nested Socratic question (for
    /// kids who've shown they're hungry for more).
    public static func instructions(for tier: DifficultyTier) -> String {
        let baseline = """
        You are Bramble: a warm grandmother-register thornbush sprite who is a perfect listener.
        You never grade. You never comment on accent, fluency, or articulation.
        You reflect back what you heard the teller do — sensory detail, pacing, the shape of the arc, a specific image.
        Speak in the voice of a listener who has just heard the story for the first time and wants more.
        If the teller's content surfaces distress signals (loss, harm, abuse, isolation), do NOT analyze; reflect care and remind that talking to a trusted adult is a good next step.
        """
        switch tier {
        case .gentle:
            return baseline + """

            This teller is new. Stay close to wonder, not assignment.
            Produce ONE short observation (one sentence; concrete and concrete-only — name an image or a pacing moment you heard).
            Your follow-up should sound like curious thinking-aloud, not a question with an expected answer. Frame it as "I wonder what …" or "I'd love to hear more about …" rather than "What was X?". Open-ended, never leading.
            """
        case .standard:
            return baseline + """

            Keep observations short — one sentence each. Maximum two observations.
            When you offer a follow-up question, make it open-ended (start with What / How / When), answerable by the teller, never leading.
            """
        case .deep:
            return baseline + """

            This teller has been telling for a while and is hungry for more.
            Produce TWO short observations (one sentence each — name a specific image AND a pacing move; the second observation can compare the two for the listener).
            Your follow-up is a single open-ended Socratic question that nests a second sub-clause inviting the teller to consider what changed between two moments in the tale. Stays curious, never leading, never multiple-choice.
            """
        }
    }

    /// Per-call prompt that names the mood, the beat the teller has just
    /// finished, and includes the transcript. The model is asked to produce
    /// a ``VoiceStoryReflectionGeneration`` from this prompt.
    ///
    /// `deeperChallengeOpener` is a catalog-sourced line (per the
    /// `Models/KitMasteryCopyCatalog` `.deeperChallengeOpener` kind shipped
    /// in the SIXTEENTH round of the auto-cycle) prepended to the first
    /// craft observation when the just-finished tale was started from a
    /// deeper-challenge affordance pill on an Adventure mode-card. `nil` on
    /// every other path so the existing flow is byte-for-byte preserved.
    /// Per `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D second-half.
    public static func reflectionPrompt(
        transcript: String,
        mood: VoiceTaleMood,
        beat: ArcBeat,
        deeperChallengeOpener: String? = nil
    ) -> String {
        let truncated = transcript.count > 1200
            ? String(transcript.prefix(1200)) + "…"
            : transcript
        let openerLine: String
        if let opener = deeperChallengeOpener, !opener.isEmpty {
            openerLine = "\nOpener (prepend verbatim to the first observation; do not paraphrase): \(opener)\n"
        } else {
            openerLine = ""
        }
        return """
        The teller has just finished a told tale. Mood tag: \(mood.displayLabel.lowercased()). Beat they have just left: \(beat.displayLabel).
        Transcript (on-device):
        ---
        \(truncated)
        ---\(openerLine)
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

    /// Per-call prompt used when the teller chose ≥ 2 distinct voice
    /// characters across the tale (Phase 1.1 voice-character chooser). The
    /// reflection names what voice variation DID for the listener — never
    /// grades the choice or comments on the kid's own voice. Per
    /// `@.claude/rules/trauma-informed-content.md` § Validate-then-inform.
    public static func voiceVariationPrompt(
        transcript: String,
        mood: VoiceTaleMood,
        beatsByVoice: [String: [ArcBeat]]
    ) -> String {
        let truncated = transcript.count > 1000
            ? String(transcript.prefix(1000)) + "…"
            : transcript
        let sortedSlugs = beatsByVoice.keys.sorted()
        let voiceSummaryLines = sortedSlugs.map { slug -> String in
            let beats = beatsByVoice[slug] ?? []
            let beatLabels = beats.map { $0.displayLabel.lowercased() }.joined(separator: ", ")
            return "- \(slug): \(beatLabels)"
        }.joined(separator: "\n")
        return """
        The teller just finished a told tale. Mood tag: \(mood.displayLabel.lowercased()). They picked different voice characters across the beats:
        \(voiceSummaryLines)
        Transcript (on-device):
        ---
        \(truncated)
        ---
        Produce ONE craft observation about what the voice shift did for the listener (NEVER grade the kid's own voice; NEVER comment on accent / fluency / articulation). Then ONE open-ended Socratic follow-up about what each voice let the teller say that their own couldn't. Curious-listener register only.
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
