# VoiceTale — Technical Design

**Status**: Pre-implementation scaffold (Tier-D). Implementing session will flesh this out per Phase 1.
**Concept source**: [`Docs/README.md`](README.md) (copy of labsmith `Docs/VoiceTale/README.md`)
**Primitive**: voice-first oral storytelling craft (kid's voice is the medium; 60-120 second told tales across a 5-beat arc)
**Curriculum**: CCSS.ELA-Literacy.SL.6-8.4 (oral presentation), CCSS.ELA-Literacy.W.6-8.3 (narrative — applied to oral form), NCAS TH:Pr4-Pr6 (theater performance + interpretation), interdisciplinary connections to NCAS MU (vocal expression) + oral-tradition cultural studies
**Primary standard mapping**: CCSS.ELA-Literacy.SL.6-8.4

## SPM Module Architecture

Per `.claude/rules/spm-architecture.md`. Standard targets:

| Target | Purpose | Dependencies |
|---|---|---|
| `Models` | Domain models, SwiftData `@Model` classes, value-type cache structs | `ForgeModels` |
| `Services` | Persistence, AVAudio session management, transcript pipeline | `Models`, `ForgePersistence`, `ForgeAudio` |
| `VoiceAuthoring` | Record/playback/annotate audio + on-device transcript via Speech framework | `Models`, `ForgeAudio` |
| `SharedUI` | Reusable SwiftUI components, ForgeUI theme integration, beat-timer + waveform views | `Models`, `ForgeUI` |
| `AIMentor` | FoundationModels `@Generable` types, Bramble listening-coach session (transcript-based) | `Models`, `ForgeAI` |
| `AppFeature` | Root view, navigation, app coordinator | All above + `ForgeAdventure` + `ForgeCelebration` |

ForgeKit deps live on `AppFeature` only (matches labsmith-app pattern); intermediate targets are deps-free for faster incremental compilation.

## ForgeKit Module Integration

Pinned at `from: "0.99.0"`. Modules:

- `ForgeUI`
- `ForgeNavigation`
- `ForgePedagogy`
- `ForgeGamification`
- `ForgeAccessibility`
- `ForgeAdventure`
- `ForgeAI`
- `ForgeAvatar`
- `ForgePersistence`
- `ForgeAnalytics`
- `ForgeAudio` (load-bearing for record + playback + voice-character pitch/timbre presets)
- `ForgeModels`
- `ForgeCelebration`

See @CLAUDE.md § ForgeKit Module Integration for the per-module rationale.

## Domain Model

The VoiceTale domain model centers on **a told audio entry + its 5-beat arc + transcript + AI listening-coach reflection** — local-only by default. The implementing session will translate this into Swift types per Phase 1. Suggested type sketches (revise during implementation):

### Value types (Sendable, nonisolated)

```swift
// Models target — placeholder shape, refine in Phase 1
nonisolated public struct VoiceTaleEntry: Codable, Sendable, Identifiable {
    public let id: UUID
    public let title: String
    public let mood: VoiceTaleMood             // .funny / .scary / .tender / .wild
    public let recordedAt: Date
    public let durationSeconds: Double         // target 60-120s
    public let beatTimeline: [BeatSegment]     // 5 beats: hook/setup/rising/turn/close
    public let transcript: String              // on-device Speech framework
    public let reflection: VoiceStoryReflection?  // AI listening-coach output
}

nonisolated public struct BeatSegment: Codable, Sendable {
    public let beat: ArcBeat                   // .hook .setup .rising .turn .close
    public let targetSeconds: Double           // 10/20/30/30/20
    public let actualSeconds: Double
    public let tolerance: Double               // ±20% per beat
}

nonisolated public enum ArcBeat: String, Codable, Sendable {
    case hook, setup, rising, turn, close
}

nonisolated public struct VoiceStoryReflection: Codable, Sendable {
    public let craftObservations: [String]    // 1-2 observations; never grades
    public let socraticPrompt: String?         // single follow-up question
}
```

### SwiftData @Model classes (MainActor)

```swift
// Models target
@Model
public final class PersistentVoiceTaleEntry {
    public var id: UUID = UUID()
    public var audioFileRelativePath: String = "" // file within container; not iCloud-synced by default
    public var encodedMetadata: Data = Data()     // JSON-encoded VoiceTaleEntry metadata
    public init() { }
}
```

Implementing session decides exact storage strategy. Audio files live in app container's documents directory; metadata in SwiftData; transcript stored in metadata (compact). Per `.claude/rules/swiftdata.md`: never `@Query` in views; cache to value-type structs in `onAppear`.

## New Engines (App-Specific)

- **VoiceAuthoring** — AVAudio capture (44.1 kHz mono 16-bit PCM → AAC/M4A); 5-beat timeline scrubber; pitch/timbre shift presets for voice-character mode (Phase 1.1). Per `.claude/rules/concurrency.md` § AVAudioNodeTap two-part rule (no `self` capture; Sendable accumulator + `@Sendable` annotation).
- **TranscriptPipeline** — on-device `SFSpeechRecognizer`; transcript stored alongside audio metadata. Per `.claude/rules/warnings.md` § Privacy-Gated Frameworks — gate access via cached `NSSpeechRecognitionUsageDescription` Info.plist check; no-op when missing.
- **VoiceCoach** — FoundationModels `@Generable VoiceStoryReflection`; transcript-based (NOT waveform-based) Socratic listening coach. Scaffolding → Socratic ladder.
- **TraditionLayer** — 5 short explainers (West African griot / Indigenous American oral histories / Irish seanchaí / Japanese rakugo / modern slam poetry) with 1-paragraph kid-readable context + 1 audio sample per tradition (licensed or public-domain).

Each engine lives in its own SPM target or is folded into `VoiceAuthoring` / `Services` per Phase 1 complexity.

## Phase 1 Scope (engineering breakdown)

- Record-a-tale flow (60-120 second story with on-screen 5-beat skeleton timer — Hook 10s / Setup 20s / Rising 30s / Turn 30s / Close 20s, ±20% per beat)
- Voice-character chooser (Phase 1.1, post-MVP) — 2-3 character voices recorded by the kid + light pitch/timbre shift presets
- AI listening coach (Bramble) — post-playback Socratic feedback on hook strength + sensory detail + arc completeness + voice variation; transcript-based, no waveform analysis
- Anthology gallery — local audio entries tagged by mood (funny / scary / tender / wild). Optional photo attach (kid-readable visual; never AI-analyzed)
- Tradition layer — 5 short explainers + 1 audio sample per tradition
- Daily prompt — optional rotating prompts ("Tell me about the most boring 10 seconds of your day — but make it interesting")

See @Docs/FEATURE_PLAN.md for the full phased roadmap.

## Adventure Mode Integration

Contributes to **Word Workshop** zone in AdventureHub. Level 1 config (canonical JSON) lives at `labsmith/Resources/HubContributions/voicetale.json`; Level 2 Swift overlay (this repo) lives at `Libraries/Sources/AppFeature/HubContribution/VoiceTaleHubContribution.swift` per `Docs/AMENDMENTS_ADVENTUREHUB_SOURCE_OWNED_UI.md`.

## Home Screen & Navigation

4-tab `TabView` per portfolio convention:

- **Tell**: core record-a-tale loop
- **Adventure**: Word Workshop mode-cards (gated via `ForgeProgressionManager`)
- **Progress**: streak, XP, badge gallery, oral-craft attunement chart
- **Profile**: avatar via `ForgeAvatar.AvatarStudioView(.lite)`, settings, parental controls

## Full-App UI/UX Patterns

- **RecordingMachine** / **PlaybackMachine** structs (per `.claude/rules/state-machines.md`) for view-local state
- **Beat-timer + waveform views** in `SharedUI` — SwiftUI Canvas-based waveform; beat-tick timeline overlay
- **Feedback sequences**: `.correctFeedback(isActive:)` / `.incorrectFeedback(isActive:)` from ForgeUI (used sparingly — VoiceTale is reflective, not grade-pass-fail)
- **Results animation**: spring + scale via `ForgeCelebration.CelebrationCoordinator`
- **Onboarding**: `ForgeOnboardingFlow.Page` builder; first 60 seconds reach the aha moment (kid records 30-second hook + setup; Bramble responds with one observation)

## Child Safety & Privacy Architecture

| Channel | Data classification | Storage | Outbound? |
|---|---|---|---|
| Recorded audio | App-internal | Local file (NOT iCloud-synced by default) | No (opt-in friend-code share via ForgeSync; audio + transcript metadata only) |
| Transcript | App-internal (derived from audio) | SwiftData (local) | No (only with opt-in share) |
| Mentor reflection context | App-internal | In-memory only | No |
| Achievement badges | App-internal | SwiftData (local) | No |
| Parental consent records | Required for COPPA voice-opt-in audit (load-bearing) | SwiftData (local, 12-month expiry per FTC 2026) | No |

**Critical COPPA dependency**: voice recording requires verifiable parental consent. Reuses LyricForge's `ParentalConsentService` voice-opt-in pattern. See @Docs/KIDSAFE_PREPARATION.md for the full plan + Info.plist `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` defensive gating per `.claude/rules/warnings.md` § Privacy-Gated Frameworks.

## Parent & Educator Integration

- `ProgressReportService` standards-mapped to **CCSS.ELA-Literacy.SL.6-8.4**
- `ParentalControlsManager`: session limits, voice-recording opt-in, dashboard with optional preview-before-save
- Teacher dashboard data model: weekly summary, anonymized class-wide trends (no per-student PII; no audio shared with teachers without separate per-recording opt-in)

## Onboarding & First-Time Experience

See @CLAUDE.md § Onboarding for the First 60 Seconds timeline. Aha moment: kid records a 30-second hook + setup, the beat-timer visualizes pacing, Bramble (mascot) responds with one craft observation reflecting back what the listener heard.

## Engagement & Retention Engine

- `ForgeGamification.StreakManager` with streak freezes + `heldUnderDistress` (0.86 case)
- `ForgeGamification.XPEngine` for level progression
- Anthology growth — every completed tale unlocks a card; cumulative anthology becomes the kid's portfolio
- Variable-ratio reward schedule via `CelebrationCoordinator` (per labsmith `DESIGN_FORGEADVENTURE_API_SPECS.md`)

## Delight & Emotional Design

- 8 micro-delight types per `labsmith/Docs/TEMPLATE_EXCELLENCE_ADDITIONS.md`
- Mascot (Bramble — chunky-cartoon thornbush sprite with cocked ear-leaf) reaction animations during recording playback and post-reflection
- Hero color `#1B7B8C` (Ocean teal) used judiciously — primary CTA, mascot background, ForgeAdventure zone tag

## Analytics & Instrumentation

- Privacy-first on-device analytics via `ForgeAnalytics`
- MetricKit for crash + performance reporting (no PII)
- Feature flags via `ForgeExperiments` (COPPA-safe on-device A/B)
- **No third-party analytics SDKs** — no Firebase, no Mixpanel, no Amplitude

## Trauma-Informed Design Posture

VoiceTale is NOT in the formally-trauma-gated cluster but engages **voice-shame surface area** that warrants soft TI posture:

- **No grading on voice quality** — Bramble reflects on craft (arc, sensory detail, hook strength); never on accent, fluency, or articulation
- **Pre-content warning + skip-with-summary** on the tradition-layer explainers if a tradition touches historically-painful contexts (e.g., Indigenous American oral-history tradition acknowledges colonial suppression)
- **No comparison feedback** — no leaderboards on voice quality; the anthology is the kid's own
- **Cultural-tradition layer authored carefully** per `.claude/rules/distributed-narrative.md` § Cultural-sensitivity gates — credit traditions explicitly, no appropriation, mascot models respectful curiosity not expertise

Document this posture explicitly so future sessions don't re-litigate or skip the cultural-credit work.

## Open Questions / Decisions Pending

Implementing session resolves these in Phase 1 design:

1. Exact SwiftData storage strategy for voice tales (file-on-disk + metadata vs file blob in `@Model`)
2. AI prompt-engineering pass for Bramble persona (use `labsmith/Docs/TEMPLATE_MASCOT_PROMPT.md` voice guidance; "and then?", "oh?", listener-stance)
3. Specific `ForgeProgressionManager` unlock schedule (which Phase 1 features gate behind which session count)
4. Asset bundle plan (mascot poses arrive via labsmith handoff; topic illustrations deferred per portfolio convention)
5. Voice-character pitch/timbre presets — AVAudioUnitTimePitch tunings + UX for "narrator / old wise one / tiny squeaky friend"
6. Tradition-layer audio sample sourcing — public-domain candidates per tradition + accessible licensing pipeline
7. Friend-code share API surface — audio file transfer over ForgeSync (size budget; chunked transfer; resume)
