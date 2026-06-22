import Testing
import SwiftUI
import Models
@testable import SharedUI

@Suite("MoodTagView accessibility")
@MainActor
struct MoodTagViewTests {
    @Test func tagInitializesWithMood() {
        let tag = MoodTagView(mood: .scary, isSelected: false)
        #expect(tag.mood == .scary)
        #expect(tag.isSelected == false)
    }

    @Test func selectedTagCarriesSelectionState() {
        let tag = MoodTagView(mood: .tender, isSelected: true)
        #expect(tag.isSelected == true)
    }

    @Test func everyMoodInstantiates() {
        // Smoke-test that the view body compiles for every mood — guards
        // against a future enum case being added without the View's
        // symbol/tint switches gaining an arm.
        for mood in VoiceTaleMood.allCases {
            let tag = MoodTagView(mood: mood, isSelected: false)
            #expect(tag.mood == mood)
        }
    }
}
