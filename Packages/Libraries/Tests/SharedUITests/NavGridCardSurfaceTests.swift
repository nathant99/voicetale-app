import Testing
import SwiftUI
@testable import SharedUI

@Suite("NavGridCardSurface")
@MainActor
struct NavGridCardSurfaceTests {
    @Test func defaultCornerRadiusMatchesPortfolioConvention() {
        let modifier = NavGridCardSurface(tint: .orange, reduceTransparency: false)
        // 16pt is the portfolio-canonical card corner radius per
        // .claude/rules/liquid-glass.md § code patterns.
        #expect(modifier.cornerRadius == 16)
    }

    @Test func explicitCornerRadiusIsHonored() {
        let modifier = NavGridCardSurface(tint: .green, reduceTransparency: true, cornerRadius: 24)
        #expect(modifier.cornerRadius == 24)
    }

    @Test func reduceTransparencyFlagIsCarriedThrough() {
        let glass = NavGridCardSurface(tint: .blue, reduceTransparency: false)
        let solid = NavGridCardSurface(tint: .blue, reduceTransparency: true)
        #expect(glass.reduceTransparency == false)
        #expect(solid.reduceTransparency == true)
    }

    @Test func everyAdoptionSurfaceCanComposeTheModifier() {
        // Sanity-check the View extension compiles + composes against a
        // bare Text. Reaching this line is the assertion — a regression
        // that breaks the extension blocks compilation upstream.
        let _ = Text("nav-grid").navGridCardSurface(
            tint: .accentColor,
            reduceTransparency: false
        )
        #expect(Bool(true))
    }
}
