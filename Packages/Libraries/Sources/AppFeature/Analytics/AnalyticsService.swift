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
    /// Pillar Deepening C1 Phase D — fires when the kid taps the
    /// `ShareLink` in the Anthology export row after a CAF prep completes.
    /// Categorical-only payload (mood + bucketed duration); no PII, no tale
    /// title, no transcript, no file path.
    case voiceRecordingShared(mood: VoiceTaleMood, durationSeconds: Double)
    /// Phase 1.1 — fires when the kid finishes a kit walk-through in
    /// QuizView. `accuracy` is the fraction of choice questions answered
    /// correctly (0.0 if the kit had no choice questions). Categorical only:
    /// kit number + bucketed accuracy.
    case kitCompleted(kit: Int, accuracy: Double)
    /// Engagement-Foundation phase — fires once per session when the
    /// kid returns after a ≥ 3-day gap. Categorical: bucketed lapsed
    /// days (3-6 / 7-13 / 14+).
    case lapsedReturn(daysSinceActive: Int)
    /// Engagement-Foundation phase — fires when the daily prompt surface
    /// surfaces a "rare" prompt category as a variable reward (~1 in 5
    /// sessions per `@Docs/FEATURE_PLAN.md` § "Variable rewards").
    case rarePromptSurfaced(category: String)
    /// Phase 2 kickoff — fires when the kid applies (or clears) the mood
    /// filter on the Anthology gallery. `mood` is `nil` for the "All"
    /// selection so the categorical surface mirrors the four mood enum
    /// cases plus the cleared state. No raw tale ids, no transcript.
    case anthologyFilterApplied(mood: VoiceTaleMood?)
    /// Engagement-Foundation phase — fires once per milestone per install
    /// when the kid crosses a retention threshold (D1 / D7 / D30).
    /// Categorical-only: the milestone slug travels; the raw install
    /// timestamp + elapsed seconds NEVER do. Privacy posture per
    /// `@Docs/TECHNICAL_DESIGN.md` § Analytics + `@.claude/rules/age-
    /// assurance.md` § "no PII, no third-party transmission".
    case retentionMilestoneHit(milestone: String)
    /// Engagement-Foundation phase — fires when the SessionCloserView
    /// surfaces at the end of a session (the kid has crossed the
    /// 10-15 min "soft session cap" target). Categorical-only: the
    /// number of tales saved during the session, bucketed.
    case sessionCloserShown(talesSavedThisSession: Int)
    /// Phase 2 anthology curation — fires when the kid creates a new
    /// mood collection. Categorical-only: the mood tag (or `nil` for
    /// "any mood" collections). The kid-chosen name NEVER travels.
    case anthologyCollectionCreated(mood: VoiceTaleMood?)

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
        case .voiceRecordingShared:          return "voice_recording_shared"
        case .kitCompleted:                  return "kit_completed"
        case .lapsedReturn:                  return "lapsed_return"
        case .rarePromptSurfaced:            return "rare_prompt_surfaced"
        case .anthologyFilterApplied:        return "anthology_filter_applied"
        case .retentionMilestoneHit:         return "retention_milestone_hit"
        case .sessionCloserShown:            return "session_closer_shown"
        case .anthologyCollectionCreated:    return "anthology_collection_created"
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
        case .voiceRecordingShared(let mood, let durationSeconds):
            return [
                "mood": mood.rawValue,
                "duration_bucket": durationBucket(durationSeconds),
            ]
        case .kitCompleted(let kit, let accuracy):
            return [
                "kit": String(kit),
                "accuracy_bucket": accuracyBucket(accuracy),
            ]
        case .lapsedReturn(let days):
            return ["days_bucket": lapsedDaysBucket(days)]
        case .rarePromptSurfaced(let category):
            return ["category": category]
        case .anthologyFilterApplied(let mood):
            return ["mood": mood?.rawValue ?? "all"]
        case .retentionMilestoneHit(let milestone):
            return ["milestone": milestone]
        case .sessionCloserShown(let count):
            return ["tales_bucket": talesBucket(count)]
        case .anthologyCollectionCreated(let mood):
            return ["mood": mood?.rawValue ?? "any"]
        }
    }

    /// Bucketed tale count per session so the property stays categorical
    /// (zero / 1 / 2-3 / 4+).
    private func talesBucket(_ count: Int) -> String {
        switch count {
        case ..<1:    return "zero"
        case 1:       return "one"
        case 2...3:   return "two_to_three"
        default:      return "four_plus"
        }
    }

    /// Bucketed lapsed-return days so the property is categorical.
    private func lapsedDaysBucket(_ days: Int) -> String {
        switch days {
        case ..<3:    return "under_3"
        case 3...6:   return "3_to_6"
        case 7...13:  return "7_to_13"
        default:      return "14_plus"
        }
    }

    /// Bucketed accuracy so the property is categorical (not a raw 0.0-1.0
    /// double, which approaches fingerprint territory).
    private func accuracyBucket(_ fraction: Double) -> String {
        switch fraction {
        case 1.0:        return "perfect"
        case 0.5..<1.0:  return "majority_correct"
        case 0.0..<0.5:  return "minority_correct"
        default:         return "no_choice_items"
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
