import Foundation
import Models

/// View-local state machine for the record-a-tale loop per
/// `@.claude/rules/state-machines.md` § "*Machine Structs". Mutated by the
/// owning SwiftUI view on each timer tick + at lifecycle boundaries.
nonisolated public struct RecordingMachine: Sendable, Equatable {
    public enum Phase: Sendable, Equatable {
        case idle
        case requestingPermission
        case recording(beat: ArcBeat?, elapsedSeconds: Double)
        case reviewing(durationSeconds: Double)
        case error(message: String)
    }

    public var phase: Phase = .idle
    /// Set by the owning view whenever the recorder advances elapsed time.
    public var elapsedSeconds: Double = 0
    /// Captures the per-beat actual durations for the timeline once the
    /// recording reaches review.
    public var actualDurations: [ArcBeat: Double] = [:]

    public init() {}

    public mutating func reset() {
        self = RecordingMachine()
    }

    public mutating func beginPermissionRequest() {
        phase = .requestingPermission
    }

    public mutating func beginRecording() {
        elapsedSeconds = 0
        actualDurations = [:]
        phase = .recording(beat: .hook, elapsedSeconds: 0)
    }

    public mutating func tick(elapsedSeconds: Double) {
        self.elapsedSeconds = elapsedSeconds
        let beat = BeatTimer.beat(forElapsedSeconds: elapsedSeconds)
        phase = .recording(beat: beat, elapsedSeconds: elapsedSeconds)
    }

    public mutating func captureBeatDuration(_ beat: ArcBeat, seconds: Double) {
        actualDurations[beat] = seconds
    }

    public mutating func enterReview(durationSeconds: Double) {
        phase = .reviewing(durationSeconds: durationSeconds)
    }

    public mutating func recordError(_ message: String) {
        phase = .error(message: message)
    }

    public var isActivelyRecording: Bool {
        if case .recording = phase { return true }
        return false
    }

    public var currentBeat: ArcBeat? {
        if case let .recording(beat, _) = phase {
            return beat
        }
        return nil
    }
}
