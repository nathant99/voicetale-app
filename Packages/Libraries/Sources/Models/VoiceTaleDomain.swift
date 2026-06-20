import Foundation

// MARK: - Beat arc

nonisolated public enum ArcBeat: String, Codable, Sendable, CaseIterable {
    case hook, setup, rising, turn, close

    public var targetSeconds: Double {
        switch self {
        case .hook:   return 10
        case .setup:  return 20
        case .rising: return 30
        case .turn:   return 30
        case .close:  return 20
        }
    }

    public var displayLabel: String {
        switch self {
        case .hook:   return "Hook"
        case .setup:  return "Setup"
        case .rising: return "Rising"
        case .turn:   return "Turn"
        case .close:  return "Close"
        }
    }
}

nonisolated public struct BeatSegment: Codable, Sendable, Hashable {
    public let beat: ArcBeat
    public let targetSeconds: Double
    public let actualSeconds: Double
    public let tolerance: Double

    public init(beat: ArcBeat, targetSeconds: Double, actualSeconds: Double, tolerance: Double = 0.20) {
        self.beat = beat
        self.targetSeconds = targetSeconds
        self.actualSeconds = actualSeconds
        self.tolerance = tolerance
    }

    public var isWithinTolerance: Bool {
        let lower = targetSeconds * (1 - tolerance)
        let upper = targetSeconds * (1 + tolerance)
        return actualSeconds >= lower && actualSeconds <= upper
    }
}

// MARK: - Mood

nonisolated public enum VoiceTaleMood: String, Codable, Sendable, CaseIterable {
    case funny, scary, tender, wild

    public var displayLabel: String {
        switch self {
        case .funny:  return "Funny"
        case .scary:  return "Scary"
        case .tender: return "Tender"
        case .wild:   return "Wild"
        }
    }
}

// MARK: - Reflection

nonisolated public struct VoiceStoryReflection: Codable, Sendable, Hashable {
    public let craftObservations: [String]
    public let socraticPrompt: String?

    public init(craftObservations: [String], socraticPrompt: String?) {
        self.craftObservations = craftObservations
        self.socraticPrompt = socraticPrompt
    }
}

// MARK: - Voice tale entry

nonisolated public struct VoiceTaleEntry: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let mood: VoiceTaleMood
    public let recordedAt: Date
    public let durationSeconds: Double
    public let beatTimeline: [BeatSegment]
    public let transcript: String
    public let reflection: VoiceStoryReflection?

    public init(
        id: UUID = UUID(),
        title: String,
        mood: VoiceTaleMood,
        recordedAt: Date = Date(),
        durationSeconds: Double,
        beatTimeline: [BeatSegment],
        transcript: String,
        reflection: VoiceStoryReflection? = nil
    ) {
        self.id = id
        self.title = title
        self.mood = mood
        self.recordedAt = recordedAt
        self.durationSeconds = durationSeconds
        self.beatTimeline = beatTimeline
        self.transcript = transcript
        self.reflection = reflection
    }
}
