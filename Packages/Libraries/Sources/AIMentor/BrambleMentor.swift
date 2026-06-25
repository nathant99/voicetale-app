import Foundation
import FoundationModels
import Models

/// Bramble — the listening coach. Real `LanguageModelSession`-backed
/// reflection with a static fallback dictionary for every (mood, beat)
/// combination. Per `@.claude/rules/foundationmodels.md`:
///
/// - "Always check first": availability is observed at init and via
///   ``refreshAvailability()`` before every call
/// - "Lazy session": ``LanguageModelSession`` is created on first reflect
///   and reused
/// - "Always provide fallbacks": every call routes to ``staticFallback`` when
///   the model is unavailable OR the session throws
///
/// Bramble is `@MainActor @Observable` so SwiftUI views can observe
/// availability transitions; the `@ObservationIgnored private` session is
/// kept off the observation graph so reuse doesn't trigger re-renders.
@MainActor
@Observable
public final class BrambleMentor {
    public enum Availability: Sendable, Equatable {
        case available
        case unavailableDeviceNotEligible
        case unavailableAppleIntelligenceNotEnabled
        case unavailableModelNotReady
        case unknown
    }

    public private(set) var availability: Availability = .unknown
    public private(set) var lastReflection: VoiceStoryReflection?
    /// The most recent distress signal Bramble detected in a transcript
    /// (or `nil` when the last reflection was neutral). Surfaces to
    /// ``BrambleReflectionView`` so the crisis-resource chip can render
    /// below the bubble when an axis is non-nil. Cleared by callers
    /// (TellView resets it on retell / cancel / save).
    public private(set) var lastDistressAxis: DistressSignalDetector.Axis?
    /// Phase 2 DDA — the active tier Bramble's session is configured
    /// against. Defaults to `.standard` so brand-new Bramble instances
    /// behave like the Phase-1 baseline; ``setTier(_:)`` is the canonical
    /// way to bump the tier from outside.
    public private(set) var activeTier: BramblePromptBuilder.DifficultyTier = .standard

    @ObservationIgnored
    private let model = SystemLanguageModel.default

    @ObservationIgnored
    private var session: LanguageModelSession?

    public init() {
        refreshAvailability()
    }

    /// Update the DDA tier Bramble's session is configured against. Cheap
    /// + idempotent — when the new tier matches the active tier, this is
    /// a no-op. Otherwise the cached session is invalidated so the next
    /// reflection call rebuilds it with the new instructions body. Per
    /// `@.claude/rules/foundationmodels.md` § "Lazy session: Create
    /// `LanguageModelSession` on first use, reuse across requests — never
    /// create per-call". A tier change is the canonical reason to break
    /// the reuse contract.
    public func setTier(_ tier: BramblePromptBuilder.DifficultyTier) {
        guard tier != activeTier else { return }
        activeTier = tier
        session = nil
    }

