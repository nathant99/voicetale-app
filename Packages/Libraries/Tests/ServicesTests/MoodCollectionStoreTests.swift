import Testing
import Foundation
import SwiftData
@testable import Services
import Models
import ForgeModels

/// Tests for ``VoiceTaleStore``'s Phase 2 mood-collection CRUD.
/// Per `@.claude/rules/testing.md` § Crash-Resilience Defaults #4 every
/// in-memory container passes `cloudKitDatabase: .none` (already handled by
/// ``VoiceTalePersistence.makeInMemoryContainer``).
@MainActor
@Suite("VoiceTaleStore mood collections")
struct MoodCollectionStoreTests {
    private func newContext() throws -> ModelContext {
        let container = try VoiceTalePersistence.makeInMemoryContainer()
        return ModelContext(container)
    }

    @Test func createCollectionPersistsRow() throws {
        let context = try newContext()
        let collection = try VoiceTaleStore.createCollection(
            name: "Bedtime spooks",
            mood: .scary,
            in: context
        )
        #expect(collection.name == "Bedtime spooks")
        #expect(collection.mood == .scary)
        #expect(collection.taleCount == 0)
        let fetched = VoiceTaleStore.fetchCollections(in: context)
        #expect(fetched.count == 1)
        #expect(fetched.first?.id == collection.id)
    }

    @Test func createCollectionTrimsAndBoundsName() throws {
        let context = try newContext()
        let padded = "   Tender ones   "
        let collection = try VoiceTaleStore.createCollection(
            name: padded,
            mood: .tender,
            in: context
        )
        #expect(collection.name == "Tender ones")
    }

    @Test func createCollectionRejectsEmptyName() throws {
        let context = try newContext()
        #expect(throws: VoiceTaleStore.CollectionStoreError.nameEmpty) {
            _ = try VoiceTaleStore.createCollection(name: "   ", mood: nil, in: context)
        }
    }

    @Test func createCollectionEnforcesCapacity() throws {
        let context = try newContext()
        // Author up-to-capacity collections; each one passes.
        for i in 0..<VoiceTaleStore.moodCollectionCapacity {
            _ = try VoiceTaleStore.createCollection(name: "C\(i)", mood: nil, in: context)
        }
        #expect(throws: VoiceTaleStore.CollectionStoreError.atCapacity) {
            _ = try VoiceTaleStore.createCollection(name: "OneTooMany", mood: nil, in: context)
        }
    }

    @Test func addTaleIsIdempotent() throws {
        let context = try newContext()
        let collection = try VoiceTaleStore.createCollection(
            name: "Friday-funny",
            mood: .funny,
            in: context
        )
        let taleID = UUID()
        VoiceTaleStore.addTaleToCollection(collectionID: collection.id, taleID: taleID, in: context)
        VoiceTaleStore.addTaleToCollection(collectionID: collection.id, taleID: taleID, in: context)
        let fetched = VoiceTaleStore.fetchCollections(in: context).first
        let unwrapped = try #require(fetched)
        #expect(unwrapped.taleIDs == [taleID])
    }

    @Test func removeTaleClearsMembership() throws {
        let context = try newContext()
        let collection = try VoiceTaleStore.createCollection(name: "Mixed", mood: nil, in: context)
        let a = UUID()
        let b = UUID()
        VoiceTaleStore.addTaleToCollection(collectionID: collection.id, taleID: a, in: context)
        VoiceTaleStore.addTaleToCollection(collectionID: collection.id, taleID: b, in: context)
        VoiceTaleStore.removeTaleFromCollection(collectionID: collection.id, taleID: a, in: context)
        let fetched = try #require(VoiceTaleStore.fetchCollections(in: context).first)
        #expect(fetched.taleIDs == [b])
    }

    @Test func deleteCollectionRemovesRow() throws {
        let context = try newContext()
        let keep = try VoiceTaleStore.createCollection(name: "Keep", mood: nil, in: context)
        let drop = try VoiceTaleStore.createCollection(name: "Drop", mood: nil, in: context)
        VoiceTaleStore.deleteCollection(id: drop.id, in: context)
        let remaining = VoiceTaleStore.fetchCollections(in: context).map(\.id)
        #expect(remaining == [keep.id])
    }

    @Test func largestCollectionTaleCountReportsMax() throws {
        let context = try newContext()
        let a = try VoiceTaleStore.createCollection(name: "A", mood: nil, in: context)
        let b = try VoiceTaleStore.createCollection(name: "B", mood: nil, in: context)
        for _ in 0..<2 {
            VoiceTaleStore.addTaleToCollection(collectionID: a.id, taleID: UUID(), in: context)
        }
        for _ in 0..<4 {
            VoiceTaleStore.addTaleToCollection(collectionID: b.id, taleID: UUID(), in: context)
        }
        #expect(VoiceTaleStore.largestCollectionTaleCount(in: context) == 4)
    }

    @Test func emptyStoreLargestCountIsZero() throws {
        let context = try newContext()
        #expect(VoiceTaleStore.largestCollectionTaleCount(in: context) == 0)
    }

    @Test func collectionsSortNewestFirst() throws {
        let context = try newContext()
        let earlier = Date(timeIntervalSince1970: 1_700_000_000)
        let later = Date(timeIntervalSince1970: 1_700_001_000)
        let first = try VoiceTaleStore.createCollection(name: "First", mood: nil, now: earlier, in: context)
        let second = try VoiceTaleStore.createCollection(name: "Second", mood: nil, now: later, in: context)
        let ordered = VoiceTaleStore.fetchCollections(in: context).map(\.id)
        #expect(ordered == [second.id, first.id])
    }
}

@MainActor
@Suite("CriteriaSnapshot mood-collection curator arm")
struct CriteriaSnapshotCuratorArmTests {
    @Test func curatorArmFiresAtThreeTales() {
        let snapshot = CriteriaSnapshot(
            totalTales: 5,
            currentStreakDays: 0,
            traditionsExplored: 0,
            funnyTales: 0,
            scaryTales: 0,
            tenderTales: 0,
            wildTales: 0,
            largestCollectionTaleCount: 3
        )
        #expect(snapshot.satisfies("mood_collection_curator"))
    }

    @Test func curatorArmDoesNotFireBelowThreshold() {
        let snapshot = CriteriaSnapshot(
            totalTales: 5,
            currentStreakDays: 0,
            traditionsExplored: 0,
            funnyTales: 0,
            scaryTales: 0,
            tenderTales: 0,
            wildTales: 0,
            largestCollectionTaleCount: 2
        )
        #expect(snapshot.satisfies("mood_collection_curator") == false)
    }
}
