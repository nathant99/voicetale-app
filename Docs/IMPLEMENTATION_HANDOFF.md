# Implementation Handoff — VoiceTale

**Status**: ACTIVE — Phase 0 fill-in (2026-06-19). Replaces the 2026-05-22 scaffold stub per `Docs/HANDOFF_FROM_HUB_ENGINEERING_KICKOFF.md`.

> 🛑 **Load-bearing pre-read for every implementing session**: `@.claude/rules/xcode-agent-safety.md` + `@CLAUDE.md` § Xcode File Safety. The agent runs **inside** the Xcode workspace; writing to Xcode-managed files (`.xcworkspace` / `.xcodeproj/project.pbxproj` / `.xcscheme` / `.xctestplan` / `Info.plist` / `.entitlements` / `.xcassets/Contents.json` / `.xcdatamodeld/`) can terminate the agent session mid-task. **File a `Docs/HANDOFF_TO_USER_<TOPIC>.md` instead.** Phase 0 close-out left 4 such steps pending in `Docs/HANDOFF_TO_USER_XCODE_WORKSPACE_INTEGRATION.md` — those gate clean workspace-level build but do NOT gate SPM-package-level work (the agent can author SPM source + tests + resources freely).

## 1. Overview

VoiceTale is a **voice-first oral-storytelling workshop for tweens (ages 9–14)**. The core loop is a 60–120-second told tale across a 5-beat arc (Hook · Setup · Rising · Turn · Close), with on-device transcript-based AI listening-coach reflection (Bramble), a cultural-tradition layer that honors oral-storytelling lineages (West African griot · Indigenous American oral history · Irish seanchaí · Japanese rakugo · modern slam poetry) without appropriation, and an anthology of mood-tagged tales the kid curates over time.

**Primitive**: voice-first oral storytelling craft — the kid's voice is the medium; the 5-beat arc is the structure; the listener (Bramble) is the canvas.

**What makes VoiceTale unique in the portfolio**: it's the ONE writing-craft-cluster app whose medium is **oral, not written**. The transcript pipeline is a tool for reflection — not a way to convert the voice into text and grade it. Bramble never grades on accent, fluency, or articulation. Reflection is craft-centered (hook strength, sensory detail, arc completeness, voice variation), Socratic, and reflective.

