import Foundation
import Speech
import Models
import os

/// On-device speech-to-text for a recorded tale. Gated through
/// ``PermissionGate`` so the process does not hard-crash when
/// `NSSpeechRecognitionUsageDescription` is missing from `Info.plist`
/// (per `@.claude/rules/warnings.md` § "Privacy-Gated Frameworks").
///
/// Prefers on-device recognition when the recognizer supports it
/// (`supportsOnDeviceRecognition`), so the audio never leaves the device.
public actor TranscriptPipeline {
    public enum TranscriptError: Error, Sendable, Equatable {
        case usageDescriptionMissing
        case permissionDenied
        case recognizerUnavailable
        case recognitionFailed(String)
    }

    public init() {}

    /// Transcribe a finalized audio file. Returns the best transcription +
    /// per-utterance segments. Resolves the continuation only on the final
    /// result (per Apple's `SFSpeechURLRecognitionRequest` example) so
    /// callers don't see partial drafts.
    public func transcribe(
        fileURL: URL,
        locale: Locale = .current
    ) async throws -> TranscriptResult {
        guard PermissionGate.hasSpeechRecognitionUsageDescription else {
            throw TranscriptError.usageDescriptionMissing
        }
        let granted = await PermissionGate.requestSpeechRecognitionPermission()
        guard granted else { throw TranscriptError.permissionDenied }

        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw TranscriptError.recognizerUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: fileURL)
        request.shouldReportPartialResults = false
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        request.taskHint = .dictation

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TranscriptResult, Error>) in
            // The continuation is captured Sendable-by-value; nothing inside
            // the closure reaches back into actor state.
            let box = ContinuationBox(continuation: continuation)
            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    box.resumeOnce(throwing: .recognitionFailed(error.localizedDescription))
                    return
                }
                guard let result, result.isFinal else { return }
                let text = result.bestTranscription.formattedString
                let segments = result.bestTranscription.segments.map { segment in
                    TranscriptSegment(
                        startSeconds: segment.timestamp,
                        endSeconds: segment.timestamp + segment.duration,
                        text: segment.substring
                    )
                }
                box.resumeOnce(returning: TranscriptResult(text: text, segments: segments))
            }
        }
    }

    /// Partition transcript segments into the 5 beat-aligned chunks per the
    /// recorded timeline of per-beat actual durations. Segments outside the
    /// timeline land in the last beat.
    nonisolated public static func chunkByBeatBoundaries(
        segments: [TranscriptSegment],
        timeline: [BeatSegment]
    ) -> [TranscriptBeatChunk] {
        var cumulative: [(beat: ArcBeat, endSeconds: Double)] = []
        var runningTotal: Double = 0
        for entry in timeline {
            runningTotal += entry.actualSeconds
            cumulative.append((entry.beat, runningTotal))
        }
        var collected: [ArcBeat: [String]] = [:]
        for segment in segments {
            let beat = cumulative.first(where: { segment.startSeconds <= $0.endSeconds })?.beat
                ?? cumulative.last?.beat
                ?? .close
            collected[beat, default: []].append(segment.text)
        }
        return ArcBeat.allCases.map { beat in
            TranscriptBeatChunk(beat: beat, text: collected[beat]?.joined(separator: " ") ?? "")
        }
    }
}

/// Single-use continuation box — Speech callbacks can fire multiple times
/// while we only want to resume the continuation once. The lock holds the
/// continuation as an Optional; the first resumeOnce drains it to nil.
/// Properly `Sendable` (no `@unchecked`) because the only stored property
/// is the lock and `CheckedContinuation<TranscriptResult, Error>` is
/// itself `Sendable` (TranscriptResult is Sendable).
nonisolated private final class ContinuationBox: Sendable {
    private let state: OSAllocatedUnfairLock<CheckedContinuation<TranscriptResult, Error>?>

    init(continuation: CheckedContinuation<TranscriptResult, Error>) {
        self.state = OSAllocatedUnfairLock(initialState: continuation)
    }

    func resumeOnce(returning value: TranscriptResult) {
        let continuation = state.withLock { current -> CheckedContinuation<TranscriptResult, Error>? in
            let snapshot = current
            current = nil
            return snapshot
        }
        continuation?.resume(returning: value)
    }

    func resumeOnce(throwing error: TranscriptPipeline.TranscriptError) {
        let continuation = state.withLock { current -> CheckedContinuation<TranscriptResult, Error>? in
            let snapshot = current
            current = nil
            return snapshot
        }
        continuation?.resume(throwing: error)
    }
}
