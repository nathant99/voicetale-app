import Testing
import Foundation
@testable import Services
import Models

@Suite("TaleSpotlightItem")
struct TaleSpotlightItemTests {
    @Test func indexableShapeRoundTripsFromVoiceTaleEntry() {
        let id = UUID()
        let tale = VoiceTaleEntry(
            id: id,
            title: "Bedtime spook",
            mood: .scary,
            recordedAt: Date(timeIntervalSince1970: 1_700_000_000),
            durationSeconds: 90,
            beatTimeline: [],
            transcript: "transcript-must-not-travel-to-spotlight",
            reflection: nil
        )
        let item = TaleSpotlightItem(tale: tale)
        #expect(item.spotlightID == id.uuidString)
        #expect(item.spotlightTitle == "Bedtime spook")
        #expect(item.spotlightDescription.contains("Scary"))
        #expect(item.spotlightThumbnailName == nil)
    }

    @Test func keywordsCarryMoodCategoricallyButNeverTranscript() {
        let tale = VoiceTaleEntry(
            id: UUID(),
            title: "Wild thing",
            mood: .wild,
            recordedAt: Date(),
            durationSeconds: 60,
            beatTimeline: [],
            transcript: "the kid said something private here",
            reflection: nil
        )
        let item = TaleSpotlightItem(tale: tale)
        #expect(item.spotlightKeywords.contains("wild"))
        #expect(item.spotlightKeywords.contains("Wild"))
        for keyword in item.spotlightKeywords {
            #expect(keyword.contains("private") == false,
                    "Spotlight keyword leaked transcript content: \(keyword)")
        }
        #expect(item.spotlightDescription.contains("private") == false)
    }

    @Test func spotlightDomainIdentifierIsStable() {
        // The domain identifier is load-bearing for `deindexDomain` — if
        // it ever drifts, an erase-all surface that uses the old domain
        // can't clean up the new entries. Locking the string here makes
        // an accidental rename test-visible.
        #expect(
            VoiceTaleSpotlightIndexer.domainIdentifier
                == "com.sparkanvil.voicetale.tales"
        )
    }

    @Test func everyMoodMapsToANonEmptyKeywordSet() {
        for mood in VoiceTaleMood.allCases {
            let item = TaleSpotlightItem(
                id: UUID(),
                title: "t",
                mood: mood,
                recordedAt: Date()
            )
            #expect(item.spotlightKeywords.isEmpty == false)
            #expect(item.spotlightKeywords.contains(mood.rawValue))
            #expect(item.spotlightKeywords.contains(mood.displayLabel))
        }
    }
}
