---
status: CLOSED
date: 2026-06-19
closed: 2026-06-22
direction: app → labsmith / hub
intent: confirm ForgeKit bootstrap completion + Phase 0 close-out for voicetale-app; signal Phase 1 implementation can proceed
freshness-horizon: 30 days
---

> **CLOSED 2026-06-22**: Phase 0 fully landed — workspace integration commit `c67ee1a` (2026-06-20), all 7 SPM targets shipped, all 4 Xcode-UI prerequisites completed by user via `Docs/HANDOFF_TO_USER_XCODE_WORKSPACE_INTEGRATION.md` (status CLOSED 2026-06-21). Phase 1 substantially done: data layer + voice authoring engine + transcript pipeline + Bramble + tradition layer + onboarding + analytics + gamification + adventure mode all shipped per `Docs/FEATURE_PLAN.md`. This handoff served as the Phase 0 close-out signal; flipped to CLOSED in the same round as the FIFTH user-direct re-affirmation of the Xcode-managed file safety rule (per `CLAUDE.md` § "Xcode File Safety") to keep the doc surface clean.

# Handoff from App — ForgeKit integration complete (Phase 0 close-out)

Direction: **voicetale-app → labsmith**. Confirming the Step 6 close-out from `HANDOFF_FROM_LABSMITH_FORGEKIT_BOOTSTRAP.md` for voicetale-app. Phase 0 (full `IMPLEMENTATION_HANDOFF.md` fill-in + ForgeKit bootstrap) is complete; Phase 1 can proceed once the user completes the 4 Xcode-UI steps documented in `HANDOFF_TO_USER_XCODE_WORKSPACE_INTEGRATION.md`.

## What shipped

### ForgeKit pin

```swift
// Packages/Libraries/Package.swift
.package(url: "https://github.com/nathant99/forgekit.git", from: "0.99.0")
```

### SPM target layout

Monorepo layout per `.claude/rules/spm-architecture.md` § "Apps/Packages/Server monorepo":

```
voicetale-app/
├── Apps/VoiceTale/                            # synchronized-folder app shell
│   ├── VoiceTale/
│   ├── VoiceTale.xcodeproj
│   ├── VoiceTaleTests/
│   └── VoiceTaleUITests/
├── Packages/Libraries/
│   ├── Package.swift                           # 6 targets + 7 test targets
│   ├── Sources/
│   │   ├── Models/                             # VoiceTaleEntry, BeatSegment, ArcBeat, VoiceTaleMood, VoiceStoryReflection + PersistentVoiceTaleEntry @Model + SchemaV1
│   │   ├── Services/                           # VoiceTalePersistence (ModelContainer factory)
│   │   ├── VoiceAuthoring/                     # VoiceAuthoringActor stub (replaces the canonical GameEngine slot per VoiceTale's voice-first scope)
│   │   ├── SharedUI/                           # BeatTimerView stub
│   │   ├── AIMentor/                           # BrambleMentor @Observable stub + static fallback dictionary
│   │   └── AppFeature/                         # AppRootView with 4-tab TabView (Tell / Adventure / Progress / Profile)
│   └── Tests/                                  # one test file per target + 5 ForgeKit sanity tests
├── VoiceTale.xcworkspace                       # Xcode-generated; user adds Packages/Libraries via GUI
└── VoiceTale.xctestplan
```

### Per-target ForgeKit wiring

| Target | ForgeKit deps |
|---|---|
| `Models` | `ForgeModels` |
| `Services` | `ForgePersistence`, `ForgeAnalytics`, `ForgeAudio` |
| `VoiceAuthoring` | `ForgeAudio` |
| `SharedUI` | `ForgeUI`, `ForgeAccessibility` |
| `AIMentor` | `ForgeAI` |
| `AppFeature` | `ForgeNavigation`, `ForgeUI`, `ForgePedagogy`, `ForgeGamification`, `ForgeAdventure`, `ForgeAvatar`, `ForgeCelebration` |

### Sanity tests

5 `ForgeKitIntegrationTests` (per bootstrap doc Step 4):

1. `ForgeKitVersion.version` is non-empty
2. `BloomLevel.remember < BloomLevel.create` (Comparable conformance)
3. `GradeLevel.allCases` is non-empty (ordering exists)
4. Local `VoiceTaleEntry` compiles alongside `ForgeModels` types (no collision)
5. `XPEngine(config:).level(for: 0)` returns a non-negative level

Plus per-target stub tests (one each) — `ModelsTests`, `ServicesTests`, `VoiceAuthoringTests`, `SharedUITests`, `AIMentorTests`, `AppFeatureTests`.

## What's deferred / awaiting user

The agent operates from inside Xcode and cannot write `.xcworkspace` / `.pbxproj` / `.xcscheme` / `Info.plist` from disk per `.claude/rules/xcode-agent-safety.md`. The 4 Xcode-UI steps documented in `HANDOFF_TO_USER_XCODE_WORKSPACE_INTEGRATION.md`:

