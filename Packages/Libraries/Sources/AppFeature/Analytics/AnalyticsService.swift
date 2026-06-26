import Foundation
import Models
import ForgeAnalytics

// `ReflectionRetentionPolicy` lives in `Models`. Imported transitively
// above; referenced by `reflectionsPurged(removed:)` for the bucketing
// helper.

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
    /// Phase Delight & Polish — fires when the kid re-themes an existing
    /// collection via the per-chip "Change cover…" affordance. Mood
    /// travels for cohort analysis (which mood-keyed collections get
    /// re-themed most); the kid-chosen name NEVER travels. The cover
    /// slug travels (categorical: one of the ``AnthologyCoverDesign``
    /// raw values, or `auto` for the default).
    case anthologyCollectionCoverChanged(mood: VoiceTaleMood?, coverSlug: String)
    /// Phase 2 Tale Trial mode — fires when the kid taps "Tell this one"
    /// on a trial prompt. Categorical only: the prompt slug. The prompt
    /// text never travels; the slug is the stable categorical surface.
    case taleTrialStarted(promptSlug: String)
    /// Delight & Polish — fires exactly once per install when the kid
    /// lands their first complete five-beat tale. The `.epic` full-screen
    /// celebration is the user-facing reward; this analytics surface is
    /// the categorical signal. Mood travels for cohort analysis; no PII.
    case firstFiveBeatTaleCelebrated(mood: VoiceTaleMood)
    /// Delight & Polish "Agency" micro-delight — fires when the kid taps
    /// the "Try a different one" pill on the daily prompt. Categorical-
    /// only: the destination prompt index (no prompt text travels). Per
    /// `Docs/AUDIT_MICRO_DELIGHT_COVERAGE_2026-06-24.md` § Reds — Agency.
    case promptSwapped(toIndex: Int)
    /// Phase 2 — fires when a Siri / Spotlight / Shortcuts AppIntent posts
    /// a tab request via ``IntentTabCoordinator``. The destination raw
    /// value travels (categorical: `tell` / `anthology` / `progress` /
    /// `tradition`); no prompt text, no user-facing copy, no PII. Per
    /// `Docs/HANDOFF_TO_USER_APP_INTENTS_REGISTRATION.md` Step 3.
    case intentDestinationRequested(destination: String)
    /// ForgeReflection Phase B — fires when the kid lands a response on
    /// the "Answer Bramble" reflection sheet (or chose the `.skip`
    /// off-ramp). Categorical-only payload: the modality raw value
    /// (`text` / `voice` / `drawing` / `emoji` / `skip`) travels; the
    /// text payload NEVER does. Per `@Docs/PLAN_FORGEREFLECTION_LIFT.md`
    /// § Phase B + `@.claude/rules/age-assurance.md` § "2026 FTC COPPA
    /// Rule Amendments" (no PII surface from kid-typed text).
    case brambleAnswered(modality: String)
    /// ForgeMasteryEngine Phase B — fires only on a band crossing of the
    /// per-kit mastery score (banded into `emerging` / `developing` /
    /// `meeting` / `deepening` quartiles). Raw `masteryScore` doubles
    /// NEVER travel — anti-fingerprinting per
    /// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase B + COPPA-2026
    /// anti-PII discipline. The 4-band bucketing matches the
    /// `MasteryBand` enum used by the consumer view; the wire surface
    /// is the raw value.
    case kitMasteryAdvanced(kit: Int, fromBand: String, toBand: String)
    /// ForgeReflection Phase C — fires when the weekly retention purge
    /// runs. Categorical-only payload: the bucketed delete count travels
    /// (`zero` / `one_to_three` / `four_to_ten` / `eleven_plus`); the raw
    /// `removed` count NEVER travels (anti-fingerprinting per
    /// `@Docs/PLAN_FORGEREFLECTION_LIFT.md` § Phase C + COPPA-2026
    /// anti-PII discipline). The bucketing matches
    /// ``ReflectionRetentionPolicy.removedCountBucket(_:)``.
    case reflectionsPurged(removed: Int)
    /// ForgeReflection Phase D — fires when the grown-up opens the
    /// parent-dashboard reflection journal in ``SettingsView``.
    /// Categorical-only payload: the bucketed visible-entry count travels
    /// (`zero` / `one_to_three` / `four_to_ten` / `eleven_plus`); the raw
    /// `visibleCount` NEVER travels (anti-fingerprinting per
    /// `@Docs/PLAN_FORGEREFLECTION_LIFT.md` § Phase D + COPPA-2026 anti-
    /// PII discipline). Bucketing reuses
    /// ``ReflectionRetentionPolicy.removedCountBucket(_:)`` so the wire
    /// shape stays in lockstep with the sibling
    /// ``reflectionsPurged(removed:)`` event.
    case parentReflectionJournalOpened(visibleCount: Int)
    /// ForgeMasteryEngine Phase D — fires when the mastery-driven
    /// "deeper challenge" affordance lights on an unlocked Adventure
    /// mode-card. Categorical-only payload: the mode raw value travels
    /// (`hook_builder` / `pacing_walk` / `turn_drill` /
    /// `callback_refrain` — Tale Trial is unmapped per
    /// ``Models/ModeMasteryMapping``). The kit, the mastery score, and
    /// the Bramble copy NEVER travel (anti-fingerprinting +
    /// anti-shame per `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` §
    /// Phase D).
    case deeperChallengeAvailable(mode: String)
    /// ForgeMasteryEngine Phase D second-half — fires when the kid
    /// taps the deeper-challenge affordance pill on an Adventure
    /// mode-card. Distinct from ``deeperChallengeAvailable(mode:)``
    /// (which fires on pill-surface) so cohort analysis can separate
    /// "affordance lit" from "affordance acted on". Categorical-only
    /// payload: the mode raw value travels (one of `hook_builder` /
    /// `pacing_walk` / `turn_drill` / `callback_refrain` — Tale Trial
    /// is unmapped per ``Models/ModeMasteryMapping``). The dominant
    /// kit, the kid's mastery score, and the Bramble register-shift
    /// opener line NEVER travel (anti-fingerprinting per
    /// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D
    /// second-half).
    case deeperChallengeTaleStarted(mode: String)
    /// ForgeMasteryEngine Phase D EIGHTEENTH-round parity polish —
    /// fires when the `.extend` / `.consolidate` practice-with-Bramble
    /// badge lights on an unlocked Adventure mode-card. Distinct from
    /// ``deeperChallengeAvailable(mode:)`` (which fires for the
    /// `.stretch` band only); the two affordances NEVER co-render on
    /// the same card per ``Services/Adaptive/PracticeWithBrambleBadge``.
    /// Categorical-only payload: the mode raw value travels
    /// (`hook_builder` / `pacing_walk` / `turn_drill` /
    /// `callback_refrain` — Tale Trial is unmapped per
    /// ``Models/ModeMasteryMapping``) AND the kind raw value travels
    /// (`extend` / `consolidate`). The dominant kit, the kid's mastery
    /// score, and the Bramble copy NEVER travel (anti-fingerprinting
    /// per `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D parity
    /// polish).
    case practiceWithBrambleAvailable(mode: String, kind: String)

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
        case .anthologyCollectionCoverChanged: return "anthology_collection_cover_changed"
        case .taleTrialStarted:              return "tale_trial_started"
        case .firstFiveBeatTaleCelebrated:   return "first_five_beat_tale_celebrated"
        case .promptSwapped:                 return "prompt_swapped"
        case .intentDestinationRequested:    return "intent_destination_requested"
        case .brambleAnswered:               return "bramble_answered"
        case .kitMasteryAdvanced:            return "kit_mastery_advanced"
        case .reflectionsPurged:             return "reflections_purged"
        case .parentReflectionJournalOpened: return "parent_reflection_journal_opened"
        case .deeperChallengeAvailable:      return "deeper_challenge_available"
        case .deeperChallengeTaleStarted:    return "deeper_challenge_tale_started"
        case .practiceWithBrambleAvailable:  return "practice_with_bramble_available"
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
        case .anthologyCollectionCoverChanged(let mood, let coverSlug):
            return [
                "mood": mood?.rawValue ?? "any",
                "cover_slug": coverSlug,
            ]
        case .taleTrialStarted(let slug):
            return ["prompt_slug": slug]
        case .firstFiveBeatTaleCelebrated(let mood):
            return ["mood": mood.rawValue]
        case .promptSwapped(let toIndex):
            // Index travels (categorical pool position); prompt text NEVER does.
            return ["to_index": String(toIndex)]
        case .intentDestinationRequested(let destination):
            // The destination raw value (`tell`/`anthology`/`progress`/
            // `tradition`) is categorical — one of four enum cases — and
            // never carries PII. The derived tab is intentionally NOT
            // emitted; future fine-grained routing keeps this surface
            // stable.
            return ["destination": destination]
        case .brambleAnswered(let modality):
            // Modality raw value (`text` / `voice` / `drawing` / `emoji`
            // / `skip`) travels; the text payload NEVER does. Anti-
            // fingerprinting + COPPA-2026 anti-shame discipline: the
            // `.skip` off-ramp still emits so cohort engagement signal
            // includes the kid-engaged-then-skipped path.
            return ["modality": modality]
        case .kitMasteryAdvanced(let kit, let fromBand, let toBand):
            // Bucketed band names travel — raw `masteryScore` doubles
            // NEVER do. The from/to pair lets cohort analysis see
            // direction-of-change (advances vs regressions) without
            // exposing the underlying FSRS + recent-window state.
            return [
                "kit": String(kit),
                "from_band": fromBand,
                "to_band": toBand,
            ]
        case .reflectionsPurged(let removed):
            // Bucketed count travels — raw delete count NEVER does. The
            // bucket lets cohort analysis see "purge ran + removed N
            // entries this week" without surfacing per-kid engagement
            // depth via the run-by-run delete count signal.
            return ["removed_bucket": ReflectionRetentionPolicy.removedCountBucket(removed)]
        case .parentReflectionJournalOpened(let visibleCount):
            // Bucketed visible-entry count travels — raw count NEVER does.
            // Reuses `removedCountBucket` so the wire surface stays in
            // lockstep with `reflectionsPurged(removed:)`. The grown-up
            // opt-in toggle itself is NOT on the wire — only the bucketed
            // visible-count signal once the opt-in already happened.
            return ["visible_count_bucket": ReflectionRetentionPolicy.removedCountBucket(visibleCount)]
        case .deeperChallengeAvailable(let mode):
            // Mode raw value travels (one of `hook_builder` /
            // `pacing_walk` / `turn_drill` / `callback_refrain`); the
            // mapped kit + the kid's mastery score + the Bramble copy
            // NEVER travel. Anti-fingerprinting per
            // `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D.
            return ["mode": mode]
        case .deeperChallengeTaleStarted(let mode):
            // Same wire shape as `.deeperChallengeAvailable` — the
            // mode raw value travels; the dominant kit + mastery
            // score + Bramble register-shift opener NEVER do. Anti-
            // fingerprinting per `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md`
            // § Phase D second-half.
            return ["mode": mode]
        case .practiceWithBrambleAvailable(let mode, let kind):
            // Mode raw value + kind raw value (`extend` / `consolidate`)
            // travel. The mapped kit + the kid's mastery score + the
            // Bramble copy NEVER travel. Anti-fingerprinting per
            // `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D parity
            // polish. The kind partition gives cohort analysis a
            // direction-of-recommendation signal without leaking
            // per-kid mastery depth.
            return ["mode": mode, "kind": kind]
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
