import Foundation
import Models

/// Final transcript + per-utterance segments produced by ``TranscriptPipeline``.
nonisolated public struct TranscriptResult: Sendable, Hashable, Codable {
    public let text: String
    public let segments: [TranscriptSegment]

    public init(text: String, segments: [TranscriptSegment] = []) {
        self.text = text
        self.segments = segments
    }
}

/// One contiguous utterance from a speech-recognition pass. ``startSeconds``
/// and ``endSeconds`` are referenced to the start of the audio file.
nonisolated public struct TranscriptSegment: Sendable, Hashable, Codable {
    public let startSeconds: Double
    public let endSeconds: Double
    public let text: String

    public init(startSeconds: Double, endSeconds: Double, text: String) {
        self.startSeconds = startSeconds
        self.endSeconds = endSeconds
        self.text = text
    }
}

/// Beat-aligned transcript slice for ``TranscriptReviewView`` per-beat editor.
nonisolated public struct TranscriptBeatChunk: Sendable, Hashable, Identifiable, Codable {
    public var id: ArcBeat { beat }
    public let beat: ArcBeat
    public let text: String

    public init(beat: ArcBeat, text: String) {
        self.beat = beat
        self.text = text
    }
}