    /// Updates ``availability`` to mirror the model's current state. Cheap;
    /// safe to call on every screen appear.
    public func refreshAvailability() {
        switch model.availability {
        case .available:
            availability = .available
        case .unavailable(.deviceNotEligible):
            availability = .unavailableDeviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled):
            availability = .unavailableAppleIntelligenceNotEnabled
        case .unavailable(.modelNotReady):
            availability = .unavailableModelNotReady
        case .unavailable:
            availability = .unknown
        }
    }

    /// Produces a craft observation + Socratic prompt for the tale at the
    /// given beat. Always succeeds; falls back to the static dictionary when
    /// the model is unavailable or the session throws.
    ///
    /// When `favoriteMood` is non-`nil` AND matches `mood` (i.e. the kid is
    /// telling today's tale in their established favorite register), a
    /// warm Bramble-register callback line is prepended to the first
    /// craft observation per ``BrambleMoodMemory/callback(favoriteMood:todayMood:)``.
    /// Per the anti-shame contract on ``BrambleMoodMemory``, the callback
    /// is suppressed for distress paths + for non-matching moods.
    ///
    /// When `deeperChallengeOpener` is non-`nil` (the just-finished tale
    /// was started from a deeper-challenge affordance pill on an Adventure
    /// mode-card), the catalog-sourced opener is prepended to the first
    /// craft observation BEFORE the favorite-mood callback. Per
    /// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D second-half +
    /// `Models/KitMasteryCopyCatalog` `.deeperChallengeOpener` kind.
    /// Suppressed on distress paths (the hold-space register comes first).
    /// The opener string is sourced by the caller from
    /// ``Models/KitMasteryCopyCatalog/line(for:kit:)`` so AIMentor stays
    /// unaware of `KitID` + the catalog single-seam discipline holds.
    public func reflect(
        transcript: String,
        mood: VoiceTaleMood,
        beat: ArcBeat,
        favoriteMood: VoiceTaleMood? = nil,
        deeperChallengeOpener: String? = nil
    ) async -> VoiceStoryReflection {
        // Trauma-informed gate FIRST. Per
        // `@.claude/rules/trauma-informed-content.md` § "refer up", any
        // distress axis bypasses the LM entirely + uses the hold-space
        // fallback. The view surfaces a crisis-resource chip alongside.
        // Note: the favorite-mood callback is intentionally SUPPRESSED on
        // distress paths — the hold-space register comes first.
        if let axis = DistressSignalDetector.detect(in: transcript) {
            let holdSpace = BrambleFallbackCatalog.holdSpaceFallback(axis: axis)
            lastReflection = holdSpace
            lastDistressAxis = axis
            return holdSpace
        }
        lastDistressAxis = nil
        let fallback = staticFallback(for: mood, beat: beat)
        guard availability == .available else {
            let withOpener = applyDeeperChallengeOpener(fallback, opener: deeperChallengeOpener)
            let withCallback = applyFavoriteMoodCallback(
                withOpener,
                favoriteMood: favoriteMood,
                todayMood: mood
            )
            lastReflection = withCallback
            return withCallback
        }
        let workingSession = ensureSession()
        let prompt = BramblePromptBuilder.reflectionPrompt(
            transcript: transcript,
            mood: mood,
            beat: beat,
            deeperChallengeOpener: deeperChallengeOpener
        )
        do {
            let response = try await workingSession.respond(
                to: prompt,
                generating: VoiceStoryReflectionGeneration.self
            )
            let generated = response.content
            let reflection = VoiceStoryReflection(
                craftObservations: sanitizeObservations(generated.craftObservations, fallback: fallback),
                socraticPrompt: sanitizePrompt(generated.socraticPrompt, fallback: fallback)
            )
            // Belt-and-braces: if the model didn't prepend the opener verbatim
            // (instructions are obeyed best-effort, not guaranteed), prepend
            // it ourselves. Idempotent against an already-prefixed observation.
            let withOpener = applyDeeperChallengeOpener(reflection, opener: deeperChallengeOpener)
            let withCallback = applyFavoriteMoodCallback(
                withOpener,
                favoriteMood: favoriteMood,
                todayMood: mood
            )
            lastReflection = withCallback
            return withCallback
        } catch {
            let withOpener = applyDeeperChallengeOpener(fallback, opener: deeperChallengeOpener)
            let withCallback = applyFavoriteMoodCallback(
                withOpener,
                favoriteMood: favoriteMood,
                todayMood: mood
            )
            lastReflection = withCallback
            return withCallback
        }
    }

    /// Instance shim used by the existing ``reflect`` call sites for
    /// natural-reading code. Delegates to the
    /// `nonisolated public static` helper below.
    nonisolated private func applyDeeperChallengeOpener(
        _ reflection: VoiceStoryReflection,
        opener: String?
    ) -> VoiceStoryReflection {
        Self.applyDeeperChallengeOpener(reflection, opener: opener)
    }

    /// Prepend the catalog-sourced deeper-challenge opener to the first
    /// craft observation. `nil` opener → reflection unchanged. Empty opener
    /// → reflection unchanged. Empty `craftObservations` → opener becomes
    /// the first (+ only) observation so Bramble's bubble still renders.
    /// Idempotent against an already-prefixed observation (the model may
    /// obey the prompt's verbatim prepend instruction OR may not — we
    /// belt-and-braces here so the opener surfaces regardless). Per
    /// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D second-half +
    /// the catalog-single-seam discipline. Public so tests can pin the
    /// helper without spinning up a FoundationModels session — same
    /// pattern as ``applyFavoriteMoodCallback(_:favoriteMood:todayMood:)``.
    nonisolated public static func applyDeeperChallengeOpener(
        _ reflection: VoiceStoryReflection,
        opener: String?
    ) -> VoiceStoryReflection {
        guard let opener, !opener.isEmpty else { return reflection }
        var observations = reflection.craftObservations
        if let first = observations.first, !first.isEmpty {
            // Idempotency: if the first observation already starts with
            // the opener (the LM obeyed the prompt's "prepend verbatim"
            // instruction), leave it alone.
            if first.hasPrefix(opener) { return reflection }
            observations[0] = "\(opener) \(first)"
        } else {
            // Empty observations / empty first slot: the opener becomes
            // the first observation so the surface doesn't render an
            // empty bubble (mirrors `applyFavoriteMoodCallback`'s shape).
            observations.insert(opener, at: 0)
        }
        return VoiceStoryReflection(
            craftObservations: observations,
            socraticPrompt: reflection.socraticPrompt
        )
    }

    /// Look up the hand-authored fallback for a given mood + beat. Public so
    /// previews + tests can pin Bramble's voice without needing the model.
    nonisolated public func staticFallback(
        for mood: VoiceTaleMood,
        beat: ArcBeat
    ) -> VoiceStoryReflection {
        BrambleFallbackCatalog.reflection(for: mood, beat: beat)
    }

    /// Produces a retell-aware reflection. Pairs the previous transcript with
    /// the current one so Bramble can notice what shifted between the two
    /// tellings. Always succeeds via the retell static fallback.
    public func reflectRetell(
        transcript: String,
        previousTranscript: String,
        mood: VoiceTaleMood,
        beat: ArcBeat
    ) async -> VoiceStoryReflection {
        // Retell distress gate: check BOTH the current AND the previous
        // transcript (a kid sometimes only surfaces the distress on the
        // retake). First match wins.
        if let axis = DistressSignalDetector.detect(in: transcript)
            ?? DistressSignalDetector.detect(in: previousTranscript) {
            let holdSpace = BrambleFallbackCatalog.holdSpaceFallback(axis: axis)
            lastReflection = holdSpace
            lastDistressAxis = axis
            return holdSpace
        }
        lastDistressAxis = nil
        let fallback = BrambleFallbackCatalog.retellFallback(mood: mood, beat: beat)
        guard availability == .available, !previousTranscript.isEmpty else {
            lastReflection = fallback
            return fallback
        }
        let workingSession = ensureSession()
        let prompt = BramblePromptBuilder.retellPrompt(
            transcript: transcript,
            previousTranscript: previousTranscript,
            mood: mood,
            beat: beat
        )
        do {
            let response = try await workingSession.respond(
                to: prompt,
                generating: VoiceStoryReflectionGeneration.self
            )
            let generated = response.content
            let reflection = VoiceStoryReflection(
                craftObservations: sanitizeObservations(generated.craftObservations, fallback: fallback),
                socraticPrompt: sanitizePrompt(generated.socraticPrompt, fallback: fallback)
            )
            lastReflection = reflection
            return reflection
        } catch {
            lastReflection = fallback
            return fallback
        }
    }

    /// Produces a reflection that names beats the listener noticed went by
    /// briefly (< 50% of their target duration). Per
    /// `@.claude/rules/trauma-informed-content.md` § Validate-then-inform, the
    /// reflection never frames a brief beat as missed or wrong — only as
    /// something the listener noticed. Always succeeds via the static
    /// fallback when the model is unavailable.
    public func reflectBeatSkipped(
        transcript: String,
        mood: VoiceTaleMood,
        skippedBeats: [ArcBeat]
    ) async -> VoiceStoryReflection {
        if let axis = DistressSignalDetector.detect(in: transcript) {
            let holdSpace = BrambleFallbackCatalog.holdSpaceFallback(axis: axis)
            lastReflection = holdSpace
            lastDistressAxis = axis
            return holdSpace
        }
        lastDistressAxis = nil
        let fallback = BrambleFallbackCatalog.beatSkippedFallback(skippedBeats: skippedBeats)
        guard availability == .available, !skippedBeats.isEmpty else {
            lastReflection = fallback
            return fallback
        }
        let workingSession = ensureSession()
        let prompt = BramblePromptBuilder.beatSkippedPrompt(
            transcript: transcript,
            mood: mood,
            skippedBeats: skippedBeats
        )
        do {
            let response = try await workingSession.respond(
                to: prompt,
                generating: VoiceStoryReflectionGeneration.self
            )
            let generated = response.content
            let reflection = VoiceStoryReflection(
                craftObservations: sanitizeObservations(generated.craftObservations, fallback: fallback),
                socraticPrompt: sanitizePrompt(generated.socraticPrompt, fallback: fallback)
            )
            lastReflection = reflection
            return reflection
        } catch {
            lastReflection = fallback
            return fallback
        }
    }

    /// Produces a reflection about the kid's voice-character choices (Phase
    /// 1.1 voice-character chooser). Returns `nil` when fewer than 2
    /// distinct non-narrator presets appear — callers skip the secondary
    /// reflection in that case. Always succeeds via the static fallback
    /// when the model is unavailable.
    public func reflectVoiceVariation(
        transcript: String,
        mood: VoiceTaleMood,
        beatsByVoice: [String: [ArcBeat]]
    ) async -> VoiceStoryReflection? {
        guard let fallback = BrambleFallbackCatalog.voiceVariationFallback(beatsByVoice: beatsByVoice) else {
            return nil
        }
        guard availability == .available else {
            return fallback
        }
        let workingSession = ensureSession()
        let prompt = BramblePromptBuilder.voiceVariationPrompt(
            transcript: transcript,
            mood: mood,
            beatsByVoice: beatsByVoice
        )
        do {
            let response = try await workingSession.respond(
                to: prompt,
                generating: VoiceStoryReflectionGeneration.self
            )
            let generated = response.content
            return VoiceStoryReflection(
                craftObservations: sanitizeObservations(generated.craftObservations, fallback: fallback),
                socraticPrompt: sanitizePrompt(generated.socraticPrompt, fallback: fallback)
            )
        } catch {
            return fallback
        }
    }

    // MARK: - Internals

    private func ensureSession() -> LanguageModelSession {
        if let session { return session }
        let instructions = Instructions(BramblePromptBuilder.instructions(for: activeTier))
        let created = LanguageModelSession(model: model, instructions: instructions)
        session = created
        return created
    }

    /// Prepend a Bramble favorite-mood callback line to the first
    /// observation when the kid is telling today's tale in their
    /// established favorite register. The callback is suppressed when
    /// ``BrambleMoodMemory/callback(favoriteMood:todayMood:)`` returns
    /// `nil` (no favorite earned OR today's mood doesn't match the
    /// favorite). Anti-shame: never names a non-favorite, never compares
    /// moods. Public so tests can pin the helper without spinning up a
    /// FoundationModels session.
    nonisolated public static func applyFavoriteMoodCallback(
        _ reflection: VoiceStoryReflection,
        favoriteMood: VoiceTaleMood?,
        todayMood: VoiceTaleMood
    ) -> VoiceStoryReflection {
        guard let callback = BrambleMoodMemory.callback(
            favoriteMood: favoriteMood,
            todayMood: todayMood
        ) else {
            return reflection
        }
        var observations = reflection.craftObservations
        if let first = observations.first, !first.isEmpty {
            observations[0] = "\(callback) \(first)"
        } else {
            observations.insert(callback, at: 0)
        }
        return VoiceStoryReflection(
            craftObservations: observations,
            socraticPrompt: reflection.socraticPrompt
        )
    }

    /// Instance shim so the existing call sites in ``reflect(...)`` read
    /// naturally. Delegates to the `nonisolated public static` helper.
    nonisolated private func applyFavoriteMoodCallback(
        _ reflection: VoiceStoryReflection,
        favoriteMood: VoiceTaleMood?,
        todayMood: VoiceTaleMood
    ) -> VoiceStoryReflection {
        Self.applyFavoriteMoodCallback(
            reflection,
            favoriteMood: favoriteMood,
            todayMood: todayMood
        )
    }

    /// Defensive trim — strip empties, cap at two entries, swap to fallback
    /// if the model produced nothing useful.
    private nonisolated func sanitizeObservations(
        _ raw: [String],
        fallback: VoiceStoryReflection
    ) -> [String] {
        let cleaned = raw
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(2)
        if cleaned.isEmpty {
            return fallback.craftObservations
        }
        return Array(cleaned)
    }

    private nonisolated func sanitizePrompt(
        _ raw: String?,
        fallback: VoiceStoryReflection
    ) -> String? {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            return trimmed
        }
        return fallback.socraticPrompt
    }
}
