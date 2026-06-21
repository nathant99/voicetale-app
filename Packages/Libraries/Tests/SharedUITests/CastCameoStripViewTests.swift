import Testing
import Foundation
import SwiftUI
@testable import SharedUI
import Models

@Suite("CastCameoStripView")
struct CastCameoStripViewTests {
    @Test func initializesWithCameos() {
        let view = CastCameoStripView(
            cameos: [
                CastCameo(slug: "lean", line: "Specificity pulls the body forward."),
                CastCameo(slug: "slow", line: "Pacing makes the tale's shape."),
            ],
            anchorSlug: "lean",
            kitTitle: "The Hook"
        )
        // SwiftUI views can't be assert-rendered without a host; verify the
        // body composes without crashing (which would surface as a fatal
        // error or actor-isolation mismatch at compile time).
        _ = view.body
    }

    @Test func initializesWithoutAnchorOrTitle() {
        // The optional anchor + kit title parameters must default cleanly so
        // the view can be reused in surfaces that don't have a kit context
        // (e.g., a daily-prompt summary or a future cast directory).
        let view = CastCameoStripView(
            cameos: [
                CastCameo(slug: "pivot", line: "The head turns when the meaning rotates."),
            ]
        )
        _ = view.body
    }

    @Test func handlesEmptyCameoList() {
        // Empty list is a degenerate case — must still compose without
        // crashing so callers don't have to guard upstream.
        let view = CastCameoStripView(cameos: [])
        _ = view.body
    }
}
