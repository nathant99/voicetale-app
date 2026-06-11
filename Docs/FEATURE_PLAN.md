# VoiceTale — Feature Plan

> Phased delivery roadmap. Mirrors the engineering breakdown in `@Docs/TECHNICAL_DESIGN.md`. Implementing sessions check off boxes as work lands; do not collapse phases — the per-phase exit criteria gate ship readiness.

## Phase 1: Voice-First MVP

Core 60-120 second record-a-tale loop with 5-beat timer skeleton, on-device transcript-based Socratic listening coach (Bramble), anthology gallery, tradition layer, and daily prompts.

### Scaffolding

- [ ] Create Xcode project with thin app shell (`VoiceTale/VoiceTaleApp.swift`)
- [ ] Create `Libraries/Package.swift` with 6 targets (Models, Services, SharedUI, GameEngine, AIMentor, AppFeature)
- [ ] Add ForgeKit dependency (remote GitHub URL, `from: "0.99.0"`)
- [ ] Create stub source files for all targets
- [ ] Verify build succeeds with zero warnings
- [ ] Create `.xcworkspace` with Libraries as workspace member
- [ ] Add `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` to Info.plist with kid-readable copy

### Data Layer

- [ ] Define SwiftData models: `Tale`, `TaleBeat`, `TraditionEntry`, `PlayerProgress`, `AnthologyMood`
- [ ] Create `VersionedSchema` (V1) with all models
- [ ] Create `SchemaMigrationPlan` (V1 only — start early)
- [ ] Bundle 5 tradition entries as JSON in `Services/Resources/`
- [ ] Bundle 1 audio sample per tradition (licensed or public-domain; CAF) in `Services/Resources/`
- [ ] Bundle daily-prompt pool (30 starter prompts) as JSON
- [ ] Create value-type cache structs for all `@Model` types

### Voice Authoring Engine

- [ ] Implement `VoiceAuthoring` actor — AVAudio capture (44.1 kHz mono 16-bit PCM → AAC/M4A)
- [ ] Apply two-part AVAudioNodeTap rule per `.claude/rules/concurrency.md` (no `self` capture; Sendable accumulator + `@Sendable` annotation)
- [ ] Implement 5-beat timeline (Hook 10s / Setup 20s / Rising 30s / Turn 30s / Close 20s; ±20% per beat)
- [ ] Implement timeline scrubber UI for review + edit
- [ ] Implement per-beat timing visualization (color-shifted bar advancing)
- [ ] Implement gentle nudge animations at beat boundaries (no abrupt cuts)

### Transcript Pipeline

- [ ] Implement `TranscriptPipeline` — on-device `SFSpeechRecognizer`
- [ ] Per `.claude/rules/warnings.md` § Privacy-Gated Frameworks — gate access via cached `NSSpeechRecognitionUsageDescription` Info.plist check; no-op when missing
- [ ] Store transcript alongside audio metadata in SwiftData
- [ ] Implement per-beat transcript chunking (5 chunks aligned to beat boundaries)
- [ ] Implement transcript editor (kid corrects misrecognitions before reflection)

### Voice Coach (Bramble — Socratic AI mentor)

- [ ] Create `BrambleMentor` class with lazy `LanguageModelSession`
- [ ] Implement `VoiceStoryReflection` `@Generable` — transcript-based (NOT waveform-based) Socratic feedback on:
  - Hook strength (1st beat — does it pull the listener in?)
  - Sensory detail (concrete imagery throughout)
  - Arc completeness (5 beats reachable)
  - Voice variation (Phase 1.1+)
- [ ] Implement static fallbacks for every `@Generable` per `.claude/rules/foundationmodels.md`
- [ ] Implement scaffolding → Socratic ladder per `.claude/rules/foundationmodels.md` reflection pattern
- [ ] Create mentor speech-bubble UI component
- [ ] Wire mentor to events: tale-complete, replay, beat-skipped reflection request

### Tradition Layer

- [ ] Bundle 5 short explainers (West African griot / Indigenous American oral histories / Irish seanchaí / Japanese rakugo / modern slam poetry)
- [ ] Implement kid-readable 1-paragraph context per tradition
- [ ] Implement audio sample playback per tradition
- [ ] Apply cultural-sensitivity gate per `.claude/rules/trauma-informed-content.md`:
  - Indigenous oral histories: credit + cultural-context note; archetype-only references; no TEK appropriation
  - Other traditions: respectful framing; cite source
- [ ] Trauma-informed reviewer sign-off required BEFORE shipping the tradition layer (per ADR-016 protocol)

### SwiftUI Views

- [ ] Create 4-tab `TabView` (Tell / Adventure / Progress / Profile) per portfolio convention
- [ ] Build `TellView` wrapping voice-authoring + 5-beat timer
- [ ] Build `RecordingControlsView` (record / pause / re-record beat / done)
- [ ] Build `TranscriptReviewView` with editor + per-beat chunking
- [ ] Build `BrambleReflectionView` with Socratic ladder
- [ ] Build `AnthologyView` — local audio entries tagged by mood (funny / scary / tender / wild)
- [ ] Build `TraditionView` — 5 tradition cards with explainer + audio sample
- [ ] Build `DailyPromptView` — rotating prompt of the day
- [ ] Build `ProgressView` with XP / streak / badge / oral-craft attunement chart
- [ ] Build `ProfileView` with `ForgeAvatar.AvatarStudioView(.lite)`
- [ ] Build `SettingsView` with parental gate
- [ ] Build `QuizView` for question kits

