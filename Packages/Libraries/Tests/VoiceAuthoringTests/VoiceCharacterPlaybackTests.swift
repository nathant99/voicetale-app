import Testing
import Foundation
@testable import VoiceAuthoring
import Models

@Suite("VoiceCharacterPlayback")
@MainActor
struct VoiceCharacterPlaybackTests {
    @Test func initialStateIsIdle() {
        let player = VoiceCharacterPlayback()
        #expect(player.state == .idle)
        #expect(player.activeFileURL == nil)
        #expect(player.activePreset == .narrator)
    }

    @Test func stopOnIdleIsNoOp() {
        let player = VoiceCharacterPlayback()
        player.stop()
        #expect(player.state == .idle)
        #expect(player.activeFileURL == nil)
    }

    @Test func isActiveReturnsFalseOnIdle() {
        let player = VoiceCharacterPlayback()
        let fakeURL = URL(fileURLWithPath: "/tmp/does-not-exist.m4a")
        #expect(player.isActive(for: fakeURL, preset: .hero) == false)
        #expect(player.isActive(for: fakeURL, preset: .narrator) == false)
    }

    @Test func previewWithMissingFileTransitionsToFailed() {
        let player = VoiceCharacterPlayback()
        let missing = URL(fileURLWithPath: "/tmp/voicetale-tests/\(UUID().uuidString).m4a")
        player.preview(fileURL: missing, preset: .hero)
        guard case .failed = player.state else {
            Issue.record("expected .failed, got \(player.state)")
            return
        }
        #expect(player.activeFileURL == nil)
    }

    @Test func resetActivePresetReturnsToNarrator() {
        let player = VoiceCharacterPlayback()
        let missing = URL(fileURLWithPath: "/tmp/voicetale-tests/\(UUID().uuidString).m4a")
        // Drive into failed state with a non-narrator preset, then reset.
        player.preview(fileURL: missing, preset: .ogre)
        // Even on failed path, activePreset may have been set during attempt; reset returns to narrator.
        player.resetActivePreset()
        #expect(player.activePreset == .narrator)
    }

    @Test func stopAfterFailedReturnsToIdle() {
        let player = VoiceCharacterPlayback()
        let missing = URL(fileURLWithPath: "/tmp/voicetale-tests/\(UUID().uuidString).m4a")
        player.preview(fileURL: missing, preset: .sage)
        player.stop()
        #expect(player.state == .idle)
        #expect(player.activeFileURL == nil)
    }
}
