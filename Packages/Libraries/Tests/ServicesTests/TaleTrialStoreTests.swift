import Testing
import Foundation
import SwiftData
@testable import Services
import Models

@MainActor
@Suite("VoiceTaleStore Tale Trial counter")
struct TaleTrialStoreTests {
    private func newContext() throws -> ModelContext {
        let container = try VoiceTalePersistence.makeInMemoryContainer()
        return ModelContext(container)
    }

    @Test func bumpTaleTrialPlaysReturnsOneOnFirstCall() throws {
        let context = try newContext()
        let count = VoiceTaleStore.bumpTaleTrialPlays(in: context)
        #expect(count == 1)
        #expect(VoiceTaleStore.progressSnapshot(in: context).taleTrialPlays == 1)
    }

    @Test func bumpTaleTrialPlaysIsAdditive() throws {
        let context = try newContext()
        _ = VoiceTaleStore.bumpTaleTrialPlays(in: context)
        _ = VoiceTaleStore.bumpTaleTrialPlays(in: context)
        let third = VoiceTaleStore.bumpTaleTrialPlays(in: context)
        #expect(third == 3)
        #expect(VoiceTaleStore.progressSnapshot(in: context).taleTrialPlays == 3)
    }

    @Test func bumpTaleTrialPlaysSurvivesContextReload() throws {
        let container = try VoiceTalePersistence.makeInMemoryContainer()
        let firstContext = ModelContext(container)
        _ = VoiceTaleStore.bumpTaleTrialPlays(in: firstContext)
        _ = VoiceTaleStore.bumpTaleTrialPlays(in: firstContext)
        // Open a second context against the same container — should
        // observe the persisted count, not a fresh row.
        let secondContext = ModelContext(container)
        #expect(VoiceTaleStore.progressSnapshot(in: secondContext).taleTrialPlays == 2)
    }
}
