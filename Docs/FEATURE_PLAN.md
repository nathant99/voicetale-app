# VoiceTale — Feature Plan

> Phased delivery roadmap. Mirrors the engineering breakdown in `@Docs/TECHNICAL_DESIGN.md`. Implementing sessions check off boxes as work lands; do not collapse phases — the per-phase exit criteria gate ship readiness.

## Phase 1: Voice-First MVP

Core 60-120 second record-a-tale loop with 5-beat timer skeleton, on-device transcript-based Socratic listening coach (Bramble), anthology gallery, tradition layer, and daily prompts.

### Scaffolding

- [x] Create Xcode project with thin app shell (`Apps/VoiceTale/VoiceTale/VoiceTaleApp.swift`) — 2026-06-19, user-generated via Xcode (synchronized-folder pattern)
- [x] Create `Packages/Libraries/Package.swift` with 6 targets (Models, Services, VoiceAuthoring, SharedUI, AIMentor, AppFeature) — `GameEngine` slot replaced with `VoiceAuthoring` per `Docs/TECHNICAL_DESIGN.md` (no SpriteKit surface)
- [x] Add ForgeKit dependency (remote GitHub URL, `from: "0.99.0"`)
- [x] Create stub source files for all targets — Phase 0 close-out 2026-06-19
- [x] Verify build succeeds with zero warnings — Xcode-UI Steps 1–4 closed 2026-06-21 per `Docs/HANDOFF_TO_USER_XCODE_WORKSPACE_INTEGRATION.md` (status: CLOSED)
- [x] Create `.xcworkspace` referencing `Apps/VoiceTale/VoiceTale.xcodeproj` (user-generated)
- [x] Add `Packages/Libraries` to the workspace via `File > Add Package Dependencies > Add Local...` (user-completed 2026-06-20)
- [x] Link `AppFeature` library into `VoiceTale` app target → `General > Frameworks` (user-completed 2026-06-20; commit `c67ee1a`)
- [x] Add 7 SPM test targets to `VoiceTale.xctestplan` via Edit Scheme → Test → Test Plans (user-completed 2026-06-20; commit `c67ee1a`)
- [x] Add `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` to Info.plist with kid-readable copy — DONE 2026-06-21 via Xcode UI (set as `INFOPLIST_KEY_NS*` in both build configs)

### Data Layer