### Gamification

- [ ] Integrate ForgeGamification `XPEngine` for leveling
- [ ] Integrate `StreakManager` for daily engagement
- [ ] Integrate `AchievementEngine` with first 10 Phase-1 achievements
- [ ] Wire question kits 01-04 via `Bundle.module` (hook / sensory detail / arc / mood)
- [ ] Implement XP awards for: first tale told, all 5 beats hit, transcript reviewed, tradition explored

### Adventure Mode

- [ ] Wire Level 1 config from `spark-anvil-hub/Resources/HubContributions/voicetale.json` (Word Workshop zone)
- [ ] Implement `VoiceTaleHubContribution` Level 2 Swift overlay in `Libraries/Sources/AppFeature/HubContribution/`
- [ ] Register mode-cards in `AdventureView`
- [ ] Wire `ForgeProgressionManager` gating

### Onboarding

- [ ] Create 5-step onboarding flow (welcome, mic permission, first 30-second tale, transcript review, Bramble first reflection)
- [ ] Implement aha moment: first Socratic reflection that surfaces something the kid didn't realize they did
- [ ] Implement progressive disclosure (Session 1: free-form tell, beat timer optional)
- [ ] Implement parent handoff flow (30s setup; explicit on mic permission)
- [ ] Implement Apple Declared Age Range API gate (iOS 26+)

### Quality

- [ ] Unit tests for 5-beat timer + boundary nudge logic
- [ ] Unit tests for transcript pipeline fallback when permission denied
- [ ] Unit tests for `VoiceStoryReflection` static fallbacks
- [ ] Unit tests for tradition catalog loading
- [ ] UI tests for record → review → reflect flow
- [ ] UI tests for anthology + tradition + daily prompt flows
- [ ] Accessibility audit (VoiceOver / Dynamic Type / color contrast; mic-recording status spoken)
- [ ] Performance profiling (record latency < 50ms; transcript turnaround < 2s for 60s audio)

**Exit criteria**: first session reaches aha moment in ≤ 60 seconds; 60-120s tale recordable + transcribable + reflectable; tradition layer cleared for cultural-sensitivity ship; 4 question kits ship.

---

## Phase 1.1: Voice-Character Chooser

Post-MVP voice-character recordings + light pitch/timbre shift presets.

- [ ] Implement 2-3 voice-character recordings (kid records voices for narrator / hero / antagonist / etc.)
- [ ] Implement light pitch + timbre shift presets (no full-voice-clone — on-device DSP only)
- [ ] Implement per-character voice picker for each beat
- [ ] Implement voice-variation Socratic reflection in Bramble
- [ ] Add 1 voice-character question kit (kit 05)
- [ ] Add 4 Phase-1.1 achievements

**Exit criteria**: 2-3 voice characters usable in a single tale; voice variation reflection actionable.

---

## Phase 2: Expanded Anthology + Photo Attach

Anthology curation, mood-tagged organization, kid-readable photo attach (never AI-analyzed), and 4 more question kits.

- [ ] Implement anthology curation (kid-curated collection of best tales themed by mood)
- [ ] Implement optional photo attach per tale (kid takes / picks a photo; stored alongside audio; never sent to AI for analysis)
- [ ] Implement photo-privacy guard rails: parental gate before camera permission; on-device only
- [ ] Implement mood-tag filter UI (funny / scary / tender / wild)
- [ ] Integrate question kits 06-09 (mood / pacing / surprise / closing)
- [ ] Add 6 Phase-2 achievements
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
- [ ] **Variable rewards** — ~1 in 5 sessions: rare tradition unlock / hidden prompt category / Bramble's special-tale-of-the-day praise
- [ ] **Return loop** — Welcome-back flow for 3+ day lapsed users: warm greeting + best-tale recap
- [ ] **Retention metrics baseline** — D1 / D7 / D30 (on-device, privacy-first)

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
- [ ] **Session closer** — End-of-session summary with achievements + preview of next session content

---

## Phase: Accessibility & Trauma-Informed Polish

- [ ] VoiceOver labels for every beat timer marker + tradition card
- [ ] Dynamic Type support across all SwiftUI views
- [ ] Color-contrast audit (WCAG AA in default + dark + high-contrast themes)
- [ ] Reduce-Motion variants for beat-timer animations + Bramble reflection flourishes
- [ ] Reduce-Transparency variants for any glass UI (per portfolio Liquid Glass policy)
- [ ] **Trauma-informed gate** for advanced tale content (scary mood / loss / family-conflict themes) — kid can disengage at any point; reflection never shames a "bad" tale
- [ ] **Tradition layer cultural-sensitivity gate** — external reviewer sign-off per ADR-016 BEFORE Phase 1 ship
- [ ] Crisis-resource list (988 / Childhelp / Crisis Text Line) surfaced from Settings + if mood-tagged tales surface distress signals

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
