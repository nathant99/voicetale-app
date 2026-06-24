# VoiceTale

Voice-first oral storytelling workshop for tweens — 60-120 second told tales across a 5-beat arc (hook/setup/rising/turn/close), with on-device transcript-side AI reflection and a tradition layer that honors oral-storytelling lineages without appropriation.

> **Deeper context**: `@Docs/TECHNICAL_DESIGN.md` (architecture), `@Docs/FEATURE_PLAN.md` (in-flight work), `@Docs/IMPLEMENTATION_HANDOFF.md` (handoff state), `@Docs/APP_SPECIFIC_NOTES.md` (preserved prior CLAUDE.md content). Portfolio-wide rules auto-load from `@.claude/rules/`.

## Tech Stack

- **Language**: Swift 6 (strict concurrency)
- **UI**: SwiftUI
- **AI**: FoundationModels (on-device)
- **Persistence**: SwiftData
- **Testing**: Swift Testing (`@Test`, `#expect`)
- **Min Target**: iOS 26 / Xcode 26
- **Architecture**: App shell + local Swift Package — monorepo layout: `Apps/VoiceTale/` (xcodeproj) + `Packages/Libraries/Package.swift` (SPM)
- **Framework**: ForgeKit (pinned via `.package(url:, from: "0.99.0")`)

Portfolio-wide tech stack rules live in `@.claude/rules/forgekit.md` + `@.claude/rules/concurrency.md` + `@.claude/rules/swiftui.md` + `@.claude/rules/swiftdata.md` + `@.claude/rules/spritekit.md` + `@.claude/rules/foundationmodels.md`. All auto-load with this file.

## Commands

