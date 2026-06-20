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

## Xcode File Safety (load-bearing)

**DO NOT WRITE Xcode-managed files from disk** — the agent operates from inside Xcode. Direct edits to any of these can corrupt the workspace, force a workspace reload, or terminate the agent session mid-task:

- `*.xcodeproj/project.pbxproj`
- `*.xcworkspace/contents.xcworkspacedata`
- `*.xcscheme`
- `*.xctestplan` (the file Xcode generates IS canonical and committed; what's forbidden is hand-authoring the JSON)
- `*.xcassets/Contents.json`
- `Info.plist` / `*.entitlements` / `*.xcdatamodeld/`

**INSTEAD**: file `Docs/HANDOFF_TO_USER_<TOPIC>.md` describing the GUI steps. Staging + committing files the user generated via the Xcode UI is fine.

Full canonical rule + recovery steps: `@.claude/rules/xcode-agent-safety.md`.

## App-Specific Conventions

See `@Docs/APP_SPECIFIC_NOTES.md` for the preserved prior CLAUDE.md content (architecture / domain patterns / gotchas accumulated through development). Portfolio-wide rules — Swift 6 concurrency, SwiftData patterns, testing conventions, ForgeKit module APIs, Liquid Glass register, distributed-narrative methodology, trauma-informed gates, COPPA / age-assurance — auto-load from `@.claude/rules/` (24+ files synced from labsmith). Do NOT re-state portfolio-wide rules here.

## Reference Documents

- `@Docs/TECHNICAL_DESIGN.md` — architecture, state machines, domain model
- `@Docs/IMPLEMENTATION_HANDOFF.md` — labsmith-shipped implementation context
- `@Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` (or `_ENHANCEMENT.md`) — cast + curricular embedding
- `@Docs/APP_SPECIFIC_NOTES.md` — content preserved from prior CLAUDE.md (pre-v2)
- `@.claude/rules/` — portfolio-wide rules (24+ auto-loaded files)
