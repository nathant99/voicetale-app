import Testing
@testable import AppFeature

@Suite("AppRootView scaffold")
struct AppRootViewTests {
    @Test func appTabCasesCoverFourTabs() {
        #expect(AppRootView.AppTab.allCases.count == 4)
    }

    @Test func appTabTitlesAreNonEmpty() {
        for tab in AppRootView.AppTab.allCases {
            #expect(tab.title.isEmpty == false)
            #expect(tab.systemImage.isEmpty == false)
        }
    }
}
