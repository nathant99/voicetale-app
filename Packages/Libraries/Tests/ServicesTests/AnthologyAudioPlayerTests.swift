import Testing
import Foundation
@testable import Services

/// ``AnthologyAudioPlayer`` exercises ``AVAudioPlayer`` which needs an
/// audio-session-bootstrappable surface — these tests verify the
/// state-machine + URL-tracking surface without forcing playback. Real
/// playback validation happens in UI tests / device runs.
@MainActor
@Suite("AnthologyAudioPlayer state machine")
struct AnthologyAudioPlayerTests {
    @Test func initialStateIsIdleWithNoActiveURL() {
        let player = AnthologyAudioPlayer()
        #expect(player.state == .idle)
        #expect(player.activeFileURL == nil)
        #expect(player.progressFraction == 0)
        #expect(player.elapsedSeconds == 0)
        #expect(player.totalSeconds == 0)
    }

    @Test func isActiveReturnsFalseBeforePlayback() {
        let player = AnthologyAudioPlayer()
        let url = URL(fileURLWithPath: "/tmp/anthology-test.m4a")
        #expect(player.isActive(for: url) == false)
    }

    @Test func stopOnIdleIsNoOp() {
        let player = AnthologyAudioPlayer()
        player.stop()
        #expect(player.state == .idle)
        #expect(player.activeFileURL == nil)
    }

    @Test func pauseOnIdleIsNoOp() {
        let player = AnthologyAudioPlayer()
        player.pause()
        #expect(player.state == .idle)
    }

    @Test func playWithMissingFileTransitionsToFailedState() {
        let player = AnthologyAudioPlayer()
        let missingURL = URL(fileURLWithPath: "/tmp/voicetale-missing-\(UUID().uuidString).m4a")
        player.play(fileURL: missingURL)
        // AVAudioPlayer init throws when the file doesn't exist; the player
        // surfaces this as `.failed(_)` and resets activeFileURL to nil.
        if case .failed = player.state {
            #expect(true)
        } else {
            Issue.record("Expected .failed for missing file; got \(player.state)")
        }
        #expect(player.activeFileURL == nil)
    }
}
