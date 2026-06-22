import Testing
import Foundation
@testable import AIMentor
import ForgeAI
import Models

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

    @Test func slugForMoodIsStableAndCoversAllFourMoods() {
        // Mapping must be total + deterministic so each saved tale routes to a
        // predictable cast voice. Codifies the table in `CastVoicingService.slugForMood`.
        #expect(CastVoicingService.slugForMood(.funny) == .refrain)
        #expect(CastVoicingService.slugForMood(.scary) == .slow)
        #expect(CastVoicingService.slugForMood(.tender) == .lean)
        #expect(CastVoicingService.slugForMood(.wild) == .pivot)
    }

    @Test func slugForMoodSpansEveryCastMember() {
        // Defensive: the 4-mood→4-cast mapping must exhibit every cast member.
        // If a future refactor consolidates the mapping onto fewer cast voices,
        // this catches the regression — the design contract is "every mood
        // routes to a different cast voice over a session that explores all
        // four moods."
        let routedSlugs = Set(VoiceTaleMood.allCases.map(CastVoicingService.slugForMood))
        #expect(routedSlugs.count == CastVoiceRegistry.Slug.allCases.count)
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
