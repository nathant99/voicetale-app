import Foundation
import Models

/// Session-level coordinator for a told tale. Holds the simple time-of-day
/// state — the actual AVAudio capture lives in ``AudioRecorder`` (an
/// `@MainActor` class so it can drive `AVAudioEngine`).
///
/// Static beat lookups forward to ``BeatTimer`` so callers and tests don't
/// need to instantiate the actor for pure math.
public actor VoiceAuthoringActor {
    public enum AuthoringError: Error, Sendable {
        case recordingInProgress
        case noActiveRecording
    }

    private var isRecording = false
    private var startedAt: Date?

    public init() {}

    public func beginRecording(at now: Date = Date()) async throws {
        guard !isRecording else { throw AuthoringError.recordingInProgress }
        isRecording = true
        startedAt = now
    }

    public func endRecording(at now: Date = Date()) async throws -> Double {
        guard isRecording, let startedAt else { throw AuthoringError.noActiveRecording }
        isRecording = false
        defer { self.startedAt = nil }
        return now.timeIntervalSince(startedAt)
    }

    public func currentElapsedSeconds(at now: Date = Date()) -> Double {
        guard let startedAt else { return 0 }
        return now.timeIntervalSince(startedAt)
    }

    public var currentBeat: ArcBeat? {
        guard let startedAt else { return nil }
        let elapsed = Date().timeIntervalSince(startedAt)
        return BeatTimer.beat(forElapsedSeconds: elapsed)
    }

    /// Convenience forwarder so callers can do
    /// `VoiceAuthoringActor.beat(forElapsedSeconds:)` without instantiating
    /// the actor. The canonical implementation lives in ``BeatTimer``.
    nonisolated public static func beat(forElapsedSeconds elapsed: Double) -> ArcBeat? {
        BeatTimer.beat(forElapsedSeconds: elapsed)
    }
}
