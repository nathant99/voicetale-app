import Foundation
import AVFoundation
import Models

/// Phase 1.1 voice-character playback. Wraps ``AVAudioEngine`` +
/// ``AVAudioPlayerNode`` + ``AVAudioUnitTimePitch`` so the kid can preview
/// a recorded tale through the picked preset (pitch + rate shift over the
/// original recording — no synthesis, no voice cloning).
///
/// Scope per `@Docs/FEATURE_PLAN.md` § Phase 1.1: whole-tale single-preset
/// preview. Per-beat chunked playback (different preset per beat in one
/// pass) is a Phase 1.2 polish; the persistence layer (the new
/// ``BeatSegment.voiceCharacterSlug``) is already in place for it.
///
/// Concurrency: `@MainActor` + `@Observable` because views drive playback
/// state. The `scheduleFile` completion handler is called by AVFAudio on
/// its internal queue; per `@.claude/rules/concurrency.md` §
/// "framework-delegate protocols invoked off-actor" we hop back to Main
/// via `DispatchQueue.main.async` (NOT `Task { @MainActor in }`) to avoid
/// the `@Observable` registrar's `_dispatch_assert_queue_fail` trap.
@Observable @MainActor
public final class VoiceCharacterPlayback {
    public enum State: Equatable, Sendable {
        case idle
        case loading
        case playing
        case finished
        case failed(String)
    }

    public private(set) var state: State = .idle
    public private(set) var activeFileURL: URL?
    public private(set) var activePreset: VoiceCharacterPreset = .narrator

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let timePitch = AVAudioUnitTimePitch()
    private var hasAttached = false

    public init() {}

    /// True iff this player is currently driving `fileURL` with `preset`.
    /// View rows use this to flip their button between "Preview" and "Stop".
    public func isActive(for fileURL: URL, preset: VoiceCharacterPreset) -> Bool {
        activeFileURL == fileURL && activePreset == preset && state == .playing
    }

    /// Start whole-tale playback with the preset's pitch + rate applied.
    /// Stops any in-flight preview first; safe to call repeatedly from a
    /// chip-strip tap.
    public func preview(fileURL: URL, preset: VoiceCharacterPreset) {
        stop()
        state = .loading
        do {
            let file = try AVAudioFile(forReading: fileURL)
            attachIfNeeded(format: file.processingFormat)
            timePitch.pitch = Float(preset.pitchShiftCents)
            timePitch.rate = preset.rate
            try configureSession()
            try engine.start()
            activeFileURL = fileURL
            activePreset = preset
            player.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.handleFinish()
                }
            }
            player.play()
            state = .playing
        } catch {
            activeFileURL = nil
            state = .failed("Couldn't preview the voice character (\(error.localizedDescription)).")
        }
    }

    /// Stop the active preview. Safe to call from any state. Tears down
    /// player + engine so the next preview re-attaches with the fresh
    /// file format.
    public func stop() {
        if player.isPlaying { player.stop() }
        if engine.isRunning { engine.stop() }
        if activeFileURL != nil { activeFileURL = nil }
        if state != .idle { state = .idle }
    }

    /// Reset the activePreset to `.narrator` without disturbing playback.
    /// Useful for tests + view-level reset paths.
    public func resetActivePreset() {
        activePreset = .narrator
    }

    // MARK: - Private

    private func attachIfNeeded(format: AVAudioFormat) {
        if !hasAttached {
            engine.attach(player)
            engine.attach(timePitch)
            hasAttached = true
        }
        // Engine must be stopped before re-routing — AVAudioEngine's docs
        // allow runtime connection changes but the format must be stable
        // when buffers are mid-flight; we'd rather pay the start cost than
        // risk a routing race.
        if engine.isRunning { engine.stop() }
        engine.disconnectNodeInput(timePitch)
        engine.disconnectNodeInput(engine.mainMixerNode)
        engine.connect(player, to: timePitch, format: format)
        engine.connect(timePitch, to: engine.mainMixerNode, format: format)
    }

    private func configureSession() throws {
        #if !targetEnvironment(simulator)
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [])
        try AVAudioSession.sharedInstance().setActive(true, options: [])
        #endif
    }

    private func handleFinish() {
        if state == .playing { state = .finished }
        activeFileURL = nil
    }
}