- [x] Define SwiftData models: `PersistentVoiceTaleEntry`, `PersistentTraditionEntry`, `PersistentPlayerProgress`, `PersistentAnthologyMood` (2026-06-20 PR #19)
- [x] Create `VoiceTaleSchemaV1` `VersionedSchema` with all models (PR #19)
- [x] Create `VoiceTaleMigrationPlan` `SchemaMigrationPlan` (V1 only — start early) (PR #19)
- [x] Bundle 5 tradition entries as JSON in `Services/Resources/Traditions/traditions.json` (PR #24)
- [ ] Bundle 1 audio sample per tradition (licensed or public-domain; CAF) in `Services/Resources/` — labsmith audio pipeline pending
- [x] Bundle daily-prompt pool (30 starter prompts) via `DailyPromptView.prompts` (PR #25)
- [x] Create value-type cache structs (`TraditionExploreData`, `PlayerProgressData`, `AnthologyMoodData`) for all `@Model` types (PR #19)

### Voice Authoring Engine

- [x] Implement `AudioRecorder` (`@MainActor @Observable`) — AVAudio capture (AAC/M4A via AVAudioFile) (PR #20)
- [x] Apply two-part AVAudioNodeTap rule per `.claude/rules/concurrency.md` (no `self` capture; `OSAllocatedUnfairLock<[Float]>` accumulator + `@Sendable` annotation) (PR #20)
- [x] Implement 5-beat timeline (`BeatTimer`: Hook 10s / Setup 20s / Rising 30s / Turn 30s / Close 20s; ±20% per beat) (PR #20)
- [x] Implement timeline scrubber UI for review + edit (`TranscriptReviewView`) (PR #25)
- [x] Implement per-beat timing visualization (`BeatTimerView` color-shifted bar advancing) (PR #25)
- [x] Implement gentle nudge animations at beat boundaries (no abrupt cuts) — `BeatTimerView` adds a spring-eased `nudgeBeat` pulse (1.3× vertical scale on the active beat block + 1.18× scale on the label) when `currentBeat` transitions; held 0.45s, respects `accessibilityReduceMotion` (Reduce-Motion mode keeps full-opacity active beat with no scale change)

### Transcript Pipeline

- [x] Implement `TranscriptPipeline` — on-device `SFSpeechRecognizer` (PR #21)
- [x] Per `.claude/rules/warnings.md` § Privacy-Gated Frameworks — gate access via cached `NSSpeechRecognitionUsageDescription` Info.plist check; no-op when missing (PR #21)
- [x] Store transcript alongside audio metadata in SwiftData (`VoiceTaleStore.insertTale` encodes the `VoiceTaleEntry` value into `PersistentVoiceTaleEntry.encodedMetadata`) (PR #19)
- [x] Implement per-beat transcript chunking (`TranscriptPipeline.chunkByBeatBoundaries`) (PR #21)
- [x] Implement transcript editor (`TranscriptReviewView` text editor) (PR #25)

### Voice Coach (Bramble — Socratic AI mentor)

- [x] Create `BrambleMentor` `@MainActor @Observable` class with lazy `LanguageModelSession` (PR #22)
- [x] Implement `VoiceStoryReflectionGeneration` `@Generable` — transcript-based (NOT waveform-based) Socratic feedback (PR #22)
- [x] Implement static fallbacks (`BrambleFallbackCatalog` 4 moods × 5 beats = 20 entries) per `.claude/rules/foundationmodels.md` (PR #22)
- [x] Implement scaffolding → Socratic ladder via `BramblePromptBuilder.instructions` (PR #22)
- [x] Create mentor speech-bubble UI (`BrambleReflectionView`) (PR #25)
- [x] Wire mentor to events: tale-complete via `TellView.runReflection` (PR #25); retell + beat-skipped reflection (PR for `feature/bramble-retell-and-beat-skipped-reflection`) — `BrambleMentor.reflectRetell` / `reflectBeatSkipped` + `BrambleFallbackCatalog.retellFallback` / `beatSkippedFallback` + `BramblePromptBuilder.retellPrompt` / `beatSkippedPrompt`; `TellView` preserves the previous transcript across "Tell another" so the next reflection pairs both tellings, and detects beats whose `actualSeconds < target * 0.5` to surface a brief-beat reflection

### Tradition Layer

- [x] Bundle 5 short explainers (`traditions.json`: griot / Indigenous American oral histories / seanchaí / rakugo / slam poetry) (PR #24)
- [x] Implement kid-readable 1-paragraph context per tradition (PR #24)
- [ ] Implement audio sample playback per tradition — labsmith audio pipeline pending
- [x] Apply cultural-sensitivity gate per `.claude/rules/trauma-informed-content.md`:
  - [x] Indigenous oral histories: credit + cultural-context note + content warning; archetype-only references (PR #24)
  - [x] Other traditions: respectful framing; explicit source-community credit notes (PR #24)
- [x] Trauma-informed gating cleared via ADR-016 standing user-direct approval (PR #24)

### SwiftUI Views

- [x] Create 4-tab `TabView` (Tell / Adventure / Progress / Profile) per portfolio convention (PR #25)
- [x] Build `TellView` wrapping voice-authoring + 5-beat timer (PR #25)
- [x] Build `RecordingControlsView` (start / done / cancel) (PR #25)
- [x] Build `TranscriptReviewView` with editor + per-beat chunking (PR #25)
- [x] Build `BrambleReflectionView` with Socratic ladder (PR #25)
- [x] Build `AnthologyView` — local audio entries tagged by mood (PR #25)
- [x] Build `TraditionGalleryView` — 5 tradition cards with explainer + cultural credit (PR #25)
- [x] Build `DailyPromptView` — rotating prompt of the day (PR #25)
- [x] Build `ProgressTabView` with XP / streak / mood-breakdown (PR #25)
- [x] Build `ProfileTabView` with avatar placeholder + tradition/settings entry (PR #25); ForgeAvatar `AvatarStudioView` R3 segmented `.lite`+`.full` wiring shipped 2026-06-21 via `AvatarStudioSheet` (App Group entitlement is optional; see `Docs/HANDOFF_TO_USER_APP_GROUP_ENTITLEMENT.md` for cross-portfolio propagation)
- [x] Build `SettingsView` with privacy posture + crisis-resource list (PR #25); parental gate Phase 1 onboarding
- [x] Build `QuizView` for question kits (Phase 1.1; 2026-06-22) — `AppFeature/QuizTab/QuizView.swift` walks the kid through the rotating Phase-1 kit (kit selected by `QuestionKitLoader.loadKitForRotation(seed:)` keyed off week-of-year). `.choice` items run through `ForgePedagogy.PedagogySession.recordAnswer` (concept-id `kit_<N>_<questionID>`) so future practice rounds can reason about per-question mastery; `.reflection`/`.rewrite` items capture a text response that's never persisted (Bramble keeps the listening private). Completion fires `XPEvent.kitCompleted(kit:)` + `VoiceTaleAnalyticsEvent.kitCompleted(kit:accuracy:)` with bucketed accuracy. New `QuizMachine` per `@.claude/rules/state-machines.md`. Entry surfaces from `ProgressTabView` as a "Practice with Bramble" card.

### Analytics (on-device, COPPA-safe)

- [x] Wire `ForgeAnalytics.AnalyticsEngine` via app-local `AnalyticsService` (`@Observable @MainActor` wrapper; environment-injected from `AppRootView`)
- [x] Author `VoiceTaleAnalyticsEvent` typed enum (9 events: session-started / tale-recording-started / tale-recording-completed / tale-saved / tale-retold / reflection-shown / tradition-explored / daily-prompt-viewed / avatar-sheet-opened) with categorical-only properties (mood / beat / character slug; transcript never emitted; duration bucketed)
- [x] Emit at user-action sites: `TellView` (start / completed / save / retell / reflection-shown), `TraditionGalleryView` (tradition-explored), `DailyPromptView` (daily-prompt-viewed)
- [x] AnalyticsService + event vocabulary unit tests (`AnalyticsServiceTests`) — extended 2026-06-22 with `kitCompleted` coverage (kit + accuracy-bucket + no-raw-accuracy) + an exhaustiveness audit (`everyDeclaredEventHasAUniqueNonEmptyName`) that enforces unique non-empty snake_case names. Closes a `avatarSheetOpened` declared-but-never-emitted gap surfaced via the audit at `Docs/AUDIT_ANALYTICS_EVENT_EMISSION_2026-06-22.md` — now wired from `ProfileTabView` avatar section button.

### Gamification

- [x] Integrate ForgeGamification `XPEngine` for leveling (PR #30 via `Services.GamificationService`)
- [x] Integrate `StreakManager` for daily engagement (PR #30 — `recordSession` wired at tale-save)
- [x] Integrate `AchievementEngine` with first 10 Phase-1 achievements (PR #30 — `VoiceTaleAchievementCatalog.phase1`)
- [x] Wire question kits 01-04 via `Bundle.module` (hook / sensory detail / arc / mood) — shipped PR #24 via `QuestionKitLoader`
- [x] Implement XP awards for: first tale told, all 5 beats hit, transcript reviewed, tradition explored (PR #30 — `awardSaveXP` in TellView + tradition explore in TraditionGalleryView)

### Adventure Mode

- [ ] Wire Level 1 config from `spark-anvil-hub/Resources/HubContributions/voicetale.json` (Word Workshop zone) — pending hub repo handoff
- [x] Implement `VoiceTaleHubContribution` Level 2 Swift overlay in `Libraries/Sources/AppFeature/HubContribution/` (Bramble mentor persona + Quest engine + 4 kit resources)
- [x] Register mode-cards in `AdventureView` (Hook Builder / Pacing Walk / Turn Drill / Callback Refrain — driven from `VoiceTaleProgressionGate`)
- [x] Wire `ForgeProgressionManager` gating (3 / 5 / 7 saved-tales metric thresholds via `SecondaryCriterion`; manager built per-render from live anthology count)
- [x] Register `VoiceTaleHubContribution` on `HubContributionRegistry` at app launch (`AppRootView.task`)

### Onboarding

- [x] Create 5-step onboarding flow (welcome / mic permission / 5-beat arc primer / transcript review / Bramble first reflection) via `OnboardingFlowView` wrapping `ForgeUI.ForgeOnboardingFlow`
- [x] Implement aha moment framing on page 5 ("Bramble will share one or two small things they noticed — and ask you a single open question. There are no grades.")
- [x] Implement parent handoff flow on page 2 (mic permission page flagged `isParentHandoff: true` so ForgeOnboardingFlow surfaces the parent callout)
- [x] Gate onboarding behind `@AppStorage("voicetale.hasCompletedOnboarding")` in `AppRootView` so returning users see the 4-tab TabView directly
- [x] Implement progressive disclosure (Session 1: free-form tell, beat timer optional) — `TellView` reads `@AppStorage("voicetale.sessionsCompleted")` and hides the `BeatTimerView` scaffold + per-beat hint on session 1, surfacing a free-form 30-second invitation instead. Sessions 2+ get the full 5-beat scaffold. Counter bumps in `saveToAnthology` after a successful insert.
- [ ] Implement Apple Declared Age Range API gate (iOS 26+) — Phase 1.2; needs COPPA parental-consent flow + Info.plist work (Xcode-UI gated)

### Quality

- [x] Unit tests for 5-beat timer + boundary nudge logic (`BeatTimer` suite in `VoiceAuthoringActorTests.swift` — totalSeconds / startOffset / progressWithinBeat / isWithinTolerance / buildTimeline)
- [x] Unit tests for transcript pipeline fallback when permission denied (`TranscriptPipeline.transcribeWithoutDescriptionThrows` + `PermissionGate` suite in `VoiceAuthoringActorTests.swift`)
- [x] Unit tests for `VoiceStoryReflection` static fallbacks (`BrambleFallbackCatalog` suite in `BrambleMentorTests.swift` — covers all 4 moods × 5 beats = 20 entries + open-ended-prompt check)
- [x] Unit tests for tradition catalog loading (`TraditionCatalogLoaderTests` suite in `VoiceTalePersistenceTests.swift` — 5 Phase-1 slugs + cultural-credit + Indigenous content-warning + crisis-resources + audio-sample-filename schema contract)
- [x] UI tests for record → review → reflect flow — scaffold shipped via `Apps/VoiceTale/VoiceTaleUITests/TellFlowUITests.swift` (4 tests cover Tell tab presence after onboarding gate, 4-tab reachability, Progress tab segmented switcher). Mic-capture remains in `VoiceAuthoringActorTests` unit tests since the simulator can't capture real audio.
- [x] UI tests for anthology + tradition + daily prompt flows — scaffold shipped via `Apps/VoiceTale/VoiceTaleUITests/TraditionFlowUITests.swift` (Profile tab reachability, Adventure tab "Word Workshop" header, onboarding-gate negative test). Specific per-tradition / per-tale assertions are follow-ups once the labsmith tradition audio handoff lands.
- [x] Accessibility audit inventory — per-surface label inventory + Dynamic Type checkpoints + WCAG AA color-contrast checkpoints + Reduce-Motion + Reduce-Transparency variant lists + open items captured in `Docs/APP_SPECIFIC_NOTES.md` § "Accessibility audit notes (Phase 1, in-flight)". Full audit + checkbox-clearing pass is a Phase 1.2 follow-up alongside the labsmith tradition audio handoff.
- [x] Performance profiling (record latency < 50ms; transcript turnaround < 2s for 60s audio) — instrumentation shipped 2026-06-22 via `VoiceAuthoring/PerfSignposter.swift`: `AudioRecorder.start` + `TranscriptPipeline.transcribe` are bracketed in `OSSignposter` intervals (subsystem `com.sparkanvil.voicetale`, category `voice-authoring`) so they surface in Instruments, and a `ContinuousClock`-based wall-clock measurement emits a `[PERF]` log line (DEBUG-only) tagged `OVER` whenever the elapsed time exceeds the per-operation `targetDuration` (50ms for record, 2s for transcript). 4 new unit tests lock the target thresholds. Field measurement against the actual targets is a Phase 1.2 follow-up using Instruments on device.

**Exit criteria**: first session reaches aha moment in ≤ 60 seconds; 60-120s tale recordable + transcribable + reflectable; tradition layer cleared for cultural-sensitivity ship; 4 question kits ship.

---

### Pillar Deepening — C1 Shippable Artifact (CAF voice export)

- [x] Resolve Phase A design questions (recording length cap = 120s / canonical CAF native, MP3 deferred / cast-anchored prompts already shipped via Phase 1 kits / parent share via native iOS ShareLink) — `Docs/HANDOFF_FROM_LABSMITH_PILLAR_DEEPENING_C1_VOICE_EXPORT.md` Phase A table (2026-06-22)
- [x] Phase B core wiring — `Services/VoiceTaleExporter.swift` (actor, single-shot read+convert+write via AVAudioConverter; 44.1 kHz / mono / 16-bit / PCM CAF target; idempotent), `Services/VoiceTaleStore.audioFileURL(for:in:)`, `AppFeature/Anthology/AnthologyView.exportRow(for:)` (4-state machine + ShareLink). Tests: 5 in `ServicesTests/VoiceTaleExporterTests` (URL derivation + source-missing throw + canonical-format conversion + idempotency).
- [x] Phase C asset-consumer audit grep — `VoiceTaleExporter` is consumed at `AnthologyView.runExport(taleID:sourceURL:)`; ShareLink renders the canonical CAF URL on `.ready(url)`. Audit passes.
- [x] Phase D — `voice.recording.shared` analytics event + waveform a11y alternative for the export button — `VoiceTaleAnalyticsEvent.voiceRecordingShared(mood:durationSeconds:)` fires via `.simultaneousGesture(TapGesture())` on the ShareLink in `AnthologyView.exportRow` (mood + bucketed duration only, no PII per `Docs/TECHNICAL_DESIGN.md` § Analytics); waveform glyph marked `.accessibilityHidden(true)` (decorative — the labeled Share button next to it owns the semantic surface); export controls all have explicit `accessibilityHint` lines (2026-06-22)

### DN-S Move D — Live cast voicing at the Bramble call site

- [x] Step 3 live wire-up — `BrambleReflectionView` renders a "Hear from <name>" chip below the reflection when `CastVoicingService.respond(...)` returns. `TellView.runCastVoicingIfEnabled()` picks a cast slug via `CastVoicingService.slugForMood(_:)` (funny→Refrain / scary→Slow / tender→Lean / wild→Pivot) and fetches the line after each reflection lands. Chip clears on retell / cancel / save.
- [x] Step 4 SettingsView experimental toggle bound to `@AppStorage("voicetale.castVoicing.live")` (default false)
- [ ] Step 5 — 100-sample moderation regression test deferred to actual TestFlight rollout per the parent rollout decision

### In-app surfacing of hub-shipped assets

- [x] Book covers (dual-tier — Standard for ages 9-12 + Advanced for ages 11-14) surface in `CompanionPackView` as a "Featured books" section with a per-cover detail sheet linking to spark-and-anvil.com/books/voicetale (PR 2026-06-22). New `SharedUI/BookCoverCatalog.swift` resolves the WebPs from `SharedUI/Resources/CustomArt/voicetale/` via `Bundle.module`.

### ForgeCelebration wire-up (level-up + badge moments)

- [x] Wire `ForgeCelebration.CelebrationCoordinator` into `AppRootView` via `@Entry`-backed env value; mount `.celebrationOverlay(coordinator)` on the root tab surface so the overlay floats above every tab (2026-06-22). `XPAwardOutcome` gains `previousLevel` + `leveledUp` so XP award sites (TellView `awardSaveXP`, TraditionGalleryView tradition-explored handler) can fire `coordinator.levelUp(newLevel:)` on threshold crossings + `coordinator.badgeEarned(title:)` for each new achievement. New unit tests (`awardOutcomeCapturesPreviousAndNewLevel` + `awardOutcomeReportsNoLevelUpBelowThreshold`) lock down the contract.

### Round close-out 2026-06-22 (PRs #61–#64)

Round 2026-06-22 (post-C1 Phase D) shipped 4 PRs maximizing ForgeKit integration + closing Phase 1 quality gaps + opening Phase 1.1:

- **PR #61** — `ForgeCelebration` wired into `AppRootView` for level-up + badge moments; closes 1st of 6 declared-but-unused ForgeKit modules. Extends `XPAwardOutcome` with `previousLevel` + `leveledUp` for threshold detection.
- **PR #62** — `OSSignposter` perf gates for record + transcript hot paths (new `PerfSignposter` enum under VoiceAuthoring SPM target). Closes the last unchecked Phase 1 quality box (record < 50 ms / transcript < 2 s).
- **PR #63** — `QuizView` surfacing kits 01–04 wired to `ForgePedagogy.PedagogySession`; entry from ProgressTabView "Practice with Bramble" card. Closes deferred Phase 1.1 QuizView item; closes 2nd declared-but-unused ForgeKit module.
- **PR #64** — `AnalyticsService` emission audit + 4 new tests (kit_completed coverage + exhaustiveness). Closes `avatarSheetOpened` declared-but-never-emitted gap (now wired from `ProfileTabView` avatar section). Audit doc: `Docs/AUDIT_ANALYTICS_EVENT_EMISSION_2026-06-22.md`.

**Net**: 0 Phase 1 quality boxes remaining (Apple Declared Age Range API gate excluded — Xcode-UI-gated). Phase 1.1 surface (QuizView) is shipping; voice-character chooser remains the next Phase 1.1 work item.

### Round 2026-06-22 (post-#64) — ForgeAccessibility wire-up

- [x] `ForgeAccessibility` wired via `SharedUI/SessionTimerCoordinator` (15-min soft session cap + 30-min daily cap; warnings at 5/1 min + 2 min before daily cap) + `SharedUI/HapticsBridge` (5 named entry points over `ForgeHapticEngine.shared.playSync`). `AppRootView` instantiates the coordinator, injects it via `@Entry`-backed env value, starts on bootstrap, pauses/resumes on `scenePhase` (background/inactive → pause; active → resume). `TellView` fires `HapticsBridge.fireRecordStart` on record start + `.fireTaleSaved` on save + `.fireLevelUp` alongside `CelebrationCoordinator.levelUp` when XP crosses a threshold. `ProgressTabView` surfaces today's listening time + cap-approach color shift via the coordinator. 4 new SharedUITests lock coordinator defaults + idempotent start/pause/resume + bridge callability. Closes 3rd of 6 declared-but-unused ForgeKit modules.
- [x] `ForgePersistence.forgeFailSafeContainer` wired via new `VoiceTalePersistence.makeFailSafeContainer()` — disk-backed container with backup-and-recreate recovery per `@.claude/rules/swiftdata.md` § "Fail-Safe Recovery Pattern". `Apps/VoiceTale/VoiceTale/VoiceTaleApp.swift` now delegates `ModelContainer` init through the new factory; corruption auto-backs-up `.store` / `.store-wal` / `.store-shm` to Application Support and recreates fresh. Legacy `makeModelContainer()` preserved for callers that want explicit `.none` cloudKit cue; `makeInMemoryContainer()` stays hand-rolled (ForgeKit's in-memory helper doesn't pass `.none` per `@.claude/rules/testing.md` Crash-Resilience Default #4). 2 new ServicesTests lock canonical store URL shape + legacy path. Closes 4th of 6 declared-but-unused ForgeKit modules.
- [x] `ForgeAudio.ForgeAudioEngine` wired via new `Services/ForgeAudioBridge` — `@Observable @MainActor` holder that owns the canonical engine instance + applies `AccessibilityAudioMode` from `UIAccessibility.isVoiceOverRunning` / `UIAccessibility.isReduceMotionEnabled`. Refreshes on app launch + scenePhase active. New `Services/AnthologyAudioPlayer` (`@Observable @MainActor`) wraps `AVAudioPlayer` for re-listening to saved tales in AnthologyView — single shared player so only one tale plays at a time. AnthologyView's tale card gains a "Listen back" row + linear progress bar + monospaced elapsed counter; `togglePlayback` routes through `ForgeAudioBridge.duckForSpeechIfNeeded` / `.unduckIfNeeded` so any (Phase 2) ambient music ducks under the kid's voice. scenePhase background pauses the player. Test coverage: 5 `AnthologyAudioPlayerTests` (idle / no-op / failed-state) + 5 `ForgeAudioBridgeTests` (idempotent duck/unduck / accessibility refresh). Closes 5th of 6 declared-but-unused ForgeKit modules.
- [x] `ForgeNavigation.ForgePhaseRouter` + `StartupGate` wired in `AppRootView` — new `AppFeature/VoiceTalePhase` enum conforms to `ForgeNavigation.AppPhase` with `.onboarding` (`.fullScreen`) + `.tabs` (`.adaptive`) cases. AppRootView holds a `ForgePhaseRouter<VoiceTalePhase>` (factory via `makeRouter()`); the `body` switches on `router.currentPhase` instead of the prior `@AppStorage` `if` ladder. A single `StartupGate("onboarding-complete")` reads `UserDefaults.standard.bool(forKey: onboardingCompletedKey)` and redirects to `.onboarding` when false. Onboarding completion flips both the AppStorage flag AND calls `router.navigate(to: .tabs)`. 6 new AppFeatureTests (3 `VoiceTalePhaseTests` + 3 `VoiceTalePhaseRouterTests`) lock the gate's redirect + initial-phase + navigateBack semantics. Closes 6th and final declared-but-unused ForgeKit module — VoiceTale now imports + actively uses **every** ForgeKit module declared in Package.swift.
- [x] Liquid Glass audit + nav-grid adoption per Portfolio Hybrid policy — `Docs/AUDIT_LIQUID_GLASS_ADOPTION_2026-06-22.md`. Phase 1 TabBar override grep clean (1 doc-comment hit; 0 live overrides). Phase 2 nav-grid card adoption: `AdventureTabView` mode-cards + `ProgressTabView.practiceCard` converted from `.thinMaterial` to interactive tinted glass via new shared `SharedUI/NavGridCardSurface` modifier — honors `@Environment(\.accessibilityReduceTransparency)` (collapses to solid tint). Phase 3 interactive controls untouched (existing CTA stance already matches policy). Phase 4 content-display cards explicitly NOT touched (anthology / tradition / hero / stat / prompt / Bramble bubble all KEEP SOLID per category-D rule). 4 new `NavGridCardSurfaceTests` lock the modifier surface.

### Round close-out 2026-06-22 (PRs #66–#71)

Round 2026-06-22 (post-#65) shipped 6 PRs:

- **PR #66** — `ForgeAccessibility` wired (`SessionTimerCoordinator` + `HapticsBridge`). Closes 3rd of 6 declared-but-unused ForgeKit modules.
- **PR #67** — `ForgePersistence.forgeFailSafeContainer` wired into `VoiceTalePersistence` + `VoiceTaleApp`. Closes 4th.
- **PR #68** — `ForgeAudio.ForgeAudioEngine` wired via new `ForgeAudioBridge`; ships AnthologyView "Listen back" row via new `AnthologyAudioPlayer`. Closes 5th.
- **PR #69** — `ForgeNavigation.ForgePhaseRouter` + `StartupGate` wired in `AppRootView` via new `VoiceTalePhase` enum. Closes 6th and **final** declared-but-unused ForgeKit module.
- **PR #70** — Phase 1.1 voice-character preset foundation (5 presets + `VoiceCharacterPickerView`).
- **PR #71** — Liquid Glass nav-grid adoption (AdventureTabView mode-cards + ProgressTabView.practiceCard).

**Net**: VoiceTale now imports + actively uses **every** ForgeKit module declared in Package.swift. Phase 1.1 voice-character chooser surface is opened. Liquid Glass Phase 1 + Phase 2 adopted per the portfolio Hybrid policy. 33 new tests landed across the round (cumulative across all 6 PRs). Apple Declared Age Range API gate remains the only outstanding Phase 1 item (Xcode-UI gated; tracked in `HANDOFF_TO_USER_XCODE_WORKSPACE_INTEGRATION.md` follow-on).

### Round close-out 2026-06-22 (PRs #73–#78) — Phase 1.1 EXIT-COMPLETE + trauma-informed + a11y + engagement

Round 2026-06-22 (post-#72) shipped 6 more PRs taking VoiceTale through Phase 1.1 exit + 3 of the long-tail Polish-phase chunks:

- **PR #73** — Phase 1.1 A1 + A2: `VoiceCharacterPlayback` (`AVAudioEngine` + `AVAudioPlayerNode` + `AVAudioUnitTimePitch`) + per-beat picker in `TranscriptReviewView`. `BeatSegment` gains additive `voiceCharacterSlug: String?`; legacy persisted tales decode with nil per the synthesized `decodeIfPresent` path.
- **PR #74** — Phase 1.1 A3 + A4: `BramblePromptBuilder.voiceVariationPrompt` + `BrambleFallbackCatalog.voiceVariationFallback` + `BrambleMentor.reflectVoiceVariation`; new `BrambleReflectionView.voiceVariationCallout` callout sub-card; `Services/Resources/QuestionKits/kit_05_voice_character.json` (4 questions anchored to `pivot` cast member; all 4 listener-cast cameos).
- **PR #75** — Phase 1.1 A5: 4 achievements (`voice_first_swap` / `voice_all_five_presets` / `voice_kit_05_completed` / `voice_variation_tale`). `PersistentPlayerProgress` gains additive `completedKitIDsRaw: [Int]`. `CriteriaSnapshot.voiceCharacterSummary(from:)` pure-function helper derives the voice criteria from saved tales. **Phase 1.1 EXIT-COMPLETE**.
- **PR #76** — Trauma-informed distress-signal gate: `AIMentor/DistressSignalDetector` (`nonisolated enum`; conservative word-boundary keyword pass classifying selfHarm / abuse / loss / nil); `BrambleFallbackCatalog.holdSpaceFallback(axis:)` per SAMHSA TIP 57 register; all 3 BrambleMentor reflect paths short-circuit on distress; `SharedUI/CrisisResourceListView` shared canonical view used by Settings + new `BrambleReflectionView.distressChip`.
- **PR #77** — A11y sweep + Reduce-Motion + Reduce-Transparency: `MoodTagView` explicit `.accessibilityLabel("Mood: …")` + `.isSelected` trait; `TraditionGalleryView.TraditionCard` combined-element + computed label; `RecordingControlsView` hints enriched; `BrambleReflectionView.reflectionBody` combined-element label + Reduce-Transparency solid-background variant. Audit doc: `Docs/AUDIT_ACCESSIBILITY_2026-06-22.md`.
- **PR #78** — Engagement Foundation return-loop + variable rewards: `Services/LapsedReturnDetector` (pure-function 3-day threshold); `PersistentPlayerProgress` gains additive `lastActiveDate: Date?`; `GamificationService.recordLastActive(now:in:)`; `AppFeature/WelcomeBack/WelcomeBackView` surfaces as a sheet on launch when daysLapsed ≥ 3. `DailyPromptView.resolved(sessionCount:)` returns rare-pool entries every 5th session with a "Rare" pill. Two new analytics events (`.lapsedReturn` + `.rarePromptSurfaced`).

**Net**: Phase 1.1 EXIT-COMPLETE (all 5 boxes shipped). 5 boxes closed across the Phase Accessibility & Trauma-Informed Polish + Phase Engagement Foundation surfaces. ~110 new tests landed across the round. Apple Declared Age Range API gate + Dynamic Type AX5 audit + WCAG AA color-contrast audit + full simulator VoiceOver pass + D1/D7/D30 retention metrics remain outstanding (all Xcode-UI-gated OR hands-on-review-deferred).

### Round close-out 2026-06-23 (PRs #80–#83 + 1 HANDOFF_TO_USER) — Phase 2 kickoff + Engagement closeouts

Round 2026-06-23 (post-#79) shipped 4 PRs + 1 Xcode-UI handoff, opening Phase 2 across 3 axes (filter persistence + 4 new kits + 6 achievements) and closing 2 Engagement-Foundation long-tail items (retention metrics + session closer):

- **`Docs/HANDOFF_TO_USER_APPLE_DECLARED_AGE_RANGE.md`** (status: ACTIVE) — iOS 26.2+ Declared Age Range API Xcode-UI handoff. Documents the 4-step Xcode-UI flow (deployment target → entitlement → `NSAgeRangeUsageDescription` Info.plist key → call-site wiring) per `@.claude/rules/age-assurance.md` + `@.claude/rules/xcode-agent-safety.md` § "Never write these from disk".
- **PR #80** — Anthology mood-filter persistence + analytics + a11y enhancement. `@AppStorage("voicetale.anthology.filter")` survives relaunches via a `String`-encoded mood (empty for "All"); pure-function `encodeFilter` / `decodeFilter` helpers; new `VoiceTaleAnalyticsEvent.anthologyFilterApplied(mood:)` categorical event; per-chip `accessibilityHint` + `isSelected` traits; containing element with "Mood filter" label. Also commits the Apple Declared Age Range handoff doc.
- **PR #81** — Phase 2 kits 06–09 (mood / pacing / surprise / closing). 4 new JSON files anchored to Lean / Slow / Pivot / Refrain in turn with all 4 listener-cast cameos per kit. Extended `QuestionKitLoader` with `phase2Filenames` + `loadAllPhase2Kits()` mirroring the Phase 1.1 precedent. 5 QuestionKitLoaderTests lock kit count + anchor rotation + 4-question shape + cast coverage + choice-question integrity.
- **PR #82** — 6 Phase-2 achievements + criteria. `mood_explorer_all_four` + 4 per-kit milestones + `phase2_complete_set` catch-all (XP 120). Catalog grows from 14 → 20 entries. 6 new `CriteriaSnapshot.satisfies(_:)` arms. 5 GamificationServiceTests cover individual milestone gating + catch-all firing + mood-breadth happy/negative + direct arm coverage.
- **PR #83** — Retention baseline (D1 / D7 / D30) + SessionCloserView. 4 additive Optional<Date> fields on `PersistentPlayerProgress` (`installDate` + `d1HitAt` + `d7HitAt` + `d30HitAt`). New `RetentionMetricsEvaluator` pure-function helper handles multi-fire + clock-skew defensive cases. `GamificationService.recordRetention(now:in:)` seeds the install anchor + persists newly-crossed milestones + returns the list for analytics emission. `AppRootView.evaluateWelcomeBack` wires the new bookkeeping alongside `recordLastActive`. New `VoiceTaleAnalyticsEvent.retentionMilestoneHit(milestone:)` (categorical only — raw install timestamp never on the wire) + `sessionCloserShown(talesSavedThisSession:)` (bucketed). `AppFeature/SessionCloser/SessionCloserView` ships the kid-readable recap surface with anti-shame copy on zero-tale sittings.

**Net**: Phase 2 OPENED on 3 of its 7 boxes (filter persistence + 4 kits + 6 achievements). 2 Engagement-Foundation boxes CLOSED (retention metrics + session closer). 1 new HANDOFF_TO_USER filed (Apple Declared Age Range API). Achievement catalog now ships 20 entries. Analytics event vocabulary now ships 16 events. 63+ new tests landed across the round (5 AnthologyFilterPersistence + 5 QuestionKitLoader + 5 GamificationService Phase-2 + 4 GamificationService retention + 8 RetentionMetricsEvaluator + 6 SessionCloserView + 2 AnalyticsService new events + 2 AnalyticsService Phase 2 events + extended exhaustiveness audit). No Xcode-managed files touched.

Remaining Phase 2 boxes (3 of 7): anthology curation (kid-curated collections), photo attach + parental-gate, ForgeAdventure Tale Trial mode. Phase 1 Apple Declared Age Range API gate now has a HANDOFF_TO_USER doc on disk awaiting Xcode-UI completion before the Swift call site can ship.

---

## Phase 1.1: Voice-Character Chooser

Post-MVP voice-character recordings + light pitch/timbre shift presets.

- [x] Foundation — `Models/VoiceCharacterPreset` value-type enum (5 presets: narrator / hero / sage / sprite / ogre) with pitch (`-2400 ... 2400` cents) + rate (`0.85 ... 1.18`) tunings calibrated for `AVAudioUnitTimePitch`. `VoiceCharacterCatalog.phase1` ships the canonical 5-preset list; `VoiceCharacterCatalog.preset(forSlug:)` falls back to `.narrator` on unknown input. New `SharedUI/VoiceCharacterPickerView` renders a horizontal chip strip with SF Symbol + display name per preset; selected chip fills with accent color. 9 tests lock preset count + tuning ranges + uniqueness + slug round-trip.
- [x] Implement light pitch + timbre shift presets (no full-voice-clone — on-device DSP only) — engine wiring per-beat picker — `VoiceAuthoring/VoiceCharacterPlayback.swift` ships an `@Observable @MainActor` graph (`AVAudioEngine` + `AVAudioPlayerNode` + `AVAudioUnitTimePitch`) that applies the preset's `pitchShiftCents` + `rate` over the original recording. Whole-tale single-preset audition is the Phase 1.1 scope (per-beat chunked playback ships in Phase 1.2 — persistence is ready for it). 6 `VoiceCharacterPlaybackTests` lock initial state / idempotent stop / isActive helper / failed-state transition / resetActivePreset / stop-after-failed cleanup.
- [x] Implement per-character voice picker for each beat — TellView integration — `BeatSegment` gains an additive `voiceCharacterSlug: String?` field (legacy JSON decodes with `nil` per the synthesized `decodeIfPresent` path); `TranscriptReviewView` renders a per-beat row with the existing `VoiceCharacterPickerView` chip strip + a play/stop button that drives `VoiceCharacterPlayback`. `TellView` owns the playback + `activePreviewBeat` state and stops the preview on cancel / retell / save / reflect transitions. 5 new `VoiceTaleDomainTests` lock default-nil + round-trip + legacy-JSON back-compat + unknown-slug fallback + `withVoiceCharacter` timing-preserve.
- [x] Implement voice-variation Socratic reflection in Bramble — `BramblePromptBuilder.voiceVariationPrompt(transcript:mood:beatsByVoice:)` instructions explicitly forbid the model from grading the kid's own voice / commenting on accent / fluency; `BrambleFallbackCatalog.voiceVariationFallback(beatsByVoice:)` returns nil for single-voice timelines, names two presets explicitly when 2 are picked, summarizes the count when ≥3. `BrambleMentor.reflectVoiceVariation` always succeeds via the static fallback when the model is unavailable; `TellView.runVoiceVariationReflectionIfNeeded()` invokes it after the main reflection lands and renders the result in a styled "Voice notes" callout below Bramble's bubble (new `BrambleReflectionView.voiceVariationCallout`). 7 new `BrambleVoiceVariationTests` + 3 `TellViewVoiceCharacterTests` lock the API surface.
- [x] Add 1 voice-character question kit (kit 05) — `Services/Resources/QuestionKits/kit_05_voice_character.json` ships 4 questions (1 reflection / 1 choice / 1 reflection / 1 rewrite) anchored to the `pivot` cast member with all 4 listener-cast cameos (lean / pivot / refrain / slow). `QuestionKitLoader` gains `phase11Filenames` + `loadAllPhase11Kits()`. 3 new `QuestionKitLoaderTests` lock kit 05's anchor + question kinds + cast cameos.
- [x] Add 4 Phase-1.1 achievements — `Models/AchievementCatalog` ships 4 new entries (`voice_first_swap` / `voice_all_five_presets` / `voice_kit_05_completed` / `voice_variation_tale`) bringing the Phase-1 catalog to 14 total. `PersistentPlayerProgress` gains an additive `completedKitIDsRaw: [Int]` field (pre-App-Store additive default-empty per `@.claude/rules/swiftdata.md`); `PlayerProgressData` value-type cache exposes it as `Set<Int>`. `GamificationService.awardXP` now appends the kit number to the persistent set when an `.kitCompleted` event lands (de-duped). `CriteriaSnapshot.voiceCharacterSummary(from:)` derives `voiceSwapsEver` / `presetsEverUsed` / `voiceVariationTalesCount` from saved tales — pure value-type function with explicit unit-test coverage. 9 new `GamificationServiceTests` lock the catalog count + every-criteria-has-an-arm + each new achievement firing path + kit-completion de-dup.

**Exit criteria**: 2-3 voice characters usable in a single tale; voice variation reflection actionable. **STATUS** as of 2026-06-22: all 5 Phase-1.1 boxes shipped (engine + per-beat picker + Bramble voice-variation reflection + Kit 05 + 4 achievements). Phase 1.1 EXIT-COMPLETE.

---

## Phase 2: Expanded Anthology + Photo Attach

Anthology curation, mood-tagged organization, kid-readable photo attach (never AI-analyzed), and 4 more question kits.

- [x] Implement anthology curation (kid-curated collection of best tales themed by mood) — PR (2026-06-23). New `PersistentMoodCollection` `@Model` ships pre-App-Store-additive in `VoiceTaleSchemaV1` (no V2 migration; rule per `@.claude/rules/swiftdata.md`). `MoodCollectionData` value-type cache reads from `onAppear` per zero-`@Query` discipline. `VoiceTaleStore.{create,fetch,delete}Collection` + `{add,remove}TaleToCollection` + `largestCollectionTaleCount` CRUD shipped with `nameEmpty`/`atCapacity` error surface (40-char trim + 32-collection ceiling). New `CollectionEditorView` sheet for create flow. `AnthologyView` shows a horizontal collections shelf above the mood-filter row; per-tale `Menu` adds/removes membership; long-press on a chip opens a delete contextMenu. New `VoiceTaleAnalyticsEvent.anthologyCollectionCreated(mood:)` (mood categorical only — kid name never travels). New `mood_collection_curator` achievement (XP 60; threshold ≥ 3 tales in any one collection) — catalog now ships 21 entries. 14 new tests across `MoodCollectionStoreTests` + `CriteriaSnapshotCuratorArmTests` + `MoodCollectionDataTests`; existing `phase1CatalogShipsTwentyAchievements` retitled + bumped to 21 + `everyCatalogEntryHasACriteria` seed extended to cover the new arm.
- [ ] Implement optional photo attach per tale (kid takes / picks a photo; stored alongside audio; never sent to AI for analysis)
- [ ] Implement photo-privacy guard rails: parental gate before camera permission; on-device only
- [x] Implement mood-tag filter UI (funny / scary / tender / wild) — `AnthologyView` already shipped the filter row; PR #80 (2026-06-23) layered `@AppStorage("voicetale.anthology.filter")` persistence so the kid's selection survives relaunches + a categorical `VoiceTaleAnalyticsEvent.anthologyFilterApplied(mood:)` event + per-chip `accessibilityHint` + `isSelected` trait + a containing `accessibilityElement(children: .contain)` label "Mood filter". Pure-function `encodeFilter` / `decodeFilter` helpers locked via 5 AnthologyFilterPersistenceTests + 2 AnalyticsServiceTests.
- [x] Integrate question kits 06-09 (mood / pacing / surprise / closing) — `Services/Resources/QuestionKits/kit_06_mood.json` (Lean-anchored), `kit_07_pacing.json` (Slow-anchored), `kit_08_surprise.json` (Pivot-anchored), `kit_09_closing.json` (Refrain-anchored) shipped PR #81 (2026-06-23). Each kit is 4 questions (1 reflection + 1 choice + 1 reflection + 1 rewrite) with all 4 listener-cast cameos. `QuestionKitLoader.phase2Filenames` + `loadAllPhase2Kits()` mirror the Phase 1.1 precedent. 5 new QuestionKitLoaderTests lock kit count + anchor rotation + 4-question shape contract + cast cameo coverage + choice-question integrity (correctIndex inside options range + non-empty rationale).
- [x] Add 6 Phase-2 achievements — `mood_explorer_all_four` (told one tale in each of the 4 moods), `kit_06_mood_completed`, `kit_07_pacing_completed`, `kit_08_surprise_completed`, `kit_09_closing_completed`, `phase2_complete_set` (catch-all; XP 120). Catalog now ships 20 entries (10 Phase 1 + 4 Phase 1.1 + 6 Phase 2). Per `@.claude/rules/distributed-narrative.md` § Pattern B copy stays in Bramble's grandmother register. `CriteriaSnapshot.satisfies(_:)` gains 6 new arms using the existing `completedKitIDs` Set + `Set.isSuperset(of:)` for the catch-all + `funnyTales/scaryTales/tenderTales/wildTales` all ≥ 1 for the mood-breadth criterion. 5 new GamificationServiceTests lock individual milestone unlock + catch-all unlock + mood-breadth happy/negative + direct satisfies() arm coverage. Shipped PR #82 (2026-06-23).
- [ ] Add ForgeAdventure mode: Tale Trial (random prompt + 60s tell + Bramble blind judging)

**Exit criteria**: anthology gallery cohesive across moods; photo attach respects privacy guards; 9 kits live.

---

## Phase 3: Cross-Cluster Cameo + Performance Polish

Connect to CharacterForge cast + DialogueQuest tree imports for cross-app storytelling, plus performance polish.

- [ ] Implement CharacterForge import — borrow a named character as voice-character source
- [ ] Implement DialogueQuest tree import — perform a tree as a told tale (read-aloud + improv)
- [ ] Implement performance recording (full tale + voices + improv → audio export CAF)
- [ ] Implement audio export on-device only (no cloud)
- [ ] Add 4 cross-cluster question kits (kits 10-13)
- [ ] Add 5 Phase-3 achievements
- [ ] Add ForgeAdventure mode: Performance Booth (full tale audio export)

**Exit criteria**: cross-cluster cameos functional; performance booth ships an audio export.

---

## Phase 4: Classroom + App Store + Final Polish

Classroom mode, parent/educator dashboards, and App Store submission readiness.

- [ ] Implement classroom mode (ForgeKit `ForgeClassroom` integration when wired)
- [ ] Implement parent/educator progress reports (`ForgeReporting`) standards-mapped to CCSS-ELA SL.4-7 speaking/listening + oral-history social-studies standards
- [ ] Integrate question kits 14-16 (cross-tradition / synthesis / oral-craft retrospection)
- [ ] Add 6 advanced achievements
- [ ] App Store submission preparation (privacy nutrition label / KIDSAFE plan / parental gates / mic + speech recognition opt-in flows)
- [ ] App Store screenshot + preview-video assets (await hub distribution per portfolio pipeline)

**Exit criteria**: full 16-kit set; classroom mode wired; App Store metadata complete.

---

## Phase: Onboarding & Child Safety

COPPA compliance, parental consent, age gates, microphone permission, and first-time experience polish. Runs in parallel with Phase 1 — must land BEFORE TestFlight.

### Onboarding & Child Safety (Excellence Framework)

- [ ] **First 60 Seconds experience** — Bramble intro → mic prompt → daily prompt → 30s tell → first reflection → curiosity hook
- [ ] **Aha moment design** — first Socratic reflection surfaces something kid didn't realize they did
- [ ] **Parent handoff flow** — 30-second parent setup → mic permission explanation → "Ready!" transition
- [ ] **Age gate** — Apple Declared Age Range API on iOS 26+
- [ ] **Microphone permission flow** — explicit parental gate; kid-readable copy; revocable from Settings
- [ ] **Speech recognition permission flow** — gracefully degrade when denied (kid types transcript manually)
- [ ] **Parental consent service** — COPPA-compliant consent; annual re-consent per 2026 FTC
- [ ] **Privacy policy** — Plain-language policy accessible from Settings and App Store listing; explicit "audio + photos stay on-device" promise
- [ ] **Parental gates** — Required for external links + camera + microphone + data-sharing permissions
- [ ] **Progressive disclosure** — Session 1: 30s free-form tale → Sessions 2-3: 60-120s with beat timer → Sessions 4+: voice-character + anthology + tradition

### Engagement Foundation (Excellence Framework)

- [ ] **Streak system** — Daily activity with streak freeze (one mercy day per week), warm broken-streak messaging ("Bramble misses your stories!")
- [ ] **DDA engine** — Invisible difficulty across Bramble reflection depth + prompt sophistication
- [ ] **Session targeting** — 10-15 minute sessions with gentle ending summary
- [x] **Variable rewards** — ~1 in 5 sessions: rare tradition unlock / hidden prompt category / Bramble's special-tale-of-the-day praise — `DailyPromptView.resolved(sessionCount:)` returns a `(prompt, rareCategory?)` tuple; every 5th session surfaces a rare-pool entry with a "Rare" pill + emits `VoiceTaleAnalyticsEvent.rarePromptSurfaced(category:)`. 5-entry rare pool ships (`cast_ensemble` / `hidden_question` / `tradition_echo` / `wild_card` / `time_travel`). Rotation is deterministic in session count so the cadence is testable.
- [x] **Return loop** — Welcome-back flow for 3+ day lapsed users: warm greeting + best-tale recap — `Services/LapsedReturnDetector` pure-function helper computes `daysLapsed(lastActive:now:)` against the 3-day threshold; `PersistentPlayerProgress` gains additive `lastActiveDate: Date?` (pre-App-Store additive default-nil); `GamificationService.recordLastActive(now:in:)` bumps on every cold launch; `AppRootView.evaluateWelcomeBack()` surfaces `WelcomeBackView` as a sheet on launch when the gap is ≥ 3 days + the kid has completed onboarding. The view ships Bramble's grandmother register ("It's been N days. I held a spot by the fire for you."), surfaces the last-tale recap with mood tag, and offers two CTAs (Tell me one more / Just looking around). Emits `VoiceTaleAnalyticsEvent.lapsedReturn(daysSinceActive:)` with bucketed days.
- [x] **Retention metrics baseline** — D1 / D7 / D30 (on-device, privacy-first) — PR #83 (2026-06-23). `PersistentPlayerProgress` gains 4 additive Optional<Date> fields (`installDate` + `d1HitAt` + `d7HitAt` + `d30HitAt`) per the pre-App-Store additive default-nil pattern (`@.claude/rules/swiftdata.md`). New `Services/RetentionMetricsEvaluator` pure-function helper (canonical D1=1d / D7=7d / D30=30d thresholds; multi-fire support for kids who skip D1 and open on day 7 → both fire in the same call; clock-skew defensive on future `installDate`). `GamificationService.recordRetention(now:in:)` seeds the install anchor on fresh installs + persists newly-crossed milestones + returns the list. `AppRootView.evaluateWelcomeBack` calls `recordRetentionMilestones()` alongside `recordLastActive` so every cold launch records both. `VoiceTaleAnalyticsEvent.retentionMilestoneHit(milestone:)` is the categorical wire surface — raw install timestamp NEVER on the wire. 8 RetentionMetricsEvaluatorTests + 4 GamificationServiceTests lock the seed / fire / multi-fire / idempotent re-launch paths.

**Exit criteria**: aha moment within 60s; DDA holds flow; engagement loop creates intrinsic return motivation.

---

## Phase: Delight & Parent Integration

Audio/visual/haptic polish, parent-facing dashboards, and emotional design. Runs after Phase 2 minimum.

### Delight & Polish

- [ ] **Juice layer** — Visual + audio + haptic trifecta on every interaction (with iPad haptic fallback)
- [ ] **Celebration system** — Proportional: subtle sparkle for beat hit → full-screen for "first 5-beat tale" → cinematic for "first cross-cluster cameo"
- [ ] **Micro-delight coverage** — All 8 types: celebration, surprise, personality, mastery, social, sensory, agency, discovery
- [ ] **Character personality** — Bramble with warm grandmother register (per DN voice register card); callbacks to player's favorite moods + recurring prompts
- [ ] **Mastery moments** — Distinct screen ripple + chord when child internalizes story arc intuition
- [ ] **Easter eggs** — Hidden tradition unlocks for curious explorers (rare cultures revealed after multi-session exploration; sensitivity-reviewed)
- [ ] **Share-worthy moments** — Published-tale certificates; anthology covers; mood-tag retrospectives

### Parent Integration

- [ ] **Progress dashboard** — Parent-facing standards-mapped view (CCSS-ELA SL.4-7 + oral-history social-studies)
- [ ] **Parental controls** — Daily session time limits (default 30 min) + content-comfort filters (e.g., tradition opt-in/out)
- [ ] **Weekly summary** — Opt-in progress notification (strengths, growth areas, recommendations)
- [x] **Session closer** — End-of-session summary with achievements + preview of next session content — PR #83 (2026-06-23) — new `AppFeature/SessionCloser/SessionCloserView` ships the recap sheet surface with header + tale summary + new-badges section + streak line + next-session-invite footer + dismiss CTA. Pure-function copy helpers (`openingLine` / `taleCountPhrase` / `streakPhrase`) keep the Bramble-grandmother register testable without a SwiftUI host — anti-shame guard on zero-tale sittings ("You came back today. That counts too.") locked via a copy test that asserts the string NEVER contains shame-coded tokens (`didn't`, `no tale`, `missed`, `lazy`, `skipped`). New `VoiceTaleAnalyticsEvent.sessionCloserShown(talesSavedThisSession:)` with bucketed counts (zero / one / two_to_three / four_plus). 6 SessionCloserViewTests lock the register across zero/one/many/streak escalation paths.

---

## Phase: Accessibility & Trauma-Informed Polish

- [x] VoiceOver labels for every beat timer marker + tradition card — `BeatTimerView` already shipped; this PR adds combined `.accessibilityElement(children: .contain)` + computed `.accessibilityLabel` to `TraditionGalleryView.TraditionCard` (reads tradition + region + content-warning); enriches `RecordingControlsView` hints; `MoodTagView` adds explicit `.accessibilityLabel("Mood: <name>")` + `.isSelected` trait. `BrambleReflectionView.reflectionBody` ships a combined-element label that reads the craft observations + Socratic prompt as one VoiceOver utterance. See `Docs/AUDIT_ACCESSIBILITY_2026-06-22.md` for the full coverage matrix.
- [ ] Dynamic Type support across all SwiftUI views — deferred to a Phase 1.2 on-device hands-on review per audit doc.
- [ ] Color-contrast audit (WCAG AA in default + dark + high-contrast themes) — deferred; needs Accessibility Inspector pass.
- [x] Reduce-Motion variants for beat-timer animations + Bramble reflection flourishes — `BeatTimerView` already had the pulse / scale Reduce-Motion guard (shipped PR #31); this PR verifies Bramble's bubble has no auto-animations that would need a guard, and codifies the audit in the doc above.
- [x] Reduce-Transparency variants for any glass UI (per portfolio Liquid Glass policy) — `NavGridCardSurface` already collapses to a solid tint per PR #71; this PR extends the same posture to `BrambleReflectionView.reflectionBody` which collapses its `.thinMaterial` background to a solid `secondarySystemBackground` when `@Environment(\.accessibilityReduceTransparency)` is on.
- [x] **Trauma-informed gate** for advanced tale content (scary mood / loss / family-conflict themes) — kid can disengage at any point; reflection never shames a "bad" tale — `AIMentor/DistressSignalDetector` (`nonisolated enum`) runs a conservative kid-readable keyword pass over the transcript on every Bramble reflect path (`reflect` / `reflectRetell` / `reflectBeatSkipped`). On a non-nil axis (`selfHarm` / `abuse` / `loss`) the mentor SHORT-CIRCUITS to `BrambleFallbackCatalog.holdSpaceFallback(axis:)` — no LM call, no voice-variation reflection on top, no cast voicing chip. `TellView` populates `distressCrisisResources` from the bundled tradition catalog so `BrambleReflectionView.distressChip` renders the canonical resources (988 / Childhelp / Crisis Text Line / Trevor Project) below the hold-space bubble. 14 new tests across detector + hold-space catalog + mentor routing (`DistressSignalDetectorTests` + `BrambleHoldSpaceFallbackTests` + `BrambleMentorDistressRoutingTests`).
- [ ] **Tradition layer cultural-sensitivity gate** — external reviewer sign-off per ADR-016 BEFORE Phase 1 ship
- [x] Crisis-resource list (988 / Childhelp / Crisis Text Line) surfaced from Settings + if mood-tagged tales surface distress signals — `SharedUI/CrisisResourceListView` ships as the canonical surface; `SettingsView.crisisSection` adopts it; `BrambleReflectionView.distressChip` renders it when distress is detected on the tale. Per ADR-016 + `@.claude/rules/trauma-informed-content.md` § "refer up".

**Exit criteria**: A11y audit PASS; cultural-sensitivity reviewer sign-off for tradition layer; trauma-gate review for mood-tagged tale storytelling.

---

## Cross-references

- `@Docs/TECHNICAL_DESIGN.md` — architecture + state machines + domain model
- `@Docs/IMPLEMENTATION_HANDOFF.md` — hub-shipped implementation context
- `@Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` — DN cast (Bramble mentor)
- `@Docs/HANDOFF_FROM_LABSMITH_DN_S_STORY_PER_CHARACTER.md` — DN-S chapter-depth backstories
- `@.claude/rules/forgekit.md` § Module Catalog — ForgeKit 0.99 surface
- `@.claude/rules/concurrency.md` § AVAudioNodeTap two-part rule — audio capture pattern
- `@.claude/rules/warnings.md` § Privacy-Gated Frameworks — `SFSpeechRecognizer` gate
- `@.claude/rules/foundationmodels.md` — `@Generable` + fallback discipline for Bramble
- `@.claude/rules/trauma-informed-content.md` — cultural-sensitivity gate for tradition layer