1. `File > Add Package Dependencies > Add Local...` → `Packages/Libraries`
2. Link `AppFeature` product into the VoiceTale app target's Frameworks list
3. Add the 7 SPM test targets to `VoiceTale.xctestplan` via Edit Scheme → Test
4. Add `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` via Target → Info

After Step 2, the agent will author the small `VoiceTaleApp.swift` edit to render `AppRootView()` (synchronized-folder file, safe to write once `AppFeature` resolves).

## Type-collision risks observed

Per `.claude/rules/forgekit.md` § Common Gotchas, the canonical collision candidates are `AppPhase` / `AppTab` / `AvatarConfig`. Voicetale's `AppRootView.AppTab` is namespaced to the view (not a top-level enum) so the only practical collision would be with `ForgeNavigation.AppTab` — qualified at the import site if it ever appears. No proactive renames needed for the bootstrap.

`Models.Expression` collision per `.claude/rules/spm-architecture.md` § Gotchas does not apply — VoiceTale does not define any `Expression` type.

## Open questions resolved during bootstrap

1. **Repo layout — flat vs Apps/Packages/Server monorepo?** Resolved monorepo (`Apps/VoiceTale/` already exists from the Xcode-project generation; `Packages/Libraries/` follows naturally).
2. **`GameEngine` vs `VoiceAuthoring` as the 4th target?** Resolved `VoiceAuthoring` per `TECHNICAL_DESIGN.md` (no SpriteKit surface in VoiceTale). `FEATURE_PLAN.md` updated in the same PR.
3. **ForgeKit version pin?** Resolved `from: "0.99.0"` per the bootstrap doc default.
4. **SwiftLintPlugins?** Resolved SUSPENDED per `.claude/rules/swiftlint.md` (Xcode 26 incompatibility). Commented out in `Package.swift` with a re-enable note.

## Phase 0 IMPLEMENTATION_HANDOFF.md fill-in

Authored inline by the engineering session per `HANDOFF_FROM_HUB_ENGINEERING_KICKOFF.md` § "Phase 0 fill-in ownership" (option B — engineering session authors). 9-section structure per `labsmith/Docs/PORTFOLIO_PATTERNS.md`. Hub does NOT need to file a Phase 0 fill-in handoff; voicetale's `Docs/IMPLEMENTATION_HANDOFF.md` is now canonical.

## Next migration steps (for the next implementing session)

Per `TEMPLATE_PLAN_FORGEKIT_INTEGRATION.md` migration ladder — but voicetale is GREENFIELD (no pre-existing types to migrate), so the ladder doesn't apply. Instead the implementing session walks Phase 1 from `@Docs/FEATURE_PLAN.md` § "Phase 1: Voice-First MVP", authoring directly against ForgeKit types from day one:

1. **VoiceAuthoring real implementation** — AVAudio capture (44.1 kHz mono 16-bit PCM → AAC/M4A) per `.claude/rules/concurrency.md` § AVAudioNodeTap TWO-PART rule
2. **TranscriptPipeline** — on-device `SFSpeechRecognizer` per `.claude/rules/warnings.md` § Privacy-Gated Frameworks (cached usage-description check)
3. **BrambleMentor real implementation** — `LanguageModelSession` + `@Generable VoiceStoryReflectionGeneration` + try-?-fallback discipline per `.claude/rules/foundationmodels.md`
4. **TellView + RecordingControlsView + TranscriptReviewView + BrambleReflectionView** — the core record loop UI
5. **Tradition layer JSON + audio samples** — covered by ADR-016 standing approval (no R0 reviewer block on the story-axis)
6. **Adventure mode Level 2 overlay** — `Packages/Libraries/Sources/AppFeature/HubContribution/VoiceTaleHubContribution.swift` per `TECHNICAL_DESIGN.md` § Adventure Mode

## Cross-references

- `Docs/HANDOFF_TO_USER_XCODE_WORKSPACE_INTEGRATION.md` — companion handoff (4 Xcode-UI steps for the user)
- `Docs/IMPLEMENTATION_HANDOFF.md` — Phase 0 9-section fill-in
- `Docs/TECHNICAL_DESIGN.md` — architecture (updated SPM target shape)
- `Docs/FEATURE_PLAN.md` — phased roadmap (reconciled GameEngine → VoiceAuthoring)
- `Docs/HANDOFF_FROM_LABSMITH_FORGEKIT_BOOTSTRAP.md` — the bootstrap playbook this handoff closes out
- `Docs/HANDOFF_FROM_HUB_ENGINEERING_KICKOFF.md` — Tier-3 ELA cluster engineering kickoff
- `.claude/rules/xcode-agent-safety.md` — load-bearing rule on Xcode-managed file writes
- `.claude/rules/spm-architecture.md` — monorepo + SPM gotchas
- `.claude/rules/forgekit.md` — module catalog + gotchas
- `CLAUDE.md` § Xcode File Safety — surfaced atop the app-specific notes
