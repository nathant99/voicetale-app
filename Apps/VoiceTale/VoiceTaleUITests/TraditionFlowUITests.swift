//
//  TraditionFlowUITests.swift
//  VoiceTaleUITests
//
//  Phase 1 quality polish — UI test scaffold for the tradition gallery + daily
//  prompt + anthology navigation paths. Per `@Docs/FEATURE_PLAN.md` line 122.
//

import XCTest

final class TraditionFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testProfileTabReachesSettings() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-voicetale.hasCompletedOnboarding", "YES"]
        app.launch()

        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5))
        profileTab.tap()
        // ProfileTabView renders settings + tradition entry rows; this scaffold
        // confirms the surface is reachable. Specific row assertions deferred
        // until the Profile a11y labels are pinned in a follow-up PR.
    }

    @MainActor
    func testAdventureTabSurfacesWordWorkshopHeader() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-voicetale.hasCompletedOnboarding", "YES"]
        app.launch()

        let adventureTab = app.tabBars.buttons["Adventure"]
        XCTAssertTrue(adventureTab.waitForExistence(timeout: 5))
        adventureTab.tap()

        // The static heading "Word Workshop" rendered by AdventureTabView.
        let header = app.staticTexts["Word Workshop"]
        XCTAssertTrue(header.waitForExistence(timeout: 3), "Word Workshop header should be visible")
    }

    @MainActor
    func testOnboardingShowsWhenNotCompleted() throws {
        let app = XCUIApplication()
        // Explicitly start with onboarding NOT completed. The 5-step
        // ForgeOnboardingFlow surfaces in place of the 4-tab TabView.
        app.launchArguments = ["-voicetale.hasCompletedOnboarding", "NO"]
        app.launch()

        // Onboarding mounts before the TabView — confirm the tab bar is NOT
        // present immediately.
        let tellTab = app.tabBars.buttons["Tell"]
        XCTAssertFalse(tellTab.waitForExistence(timeout: 2), "Tell tab should NOT be visible during onboarding")
    }
}
