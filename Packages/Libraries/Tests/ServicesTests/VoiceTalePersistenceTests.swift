import Testing
import Foundation
@testable import Services
import Models

@Suite("VoiceTalePersistence")
struct VoiceTalePersistenceTests {
    @Test func inMemoryContainerInitializes() throws {
        let container = try VoiceTalePersistence.makeInMemoryContainer()
        #expect(container.schema.entities.isEmpty == false)
    }
}
