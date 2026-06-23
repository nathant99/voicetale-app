import Testing
import Foundation
@testable import AppFeature
import Models

/// Coverage for the persisted mood filter on AnthologyView. The
/// `@AppStorage` value type is a raw `String` (empty = "All"); the
/// view exposes pure `static` encode / decode helpers so the round-trip
/// can be locked without spinning up a SwiftUI host.
@MainActor
@Suite("AnthologyFilterPersistence")
struct AnthologyFilterPersistenceTests {
    @Test func decodeEmptyResolvesToNilAllSelection() {
        #expect(AnthologyView.decodeFilter("") == nil)
    }

    @Test func decodeUnknownRawResolvesToNil() {
        // Defensive: a stray write to the AppStorage key (or a future
        // mood-rename) should not crash — fallback is the "All" selection.
        #expect(AnthologyView.decodeFilter("not_a_real_mood") == nil)
    }

    @Test func decodeKnownRawRoundTrips() {
        for mood in VoiceTaleMood.allCases {
            #expect(AnthologyView.decodeFilter(mood.rawValue) == mood)
        }
    }

    @Test func encodeNilProducesEmptyString() {
        #expect(AnthologyView.encodeFilter(nil) == "")
    }

    @Test func encodeMoodProducesRawValue() {
        for mood in VoiceTaleMood.allCases {
            #expect(AnthologyView.encodeFilter(mood) == mood.rawValue)
        }
    }
}
