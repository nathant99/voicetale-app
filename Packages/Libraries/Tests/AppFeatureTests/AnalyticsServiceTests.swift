import Testing
import Foundation
@testable import AppFeature
import Models
import ForgeAnalytics

@MainActor
@Suite("AnalyticsService")
struct AnalyticsServiceTests {
    @Test func sessionStartedEventHasNoProperties() {
        let event = VoiceTaleAnalyticsEvent.sessionStarted
        #expect(event.name == "session_started")
        #expect(event.properties.isEmpty)
    }

    @Test func taleRecordingStartedCarriesMood() {
        let event = VoiceTaleAnalyticsEvent.taleRecordingStarted(mood: .funny)
        #expect(event.name == "tale_recording_started")
        #expect(event.properties["mood"] == "funny")
    }

    @Test func taleRecordingCompletedBucketsDuration() {
        // 60-90s bucket
        let normal = VoiceTaleAnalyticsEvent.taleRecordingCompleted(durationSeconds: 75, mood: .tender)
        #expect(normal.properties["duration_bucket"] == "60_to_90s")
        #expect(normal.properties["mood"] == "tender")

        // Below 60s
        let short = VoiceTaleAnalyticsEvent.taleRecordingCompleted(durationSeconds: 30, mood: .scary)
        #expect(short.properties["duration_bucket"] == "under_60s")

        // Above 150s
        let long = VoiceTaleAnalyticsEvent.taleRecordingCompleted(durationSeconds: 200, mood: .wild)
        #expect(long.properties["duration_bucket"] == "over_150s")
    }

    @Test func taleSavedCarriesBeatHitFlag() {
        let saved = VoiceTaleAnalyticsEvent.taleSavedToAnthology(mood: .funny, hitAllBeats: true)
        #expect(saved.properties["mood"] == "funny")
        #expect(saved.properties["hit_all_beats"] == "true")
    }

    @Test func reflectionShownIncludesModelAvailabilityFlag() {
        let event = VoiceTaleAnalyticsEvent.reflectionShown(
            mood: .tender,
            beat: .close,
            modelAvailable: false
        )
        #expect(event.properties["mood"] == "tender")
        #expect(event.properties["beat"] == "close")
        #expect(event.properties["model_available"] == "false")
    }

    @Test func traditionExploredCarriesSlug() {
        let event = VoiceTaleAnalyticsEvent.traditionExplored(slug: "rakugo")
        #expect(event.properties["tradition_slug"] == "rakugo")
    }

    @Test func voiceRecordingSharedCarriesMoodAndBucketedDuration() {
        // Pillar Deepening C1 Phase D — categorical-only payload; no PII.
        let event = VoiceTaleAnalyticsEvent.voiceRecordingShared(
            mood: .tender,
            durationSeconds: 95
        )
        #expect(event.name == "voice_recording_shared")
        #expect(event.properties["mood"] == "tender")
        #expect(event.properties["duration_bucket"] == "90_to_120s")
        // Categorical-only: no raw seconds, no tale id, no transcript.
        #expect(event.properties["tale_id"] == nil)
        #expect(event.properties["transcript"] == nil)
        #expect(event.properties["duration_seconds"] == nil)
    }

    @Test func serviceTrackForwardsToEngine() async {
        // Build a fresh engine + service; track a single event; verify it
        // landed via the engine's eventCount accessor. Tasks fired by
        // service.track must drain before we read the count.
        let engine = AnalyticsEngine()
        let service = AnalyticsService(engine: engine)
        service.track(.sessionStarted)
        // Yield a Task tick so the fire-and-forget Task fired inside
        // service.track resolves before we sample eventCount.
        try? await Task.sleep(for: .milliseconds(50))
        let count = await engine.eventCount
        #expect(count >= 1)
    }

    // MARK: - kitCompleted (Phase 1.1)

    @Test func kitCompletedNameAndKitCarried() {
        let event = VoiceTaleAnalyticsEvent.kitCompleted(kit: 3, accuracy: 1.0)
        #expect(event.name == "kit_completed")
        #expect(event.properties["kit"] == "3")
    }

