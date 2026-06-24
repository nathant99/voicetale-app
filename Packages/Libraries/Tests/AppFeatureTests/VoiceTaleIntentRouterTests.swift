import Testing
@testable import AppFeature

@Suite("VoiceTaleIntentRouter")
struct VoiceTaleIntentRouterTests {
    // MARK: - Destination → Tab mapping

    @Test func tellDestinationMapsToTellTab() {
        #expect(VoiceTaleIntentRouter.tab(for: .tell) == .tell)
    }

    @Test func anthologyDestinationCurrentlyMapsToTellTab() {
        // Anthology lives inside the Tell-tab sibling-navigation surface
        // until a dedicated tab ships. The mapper documents the current
        // shape so the future PR (dedicated tab OR destination param on
        // an intent) updates this in one place.
        #expect(VoiceTaleIntentRouter.tab(for: .anthology) == .tell)
    }

    @Test func progressDestinationMapsToProgressTab() {
        #expect(VoiceTaleIntentRouter.tab(for: .progress) == .progress)
    }

    @Test func traditionDestinationMapsToAdventureTab() {
        // Tradition gallery is surfaced under the Adventure tab. The
        // intent destination is named for the kid-facing concept
        // ("tradition gallery") not the tab; the mapper translates.
        #expect(VoiceTaleIntentRouter.tab(for: .tradition) == .adventure)
    }

    @Test func everyDestinationMapsToAValidTab() {
        // Exhaustiveness — every destination must produce a tab without
        // trapping. Catches future destination additions without an
        // explicit mapper arm.
        for destination in VoiceTaleIntentDestination.allCases {
            let tab = VoiceTaleIntentRouter.tab(for: destination)
            #expect(AppRootView.AppTab.allCases.contains(tab),
                    "destination \(destination) mapped to non-existent tab \(tab)")
        }
    }

    // MARK: - Shortcut phrase plumbing

    @Test func shortcutPhrasesAreNonEmptyAndContainAppName() {
        let phrases = VoiceTaleIntentRouter.shortcutPhrases
        #expect(phrases.openApp.contains("VoiceTale"))
        #expect(phrases.tellATale.contains("VoiceTale"))
        #expect(phrases.showMyTales.contains("VoiceTale"))
        #expect(phrases.showMyProgress.contains("VoiceTale"))
        #expect(phrases.showTraditionGallery.contains("VoiceTale"))
    }

    @Test func shortcutPhrasesReadAsKidInvocations() {
        let phrases = VoiceTaleIntentRouter.shortcutPhrases
        #expect(phrases.openApp == "Open VoiceTale")
        #expect(phrases.tellATale == "Tell a tale in VoiceTale")
        #expect(phrases.showMyTales == "Show my tales in VoiceTale")
        #expect(phrases.showMyProgress == "Show my progress in VoiceTale")
        #expect(phrases.showTraditionGallery == "Show the traditions in VoiceTale")
    }

    @Test func shortcutPhrasesAreAllDistinct() {
        // Every phrase MUST be unique so Siri's matcher can disambiguate
        // among the four registered AppShortcuts. A collision here would
        // make the runtime register two identical phrases for different
        // intents — Siri would coin-flip which intent fires.
        let phrases = VoiceTaleIntentRouter.shortcutPhrases
        let all = [
            phrases.openApp,
            phrases.tellATale,
            phrases.showMyTales,
            phrases.showMyProgress,
            phrases.showTraditionGallery,
        ]
        #expect(Set(all).count == all.count)
    }
}

@Suite("VoiceTaleIntentDestination")
struct VoiceTaleIntentDestinationTests {
    @Test func allDestinationsHaveDisplayLabels() {
        for destination in VoiceTaleIntentDestination.allCases {
            #expect(!destination.displayLabel.isEmpty,
                    "destination \(destination) missing displayLabel")
        }
    }

    @Test func rawValuesAreStableForSerialization() {
        // Pin the raw values — these become the wire format if an
        // intent's `destination` ever travels through a payload (e.g.,
        // user-activity restoration). Reordering / renaming a case in
        // the source must NOT silently change the wire format.
        #expect(VoiceTaleIntentDestination.tell.rawValue == "tell")
        #expect(VoiceTaleIntentDestination.anthology.rawValue == "anthology")
        #expect(VoiceTaleIntentDestination.progress.rawValue == "progress")
        #expect(VoiceTaleIntentDestination.tradition.rawValue == "tradition")
    }
}
