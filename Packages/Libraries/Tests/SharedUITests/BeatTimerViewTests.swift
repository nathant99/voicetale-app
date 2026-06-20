import Testing
@testable import SharedUI

@Suite("SharedUI scaffold")
struct SharedUITests {
    @Test func beatTimerViewInitializes() {
        let view = BeatTimerView(elapsedSeconds: 5, beatTimeline: [])
        #expect(view.elapsedSeconds == 5)
    }
}
