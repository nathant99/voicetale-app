import Testing
import Foundation
@testable import Models

@Suite("MoodCollectionData")
struct MoodCollectionDataTests {
    @Test func taleCountReflectsIDsLength() {
        let collection = MoodCollectionData(
            id: UUID(),
            name: "Friday-funny",
            mood: .funny,
            taleIDs: [UUID(), UUID(), UUID()]
        )
        #expect(collection.taleCount == 3)
    }

    @Test func containsReturnsTrueForMembership() {
        let memberID = UUID()
        let collection = MoodCollectionData(
            id: UUID(),
            name: "Tender ones",
            mood: .tender,
            taleIDs: [memberID, UUID()]
        )
        #expect(collection.contains(memberID))
        #expect(collection.contains(UUID()) == false)
    }

    @Test func defaultInitDefaultsAreEmptyAndAnyMood() {
        let collection = MoodCollectionData(id: UUID(), name: "Mixed")
        #expect(collection.mood == nil)
        #expect(collection.taleIDs.isEmpty)
    }

    @Test func codableRoundTrips() throws {
        let original = MoodCollectionData(
            id: UUID(),
            name: "Bedtime spooks",
            mood: .scary,
            taleIDs: [UUID()]
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MoodCollectionData.self, from: encoded)
        #expect(decoded == original)
    }
}
