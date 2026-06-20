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

// MARK: - Tradition

/// Value-type cache for ``PersistentTraditionEntry``. Read in `onAppear`, never
/// in `body` (per `@.claude/rules/swiftdata.md` § "Zero @Query in Views").
nonisolated public struct TraditionExploreData: Codable, Sendable, Hashable {
    public let slug: String
    public let firstExploredAt: Date?
    public let lastListenedAt: Date?
    public let listenCount: Int

    public init(
        slug: String,
        firstExploredAt: Date? = nil,
        lastListenedAt: Date? = nil,
        listenCount: Int = 0
    ) {
        self.slug = slug
        self.firstExploredAt = firstExploredAt
        self.lastListenedAt = lastListenedAt
        self.listenCount = listenCount
    }
}

// MARK: - Player progress

/// Value-type cache for ``PersistentPlayerProgress``.
nonisolated public struct PlayerProgressData: Codable, Sendable, Hashable {
    public let xpTotal: Int
    public let currentStreakDays: Int
    public let maxStreakDays: Int
    public let availableStreakFreezes: Int
    public let lastSessionAt: Date?
    public let tutorialCompletedAt: Date?

    public init(
        xpTotal: Int = 0,
        currentStreakDays: Int = 0,
        maxStreakDays: Int = 0,
        availableStreakFreezes: Int = 2,
        lastSessionAt: Date? = nil,
        tutorialCompletedAt: Date? = nil
    ) {
        self.xpTotal = xpTotal
        self.currentStreakDays = currentStreakDays
        self.maxStreakDays = maxStreakDays
        self.availableStreakFreezes = availableStreakFreezes
        self.lastSessionAt = lastSessionAt
        self.tutorialCompletedAt = tutorialCompletedAt
    }
}

// MARK: - Anthology mood

/// Value-type cache for ``PersistentAnthologyMood``.
nonisolated public struct AnthologyMoodData: Codable, Sendable, Hashable, Identifiable {
    public var id: VoiceTaleMood { mood }
    public let mood: VoiceTaleMood
    public let customLabel: String?
    public let taleCount: Int
    public let lastTaleAt: Date?

    public init(
        mood: VoiceTaleMood,
        customLabel: String? = nil,
        taleCount: Int = 0,
        lastTaleAt: Date? = nil
    ) {
        self.mood = mood
        self.customLabel = customLabel
        self.taleCount = taleCount
        self.lastTaleAt = lastTaleAt
    }

    public var displayLabel: String {
        customLabel ?? mood.displayLabel
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
