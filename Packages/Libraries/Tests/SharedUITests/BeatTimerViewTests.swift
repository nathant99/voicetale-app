import Testing
@testable import SharedUI
import Models

@Suite("SharedUI scaffold")
struct SharedUITests {
    @Test func beatTimerViewInitializes() {
        let view = BeatTimerView(elapsedSeconds: 5)
        #expect(view.elapsedSeconds == 5)
        #expect(view.currentBeat == nil)
        #expect(view.isActivelyRecording == false)
    }

    @Test func beatTimerViewAcceptsCurrentBeat() {
        let view = BeatTimerView(elapsedSeconds: 12, currentBeat: .setup, isActivelyRecording: true)
        #expect(view.currentBeat == .setup)
        #expect(view.isActivelyRecording)
    }

    @Test func beatTimerViewAcceptsEveryBeatCase() {
        // Ensure the view can be constructed for every beat — guards against
        // a future ArcBeat case being added without the timeline picking it up.
        for beat in ArcBeat.allCases {
            let view = BeatTimerView(elapsedSeconds: 0, currentBeat: beat, isActivelyRecording: true)
            #expect(view.currentBeat == beat)
        }
    }
}
