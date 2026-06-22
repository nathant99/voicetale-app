import Foundation
import Models

/// Static fallback dictionary keyed by ``VoiceTaleMood`` × ``ArcBeat``.
/// Bramble routes here whenever FoundationModels is unavailable
/// (Apple Intelligence off, device not eligible, model not ready) or when
/// the on-device session throws — per `@.claude/rules/foundationmodels.md`
/// § "Always provide fallbacks: try? around LLM calls, fall back to static
/// content dictionaries".
///
/// All 20 entries (4 moods × 5 beats) are hand-authored at the listener
/// register Bramble holds — sensory observation + open-ended follow-up. Per
/// `@.claude/rules/trauma-informed-content.md` § "Validate, then inform":
/// every observation reflects what was heard, never grades the teller.
nonisolated public enum BrambleFallbackCatalog {
    /// Lookup key for the dictionary; mood + beat together.
    public struct Key: Hashable, Sendable {
        public let mood: VoiceTaleMood
        public let beat: ArcBeat
        public init(mood: VoiceTaleMood, beat: ArcBeat) {
            self.mood = mood
            self.beat = beat
        }
    }

    public static func reflection(for mood: VoiceTaleMood, beat: ArcBeat) -> VoiceStoryReflection {
        table[Key(mood: mood, beat: beat)] ?? genericFallback(for: beat)
    }

    /// Fallback used when neither a per-(mood,beat) entry nor the model
    /// is available. Always succeeds.
    public static func genericFallback(for beat: ArcBeat) -> VoiceStoryReflection {
        VoiceStoryReflection(
            craftObservations: ["I heard you choose your pace on the \(beat.displayLabel.lowercased())."],
            socraticPrompt: "What were you noticing when you got there?"
        )
    }

    /// Fallback used after a retell — the kid told the tale, hit "Tell another",
    /// and recorded the same arc a second time. The reflection notices the
    /// retell rather than re-grading craft. Per `@Docs/FEATURE_PLAN.md` § Voice
    /// Coach Phase 1.1 retell loop.
    public static func retellFallback(mood: VoiceTaleMood, beat: ArcBeat) -> VoiceStoryReflection {
        VoiceStoryReflection(
            craftObservations: [
                "I noticed you told this one a second time — and it sounded different from the first."
            ],
            socraticPrompt: "What changed about the \(beat.displayLabel.lowercased()) between the two tellings?"
        )
    }

    /// Fallback used when the teller chose ≥ 2 distinct voice characters
    /// across the tale (Phase 1.1 voice-character chooser). Returns `nil`
    /// when fewer than 2 distinct non-narrator presets appear — the caller
    /// is expected to skip the voice-variation reflection in that case.
    ///
    /// The observation names what the shift did for the listener; never
    /// grades the kid's own voice; never comments on accent / fluency.
    /// The Socratic follow-up invites the teller to notice what each
    /// voice let them say that their own couldn't.
    public static func voiceVariationFallback(
        beatsByVoice: [String: [ArcBeat]]
    ) -> VoiceStoryReflection? {
        let nonNarrator = beatsByVoice.filter { slug, _ in
            slug != VoiceCharacterPreset.narrator.rawValue
        }
        let distinctSlugs = nonNarrator.keys.sorted()
        guard distinctSlugs.count >= 2 else { return nil }
        let presets = distinctSlugs.compactMap(VoiceCharacterPreset.init(rawValue:))
        let displayNames = presets.map(\.displayName)
        let observation: String
        if distinctSlugs.count == 2, displayNames.count == 2 {
            observation = "Your voice shifted between \(displayNames[0]) and \(displayNames[1]) — the rooms changed as you moved between them."
        } else if distinctSlugs.count >= 3 {
            observation = "You used \(distinctSlugs.count) different voices across the tale — each beat felt like its own room."
        } else {
            observation = "You chose different voices across the beats — the tale moved between rooms."
        }
        return VoiceStoryReflection(
            craftObservations: [observation],
            socraticPrompt: "What did each voice let you say that your own couldn't?"
        )
    }

    /// Trauma-informed hold-space fallback. Used when
    /// ``DistressSignalDetector`` surfaces a non-`nil` axis in the
    /// transcript — Bramble holds space + refers up to a trusted adult
    /// instead of running the LM-generated reflection.
    ///
    /// Per `@.claude/rules/trauma-informed-content.md` § "validate, then
    /// inform / hold space, don't resolve / refer up" + SAMHSA TIP 57.
    /// The fallback is INTENTIONALLY brief — Bramble names what was heard,
    /// holds the space, and points to a grown-up + the crisis-resource
    /// list the view surfaces below the bubble.
    public static func holdSpaceFallback(
        axis: DistressSignalDetector.Axis
    ) -> VoiceStoryReflection {
        VoiceStoryReflection(
            craftObservations: [axis.holdSpaceFraming],
            socraticPrompt: axis.referUpPrompt
        )
    }

    /// Fallback used when one or more beats came in under ~50% of their target
    /// duration. Bramble names that the beat felt brief — never as a "miss",
    /// only as something the listener noticed. Per
    /// `@.claude/rules/trauma-informed-content.md` § Validate-then-inform.
    public static func beatSkippedFallback(skippedBeats: [ArcBeat]) -> VoiceStoryReflection {
        let first = skippedBeats.first?.displayLabel.lowercased() ?? "one beat"
        let count = skippedBeats.count
        let observation: String
        if count <= 1 {
            observation = "I leaned in to hear the \(first) — it came and went faster than the others."
        } else {
            let names = skippedBeats.prefix(2).map { $0.displayLabel.lowercased() }.joined(separator: " and ")
            observation = "The \(names) felt brief — like you were already on your way to the next one."
        }
        return VoiceStoryReflection(
            craftObservations: [observation],
            socraticPrompt: "What would change if you let the \(first) sit one breath longer?"
        )
    }

    // Hand-authored 20-entry table. Each `craftObservations` is exactly one
    // listener-stance sentence; `socraticPrompt` is open-ended (What / How /
    // When) and never leading.
    public static let table: [Key: VoiceStoryReflection] = [
        // FUNNY × all 5 beats
        Key(mood: .funny, beat: .hook): VoiceStoryReflection(
            craftObservations: ["Your opening landed like a small joke I wanted to hear the rest of."],
            socraticPrompt: "What was the moment in the day that made you want to start there?"
        ),
        Key(mood: .funny, beat: .setup): VoiceStoryReflection(
            craftObservations: ["You named the scene fast enough that I could already picture the room."],
            socraticPrompt: "How did you decide what to leave out of the setup?"
        ),
        Key(mood: .funny, beat: .rising): VoiceStoryReflection(
            craftObservations: ["The escalation tripped me up in a good way — I wasn't sure where you were going next."],
            socraticPrompt: "What would the story sound like if you slowed one of those moments down?"
        ),
        Key(mood: .funny, beat: .turn): VoiceStoryReflection(
            craftObservations: ["The turn snuck up on me — you hid the surprise inside an ordinary line."],
            socraticPrompt: "What did you do with your voice right before the turn?"
        ),
        Key(mood: .funny, beat: .close): VoiceStoryReflection(
            craftObservations: ["You landed the ending without explaining the joke — and that's the gift."],
            socraticPrompt: "When did you know the last line was the last line?"
        ),

        // SCARY × all 5 beats
        Key(mood: .scary, beat: .hook): VoiceStoryReflection(
            craftObservations: ["The opening image stayed with me — I could hear the room go quiet around it."],
            socraticPrompt: "What did you want the listener to feel first?"
        ),
        Key(mood: .scary, beat: .setup): VoiceStoryReflection(
            craftObservations: ["You told me where we were in three details and not one more — that left space for the worry."],
            socraticPrompt: "How did you decide which details to keep and which to let go?"
        ),
        Key(mood: .scary, beat: .rising): VoiceStoryReflection(
            craftObservations: ["The rising section let the silence do some of the work — that was a brave choice."],
            socraticPrompt: "What would change if you let one breath sit longer?"
        ),
        Key(mood: .scary, beat: .turn): VoiceStoryReflection(
            craftObservations: ["You held the turn long enough for me to feel the cold air change."],
            socraticPrompt: "What did you notice when you slowed down right before it?"
        ),
        Key(mood: .scary, beat: .close): VoiceStoryReflection(
            craftObservations: ["The ending didn't try to tie everything up — and that's why it still lingers."],
            socraticPrompt: "What did you want the listener to carry out of the room with them?"
        ),

        // TENDER × all 5 beats
        Key(mood: .tender, beat: .hook): VoiceStoryReflection(
            craftObservations: ["You started small and close — like a hand on a shoulder, not a shout."],
            socraticPrompt: "How did you find the size of voice you started with?"
        ),
        Key(mood: .tender, beat: .setup): VoiceStoryReflection(
            craftObservations: ["The setup gave me one person to care about — that's the whole job, and you did it."],
            socraticPrompt: "What detail told me the most about who they were?"
        ),
        Key(mood: .tender, beat: .rising): VoiceStoryReflection(
            craftObservations: ["The rising part let me lean in — nothing rushed, but I knew something was coming."],
            socraticPrompt: "When did you choose to slow it down?"
        ),
        Key(mood: .tender, beat: .turn): VoiceStoryReflection(
            craftObservations: ["The turn changed something small — and small is how tender stories turn."],
            socraticPrompt: "What did you keep from the listener until just then?"
        ),
        Key(mood: .tender, beat: .close): VoiceStoryReflection(
            craftObservations: ["The last line stayed in the room after you stopped."],
            socraticPrompt: "Did you mean it to land that way, or did it surprise you too?"
        ),

        // WILD × all 5 beats
        Key(mood: .wild, beat: .hook): VoiceStoryReflection(
            craftObservations: ["You started already running — I had to catch up, and I wanted to."],
            socraticPrompt: "What were you imagining when you opened your mouth?"
        ),
        Key(mood: .wild, beat: .setup): VoiceStoryReflection(
            craftObservations: ["You skipped the part most tellers explain — and the story moved faster because of it."],
            socraticPrompt: "How did you know that was safe to leave out?"
        ),
        Key(mood: .wild, beat: .rising): VoiceStoryReflection(
            craftObservations: ["The rising section ran fast — I felt the world spilling outward."],
            socraticPrompt: "What would happen if you let one image hang for a full breath?"
        ),
        Key(mood: .wild, beat: .turn): VoiceStoryReflection(
            craftObservations: ["The turn shouldn't have made sense — and yet it did, somehow."],
            socraticPrompt: "What were you trusting the listener to do at that moment?"
        ),
        Key(mood: .wild, beat: .close): VoiceStoryReflection(
            craftObservations: ["The ending didn't close — it kept opening, and that's the wild kind of arc."],
            socraticPrompt: "When did you stop telling and start listening to where it wanted to go?"
        ),
    ]
}