    @Test func kitCompletedAccuracyBuckets() {
        // 1.0 = perfect
        let perfect = VoiceTaleAnalyticsEvent.kitCompleted(kit: 1, accuracy: 1.0)
        #expect(perfect.properties["accuracy_bucket"] == "perfect")

        // 0.5..<1.0 = majority_correct
        let majority = VoiceTaleAnalyticsEvent.kitCompleted(kit: 2, accuracy: 0.75)
        #expect(majority.properties["accuracy_bucket"] == "majority_correct")

        // 0.0..<0.5 = minority_correct
        let minority = VoiceTaleAnalyticsEvent.kitCompleted(kit: 2, accuracy: 0.25)
        #expect(minority.properties["accuracy_bucket"] == "minority_correct")

        // Negative (sentinel) = no_choice_items
        let noChoice = VoiceTaleAnalyticsEvent.kitCompleted(kit: 4, accuracy: -1.0)
        #expect(noChoice.properties["accuracy_bucket"] == "no_choice_items")
    }

    @Test func kitCompletedEmitsNoRawAccuracy() {
        // Categorical-only payload — raw accuracy must never appear on the
        // wire (approaches fingerprint territory if combined with other
        // signals).
        let event = VoiceTaleAnalyticsEvent.kitCompleted(kit: 1, accuracy: 0.83)
        #expect(event.properties["accuracy"] == nil)
        #expect(event.properties["accuracy_raw"] == nil)
    }

    // MARK: - anthologyFilterApplied (Phase 2 kickoff)

    @Test func anthologyFilterAppliedCarriesMoodWhenSelected() {
        let event = VoiceTaleAnalyticsEvent.anthologyFilterApplied(mood: .tender)
        #expect(event.name == "anthology_filter_applied")
        #expect(event.properties["mood"] == "tender")
    }

    @Test func anthologyFilterAppliedReportsAllWhenClearedToNil() {
        // Categorical surface: the "All" state must surface as a stable
        // string so the property never goes blank on the wire.
        let event = VoiceTaleAnalyticsEvent.anthologyFilterApplied(mood: nil)
        #expect(event.properties["mood"] == "all")
    }

    // MARK: - retentionMilestoneHit (Engagement-Foundation)

    @Test func retentionMilestoneHitCarriesCategoricalSlug() {
        let event = VoiceTaleAnalyticsEvent.retentionMilestoneHit(milestone: "d1")
        #expect(event.name == "retention_milestone_hit")
        #expect(event.properties["milestone"] == "d1")
        // Privacy posture: NEVER emit raw install timestamps OR elapsed
        // seconds — only the categorical slug.
        #expect(event.properties["install_date"] == nil)
        #expect(event.properties["elapsed_seconds"] == nil)
    }

    @Test func sessionCloserShownBucketsTalesSaved() {
        let zero = VoiceTaleAnalyticsEvent.sessionCloserShown(talesSavedThisSession: 0)
        #expect(zero.properties["tales_bucket"] == "zero")
        let one = VoiceTaleAnalyticsEvent.sessionCloserShown(talesSavedThisSession: 1)
        #expect(one.properties["tales_bucket"] == "one")
        let triple = VoiceTaleAnalyticsEvent.sessionCloserShown(talesSavedThisSession: 3)
        #expect(triple.properties["tales_bucket"] == "two_to_three")
        let many = VoiceTaleAnalyticsEvent.sessionCloserShown(talesSavedThisSession: 7)
        #expect(many.properties["tales_bucket"] == "four_plus")
        // Categorical-only: raw count NEVER on the wire.
        #expect(triple.properties["tales_count"] == nil)
    }

    // MARK: - anthologyCollectionCoverChanged (Delight & Polish)

    @Test func anthologyCollectionCoverChangedCarriesMoodAndCoverSlug() {
        // PR — anthology cover-edit affordance. Mood travels for cohort
        // analysis; the cover slug travels (categorical: one of the
        // AnthologyCoverDesign raw values, or `auto` for the default).
        let event = VoiceTaleAnalyticsEvent.anthologyCollectionCoverChanged(
            mood: .tender,
            coverSlug: "lantern"
        )
        #expect(event.name == "anthology_collection_cover_changed")
        #expect(event.properties["mood"] == "tender")
        #expect(event.properties["cover_slug"] == "lantern")
    }

