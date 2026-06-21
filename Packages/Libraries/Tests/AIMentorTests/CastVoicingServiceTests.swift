import Testing
import Foundation
@testable import AIMentor
import ForgeAI

@Suite("CastVoicingService")
struct CastVoicingServiceTests {
    @Test func defaultDisabledReturnsStaticCatchphrase() async {
        let service = CastVoicingService()
        // With live voicing OFF the service must return a static catchphrase
        // and MUST NOT invoke FoundationModels — so this test is fast and
        // deterministic regardless of model availability.
        let utterance = await service.respond(
            as: .lean,
            trigger: .greeting,
            kitNumber: 1
        )
        let lean = CastVoiceRegistry.leanProfile
        #expect(lean.catchphrases.contains(utterance))
    }

    @Test func toggleEnablesLiveVoicing() async {
        let service = CastVoicingService()
        #expect(await service.isLiveVoicingEnabled == false)
        await service.setLiveVoicingEnabled(true)
        #expect(await service.isLiveVoicingEnabled == true)
    }

    @Test func registrationIsIdempotent() async throws {
        let service = CastVoicingService()
        try await service.registerProfilesIfNeeded()
        try await service.registerProfilesIfNeeded()
        let registered = await service.isFullyRegistered()
        #expect(registered)
    }

    @Test func staticFallbackCoversAllFourSlugs() async {
        let service = CastVoicingService()
        for slug in CastVoiceRegistry.Slug.allCases {
            let utterance = await service.respond(
                as: slug,
                trigger: .encouragement,
                kitNumber: 2
            )
            #expect(!utterance.isEmpty)
            #expect(utterance != "…", "Static fallback for \(slug) returned the registry-bug sentinel")
        }
    }
}
