import Testing
import ForgeAI
@testable import AIMentor

@Suite("CastVoiceRegistry")
struct CastVoiceRegistryTests {
    @Test func registryHasFourProfiles() {
        let profiles = CastVoiceRegistry.allProfiles
        #expect(profiles.count == 4)
    }

    @Test func everyProfileHasAtLeastThreeCatchphrases() {
        // CastVoiceProfile init precondition: ≥3 catchphrases.
        // Building the profiles in `static let` would crash at module load if
        // the precondition failed; the explicit assertion adds defense-in-depth.
        for profile in CastVoiceRegistry.allProfiles {
            #expect(profile.catchphrases.count >= 3)
        }
    }

    @Test func everyProfileEmbodimentNamesItsPrimitive() {
        // Embodiment statements must name the curricular primitive
        // (HOOK / TURN / CALLBACK / PACING) explicitly. This is the
        // "the cast IS the curriculum" load-bearing rule from
        // `.claude/rules/distributed-narrative.md`.
        #expect(CastVoiceRegistry.leanProfile.embodiment.contains("HOOK"))
        #expect(CastVoiceRegistry.pivotProfile.embodiment.contains("TURN"))
        #expect(CastVoiceRegistry.refrainProfile.embodiment.contains("CALLBACK"))
        #expect(CastVoiceRegistry.slowProfile.embodiment.contains("PACING"))
    }

    @Test func noneOfTheVoicetaleProfilesAreReviewerGated() {
        // Writing-craft cluster Pattern B: cast members are friends of the
        // hero mascot, not trauma-adjacent content.
        for profile in CastVoiceRegistry.allProfiles {
            #expect(profile.reviewerGated == false)
        }
    }

    @Test func profileLookupBySlugIsStable() {
        for slug in CastVoiceRegistry.Slug.allCases {
            let profile = CastVoiceRegistry.profile(for: slug)
            #expect(profile.id == slug.rawValue)
            #expect(profile.displayName == slug.displayName)
        }
    }

    @Test func registerInstallsAllProfilesIntoCastDialog() async throws {
        let castDialog = CastDialog()
        try await CastVoiceRegistry.register(into: castDialog)
        let count = await castDialog.registeredCount
        #expect(count == 4)
        for slug in CastVoiceRegistry.Slug.allCases {
            let registered = await castDialog.isRegistered(slug.rawValue)
            #expect(registered, "Missing registration for slug=\(slug.rawValue)")
        }
    }
}
