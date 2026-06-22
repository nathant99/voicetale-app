import Foundation
import ForgeAI
import Models

/// Thin app-side wrapper around `ForgeAI.CastDialog` for VoiceTale's 4 cast
/// members. Owns a `CastDialog` actor + auto-registers the
/// `CastVoiceRegistry` profiles at first use, then exposes a single
/// `respond(as:trigger:context:)` entry point that returns a live LM-generated
/// utterance (or a static catchphrase fallback when FoundationModels is
/// unavailable / the LM rejects / the registry is empty).
///
/// **Status — DN-S Move D step 3 (opt-in groundwork)**: per
/// `@Docs/HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` the BrambleMentor
/// `LanguageModelSession` → `CastDialog` swap is deferred to Phase 1.1 (~14d
/// telemetry observation). This service is the integration seam: app code
/// that wants LIVE per-cast utterances calls `live.respond(as:slug, ...)`
/// while the static `castCameos[]` continues to render via `CastCameoStripView`
/// per Move B (PR #38).
///
/// **Feature flag**: `isLiveVoicingEnabled` defaults to `false` so adopters
/// opt-in explicitly. When `false`, `respond(...)` returns the matching
/// profile's first catchphrase (no LM call). When `true`, routes through
/// `CastDialog.respond(...)` which itself falls back to a random catchphrase
/// if the LM is unavailable. Replaces the `ForgeExperiments.castVoicing` flag
/// the original handoff anticipated (the experiments module isn't pinned).
public actor CastVoicingService {
    /// App identifier carried in `CastDialogContext.appIdentifier` for every
    /// utterance. Hard-coded to `"voicetale"` — the per-app prompt template
    /// scaffold uses this to look up app-specific prompt overrides.
    public static let appIdentifier = "voicetale"

    private let dialog: CastDialog
    private var didRegister: Bool = false
    public private(set) var isLiveVoicingEnabled: Bool

    public init(
        dialog: CastDialog = CastDialog(),
        isLiveVoicingEnabled: Bool = false
    ) {
        self.dialog = dialog
        self.isLiveVoicingEnabled = isLiveVoicingEnabled
    }

    /// Toggle live voicing at runtime. Default-off design means a TestFlight
    /// build can flip this from a debug menu without re-deploying.
    public func setLiveVoicingEnabled(_ enabled: Bool) {
        isLiveVoicingEnabled = enabled
    }

    /// Register all 4 cast profiles into the underlying `CastDialog`.
    /// Idempotent: subsequent calls no-op after the first success.
    public func registerProfilesIfNeeded() async throws {
        guard !didRegister else { return }
        try await CastVoiceRegistry.register(into: dialog)
        didRegister = true
    }

    /// Produce a single cast utterance. Always returns a string:
    ///
    /// - When `isLiveVoicingEnabled == false`: returns the slug's first
    ///   catchphrase from `CastVoiceRegistry` (no LM call).
    /// - When `isLiveVoicingEnabled == true`: routes to `CastDialog.respond(...)`
    ///   which uses FoundationModels when available and falls back to a random
    ///   catchphrase otherwise.
    public func respond(
        as slug: CastVoiceRegistry.Slug,
        trigger: CastDialogTrigger,
        kitNumber: Int,
        topic: String? = nil,
        emotionContext: CastDialogContext.EmotionContext = .unknown
    ) async -> String {
        if !isLiveVoicingEnabled {
            return staticUtterance(for: slug)
        }
        do {
            try await registerProfilesIfNeeded()
        } catch {
            return staticUtterance(for: slug)
        }
        let context = CastDialogContext(
            appIdentifier: Self.appIdentifier,
            kitNumber: kitNumber,
            recentQuestionTopic: topic,
            emotionContext: emotionContext
        )
        return await dialog.respond(as: slug.rawValue, trigger: trigger, context: context)
    }

    /// Snapshot of whether the underlying `CastDialog` has registered all 4
    /// profiles. Exposed for tests + diagnostics.
    public func isFullyRegistered() async -> Bool {
        for slug in CastVoiceRegistry.Slug.allCases {
            if await !dialog.isRegistered(slug.rawValue) {
                return false
            }
        }
        return true
    }

    private func staticUtterance(for slug: CastVoiceRegistry.Slug) -> String {
        let profile = CastVoiceRegistry.profile(for: slug)
        return profile.catchphrases.first ?? "…"
    }

    /// Map a saved tale's mood to the cast member whose embodied primitive
    /// is most adjacent to that mood register. Used by the post-reflection
    /// "Hear from one of Bramble's friends" surface so each mood routes to
    /// a different cast voice without leaning on a single character.
    ///
    /// | Mood   | Cast member | Why |
    /// |---|---|---|
    /// | funny  | Refrain | Callbacks land humor — the second saying is the laugh |
    /// | scary  | Slow    | Pacing is the dread engineering primitive |
    /// | tender | Lean    | Hook-craft + body-tipping is the closest to tenderness |
    /// | wild   | Pivot   | Turns rotate meaning; wild tales pivot hardest |
    ///
    /// Stable + total mapping so every mood gets a deterministic voicing
    /// candidate. Per `@Docs/HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md`
    /// the voicing-priority order calls for Lean lead; this mapping spreads
    /// the four cast members evenly across the four moods so the kid hears
    /// every member over a session that explores every mood.
    public static func slugForMood(_ mood: VoiceTaleMood) -> CastVoiceRegistry.Slug {
        switch mood {
        case .funny:  return .refrain
        case .scary:  return .slow
        case .tender: return .lean
        case .wild:   return .pivot
        }
    }
}
