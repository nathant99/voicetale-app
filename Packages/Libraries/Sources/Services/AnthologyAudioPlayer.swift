import Foundation
import AVFoundation

/// `@Observable @MainActor` player for re-listening to saved tales in the
/// Anthology tab. Wraps a single ``AVAudioPlayer`` so cards can drive
/// play / pause / stop / scrub from the SwiftUI surface without per-card
/// player state.
///
/// VoiceTale's recordings live in the app container's Documents directory
/// (per `@Docs/TECHNICAL_DESIGN.md` § Privacy — never iCloud-synced) so the
/// player resolves a local file URL and never opens a network connection.
///
/// Concurrency: `@MainActor` because the player drives view state. The
/// ``progressFraction`` poll uses `Timer.publish` on the main runloop +
/// `DispatchQueue.main.async` (NOT `Task { @MainActor in }`) per
/// `@.claude/rules/concurrency.md` § "Timer.scheduledTimer + Task ...
/// dispatch_assert_queue_fail" to avoid the `@Observable` registrar trap.
@Observable @MainActor
public final class AnthologyAudioPlayer {
    public enum PlaybackState: Equatable, Sendable {
        case idle
        case loading
        case playing
        case paused
        case finished
        case failed(String)
    }

    /// The tale currently bound to the player (identified by the audio file
    /// URL). `nil` when no tale is active. Used by AnthologyView to know
    /// which card row should render the "Now playing" affordance.
    public private(set) var activeFileURL: URL?

    public private(set) var state: PlaybackState = .idle

    /// Progress through the active recording. Range [0, 1]. Updates ~10x
    /// per second while playing. Falls back to 0 in non-playing states.
    public private(set) var progressFraction: Double = 0

    /// Elapsed seconds inside the active recording. Useful for view-level
    /// MM:SS formatting.
    public private(set) var elapsedSeconds: TimeInterval = 0

    /// Total duration of the active recording.
    public private(set) var totalSeconds: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var pollTimer: Timer?
    private let delegate = PlayerDelegate()

    public init() {
        delegate.onFinish = { [weak self] in
            guard let self else { return }
            self.handleFinish()
        }
    }

    /// Begin playback of the recording at `fileURL`. If a different tale is
    /// already loaded, the current player is stopped before the new one
    /// starts. Idempotent for the same `fileURL` — re-invoking after pause
    /// resumes; re-invoking after play is a no-op.
    public func play(fileURL: URL) {
        if activeFileURL != fileURL {
            stop()
        }
        if state == .playing && activeFileURL == fileURL {
            return
        }
        if let existing = player, activeFileURL == fileURL {
            state = existing.play() ? .playing : .failed("Couldn't resume the tale.")
            startPolling()
            return
        }
        loadAndPlay(fileURL: fileURL)
    }

    /// Pause the active tale. No-op when nothing is playing.
    public func pause() {
        guard let player, state == .playing else { return }
        player.pause()
        state = .paused
        stopPolling()
        refreshProgress()
    }

    /// Stop + tear down the active player. Resets all state to idle.
    public func stop() {
        player?.stop()
        player = nil
        stopPolling()
        activeFileURL = nil
        state = .idle
        progressFraction = 0
        elapsedSeconds = 0
        totalSeconds = 0
    }

    /// True iff this player is currently driving the given `fileURL`. Used
    /// by view rows to flip their button label between "Listen back" and
    /// "Pause" without spurious state mirroring.
    public func isActive(for fileURL: URL) -> Bool {
        activeFileURL == fileURL
    }

    // MARK: - Private

    private func loadAndPlay(fileURL: URL) {
        state = .loading
        do {
            #if !targetEnvironment(simulator)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
            #endif
            let new = try AVAudioPlayer(contentsOf: fileURL)
            new.delegate = delegate
            new.prepareToPlay()
            player = new
            activeFileURL = fileURL
            totalSeconds = new.duration
            elapsedSeconds = 0
            progressFraction = 0
            if new.play() {
                state = .playing
                startPolling()
            } else {
                state = .failed("Couldn't start the tale.")
            }
        } catch {
            state = .failed("Couldn't open the tale (\(error.localizedDescription)).")
            activeFileURL = nil
        }
    }

    private func startPolling() {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshProgress()
            }
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func refreshProgress() {
        guard let player else { return }
        elapsedSeconds = player.currentTime
        totalSeconds = player.duration
        progressFraction = player.duration > 0
            ? min(max(player.currentTime / player.duration, 0), 1)
            : 0
    }

    private func handleFinish() {
        stopPolling()
        state = .finished
        progressFraction = 1
        elapsedSeconds = totalSeconds
    }

    /// `AVAudioPlayerDelegate` is `nonisolated` and invoked on AVFAudio's
    /// internal queue. Per `@.claude/rules/concurrency.md` § "Extension to
    /// framework-delegate protocols invoked off-actor" — every protocol
    /// method MUST be `nonisolated`; we hop to MainActor via
    /// `DispatchQueue.main.async` for the @Observable mutation.
    private final class PlayerDelegate: NSObject, AVAudioPlayerDelegate {
        var onFinish: (() -> Void)?

        nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
            DispatchQueue.main.async { [weak self] in
                self?.onFinish?()
            }
        }
    }
}
