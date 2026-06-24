import Foundation
import ForgeModels
import ForgeUI

/// Per-context builders for `ReflectionPromptConfig` instances. Phase A of
/// the ForgeReflection lift per `@Docs/PLAN_FORGEREFLECTION_LIFT.md` —
/// the catalog is the single source of truth for what prompts VoiceTale
/// presents through `ForgeUI.ReflectionPromptModifier`. Phase B (the
/// "Answer Bramble" button in `BrambleReflectionView`) is the first
/// consumer.
///
/// All configs declare `parentVisible: false` by default — V1 ships
/// kid-only; Phase D adds the parent-dashboard opt-in surface that flips
/// per-config visibility per `@.claude/rules/age-assurance.md` § "2026
/// FTC COPPA Rule Amendments" (opt-in default for any new parent-visible
/// data).
///
/// `.drawing` is deliberately omitted from V1 allowed-modalities —
/// PencilKit dependency + per-frame canvas justify deferral until
/// Phase D when telemetry indicates demand. The canonical V1 set is
/// `[.text, .voice, .emoji, .skip]`; `.skip` MUST stay in every
/// allowed-modality set per the trauma-informed off-ramp precondition
/// (enforced at `ReflectionPromptConfig.init`).
public nonisolated enum VoiceTaleReflectionConfigCatalog {
    /// VoiceTale's appIdentifier for cross-app journal aggregation +
    /// retention bookkeeping. Stable string — apps that depend on the
    /// shared `ReflectionPromptStorage` actor filter by this value.
    public static let appIdentifier = "com.sparkanvil.voicetale"

    /// Canonical V1 modality set — text / voice / emoji + the
    /// required `.skip` off-ramp. Exposed as a public constant so
    /// future config builders share the same surface.
    public static let v1AllowedModalities: Set<ReflectionResponseModality> = [
        .text,
        .voice,
        .emoji,
        .skip,
    ]

    /// Build a config for "answer Bramble" — uses Bramble's open
    /// Socratic question as `questions[0]` so the sheet doesn't need a
    /// static question pool. Optional `kitNumber` lets per-kit
    /// retention policy diverge if needed (V1 ships a single 180-day
    /// retention horizon for every kit; Phase C is the surface that
    /// would split policy per kit).
    ///
    /// - Parameters:
    ///   - prompt: The Socratic question Bramble asked. Non-empty +
    ///     trimmed before passing into the config. The config carries
    ///     it as the only question; ForgeUI's sheet surfaces it
    ///     verbatim above the response surface.
    ///   - kitNumber: Optional 1-9 kit identifier. When non-nil, the
    ///     config id encodes the kit so per-kit response history can
    ///     filter cleanly later. When nil, the id encodes
    ///     `"freeform"` — the Phase 1 Tell-flow (no kit context).
    public static func forSocraticPrompt(
        _ prompt: String,
        kitNumber: Int? = nil
    ) -> ReflectionPromptConfig {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let questionPayload = trimmed.isEmpty ? "What did you notice?" : trimmed
        return ReflectionPromptConfig(
            id: "bramble.socratic.\(kitNumber.map(String.init) ?? "freeform")",
            questions: [questionPayload],
            allowedModalities: v1AllowedModalities,
            appIdentifier: appIdentifier,
            kitNumber: kitNumber,
            parentVisible: false
        )
    }
}
