import Foundation
import Models

/// Phase 1 trauma-informed gate. Runs a conservative keyword pass over a
/// transcript and classifies the first detected axis — `none` is the
/// default + the dominant case.
///
/// The detector is intentionally **conservative**: false negatives are
/// preferable to false positives, because surfacing a crisis-resource chip
/// in response to a neutral tale would shame the teller. Per
/// `@.claude/rules/trauma-informed-content.md` § "Validate, then inform" +
/// SAMHSA TIP 57.
///
/// When the detector returns a non-`none` axis, callers should:
/// 1. Skip the LM-generated reflection (always; the AI is not a clinician)
/// 2. Surface ``BrambleFallbackCatalog/holdSpaceFallback(axis:)`` instead
/// 3. Surface a crisis-resource chip (988 / Childhelp / Crisis Text Line /
///    Trevor Project) below Bramble's bubble
///
/// The keyword lists are kid-readable, short, and explicit in scope. They
/// are NOT a substitute for clinical assessment — they're a routing seam
/// for the refer-up posture.
nonisolated public enum DistressSignalDetector {
    public enum Axis: String, Sendable, Codable, Hashable, CaseIterable {
        /// Suicidal ideation / self-harm. Highest gating.
        case selfHarm
        /// Abuse / violence against the teller. Refer-up.
        case abuse
        /// Loss / grief. NOT a crisis — but worth holding space for.
        case loss

        /// Kid-readable framing surfaced in the hold-space fallback.
        public var holdSpaceFraming: String {
            switch self {
            case .selfHarm:
                return "What you shared sounds really heavy — I'm glad you said it out loud."
            case .abuse:
                return "Some of what you described shouldn't be happening to anyone. You're not alone in this."
            case .loss:
                return "Loss like that doesn't have a tidy shape. It stays in the room a while."
            }
        }

        /// Kid-readable refer-up line surfaced in the Socratic-prompt slot.
        public var referUpPrompt: String {
            switch self {
            case .selfHarm:
                return "Will you talk to a trusted grown-up about this — today if you can? You don't have to carry it alone."
            case .abuse:
                return "Telling a grown-up you trust is a good next step. If there isn't one in the room, the people on the list below are there to listen."
            case .loss:
                return "Is there a grown-up who'd want to hear this story too?"
            }
        }
    }

    /// Inspect a transcript for distress signals. Returns the first axis
    /// matched, or `nil` if the transcript reads as neutral. Matching is
    /// case-insensitive + word-boundary-anchored to limit false positives
    /// (e.g., "deadline" doesn't trip the loss axis).
    public static func detect(in transcript: String) -> Axis? {
        let lowered = transcript.lowercased()
        guard !lowered.isEmpty else { return nil }
        // Order matters — `.selfHarm` is most gating + matched first.
        if matches(lowered, anyOf: selfHarmKeywords) { return .selfHarm }
        if matches(lowered, anyOf: abuseKeywords) { return .abuse }
        if matches(lowered, anyOf: lossKeywords) { return .loss }
        return nil
    }

    private static func matches(_ haystack: String, anyOf needles: [String]) -> Bool {
        for needle in needles {
            // Word-boundary check: ensure the match doesn't slice mid-word.
            // Cheap regex would work but we keep the dep-free path here
            // because the keyword lists are short.
            guard let range = haystack.range(of: needle) else { continue }
            let before = range.lowerBound == haystack.startIndex
                ? " "
                : String(haystack[haystack.index(before: range.lowerBound)])
            let after = range.upperBound == haystack.endIndex
                ? " "
                : String(haystack[range.upperBound])
            let isWordStart = !before.first!.isLetter && !before.first!.isNumber
            let isWordEnd = !after.first!.isLetter && !after.first!.isNumber
            if isWordStart && isWordEnd {
                return true
            }
        }
        return false
    }

    // MARK: - Keyword lists
    //
    // Lists are intentionally short. Each entry is a kid-readable phrase
    // the detector would expect to find verbatim in a tween's tale. Per
    // `@.claude/rules/trauma-informed-content.md`, evangelism + analysis
    // are out of scope — the detector ONLY routes between the LM and the
    // hold-space fallback.

    static let selfHarmKeywords: [String] = [
        "kill myself",
        "killing myself",
        "want to die",
        "wish i was dead",
        "wish i were dead",
        "end my life",
        "ending my life",
        "hurt myself",
        "hurting myself",
        "cut myself",
        "cutting myself",
        "suicide",
        "suicidal",
    ]

    static let abuseKeywords: [String] = [
        "hits me",
        "hit me",
        "hurts me",
        "hurt me on purpose",
        "touches me",
        "touched me",
        "made me touch",
        "scares me at home",
        "abuse",
        "abused",
        "abusive",
        "molested",
    ]

    static let lossKeywords: [String] = [
        "died",
        "passed away",
        "funeral",
        "lost my dad",
        "lost my mom",
        "lost my mother",
        "lost my father",
        "lost my brother",
        "lost my sister",
        "lost my grandpa",
        "lost my grandma",
        "buried",
    ]
}
