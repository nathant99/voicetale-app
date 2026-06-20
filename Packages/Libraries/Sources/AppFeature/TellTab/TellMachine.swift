import Foundation
import Models

/// Top-level view-local state for the record → review → reflect flow per
/// `@.claude/rules/state-machines.md` § *Machine Structs. Reset returns the
/// machine to its initial idle state.
nonisolated public struct TellMachine: Sendable, Equatable {
    public enum Phase: Sendable, Equatable {
        case idle
        case requestingPermission
        case recording
        case reviewingTranscript
        case awaitingReflection
        case showingReflection
        case savedToAnthology
        case error(String)
    }

    public var phase: Phase = .idle
    public var draftTitle: String = ""
    public var draftMood: VoiceTaleMood = .funny
    public var elapsedSeconds: Double = 0
    public var currentBeat: ArcBeat? = nil
    public var transcript: String = ""
    public var beatTimeline: [BeatSegment] = []
    public var reflection: VoiceStoryReflection?
    public var audioFileURL: URL?

    public init() {}

    public mutating func reset() {
        self = TellMachine()
    }

    public mutating func enterRecording(at start: Date = Date()) {
        elapsedSeconds = 0
        currentBeat = .hook
        phase = .recording
        beatTimeline = []
    }

    public mutating func tick(elapsedSeconds: Double, currentBeat: ArcBeat?) {
        self.elapsedSeconds = elapsedSeconds
        self.currentBeat = currentBeat
    }

    public mutating func enterReview(
        transcript: String,
        timeline: [BeatSegment],
        audioFileURL: URL?
    ) {
        self.transcript = transcript
        self.beatTimeline = timeline
        self.audioFileURL = audioFileURL
        self.phase = .reviewingTranscript
    }

    public mutating func enterAwaitingReflection() {
        phase = .awaitingReflection
    }

    public mutating func presentReflection(_ reflection: VoiceStoryReflection) {
        self.reflection = reflection
        self.phase = .showingReflection
    }

    public mutating func markSaved() {
        phase = .savedToAnthology
    }

    public mutating func markError(_ message: String) {
        phase = .error(message)
    }
}
