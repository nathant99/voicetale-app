import Foundation
import Models
import ForgeAnalytics

/// Typed event vocabulary for VoiceTale's privacy-first on-device analytics.
/// Mapped to ForgeAnalytics event names + property bags via ``AnalyticsService``.
/// Per `@Docs/TECHNICAL_DESIGN.md` § Analytics — strictly on-device, COPPA-safe,
/// no third-party transmission. Mood / beat / character slugs are categorical
/// (not PII); transcript text is NEVER emitted.
public enum VoiceTaleAnalyticsEvent: Sendable, Hashable {
    case sessionStarted
    case taleRecordingStarted(mood: VoiceTaleMood)
    case taleRecordingCompleted(durationSeconds: Double, mood: VoiceTaleMood)
    case taleSavedToAnthology(mood: VoiceTaleMood, hitAllBeats: Bool)
    case taleRetold
    case reflectionShown(mood: VoiceTaleMood, beat: ArcBeat, modelAvailable: Bool)
    case traditionExplored(slug: String)
    case dailyPromptViewed
    case avatarSheetOpened

    /// Event name in the underlying ForgeAnalytics store. Keep lowercase +
    /// snake_case so future analytics inspectors can grep cleanly.
    public var name: String {
        switch self {
        case .sessionStarted:                return "session_started"
        case .taleRecordingStarted:          return "tale_recording_started"
        case .taleRecordingCompleted:        return "tale_recording_completed"
        case .taleSavedToAnthology:          return "tale_saved_to_anthology"
        case .taleRetold:                    return "tale_retold"
        case .reflectionShown:               return "reflection_shown"
        case .traditionExplored:             return "tradition_explored"
        case .dailyPromptViewed:             return "daily_prompt_viewed"
        case .avatarSheetOpened:             return "avatar_sheet_opened"
        }
    }

    /// Categorical-only properties (never raw text, never IDs that map to
    /// identifiable user state). Values are stringified for the analytics
    /// engine's `[String: String]` shape.
    public var properties: [String: String] {
        switch self {
        case .sessionStarted, .taleRetold, .dailyPromptViewed, .avatarSheetOpened:
            return [:]
        case .taleRecordingStarted(let mood):
            return ["mood": mood.rawValue]
        case .taleRecordingCompleted(let durationSeconds, let mood):
            return [
                "mood": mood.rawValue,
                "duration_bucket": durationBucket(durationSeconds),
            ]
        case .taleSavedToAnthology(let mood, let hitAllBeats):
            return [
                "mood": mood.rawValue,
                "hit_all_beats": hitAllBeats ? "true" : "false",
            ]
        case .reflectionShown(let mood, let beat, let modelAvailable):
            return [
                "mood": mood.rawValue,
                "beat": beat.rawValue,
                "model_available": modelAvailable ? "true" : "false",
            ]
        case .traditionExplored(let slug):
            return ["tradition_slug": slug]
        }
    }

    /// Bucketed duration so the property is categorical (not raw seconds, which
    /// approaches PII as a session-fingerprint signal).
    private func durationBucket(_ seconds: Double) -> String {
        switch seconds {
        case ..<60:           return "under_60s"
        case 60..<90:         return "60_to_90s"
        case 90..<120:        return "90_to_120s"
        case 120..<150:       return "120_to_150s"
        default:              return "over_150s"
        }
    }
}

/// MainActor-isolated observable wrapper around ForgeAnalytics'
/// ``AnalyticsEngine`` actor. Provides a typed `track(_:)` entry point so
/// SwiftUI views don't need to spell out actor-hop boilerplate. Per
/// `@.claude/rules/forgekit.md` § ForgeAnalytics — purely on-device,
/// COPPA-safe, no third-party SDKs.
@MainActor
@Observable
public final class AnalyticsService {
    public let engine: AnalyticsEngine

    public init(engine: AnalyticsEngine = AnalyticsEngine()) {
        self.engine = engine
    }

    /// Records a typed event. Fire-and-forget: the underlying engine is an
    /// actor + the on-device store is bounded, so a failed hop never blocks
    /// the user-action path.
    public func track(_ event: VoiceTaleAnalyticsEvent) {
        let name = event.name
        let properties = event.properties
        Task { [engine] in
            await engine.track(name, properties: properties)
        }
    }

    /// Starts a new analytics session. Idempotent — calling repeatedly within
    /// the same calendar window simply opens a new session UUID.
    public func startSession() {
        Task { [engine] in
            _ = await engine.startSession()
        }
    }
}
