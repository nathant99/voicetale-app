import Testing
@testable import SharedUI

@Suite("SharedUI scaffold")
struct SharedUITests {
    @Test func beatTimerViewInitializes() {
        let view = BeatTimerView(elapsedSeconds: 5)
        #expect(view.elapsedSeconds == 5)
        #expect(view.currentBeat == nil)
        #expect(view.isActivelyRecording == false)
    }
}