    @Test func anthologyCollectionCoverChangedAuxOnNilMoodAndAutoCover() {
        // Ensemble collections (mood == nil) report "any" so the
        // property never goes blank on the wire; the canonical
        // auto-derived cover reports as "auto" (the slug the
        // ``handleCoverChange`` site emits when the kid leaves the
        // picker on ``AnthologyCoverDesign/autoGlyph``).
        let event = VoiceTaleAnalyticsEvent.anthologyCollectionCoverChanged(
            mood: nil,
            coverSlug: "auto"
        )
        #expect(event.properties["mood"] == "any")
        #expect(event.properties["cover_slug"] == "auto")
    }

    // MARK: - Event-vocabulary exhaustiveness / uniqueness audit

    // MARK: - ForgeMasteryEngine Phase D — deeperChallengeAvailable

    @Test func deeperChallengeAvailableEventNameIsStable() {
        let event = VoiceTaleAnalyticsEvent.deeperChallengeAvailable(mode: "hook_builder")
        #expect(event.name == "deeper_challenge_available")
    }

    @Test func deeperChallengeAvailableCarriesModeOnly() {
        // Mode raw value travels (one of hook_builder / pacing_walk /
        // turn_drill / callback_refrain). The kit + mastery score +
        // Bramble copy MUST NOT travel — anti-fingerprinting per the
        // PLAN § Phase D.
        let modes = ["hook_builder", "pacing_walk", "turn_drill", "callback_refrain"]
        for mode in modes {
            let event = VoiceTaleAnalyticsEvent.deeperChallengeAvailable(mode: mode)
            let props = event.properties
            #expect(props == ["mode": mode])
            #expect(props["kit"] == nil)
            #expect(props["mastery_score"] == nil)
            #expect(props["bramble_copy"] == nil)
        }
    }

    // MARK: - ForgeMasteryEngine Phase D second-half — deeperChallengeTaleStarted

    @Test func deeperChallengeTaleStartedEventNameIsStable() {
        let event = VoiceTaleAnalyticsEvent.deeperChallengeTaleStarted(mode: "hook_builder")
        #expect(event.name == "deeper_challenge_tale_started")
    }

    @Test func deeperChallengeTaleStartedCarriesModeOnly() {
        // Mirrors the wire shape of `.deeperChallengeAvailable` — the
        // mode raw value travels; the dominant kit + mastery score +
        // Bramble register-shift opener NEVER travel. Anti-
        // fingerprinting per `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md`
        // § Phase D second-half + COPPA-2026 anti-PII discipline.
        let modes = ["hook_builder", "pacing_walk", "turn_drill", "callback_refrain"]
        for mode in modes {
            let event = VoiceTaleAnalyticsEvent.deeperChallengeTaleStarted(mode: mode)
            let props = event.properties
            #expect(props == ["mode": mode])
            #expect(props["kit"] == nil)
            #expect(props["mastery_score"] == nil)
            #expect(props["bramble_copy"] == nil)
            #expect(props["opener"] == nil)
        }
    }

    @Test func deeperChallengeTaleStartedNameDiffersFromAvailable() {
        // Wire-shape separation invariant: cohort analysis must be able
        // to separate "affordance lit" from "affordance acted on" — the
        // two events MUST have distinct stable names.
        let avail = VoiceTaleAnalyticsEvent.deeperChallengeAvailable(mode: "hook_builder")
        let started = VoiceTaleAnalyticsEvent.deeperChallengeTaleStarted(mode: "hook_builder")
        #expect(avail.name != started.name)
    }

    // MARK: - ForgeMasteryEngine Phase D parity polish — practiceWithBrambleAvailable

    @Test func practiceWithBrambleAvailableEventNameIsStable() {
        let event = VoiceTaleAnalyticsEvent.practiceWithBrambleAvailable(mode: "hook_builder", kind: "extend")
        #expect(event.name == "practice_with_bramble_available")
    }

