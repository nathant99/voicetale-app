import Foundation
import Models

/// Loads Phase 1 question kits (01-04) bundled under
/// `Services/Resources/QuestionKits/` via `Bundle.module`. Per
/// `@Docs/IMPLEMENTATION_HANDOFF.md` § 6, kits load lazily on view
/// `onAppear`, not at app launch.
public enum QuestionKitLoader {
    public enum LoaderError: Error, Sendable, Equatable {
        case resourceMissing(String)
        case decodingFailed(String, String)
    }

    /// Canonical Phase 1 kit filenames. Stays in sync with the JSON files in
    /// `Sources/Services/Resources/QuestionKits/`.
    public static let phase1Filenames: [String] = [
        "kit_01_hook",
        "kit_02_sensory_detail",
        "kit_03_arc_completeness",
        "kit_04_mood",
    ]

    /// Phase 1.1 kit filenames. Voice-character chooser; surfaces only when
    /// the kid has reached the Phase 1.1 onboarding (sessionsCompleted ≥ 2)
    /// per `@Docs/FEATURE_PLAN.md` § Phase 1.1.
    public static let phase11Filenames: [String] = [
        "kit_05_voice_character",
    ]

    /// Phase 2 kit filenames (kits 06-09: mood / pacing / surprise / closing)
    /// per `@Docs/FEATURE_PLAN.md` § Phase 2. Each kit anchors to one cast
    /// member (Lean / Slow / Pivot / Refrain in that order) with cameos from
    /// the other three so all four listener-cast voices surface across the
    /// rotation.
    public static let phase2Filenames: [String] = [
        "kit_06_mood",
        "kit_07_pacing",
        "kit_08_surprise",
        "kit_09_closing",
    ]

    public static func loadKit(named name: String) throws -> QuestionKit {
        guard let url = ResourceLookup.url(
            forResource: name,
            withExtension: "json",
            subdirectory: "QuestionKits"
        ) else {
            throw LoaderError.resourceMissing(name)
        }
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode(QuestionKit.self, from: data)
        } catch {
            throw LoaderError.decodingFailed(name, "\(error)")
        }
    }

    public static func loadAllPhase1Kits() throws -> [QuestionKit] {
        try phase1Filenames.map { try loadKit(named: $0) }
    }

    /// Load every Phase 1.1 kit (currently kit 05). Throws on missing /
    /// malformed JSON so QA catches drift between Models + bundled resources.
    public static func loadAllPhase11Kits() throws -> [QuestionKit] {
        try phase11Filenames.map { try loadKit(named: $0) }
    }

    /// Load every Phase 2 kit (kits 06-09). Same throw-on-drift semantics as
    /// the Phase 1 / 1.1 loaders so future asset gaps surface in tests.
    public static func loadAllPhase2Kits() throws -> [QuestionKit] {
        try phase2Filenames.map { try loadKit(named: $0) }
    }

    /// Pick one of the 4 Phase 1 kits based on a stable input — typically the
    /// current tale's session index or the recorded mood — so each saved
    /// tale's reflection surfaces a different cast voice without random churn.
    /// Phase 1 DN-S Move B per `@Docs/HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md`.
    public static func loadKitForRotation(seed: Int) throws -> QuestionKit {
        let index = abs(seed) % phase1Filenames.count
        return try loadKit(named: phase1Filenames[index])
    }

    /// ForgeMasteryEngine Phase C — load the kit corresponding to a
    /// specific ``KitID``. The kit JSON filenames follow the
    /// `kit_0N_<slug>` convention; this helper resolves the right
    /// `0N` index from the `KitID.rawValue` (1-based) so the same
    /// canonical mapping carries across Phase 1 / 1.1 / Phase 2.
    /// `nil` return means the ID is registered but the corresponding
    /// JSON isn't bundled — defensive against a future kit-id
    /// extension that ships ahead of the JSON resource.
    public static func loadKit(forKitID kit: KitID) throws -> QuestionKit? {
        let allFilenames = phase1Filenames + phase11Filenames + phase2Filenames
        let prefix = String(format: "kit_%02d_", kit.rawValue)
        guard let filename = allFilenames.first(where: { $0.hasPrefix(prefix) }) else {
            return nil
        }
        return try loadKit(named: filename)
    }

    /// ForgeMasteryEngine Phase C — recommendation-first rotation per
    /// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase C. When
    /// `recommendation` is non-nil + the kit's JSON is bundled, return
    /// that kit. Otherwise fall back to the existing week-of-year
    /// rotation via ``loadKitForRotation(seed:)``. This preserves the
    /// existing cold-launch / new-kid register (no signal → unchanged
    /// rotation) while letting the engine drive the surface once
    /// signal exists.
    public static func loadKitForRotation(
        seed: Int,
        recommendation: KitMasteryRecommendation?
    ) throws -> QuestionKit {
        if let recommendation, let kit = try loadKit(forKitID: recommendation.kit) {
            return kit
        }
        return try loadKitForRotation(seed: seed)
    }
}