**Cluster placement**: Writing-craft cluster (Pattern B — hero mascot stays PRIMARY protagonist; the DN cast members are explicitly framed as Bramble's friends-around-the-fire who each embody one oral-craft primitive).

## 2. Phase 1 Scope

The complete phased roadmap lives in `@Docs/FEATURE_PLAN.md`. Phase 1 specific surfaces to build:

| Surface | What it does | ForgeKit modules |
|---|---|---|
| **TellView** | Core record-a-tale loop with 5-beat timeline scrubber (Hook 10s · Setup 20s · Rising 30s · Turn 30s · Close 20s; ±20% per beat); gentle nudge animations at boundaries — never abrupt cuts | `ForgeUI`, app-local `VoiceAuthoring` actor |
| **TranscriptReviewView** | Per-beat transcript chunking, kid corrects misrecognitions before reflection | app-local `TranscriptPipeline` |
| **BrambleReflectionView** | Socratic ladder: 1–2 craft observations + a single follow-up question; transcript-based, never waveform-based | `ForgeAI`, app-local `BrambleMentor` |
| **AnthologyView** | Local audio entries tagged by mood (funny / scary / tender / wild); kid-curated; optional photo attach (kid-readable; never AI-analyzed) | `ForgePersistence`, `ForgeUI` |
| **TraditionView** | 5 short kid-readable explainers + 1 public-domain or community-licensed audio sample per tradition; trauma-informed framing per ADR-016 | `ForgeUI`, app-local `TraditionLayer` |
| **DailyPromptView** | Rotating prompt of the day from a 30-prompt starter pool | `ForgeUI` |
| **ProgressView** | XP / streak / badge / oral-craft attunement chart | `ForgeGamification`, `ForgeUI` |
| **ProfileView** | `ForgeAvatar.AvatarStudioView(.lite)`-or-`.full` per writing-craft-cluster Pattern B + parental controls | `ForgeAvatar`, `ForgeAccessibility` |
| **AdventureView** | Word Workshop hub-contribution Level 2 overlay; gated via `ForgeProgressionManager` | `ForgeAdventure` |
| **QuizView** | Phase 1 inline kit scaffolds (kits 01–04 — hook / sensory detail / arc / mood) | `ForgePedagogy` |

**Phase 1 exit criteria** (per `@Docs/FEATURE_PLAN.md`): first session reaches aha moment in ≤ 60 seconds; 60–120s tale recordable + transcribable + reflectable; tradition layer cleared for cultural-sensitivity ship; 4 question kits ship.

## 3. Domain Types

Defined in the `Models` SPM target. Phase 1 stub types match the sketches in `@Docs/TECHNICAL_DESIGN.md` § Domain Model. Authoritative shapes:

```swift
// Value types — Sendable, nonisolated. Live in Models target.
nonisolated public struct VoiceTaleEntry: Codable, Sendable, Identifiable {
    public let id: UUID
    public let title: String
    public let mood: VoiceTaleMood             // .funny / .scary / .tender / .wild
    public let recordedAt: Date
    public let durationSeconds: Double         // target 60–120s
    public let beatTimeline: [BeatSegment]     // 5 beats
    public let transcript: String              // on-device Speech framework
    public let reflection: VoiceStoryReflection?  // AI listening-coach output
}

nonisolated public struct BeatSegment: Codable, Sendable {
    public let beat: ArcBeat                   // .hook .setup .rising .turn .close
    public let targetSeconds: Double           // 10 / 20 / 30 / 30 / 20
    public let actualSeconds: Double
    public let tolerance: Double               // ±20% per beat
}

nonisolated public enum ArcBeat: String, Codable, Sendable, CaseIterable {
    case hook, setup, rising, turn, close
}

nonisolated public enum VoiceTaleMood: String, Codable, Sendable, CaseIterable {
    case funny, scary, tender, wild
}

nonisolated public struct VoiceStoryReflection: Codable, Sendable {
    public let craftObservations: [String]    // 1–2 observations; never grades
    public let socraticPrompt: String?         // single follow-up question
}

// SwiftData @Model (MainActor — required for SwiftData).
@Model
public final class PersistentVoiceTaleEntry {
    public var id: UUID = UUID()
    public var audioFileRelativePath: String = ""  // file within container; not iCloud-synced
    public var encodedMetadata: Data = Data()       // JSON-encoded VoiceTaleEntry metadata
    public init() { }
}
```

**Phase 1 design decisions to lock down in implementation**:
- **Audio storage strategy**: file-on-disk in app container's Documents directory; metadata in SwiftData; transcript stored compactly in metadata blob. Audio is NEVER iCloud-synced by default.
- **VersionedSchema from day one** per `.claude/rules/swiftdata.md` — `SchemaV1` contains `PersistentVoiceTaleEntry`, `PersistentTraditionEntry`, `PersistentPlayerProgress`, `PersistentAnthologyMood`.
- **Value-type cache structs in views** per `.claude/rules/swiftdata.md` § "Zero `@Query` in Views" — never traverse `@Model` in `body`.

## 4. Rendering Decision

**SwiftUI only.** VoiceTale is purely interaction-driven — no SpriteKit scene graph, no RealityKit, no Canvas-heavy waveform rendering required for Phase 1. The beat-timer is a SwiftUI Canvas-based animation; if Phase 2+ adds a richer waveform display, it stays in SwiftUI Canvas.

**No `GameEngine` SPM target** — the original `FEATURE_PLAN.md` mentioned `GameEngine` as a 4th SPM target by reflex; VoiceTale has no SpriteKit surface. Replace `GameEngine` with `VoiceAuthoring` (the AVAudio capture + 5-beat timeline actor) per `@Docs/TECHNICAL_DESIGN.md`. Reconciled in `@Docs/FEATURE_PLAN.md` 2026-06-19.

## 5. AI Mentor Persona

**Bramble** — the AI listening coach AND hero mascot. Visual: chunky-cartoon thornbush sprite with one big curious eye and a tiny ear-leaf cocked sideways (listening posture). Per `@Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` (Wave 9).

**Voice register** (per labsmith DN guidance): warm grandmother register; never claims to be a storyteller; reflects what they heard the listener experience. Signature interjections: "And then?" — "Oh?" — "Tell me again — what did I just feel?" — "I leaned in then. Did you mean me to?". Bramble is the *perfect listener* and the kid is always the teller.

**Generable schema** (lives in `AIMentor` SPM target):

```swift
@Generable
public struct VoiceStoryReflectionGeneration: Codable, Sendable {
    @Guide(description: "One or two short observations about the craft (NEVER grades; NEVER comments on accent, fluency, or articulation; reflects what the listener heard the teller do)")
    public let craftObservations: [String]

    @Guide(description: "A single open-ended follow-up question that invites the teller deeper into their own choice")
    public let socraticPrompt: String?
}
```

**Property order**: `craftObservations` first, then `socraticPrompt` — the question is conditioned on the observations per `.claude/rules/foundationmodels.md` § "Property order matters."

**Fallback discipline** per `.claude/rules/foundationmodels.md`: every `@Generable` call goes through `try?` + a static-content dictionary fallback keyed by mood. The fallback dictionary covers the 4 moods × 5 beat types = 20 baseline scaffold prompts.

**Trauma-informed posture** per `.claude/rules/trauma-informed-content.md` § "The mentor posture for heavy content":
1. **Validate, then inform** — "I heard you slow down on the turn — was that on purpose?" before craft observation
2. **Hold space, don't resolve** — heavy mood-tagged tales (scary / tender) get acknowledgment, not pep talk
3. **Refer up** — if the kid's tale surfaces distress signals (loss, abuse, isolation), Bramble surfaces a "you can talk to a trusted adult" line + crisis-resource list (988 / Childhelp / Crisis Text Line) via `SettingsView`

## 6. Question Kits / Content

**Phase 1**: 4 inline scaffolds (kits 01–04) — hook / sensory detail / arc / mood. Authored as JSON in `Services/Resources/QuestionKits/` and loaded via `Bundle.module` per `.claude/rules/spm-architecture.md` § "Bundle.module for resources." Lazy-not-eager: kits load on `QuizView.onAppear`, not at app launch.

**Bundled tradition layer** (Phase 1 ship requirement): 5 explainers (1 paragraph each, kid-readable) + 1 audio sample per tradition (public-domain or community-licensed CAF). Lives in `Services/Resources/Traditions/` with a `traditions.json` manifest. **Reviewer signoff required** for tradition layer before Phase 1 ship per `@Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` § 3b — covered by ADR-016 standing user-direct approval (`.claude/rules/trauma-informed-content.md` § "Trauma-adjacent DN-S story authoring").

**DN cast cameos** per `@Docs/HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` Move B: each cast member (Lean / Slow / Pivot / Refrain) ships ≤ 16 cameos (one per kit) in `castCameos[]` of the kit JSON. Phase 1 implements the schema + the kit 01–04 cameos.

**Future kits 05–16** ship per `@Docs/FEATURE_PLAN.md` phased roadmap.

## 7. ForgeKit Modules to Wire

Pinned at `from: "0.99.0"` per `@Docs/HANDOFF_FROM_LABSMITH_FORGEKIT_BOOTSTRAP.md`. Per-target wiring:

| Target | ForgeKit modules |
|---|---|
| `Models` | `ForgeModels` |
| `Services` | `ForgePersistence`, `ForgeAnalytics`, `ForgeAudio` |
| `VoiceAuthoring` | `ForgeAudio` |
| `SharedUI` | `ForgeUI`, `ForgeAccessibility` |
| `AIMentor` | `ForgeAI` |
| `AppFeature` | `ForgeNavigation`, `ForgeUI`, `ForgePedagogy`, `ForgeGamification`, `ForgeAdventure`, `ForgeAvatar`, `ForgeCelebration` |

Plus the 7-module canonical bootstrap from `@Docs/HANDOFF_FROM_LABSMITH_FORGEKIT_BOOTSTRAP.md` § Step 3.

**Avatar editor** per `@Docs/HANDOFF_FROM_LABSMITH_AVATAR_SIMPLIFIED_MIGRATION.md` + writing-craft-cluster pattern: R3 segmented `.lite`+`.full` toggle (best-in-class). Reference impl: `quillspell-app/Packages/Libraries/Sources/AppFeature/AvatarStudioSheet.swift`.

**Optional Phase 2+ modules**: `ForgeReporting` (parent dashboard), `ForgeSync` (friend-code share — audio file transfer), `ForgeClassroom` (when LiveKit Classroom wired).

## 8. Constraints

| Constraint | Source |
|---|---|
| iOS 26 / Xcode 26 minimum target | Portfolio standard; FoundationModels availability + Liquid Glass auto-adoption |
| Swift 6 strict concurrency (`-default-isolation MainActor` + `NonisolatedNonsendingByDefault`) | `.claude/rules/concurrency.md` |
| No `import Combine` — async/await only | `.claude/rules/swiftlint.md` § "Rules That Are Errors" |
| No `import SceneKit` — deprecated WWDC 2025 | `.claude/rules/swiftlint.md` |
| No `AnyView` / no `@unchecked Sendable` / no force-unwrap | `.claude/rules/swiftlint.md` |
| SwiftLintPlugins **SUSPENDED** on Xcode 26 — commented out in `Package.swift` until compatible release | `.claude/rules/swiftlint.md` |
| AVAudioNodeTap TWO-PART rule (no `self` capture; `@Sendable` annotation; Sendable accumulator) | `.claude/rules/concurrency.md` § AVAudioNodeTap |
| `SFSpeechRecognizer` gated via cached `NSSpeechRecognitionUsageDescription` check; no-op when missing | `.claude/rules/warnings.md` § Privacy-Gated Frameworks |
| `AVAudioApplication.requestRecordPermission()` gated via cached `NSMicrophoneUsageDescription` check; no-op when missing | `.claude/rules/warnings.md` |
| COPPA-2026 parental consent — annual re-consent per FTC 2026 amendments effective 2026-04-22 | `.claude/rules/age-assurance.md` |
| Declared Age Range API on iOS 26+ | `.claude/rules/age-assurance.md` |
| Trauma-informed posture (validate-then-inform / hold-space / refer-up) for mood-tagged distress signals | `.claude/rules/trauma-informed-content.md` |
| Tradition-layer cultural-sensitivity gate per ADR-016 standing approval | `.claude/rules/trauma-informed-content.md` § ADR-016 carve-out |
| No third-party analytics SDKs — no Firebase / Mixpanel / Amplitude | `@Docs/TECHNICAL_DESIGN.md` § Analytics |
| Hub Contribution Level 1 JSON at `spark-anvil-hub/Resources/HubContributions/voicetale.json`; Level 2 Swift overlay in `Packages/Libraries/Sources/AppFeature/HubContribution/VoiceTaleHubContribution.swift` | `@Docs/TECHNICAL_DESIGN.md` § Adventure Mode |

## 9. Definition of Done (Phase 1)

Standard Phase 1 DoD pattern per `.claude/rules/workflow.md` § Definition of Done:

- [ ] Build clean (all targets, zero warnings) — verify via MCP `BuildProject`
- [ ] Unit tests cover: 5-beat timer + boundary nudge / transcript pipeline fallback when permission denied / `VoiceStoryReflection` static fallbacks / tradition catalog loading
- [ ] UI tests cover: record → review → reflect golden path / anthology + tradition + daily prompt flows
- [ ] First 60 seconds reaches aha moment (kid records 30-second hook+setup; Bramble responds with one observation)
- [ ] App icon (6-variant Liquid Glass set — light / dark / tinted variants via Icon Composer)
- [ ] COPPA-2026 parental consent functional + annual re-consent surfaced
- [ ] Composable avatar editor adopts R3 segmented `.lite`+`.full` pattern per writing-craft cluster
- [ ] Accessibility audit PASS (VoiceOver / Dynamic Type / WCAG AA contrast in light + dark; recording status spoken)
- [ ] Performance budget targets met (record latency < 50ms; transcript turnaround < 2s for 60s audio)
- [ ] Tradition layer cultural-sensitivity gate cleared per ADR-016
- [ ] CLAUDE.md § "Things That Will Bite You" updated with discovered patterns
- [ ] All 4 phase-1 kits (01–04) ship with cast cameos wired per DN-S Move B

## Read order (for the next implementing session)

1. This doc
2. `@Docs/TECHNICAL_DESIGN.md` — architecture + state machines + domain model
3. `@Docs/FEATURE_PLAN.md` — phased roadmap with per-phase exit criteria
4. `@Docs/HANDOFF_FROM_LABSMITH_FORGEKIT_BOOTSTRAP.md` — SPM/ForgeKit canonical wiring
5. `@Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` — DN cast (Lean / Slow / Pivot / Refrain)
6. `@Docs/HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` — Move D voicing (3:1 asks-vs-states)
7. `@Docs/HANDOFF_FROM_LABSMITH_AVATAR_SIMPLIFIED_MIGRATION.md` — avatar editor pattern
8. `@Docs/HANDOFF_FROM_LABSMITH_PILLAR_DEEPENING_C1_VOICE_EXPORT.md` — cross-app voice-export hook
9. `@.claude/rules/forgekit.md` — module catalog + gotchas
10. `@.claude/rules/concurrency.md` § AVAudioNodeTap — load-bearing TWO-PART rule for audio capture
11. `@.claude/rules/foundationmodels.md` — `@Generable` + fallback discipline
12. `@.claude/rules/trauma-informed-content.md` — tradition layer cultural-sensitivity gate
13. `@.claude/rules/xcode-agent-safety.md` — do not write Xcode-managed files from disk

## Cross-references

- `@Docs/TECHNICAL_DESIGN.md` — architecture
- `@Docs/FEATURE_PLAN.md` — phased roadmap
- `@Docs/HANDOFF_FROM_HUB_ENGINEERING_KICKOFF.md` — Tier-3 ELA cluster cohort placement (composite 60.0)
- `@Docs/HANDOFF_FROM_LABSMITH_FORGEKIT_BOOTSTRAP.md` — bootstrap playbook
- `@Docs/HANDOFF_TO_USER_XCODE_WORKSPACE_INTEGRATION.md` — companion handoff for the Xcode-UI steps the agent cannot perform
