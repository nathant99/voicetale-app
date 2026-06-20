import Foundation
import Models

public actor VoiceAuthoringActor {
    public enum AuthoringError: Error, Sendable {
        case microphonePermissionDenied
        case missingUsageDescription
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

    public var currentBeat: ArcBeat? {
        guard let startedAt else { return nil }
        let elapsed = Date().timeIntervalSince(startedAt)
        return Self.beat(forElapsedSeconds: elapsed)
    }

    nonisolated public static func beat(forElapsedSeconds elapsed: Double) -> ArcBeat? {
        var runningTotal: Double = 0
        for beat in ArcBeat.allCases {
            runningTotal += beat.targetSeconds
            if elapsed <= runningTotal {
                return beat
            }
        }
        return nil
    }
}
