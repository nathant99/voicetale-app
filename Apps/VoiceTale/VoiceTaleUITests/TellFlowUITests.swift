//
//  TellFlowUITests.swift
//  VoiceTaleUITests
//
//  Phase 1 quality polish — UI test scaffold for the record → review → reflect
//  golden path. Per `@Docs/FEATURE_PLAN.md` line 121 + `@.claude/rules/testing.md`
//  § UI Tests.
//
//  Tests use launch arguments to configure state without touching the device's
//  mic — the simulator can't capture real audio, so these scaffolds verify the
//  navigation + accessibility surface of each tab. Mic-bound recording is
//  covered by `VoiceAuthoringActorTests` unit tests, not here.
//

import XCTest

final class TellFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTellTabAppearsAfterOnboardingComplete() throws {
        let app = XCUIApplication()
        // Launch argument flips the onboarding gate so the 4-tab surface is
        // immediately visible. Pattern mirrors AppRootView.onboardingCompletedKey.
        app.launchArguments = ["-voicetale.hasCompletedOnboarding", "YES"]
        app.launch()

        // The Tell tab is the default. Looking for the tab-bar entry confirms
        // the TabView built per `@Docs/TECHNICAL_DESIGN.md` § Home Screen.
        let tellTab = app.tabBars.buttons["Tell"]
        XCTAssertTrue(tellTab.waitForExistence(timeout: 5), "Tell tab should be present")
    }

    @MainActor
    func testFourTabsAreReachable() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-voicetale.hasCompletedOnboarding", "YES"]
        app.launch()

        for label in ["Tell", "Adventure", "Progress", "Profile"] {
            let tab = app.tabBars.buttons[label]
            XCTAssertTrue(tab.waitForExistence(timeout: 3), "\(label) tab should be present")
            tab.tap()
        }
    }

    @MainActor
    func testProgressTabSurfacesAnthologyAndProgressPanes() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-voicetale.hasCompletedOnboarding", "YES"]
        app.launch()

        let progressTab = app.tabBars.buttons["Progress"]
        XCTAssertTrue(progressTab.waitForExistence(timeout: 5))
        progressTab.tap()

        // The segmented switcher exposes Anthology / Progress panes. Both
        // should be present in the segmented control.
        let anthologyPaneSegment = app.segmentedControls.buttons["Anthology"]
        let progressPaneSegment = app.segmentedControls.buttons["Progress"]
        XCTAssertTrue(anthologyPaneSegment.waitForExistence(timeout: 3))
        XCTAssertTrue(progressPaneSegment.exists)
    }
}