```bash
# Build (iOS Simulator) — always open VoiceTale.xcworkspace, NEVER Apps/VoiceTale/VoiceTale.xcodeproj directly
xcodebuild -workspace VoiceTale.xcworkspace -scheme VoiceTale \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# Tests
xcodebuild test -workspace VoiceTale.xcworkspace -scheme VoiceTale \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Prefer MCP `BuildProject` / `RunSomeTests` over `xcodebuild` when Xcode is open (per `@.claude/rules/workflow.md` § "MCP-First Testing Workflow").

## Xcode File Safety (LOAD-BEARING — read before any write)

> 🛑 **CRITICAL**: The Claude agent runs **inside Xcode** (Coding Assistant integration). Writing to any Xcode-managed file can force a workspace reload that **terminates the agent session mid-task**. This rule is non-negotiable — file a handoff doc instead.
>
> **User direction (load-bearing, 2026-06-20; re-affirmed 2026-06-21 — TWICE in two consecutive multi-commit work-cycles; re-affirmed AGAIN 2026-06-22 — THIRD consecutive multi-commit auto-cycle round; re-affirmed AGAIN later 2026-06-22 — FOURTH same-day session paired with "do not stop until fully done" full-autonomy approval covering within-round multi-PR sequencing; re-affirmed AGAIN 2026-06-22 evening — FIFTH same-day reaffirmation paired with the explicit instruction to "Update CLAUDE.md, rules, docs about this" alongside an in-message memory-save acknowledgement and within-round-autonomy approval ("go with all your recs / do not stop until fully done"); re-affirmed AGAIN 2026-06-23 — SIXTH consecutive round, paired with a "describe and explain options before you start" preamble + "update docs as you go" instruction + the standing "follow technical design doc" + "swift files in SPM modules follow standard project folder structure" reminders; re-affirmed AGAIN 2026-06-23 deep evening — SEVENTH consecutive round, paired with the same "describe and explain each option before you start" preamble + "update docs as you go" + "follow technical design doc" + "standard SPM folder structure" + "create session handoff at end" instructions, alongside another in-message memory-save acknowledgement and "go with all your recs / do not stop until fully done / everything is approved" within-round full-autonomy approval covering 5 planned PRs in the round; re-affirmed AGAIN 2026-06-24 — EIGHTH consecutive same-author re-affirmation and the FIRST cross-day-boundary one in the chain (the prior seven all landed within the 2026-06-22 ⇄ 2026-06-23 window), paired with the same "describe and explain and give more details about each option before you start" preamble + "Update CLAUDE.md, rules, docs about this" tri-surface doc-propagation instruction + "Update docs as you go" + "Create session handoff for the next CLAUDE session at the end of current session" + standing "follow technical design doc" + "swift files in SPM modules follow standard project folder structure" reminders, alongside another in-message memory-save acknowledgement and a MULTI-AXIS-PRIORITIZED within-round full-autonomy approval covering a 7-PR round explicitly framed as "Prioritize maximizing forgekit integration and feature plan and open handoff work. all of the above. everything is approved. go with all your recs. do not stop until fully done.")**: *"Do not author or edit Xcode-managed files — including the Xcode **workspace** file (`VoiceTale.xcworkspace/contents.xcworkspacedata`) and the Xcode **scheme** + **test plan** files (`*.xcscheme`, `VoiceTale.xctestplan`). Instead, file a handoff doc with the user to do Xcode-UI work. Staging and committing Xcode-managed files (after the user generates them via Xcode) is OK; **authoring the bytes from disk is not**."* Codified as durable preference in agent memory + `.claude/rules/xcode-agent-safety.md` (with named-file emphasis per the two specific files the user direction calls out). The 2026-06-22 morning re-affirmation paired the rule with **explicit instruction that the auto-cycle Default applies to multi-commit feature work without per-step confirmation prompts** — see `.claude/rules/workflow.md` § Auto-Cycle Default. The 2026-06-22 same-day fourth pairing **extends auto-cycle from a per-cycle Default to a within-round multi-PR Default**: when the user pre-approves a round with phrasing like "go with all your recs / everything is approved / do not stop until fully done," the agent ships every planned PR in that round through branch → PR → merge → verify without intermediate confirmation, while still honoring the Xcode-managed-file ban as the non-negotiable inner constraint. The 2026-06-22 evening fifth pairing **codified the user-direct instruction to keep CLAUDE.md + `.claude/rules/*.md` + `Docs/*.md` in lockstep with each re-affirmation** ("Update CLAUDE.md, rules, docs about this") — meaning the named-file ban, the auto-cycle Default, and the within-round multi-PR Default all propagate to all three doc surfaces in the same round they're re-affirmed in. The 2026-06-23 deep evening SEVENTH re-affirmation further codified the **per-round session-handoff requirement**: every round closes with a `Docs/SESSION_HANDOFF_<date>_<phase>.md` artifact captured for the next CC session — the in-message "create session handoff for the next CLAUDE session at the end of current session" instruction was the explicit user direction. The 2026-06-24 EIGHTH cross-day-boundary re-affirmation contributes a new load-bearing observation: **the rule survives a UTC day rollover with zero degradation** AND **a single round may legitimately span multiple prioritization axes ("maximize forgekit integration AND feature plan AND open handoff work — all of the above")** without the agent fragmenting the work into separate rounds. **The compound rule (eight consecutive same-author re-affirmations spanning two calendar days + auto-cycle Default + within-round full-autonomy pairing + tri-surface doc-propagation discipline + per-round session-handoff discipline + cross-day-boundary-stable invariant + multi-axis-prioritization-within-a-single-round Default) is SHIP-READY-WITH-URGENCY for labsmith portfolio sync (`scripts/copy_rules_to_repos.sh --apply`)**: the EIGHTH consecutive re-affirmation crossing the daily boundary, paired with explicit multi-axis prioritization in the SAME round + tri-surface doc-propagation + session-handoff instructions, is the strongest empirical signal yet that the rule is load-bearing enough across work-cycles + sequencing scales + doc-surfaces + session-boundaries + calendar-day-boundaries + prioritization-axes to warrant immediate portfolio-wide propagation to all 140 active app repos.

### Never write these from disk

| File pattern | Why it's owned by Xcode |
|---|---|
| `*.xcodeproj/project.pbxproj` | Workspace-defining XML; direct edits trigger External Changes dialog and can corrupt |
| `*.xcworkspace/contents.xcworkspacedata` | Workspace membership list; editing forces workspace reload |
| `*.xcscheme` (anywhere) | Scheme JSON; Xcode caches in memory and overwrites on save |
| `*.xctestplan` | Auto-generated by Xcode; the FILE is canonical and committed, but its JSON content is forbidden to author by hand |
| `*.xcassets/Contents.json` (catalog root OR `*.imageset/Contents.json`) | Owned by Xcode's asset-catalog editor |
| `*/Info.plist` (app-target) | Owned by Xcode's target editor |
| `*.entitlements` | Owned by Xcode's capabilities editor |
| `*.xcdatamodeld/` | Owned by Xcode's Core Data / SwiftData model editor |
| `xcuserdata/` (anywhere) | Xcode owns this; any agent edit invalidates immediately |
| `Package.resolved` | SPM resolves; never author by hand. Xcode re-resolves on workspace open |
| `.swiftpm/` (anywhere) | Xcode's SPM cache; deletion is OK as a recovery step but never write |

### Instead — file a handoff doc

When the task legitimately needs an Xcode-managed change, **file a `Docs/HANDOFF_TO_USER_<TOPIC>.md`** describing the GUI steps the user takes in Xcode. Staging + committing files the user generated via the Xcode UI is fine; what's forbidden is **authoring the bytes from disk**.

Handoff doc template:

```markdown
---
status: ACTIVE
date: YYYY-MM-DD
direction: agent → user
intent: <one-line summary of the GUI step the user must perform>
freshness-horizon: 30 days
---

