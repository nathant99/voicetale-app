import Testing
import Foundation
import ForgeModels
import ForgeUI
@testable import AppFeature

/// Phase A coverage for ``VoiceTaleReflectionConfigCatalog`` per
/// `@Docs/PLAN_FORGEREFLECTION_LIFT.md` § Phase A. Pure-function
/// builders — no SwiftUI host needed.
@Suite("VoiceTaleReflectionConfigCatalog")
struct VoiceTaleReflectionConfigCatalogTests {
    // MARK: - App identifier

    @Test func appIdentifierIsStableCanonicalValue() {
        // Cross-app journal aggregation depends on this string staying
        // stable. Lock the value so a rename is a visible diff.
        #expect(
            VoiceTaleReflectionConfigCatalog.appIdentifier
                == "com.sparkanvil.voicetale"
        )
    }

    // MARK: - V1 allowed-modalities invariants

    @Test func v1AllowedModalitiesAlwaysIncludesSkip() {
        // The trauma-informed off-ramp precondition lives at
        // `ReflectionPromptConfig.init` — if `.skip` is missing the
        // build traps. Lock the invariant at the catalog surface so a
        // refactor that drops `.skip` fails this test before it ships
        // a crash.
        let set = VoiceTaleReflectionConfigCatalog.v1AllowedModalities
        #expect(set.contains(.skip))
    }

    @Test func v1AllowedModalitiesOmitsDrawing() {
        // V1 deliberately omits `.drawing` per the plan doc § Phase A.
        // Re-introducing it requires Phase D telemetry + a PencilKit
        // dependency conversation — visible diff first.
        let set = VoiceTaleReflectionConfigCatalog.v1AllowedModalities
        #expect(!set.contains(.drawing))
    }

    @Test func v1AllowedModalitiesV1Set() {
        // Canonical set is text / voice / emoji + skip.
        let set = VoiceTaleReflectionConfigCatalog.v1AllowedModalities
        #expect(set == [.text, .voice, .emoji, .skip])
    }

    // MARK: - forSocraticPrompt builder

    @Test func socraticPromptCarriesQuestionAsSingleEntry() {
        let config = VoiceTaleReflectionConfigCatalog
            .forSocraticPrompt("What surprised you about that tale?")
        #expect(config.questions.count == 1)
        #expect(config.questions.first == "What surprised you about that tale?")
    }

    @Test func socraticPromptTrimsWhitespace() {
        // Bramble's prompt builder occasionally hands over text with
        // trailing newlines; lock the trim invariant at the catalog
        // surface.
        let config = VoiceTaleReflectionConfigCatalog
            .forSocraticPrompt("   Why did you choose that ending?   \n")
        #expect(config.questions.first == "Why did you choose that ending?")
    }

    @Test func socraticPromptEmptyOrBlankFallsBackToAntiBlankCopy() {
        // Defensive copy if a caller passes empty / whitespace —
        // `ReflectionPromptConfig.init` precondition requires 1-2
        // non-empty questions; the catalog absorbs the bad input
        // rather than trapping at the framework boundary.
        let empty = VoiceTaleReflectionConfigCatalog.forSocraticPrompt("")
        #expect(empty.questions.first == "What did you notice?")
        let blank = VoiceTaleReflectionConfigCatalog.forSocraticPrompt("   \n  ")
        #expect(blank.questions.first == "What did you notice?")
    }

    @Test func socraticPromptKitNumberFlowsIntoId() {
        // The id must encode the kit so per-kit history can filter
        // cleanly later. Locked at the catalog so a refactor of the
        // id scheme is a visible diff.
        let kit5 = VoiceTaleReflectionConfigCatalog
            .forSocraticPrompt("Where did the turn happen?", kitNumber: 5)
        #expect(kit5.id == "bramble.socratic.5")
        #expect(kit5.kitNumber == 5)
        let freeform = VoiceTaleReflectionConfigCatalog
            .forSocraticPrompt("Anything you'd tell differently?")
        #expect(freeform.id == "bramble.socratic.freeform")
        #expect(freeform.kitNumber == nil)
    }

    @Test func socraticPromptDefaultsParentVisibleFalse() {
        // V1 ships all configs kid-only; Phase D adds the explicit
        // opt-in surface. Lock the default so a refactor doesn't
        // silently flip the privacy register.
        let config = VoiceTaleReflectionConfigCatalog
            .forSocraticPrompt("Why?")
        #expect(config.parentVisible == false)
    }

    @Test func socraticPromptUsesCanonicalAppIdentifier() {
        let config = VoiceTaleReflectionConfigCatalog
            .forSocraticPrompt("Why?", kitNumber: 3)
        #expect(config.appIdentifier == "com.sparkanvil.voicetale")
    }

    @Test func socraticPromptInheritsV1Modalities() {
        // Catalog is the single source of truth for V1 modality scope.
        let config = VoiceTaleReflectionConfigCatalog
            .forSocraticPrompt("Why?")
        #expect(
            config.allowedModalities
                == VoiceTaleReflectionConfigCatalog.v1AllowedModalities
        )
    }
}