    @Test func practiceWithBrambleAvailableCarriesModeAndKind() {
        // EIGHTEENTH-round parity polish — mode + kind raw values
        // travel together; the dominant kit + mastery score + Bramble
        // copy NEVER travel.
        let modes: [String] = ["hook_builder", "pacing_walk", "turn_drill", "callback_refrain"]
        let kinds: [String] = ["extend", "consolidate"]
        for mode in modes {
            for kind in kinds {
                let event = VoiceTaleAnalyticsEvent.practiceWithBrambleAvailable(mode: mode, kind: kind)
                #expect(event.properties.count == 2,
                        "Event MUST carry exactly mode + kind — no other properties")
                #expect(event.properties["mode"] == mode)
                #expect(event.properties["kind"] == kind)
                // Anti-PII discipline locks: the kit / mastery score /
                // Bramble copy MUST NEVER appear on the wire.
                #expect(event.properties["kit"] == nil)
                #expect(event.properties["mastery_score"] == nil)
                #expect(event.properties["bramble_copy"] == nil)
            }
        }
    }

    @Test func practiceWithBrambleAvailableNameDiffersFromDeeperChallenge() {
        // Wire-shape separation invariant: the badge surface (`.extend`
        // / `.consolidate`) and the pill surface (`.stretch`) MUST have
        // distinct stable names so cohort analysis can attribute
        // engagement-per-band.
        let badge = VoiceTaleAnalyticsEvent.practiceWithBrambleAvailable(mode: "hook_builder", kind: "extend")
        let pill = VoiceTaleAnalyticsEvent.deeperChallengeAvailable(mode: "hook_builder")
        #expect(badge.name != pill.name)
    }

    // MARK: - ForgeMasteryEngine Phase D NINETEENTH-round tap-to-act —
    //         practiceWithBrambleStartedFromAdventure

    @Test func practiceWithBrambleStartedFromAdventureEventNameIsStable() {
        let event = VoiceTaleAnalyticsEvent.practiceWithBrambleStartedFromAdventure(
            mode: "hook_builder",
            kind: "extend"
        )
        #expect(event.name == "practice_with_bramble_started_from_adventure")
    }

    @Test func practiceWithBrambleStartedFromAdventureCarriesModeAndKind() {
        // NINETEENTH-round tap-to-act — wire shape mirrors
        // `.practiceWithBrambleAvailable`: mode + kind raw values
        // travel; the dominant kit + mastery score + Bramble copy
        // NEVER travel.
        let modes: [String] = ["hook_builder", "pacing_walk", "turn_drill", "callback_refrain"]
        let kinds: [String] = ["extend", "consolidate"]
        for mode in modes {
            for kind in kinds {
                let event = VoiceTaleAnalyticsEvent.practiceWithBrambleStartedFromAdventure(
                    mode: mode,
                    kind: kind
                )
                #expect(event.properties.count == 2,
                        "Event MUST carry exactly mode + kind — no other properties")
                #expect(event.properties["mode"] == mode)
                #expect(event.properties["kind"] == kind)
                // Anti-PII discipline locks: the kit / mastery score /
                // Bramble copy MUST NEVER appear on the wire.
                #expect(event.properties["kit"] == nil)
                #expect(event.properties["mastery_score"] == nil)
                #expect(event.properties["bramble_copy"] == nil)
            }
        }
    }

    @Test func practiceWithBrambleStartedFromAdventureNameDiffersFromAvailable() {
        // Wire-shape separation invariant: cohort analysis must be able
        // to separate "badge lit" from "badge acted on" — the two
        // events MUST have distinct stable names. Mirrors the
        // `.deeperChallengeAvailable` ↔ `.deeperChallengeTaleStarted`
        // separation from Phase D second-half.
        let avail = VoiceTaleAnalyticsEvent.practiceWithBrambleAvailable(
            mode: "hook_builder",
            kind: "extend"
        )
        let started = VoiceTaleAnalyticsEvent.practiceWithBrambleStartedFromAdventure(
            mode: "hook_builder",
            kind: "extend"
        )
        #expect(avail.name != started.name)
        // Wire shape should match — properties identical, names differ.
        #expect(avail.properties == started.properties)
    }

    @Test func practiceWithBrambleStartedFromAdventureNameDiffersFromDeeperChallengeStarted() {
        // The Adventure-tab badge tap MUST NOT collide with the
        // Adventure-tab pill tap. Both are tap-to-act events on the
        // Adventure tab but they cover different recommendation bands
        // (`.extend`/`.consolidate` vs `.stretch`); cohort analysis
        // depends on the separation.
        let badge = VoiceTaleAnalyticsEvent.practiceWithBrambleStartedFromAdventure(
            mode: "hook_builder",
            kind: "extend"
        )
        let pill = VoiceTaleAnalyticsEvent.deeperChallengeTaleStarted(mode: "hook_builder")
        #expect(badge.name != pill.name)
    }

    // MARK: - kitMasteryAdvanced wire-shape lock-down (TWENTIETH-round coalescing)

    @Test func kitMasteryAdvancedWireShapeIsUnchangedByCoalescing() {
        // The TWENTIETH-round @AppStorage-backed coalescing layer
        // suppresses redundant emissions in the view layer but MUST
        // NOT change the on-the-wire event shape. The payload stays
        // band raw values only — no new keys, no log JSON, no raw
        // scores. Anti-fingerprinting + COPPA-2026 anti-PII
        // discipline per
        // `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase B
        // coalescing.
        let event = VoiceTaleAnalyticsEvent.kitMasteryAdvanced(
            kit: 2,
            fromBand: "developing",
            toBand: "meeting"
        )
        #expect(event.name == "kit_mastery_advanced")
        // Exactly the same 3 keys as the pre-coalescing wire shape.
        #expect(Set(event.properties.keys) == ["kit", "from_band", "to_band"])
        // No log-shape keys leaked onto the event payload.
        let forbiddenCoalescingKeys: Set<String> = [
            "last_bands_json", "last_band", "logged_from_band",
            "coalesced", "suppressed_count", "raw_score", "elapsed",
        ]
        #expect(Set(event.properties.keys).intersection(forbiddenCoalescingKeys).isEmpty)
    }

    @Test func kitMasteryAdvancedPreservesFromBandPayloadFromLog() {
        // The coalescing layer prefers the logged last-emitted band
        // when reporting `fromBand` (so cohort analysis sees the
        // actual session-spanning transition rather than the
        // in-memory snapshot). The event signature accepts whatever
        // the caller passes — this test locks the caller-side
        // contract by exercising the public init shape.
        let logged = VoiceTaleAnalyticsEvent.kitMasteryAdvanced(
            kit: 1,
            fromBand: "emerging",  // hypothetically the logged value
            toBand: "developing"
        )
        #expect(logged.properties["from_band"] == "emerging")
        #expect(logged.properties["to_band"] == "developing")
    }

    @Test func everyDeclaredEventHasAUniqueNonEmptyName() {
        // Centralized name-collision audit. New event cases must add an
        // entry below; the test fails if the names collide OR if a case
        // returns an empty string (e.g., a stray `default` arm).
        let representativeEvents: [VoiceTaleAnalyticsEvent] = [
            .sessionStarted,
            .taleRecordingStarted(mood: .funny),
            .taleRecordingCompleted(durationSeconds: 60, mood: .funny),
            .taleSavedToAnthology(mood: .funny, hitAllBeats: false),
            .taleRetold,
            .reflectionShown(mood: .funny, beat: .hook, modelAvailable: true),
            .traditionExplored(slug: "griot"),
            .dailyPromptViewed,
            .avatarSheetOpened,
            .voiceRecordingShared(mood: .funny, durationSeconds: 60),
            .kitCompleted(kit: 1, accuracy: 1.0),
            .lapsedReturn(daysSinceActive: 5),
            .rarePromptSurfaced(category: "hidden_tradition"),
            .anthologyFilterApplied(mood: .funny),
            .retentionMilestoneHit(milestone: "d1"),
            .sessionCloserShown(talesSavedThisSession: 1),
            .anthologyCollectionCreated(mood: .tender),
            .anthologyCollectionCoverChanged(mood: .tender, coverSlug: "lantern"),
        ]
        let names = representativeEvents.map(\.name)
        // Uniqueness
        #expect(Set(names).count == names.count)
        // Non-empty
        #expect(names.allSatisfy { !$0.isEmpty })
        // snake_case (no uppercase, no spaces)
        for name in names {
            let hasUppercase = name.contains { $0.isUppercase }
            let hasSpace = name.contains { $0 == " " }
            #expect(!hasUppercase, "Event \(name) has uppercase characters; use snake_case")
            #expect(!hasSpace, "Event \(name) has spaces; use snake_case")
        }
    }
}