# Handoff to User — <topic>

Direction: **agent → user**. <Brief framing: why the agent cannot do this from disk + which rule forbids it.>

## Step 1 — <action>
1. <numbered Xcode-UI step>
...
**Expected result**: <what the user should see after>.

## Why this step requires the user, not the agent
<Cite `.claude/rules/xcode-agent-safety.md` + the specific file class.>

## Cross-references
- `.claude/rules/xcode-agent-safety.md`
- <related handoff or design doc>
```

Reference impls already in this repo:
- `Docs/HANDOFF_TO_USER_XCODE_WORKSPACE_INTEGRATION.md` — workspace add-package / target-framework link / scheme test-plan add / Info.plist usage descriptions

### Always safe to write

- **Swift source** under `Packages/Libraries/Sources/<Target>/` (SPM auto-discovers)
- **Swift test source** under `Packages/Libraries/Tests/<Target>Tests/`
- **Swift source** under `Apps/VoiceTale/VoiceTale/` (Xcode synchronized-folder)
- **Markdown** anywhere (`CLAUDE.md`, `Docs/*.md`, `.claude/rules/*.md`)
- **JSON / YAML config** that's not project-membership-defining (resource JSON under `Resources/`)
- **Static assets** (`*.webp`, `*.caf`, `*.lottie`)
- **`.gitignore`, `.gitattributes`**
- **Scripts** (`scripts/*.py`, `*.sh`)
- **`ExportOptions.plist`** at repo root (NOT the app's `Info.plist`)

### Full canonical rule + recovery steps

`@.claude/rules/xcode-agent-safety.md` — exhaustive file classification, safe escape hatches, recovery procedures when the rule's been broken, MCP-vs-filesystem priorities.

## Things That Will Bite You

App-specific gotchas accumulated through implementation. Portfolio-wide gotchas live in `@.claude/rules/` (see § App-Specific Conventions below).

- **`AVAudioFile(forWriting:settings:)` defaults `commonFormat` to `.pcmFormatFloat32`.** If you then call `write(from:)` with an Int16 PCM buffer, AVAudioFile invokes its internal Float32→Int16 converter (`ExtAudioFile::WriteInputProc` → `AudioConverterFillComplexBuffer`) which trips `CAVerboseAbort` (`EXC_BREAKPOINT`) on the iOS simulator. **Fix**: always pass `commonFormat:` + `interleaved:` to the AVAudioFile init so its processingFormat matches your write buffer. Discovered during the Pillar Deepening C1 CAF-export implementation (PR-4, 2026-06-22). Codified in `.claude/rules/audio-pipeline.md` § "iOS: AVAudioFile commonFormat must match the write buffer".
- **AVAudioConverter callback shape: deliver once, then `.endOfStream` on the second call.** For a single-shot read+convert+write path the canonical pattern is: track `didDeliver` flag; first callback sets `outStatus = .haveData` + returns the source buffer; second callback sets `outStatus = .endOfStream` + returns `nil`. Streaming many small chunks via repeated `convert(to:)` calls is much harder to get right under sample-rate conversion because resampler lookahead state spans chunks. For our ≤120s recordings the single-shot pattern is more robust and within the process memory budget (~46 MB at 48 kHz Float32 stereo). See `Packages/Libraries/Sources/Services/VoiceTaleExporter.swift` for the reference impl.
- **Test crash that says "Lost connection to testmanagerd" almost always means simulator brick, not real test failure.** Per `.claude/rules/test-crash-recovery.md` § "Detection signals" — first action is always `xcrun simctl shutdown all && xcrun simctl erase all`, NOT closing Xcode + NOT deleting DerivedData. After reset, re-run the suite. If it passes, the failure was a transient simulator state from a prior crash + we're back to the green path.
- **Additive Optional fields on `Codable` value types stored in SwiftData JSON-blobs are back-compat free.** Pre-App-Store rule per `@.claude/rules/swiftdata.md` § "Pre-App Store: don't create new VersionedSchema for unreleased models." When VoiceTale needed to attribute voice characters per beat (Phase 1.1 PR #73), `BeatSegment` gained `voiceCharacterSlug: String?` and `PersistentVoiceTaleEntry` carried it transparently because the value is serialized through `JSONEncoder` into `encodedMetadata: Data`. Swift's synthesized `init(from:)` uses `decodeIfPresent` for Optional properties — legacy JSON missing the key decodes with `nil`. Same applies for `PersistentPlayerProgress.lastActiveDate` (PR #78) and `completedKitIDsRaw: [Int] = []` (PR #75) added directly on the `@Model` class with default values. **The pattern works only because we're still pre-1.0 + no `VersionedSchema` migration has been formalized**; after the first App Store ship, additive changes to SwiftData `@Model` fields require a real `SchemaMigrationPlan` stage.
- **DistressSignalDetector keyword matching must be word-boundary-anchored.** PR #76's first cut used `String.contains` directly and would have matched "deadline" against the loss-axis "died" keyword. The canonical pattern in `Packages/Libraries/Sources/AIMentor/DistressSignalDetector.swift` walks each match's preceding + following character and confirms they're non-alphanumeric (treating start/end of string as a boundary). Future axes added to the detector must use the same `matches(_:anyOf:)` helper so the false-positive surface stays controlled. Trauma-informed framing per ADR-016 makes false positives WORSE than false negatives — every false trigger shames a neutral telling.
- **`@AppStorage` cannot box an `Optional` value type directly — encode through a stable raw `String`.** The Phase 2 anthology mood filter needs to persist `VoiceTaleMood?` across launches, but `@AppStorage("key") private var x: VoiceTaleMood?` fails to compile because `@AppStorage` only supports the canonical `Codable`-via-`RawRepresentable` shape. **Canonical fix**: store as `@AppStorage("voicetale.anthology.filter") private var persistedFilterRaw: String = ""` and expose pure `static` encode/decode helpers (`AnthologyView.encodeFilter(_:)` / `AnthologyView.decodeFilter(_:)`) that map `nil ⇄ ""` and `mood ⇄ mood.rawValue`. Pure-function helpers also unlock unit-testable round-trip coverage without spinning up a SwiftUI host. Discovered + codified during PR #80 (2026-06-23).
- **`MCP RunSomeTests` testIdentifier is the suite-name (`FooTests`), NOT the test-suite display string (`Foo`).** Calling `RunSomeTests` with `testIdentifier: "AnthologyFilterPersistence"` (or any `@Suite("Foo")` display name) fails with `Test 'Foo' not found in target 'Bar'` even though `XcodeGlob` finds the test file. The xcode-tools MCP indexes tests by the **Swift type name** (the suite struct), not the `@Suite` display attribute. Always pass the struct name + `Tests` suffix per the existing convention (e.g., `AnthologyFilterPersistenceTests` not `AnthologyFilterPersistence`). Use `GetTestList` + `grep` against `fullTestListPath` to confirm the canonical identifier when in doubt. Codified during PR #80 (2026-06-23).

## App-Specific Conventions

See `@Docs/APP_SPECIFIC_NOTES.md` for the preserved prior CLAUDE.md content (architecture / domain patterns / gotchas accumulated through development). Portfolio-wide rules — Swift 6 concurrency, SwiftData patterns, testing conventions, ForgeKit module APIs, Liquid Glass register, distributed-narrative methodology, trauma-informed gates, COPPA / age-assurance — auto-load from `@.claude/rules/` (24+ files synced from labsmith). Do NOT re-state portfolio-wide rules here.

## Reference Documents

- `@Docs/TECHNICAL_DESIGN.md` — architecture, state machines, domain model
- `@Docs/IMPLEMENTATION_HANDOFF.md` — labsmith-shipped implementation context
- `@Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` (or `_ENHANCEMENT.md`) — cast + curricular embedding
- `@Docs/APP_SPECIFIC_NOTES.md` — content preserved from prior CLAUDE.md (pre-v2)
- `@.claude/rules/` — portfolio-wide rules (24+ auto-loaded files)
