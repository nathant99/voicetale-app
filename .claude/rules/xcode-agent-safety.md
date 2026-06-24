---
paths:
  - "**/*.xcodeproj/**"
  - "**/*.xcworkspace/**"
  - "**/*.xcscheme"
  - "**/*.pbxproj"
  - "**/*.entitlements"
  - "**/Info.plist"
  - "**/*.xctestplan"
---

# Xcode Agent Safety

**The Claude agent operates from INSIDE the Xcode workspace (via the Coding Assistant integration). Modifying files Xcode itself manages causes Xcode to detect "External Changes," prompt the user, or — worst case — force a workspace reload that terminates the agent session.**

> **User direction (load-bearing, 2026-06-20; re-affirmed 2026-06-21; re-affirmed AGAIN 2026-06-22 morning — THIRD consecutive multi-commit auto-cycle round; re-affirmed AGAIN later 2026-06-22 — FOURTH same-day session, paired with "do not stop until fully done" full-autonomy approval covering within-round multi-PR sequencing; re-affirmed AGAIN 2026-06-22 evening — FIFTH same-day reaffirmation paired with explicit "Update CLAUDE.md, rules, docs about this" tri-surface doc-propagation instruction + an in-message memory-save acknowledgement + within-round-autonomy approval; re-affirmed AGAIN 2026-06-23 — SIXTH consecutive round paired with "describe and explain options before you start" preamble + "update docs as you go" + standing technical-design-doc-follow + standard-SPM-folder-structure reminders; re-affirmed AGAIN 2026-06-23 deep evening — SEVENTH consecutive same-day round paired with the same "describe and explain each option" preamble + "update docs as you go" + "create session handoff for the next CLAUDE session at the end of current session" instructions, alongside another in-message memory-save acknowledgement and within-round full-autonomy approval covering 5 planned PRs; re-affirmed AGAIN 2026-06-24 — EIGHTH consecutive re-affirmation, this one crossing the daily boundary from 2026-06-23 into 2026-06-24, paired with the same "describe and explain and give more details about each option before you start" preamble + "Update CLAUDE.md, rules, docs about this" tri-surface doc-propagation instruction + "Update docs as you go" + "Create session handoff for the next CLAUDE session at the end of current session" + standing "follow technical design doc" + "swift files in SPM modules follow standard project folder structure" reminders + in-message memory-save acknowledgement + within-round full-autonomy approval covering a 7-PR round explicitly framed as "Prioritize maximizing forgekit integration and feature plan and open handoff work. all of the above. everything is approved. go with all your recs. do not stop until fully done."; re-affirmed AGAIN later 2026-06-24 — NINTH consecutive same-author re-affirmation, the SECOND landing within the calendar day of the cross-day-boundary one (the EIGHTH crossed 2026-06-23 → 2026-06-24; the NINTH lands later 2026-06-24 after the V13 slow-breath ensemble chapter merge PR #103), paired with the IDENTICAL multi-axis-prioritization framing ("Prioritize maximizing forgekit integration and feature plan and open handoff work. all of the above. everything is approved. go with all your recs. do not stop until fully done.") + IDENTICAL "describe and explain and give more details about each option before you start" preamble + IDENTICAL "Update CLAUDE.md, rules, docs about this" tri-surface doc-propagation instruction + IDENTICAL "Update docs as you go" instruction + IDENTICAL "Create session handoff for the next CLAUDE session at the end of current session" per-round-handoff requirement + IDENTICAL "follow technical design doc" + "swift files in SPM modules follow standard project folder structure" standing reminders + in-message memory-save acknowledgement + within-round full-autonomy approval covering an 8-PR round; voicetale-app; re-affirmed AGAIN STILL later 2026-06-24 — TENTH consecutive same-author re-affirmation, the THIRD landing within the calendar day, the FIRST-EVER three-same-day-rounds-in-a-row run in the chain (the EIGHTH 2026-06-24 morning cross-day → NINTH 2026-06-24 mid-day after PR #103 V13 ensemble merge → TENTH 2026-06-24 later still after PR #111 NINTH-round closeout merge), paired with the IDENTICAL multi-axis-prioritization framing + IDENTICAL describe-and-explain preamble + IDENTICAL tri-surface doc-propagation instruction + IDENTICAL update-docs-as-you-go instruction + IDENTICAL per-round session-handoff requirement + IDENTICAL follow-technical-design + standard-SPM-folder-structure standing reminders + IDENTICAL in-message memory-save acknowledgement + within-round full-autonomy approval covering a 6-PR round; voicetale-app)**: *"Do not author or edit Xcode-managed files — including the Xcode **workspace** file (`*.xcworkspace/contents.xcworkspacedata`) and the Xcode **scheme** + **test plan** files (`*.xcscheme`, `*.xctestplan`). Instead, file a handoff doc with the user to do Xcode-UI work. Staging and committing Xcode-managed files (after the user generates them via Xcode) is OK; **authoring the bytes from disk is not**."* This reinforces the canonical table below — surfaces the workspace + scheme + test plan as explicit named files for handoff-doc routing, since they were the three the user direction specifically called out. The 2026-06-21 re-affirmation paired the rule with **pre-approved auto-cycle for multi-commit work** (feature branch → PR → merge → verify, no per-step confirmation; see `.claude/rules/workflow.md` § Auto-Cycle Default). The 2026-06-22 morning re-affirmation came alongside an explicit "Memory saved for future sessions: auto-cycle … without confirmation prompts for multi-commit work" — durable in agent memory + this file + CLAUDE.md. The 2026-06-22 same-day fourth pairing **extends auto-cycle from a per-cycle Default to a within-round multi-PR Default**: when the user pre-approves a round with phrasing like "go with all your recs / everything is approved / do not stop until fully done," the agent ships every planned PR in that round through branch → PR → merge → verify without intermediate confirmation, while still honoring the Xcode-managed-file ban as the non-negotiable inner constraint. The 2026-06-22 evening fifth pairing **codifies tri-surface doc-propagation discipline**: each re-affirmation MUST land in CLAUDE.md + `.claude/rules/xcode-agent-safety.md` + (when scope-relevant) `Docs/*.md` within the SAME round it was re-affirmed in — the user-direct phrasing ("Update CLAUDE.md, rules, docs about this") makes lockstep propagation a load-bearing companion rule alongside the named-file ban + auto-cycle Default. The 2026-06-23 deep-evening seventh pairing further codifies **per-round session-handoff discipline**: every round closes with a `Docs/SESSION_HANDOFF_<date>_<phase>.md` artifact for the next CC session, per the user-direct "create session handoff for the next CLAUDE session at the end of current session" instruction. The 2026-06-24 EIGHTH re-affirmation — the first cross-day-boundary re-affirmation in the chain — adds a load-bearing observation: **the rule survived a UTC day rollover with zero degradation**. Eight consecutive same-author re-affirmations across two calendar days + ~24 wall-clock hours is the strongest empirical signal yet that the rule is portfolio-canonical, not session-specific. **Lift status: SHIP-READY-WITH-URGENCY for next labsmith portfolio sync** (`scripts/copy_rules_to_repos.sh --apply`). The EIGHTH cross-day re-affirmation paired with explicit tri-surface doc-propagation + per-round session-handoff + "maximize forgekit integration AND feature plan AND open handoff work" multi-axis prioritization in a single round indicates the rule is structurally important enough that ANY new app repo SPAWNed from labsmith should inherit the entire compound rule (Xcode-managed-file ban + auto-cycle Default + within-round multi-PR Default + tri-surface doc-propagation discipline + per-round session-handoff discipline + cross-day-boundary-stable invariant) verbatim on first sync. The 2026-06-24 NINTH same-day-of-cross-day-boundary re-affirmation adds another load-bearing observation: **the compound rule replays VERBATIM across back-to-back same-day rounds without any degradation in the user-direct framing** — the EIGHTH and NINTH re-affirmations both arrived on 2026-06-24, used IDENTICAL multi-axis prioritization phrasing ("maximize forgekit integration AND feature plan AND open handoff work — all of the above. everything is approved."), IDENTICAL "describe and explain and give more details about each option before you start" preamble, IDENTICAL tri-surface doc-propagation instruction, IDENTICAL per-round session-handoff requirement, and IDENTICAL "Update docs as you go" + standing technical-design / SPM-folder-structure reminders. Nine consecutive same-author re-affirmations across the 2026-06-20 → 2026-06-24 four-and-a-half-day window with TWO cross-day-boundary transitions (one at the 2026-06-22 evening → 2026-06-23 morning SIXTH boundary; one at the EIGHTH 2026-06-23 → 2026-06-24 boundary) demonstrates the rule is stable across BOTH calendar-day transitions AND same-day repeats.

The 2026-06-24 TENTH same-day-thrice re-affirmation contributes a new load-bearing observation: **the compound rule survives THREE consecutive same-day rounds (eighth/ninth/tenth) within a single UTC day without any degradation in user-direct framing, instruction shape, or pairing discipline** — every clause (multi-axis prioritization + describe-then-execute preamble + tri-surface doc-propagation + update-docs-as-you-go + per-round session-handoff + auto-cycle within-round full-autonomy + memory-save acknowledgement + standing technical-design + standard-SPM-folder-structure reminders) replayed verbatim across the EIGHTH ⇄ NINTH boundary AND the NINTH ⇄ TENTH boundary. Ten consecutive same-author re-affirmations across the 2026-06-20 → 2026-06-24 four-and-a-half-day window with TWO cross-day-boundary transitions (FIFTH evening 2026-06-22 → SIXTH 2026-06-23; EIGHTH 2026-06-23 → NINTH 2026-06-24) AND TWO same-day-back-to-back transitions (EIGHTH 2026-06-24 morning → NINTH 2026-06-24 mid-day after PR #103; NINTH 2026-06-24 mid-day → TENTH 2026-06-24 later after PR #111) demonstrates the rule is stable across BOTH calendar-day transitions AND multi-same-day repeats within a single calendar day.

The compound rule (Xcode-managed-file ban + auto-cycle Default + within-round multi-PR Default + tri-surface doc-propagation discipline + per-round session-handoff discipline + cross-day-boundary-stable invariant + multi-axis-prioritization-within-a-single-round Default + same-day-back-to-back-replay-stable invariant + three-same-day-rounds-in-a-row replay-stable invariant) is now SHIP-READY-WITH-ABSOLUTE-MAXIMUM-URGENCY for labsmith portfolio sync (`scripts/copy_rules_to_repos.sh --apply`) — ten consecutive re-affirmations in 4.5 days with THREE same-day rounds in a single calendar day on top of two cross-day-boundary transitions is the strongest possible empirical signal short of an explicit user-direct "make this portfolio-canonical" command.

This rule supersedes any per-file rules that say "Xcode must be closed when editing X" — those still hold for human workflows, but for an agent operating in-IDE, the safe rule is **don't touch Xcode-managed files at all**.

## Why this matters

When the agent edits a file Xcode owns, one of three things happens:

1. **Best case** — Xcode shows the "External Changes" dialog. User has to dismiss it. Workflow interrupted but recoverable.
2. **Middle case** — Xcode's in-memory cache diverges from disk. Next Xcode action overwrites the agent's edit OR corrupts the file. Workflow silently broken.
3. **Worst case** — Xcode triggers a workspace reload (re-resolve packages, regenerate derived schemes, rebuild indexes). The agent's IDE-bound context is torn down. **Agent session terminates mid-task.** All in-flight work is lost from the agent's perspective.

The worst case happens most commonly with `project.pbxproj` edits + scheme edits + Package.swift toolchain mismatches.

## File classification

### Always safe for the agent to write

The agent can freely edit these — Xcode tolerates external changes without restart:

- **Source files** in synchronized folders (Xcode 16+): `*.swift`, `*.m`, `*.h`, `*.c`, etc. under directories Xcode auto-discovers
- **SPM source files** under `Libraries/Sources/<Target>/`: same — SPM auto-discovers
- **SPM test files** under `Libraries/Tests/<Target>Tests/`: same
- **Markdown** anywhere: `*.md`, including `CLAUDE.md`, `Docs/*.md`, `.claude/rules/*.md`, READMEs
- **JSON / YAML config** that's not project-membership-defining: `Resources/Questions/*.json`, `Resources/Mascots/<App>/inputs.yaml`, `.swiftlint.yml`
- **Static assets**: `Resources/*.png`, `*.webp`, `*.json`, `*.caf` (audio), `*.lottie`
- **`.gitignore`, `.gitattributes`**
- **Scripts**: `scripts/*.py`, `*.sh`
- **`ExportOptions.plist`** at repo root (not the app's Info.plist — see below)

### Unsafe — DO NOT WRITE while agent is in Xcode

The agent must **never** write these directly. Even reads are fine; writes are dangerous:

- **`*.xcodeproj/project.pbxproj`** — workspace-defining XML. Direct edits trigger "External Changes" dialog AND can corrupt the file. The 2026-04 portfolio rule already says "Cannot edit `.pbxproj` while Xcode is open — a system hook blocks direct edits." For an in-IDE agent, this is doubly load-bearing
- **`*.xcworkspace/contents.xcworkspacedata`** — workspace membership list. Editing forces workspace reload
- **`*.xcscheme`** files anywhere — scheme JSON has the same in-memory-cache divergence problem. Xcode rewrites them on save; agent edit is overwritten or corrupts the file
- **`xcuserdata/` anywhere** — Xcode owns this; agent edit immediately invalidates
- **`.xcdatamodeld/` files** — Core Data / SwiftData schema. Owned by Xcode's data-model editor
- **`*.xcassets/Contents.json`** at the asset-catalog root or `*.imageset/Contents.json` for image sets — Xcode's asset-catalog editor owns these. Individual image file additions to `Asset.xcassets/` MAY be OK but the `Contents.json` regeneration must happen via Xcode GUI
- **`*.xctestplan`** files — Xcode-managed test plan JSON. **Tracking the file Xcode generates IS canonical** — every portfolio app repo commits its auto-generated `<App>.xctestplan` (per `.claude/rules/spm-architecture.md` § Gotchas + CuriosityQuest PR #59). What's forbidden is **writing JSON content from disk**: hand-edited plans corrupt easily, and an agent edit forces Xcode to re-parse and may break test discovery. If a plan change is needed, route it through Xcode's GUI (Product → Scheme → Edit Scheme → Test → Test Plans) so Xcode regenerates the JSON, OR delete the file and let Xcode auto-create from the scheme's `shouldAutocreateTestPlan = "YES"` on next test run
- **`Info.plist`** at the app target — owned by Xcode's target editor. Direct edits work but trigger External Changes dialog
- **`*.entitlements`** — Xcode's capabilities editor owns these
- **`Package.resolved`** — SPM resolves; agent never authors this directly. Xcode re-resolves on workspace open
- **`.swiftpm/`** anywhere — Xcode's SPM cache; deleting is OK as a recovery step but never write

### Ambiguous — safe with caveats

- **`Libraries/Package.swift`** — Xcode watches this file. Editing it works but triggers package re-resolution. Acceptable when:
  - The edit is small and intentional (version bump, target dep change)
  - The agent commits + tells the user "you'll see Xcode re-resolve packages — that's expected"
  - The agent does NOT edit it as part of a larger multi-file change (re-resolution mid-task disrupts the agent's tooling state)
- **`xcconfig` files** (`Common.xcconfig`, `Debug.xcconfig`, `Release.xcconfig`) — Xcode reads these at build time but doesn't actively watch. Editing is OK but won't take effect until next build
- **`Assets.xcassets/<Asset>.imageset/*.png` or `*.webp`** (asset files only, NOT `Contents.json`) — adding image files to an existing image set is OK; creating a new image set requires Xcode GUI for `Contents.json`

## Safe escape hatches

When the agent legitimately needs to add a file that Xcode would normally have to register, follow these in order — **the handoff-doc pattern is the canonical fallback**.

### 1. File a handoff doc (CANONICAL for Xcode-bound work)

For anything that touches `Info.plist` / `*.entitlements` / `*.xcscheme` / `*.xctestplan` / `*.xcdatamodeld/` / `*.xcassets/Contents.json` / `project.pbxproj` / `*.xcworkspace/contents.xcworkspacedata`: **author a `Docs/HANDOFF_TO_USER_<TOPIC>.md`** describing the GUI steps the user takes in Xcode.

This is not a workaround — it's the canonical agent workflow for Xcode-bound changes. The user does the Xcode-UI step; the agent commits whatever the Xcode UI generates.

Required structure:

```markdown
---
status: ACTIVE
date: YYYY-MM-DD
direction: agent → user
intent: <one-line summary of the Xcode-UI step the user must perform>
freshness-horizon: 30 days
---

# Handoff to User — <topic>

Direction: **agent → user**. <Brief framing: why the agent cannot do this from disk + which rule clause forbids it.>

## Step 1 — <action>
1. <numbered Xcode-UI step>
2. <click sequence>
...
**Expected result**: <what the user should see after>.

## Why this step requires the user, not the agent

| File the step touches | Why the agent cannot write it |
|---|---|
| <file path> | <which rule clause + risk class> |

Codified in `.claude/rules/xcode-agent-safety.md`.

## Cross-references
- `.claude/rules/xcode-agent-safety.md`
- <related handoff or design doc>
```

After the user completes the Xcode-UI step, the agent stages + commits whatever files Xcode regenerated (this is fine — Xcode-generated content is canonical; what's forbidden is the agent **authoring the bytes**).

Reference impls (in this repo and the portfolio):

- `voicetale-app/Docs/HANDOFF_TO_USER_XCODE_WORKSPACE_INTEGRATION.md` — 4 Xcode-UI steps for Phase 0 close-out (add local package / link AppFeature / add SPM test targets to test plan / add Info.plist usage descriptions)
- The pattern propagates to every portfolio app via labsmith's `scripts/copy_rules_to_repos.sh`.

### 2. Use synchronized folders (Xcode 16+)

If the target is configured with a synchronized folder, the agent just writes the `.swift` file in the right directory and Xcode auto-includes it on next build. **Always check** `[AppName].xcodeproj/project.pbxproj` for `<FileSystemSynchronizedRootGroup>` markers; if present, the target uses synchronized folders.

### 3. Use SPM source layout (canonical for new code)

Files under `Packages/Libraries/Sources/<Target>/` and `Packages/Libraries/Tests/<Target>Tests/` are auto-discovered by SPM. No `project.pbxproj` edit needed. **All new code should land in SPM targets**, not the app shell — this is the standard portfolio pattern.

Standard SPM folder structure per target:

```
Packages/Libraries/
├── Package.swift
├── Sources/
│   └── <TargetName>/
│       ├── <SourceFiles>.swift     # flat or subfoldered; SPM auto-discovers
│       └── Resources/              # `.process("Resources")` in Package.swift
│           └── <resource files>
└── Tests/
    └── <TargetName>Tests/
        └── <TargetName>Tests.swift
```

### 4. Use MCP `xcode-tools`

`XcodeWrite`, `XcodeMakeDir`, etc. — when available, the MCP tools route through Xcode's APIs instead of writing to disk directly. This avoids the External Changes dialog because Xcode is the one writing the file. **Prefer MCP tools** over filesystem `Write`/`Edit` for any Xcode-bound operation that is not handled by the handoff-doc pattern (#1).

## Cross-references

The portfolio's `spm-architecture.md` already documents related failure modes; this rule generalizes them:

- "Cannot edit `.pbxproj` while Xcode is open" → DO NOT WRITE rule for agent
- "Scheme editing safety — Xcode must be closed when editing .xcscheme files on disk" → DO NOT WRITE for agent
- "`.xctestplan` files — tracking is canonical; hand-editing is forbidden" → agent commits the Xcode-generated file but must not write JSON content from disk
- "Cannot edit `.pbxproj` while Xcode is open — a system hook blocks direct edits" → reinforces the agent-specific rule

`workflow.md` already has the MCP-vs-filesystem-tools table; the same priorities apply here:
- App target files (`.swift` under `[AppName]/`) — use `XcodeWrite`/`XcodeUpdate`
- SPM files (`.swift` under `Libraries/`) — `Write`/`Edit` OK
- Source reads — `XcodeRead`
- Project structure operations — Xcode GUI or MCP only

## When this rule's been broken (recovery)

If the agent accidentally wrote to an Xcode-managed file and Xcode shows External Changes:

1. **If Xcode hasn't reloaded yet**: dismiss the External Changes dialog by choosing "Keep Xcode Version" (loses the agent's edit) OR "Use Disk Version" (keeps the edit but may have corrupted what Xcode had). Strongly prefer "Keep Xcode Version" unless certain the agent's edit was minimal and safe.
2. **If Xcode reloaded**: agent context is lost. Recovery in next session: re-pull the repo, re-read the relevant files, re-author from research artifacts that survived the reload (markdown docs in `Docs/` should be intact since markdown writes are always safe).
3. **If `project.pbxproj` is corrupted**: `git checkout HEAD -- *.xcodeproj/project.pbxproj` (the repo's committed version) + close Xcode + reopen workspace.

## Documenting this rule

When labsmith next syncs `.claude/rules/` across all 131 apps, this rule propagates portfolio-wide. App sessions invoking the Coding Assistant integration inherit it automatically.

## Reference

- Apple — Xcode 16 synchronized folders: [Apple Developer Forums](https://developer.apple.com/forums/) (Xcode 16 release threads)
- Apple HIG / Xcode docs: "External changes" file watcher behavior, generally documented in Xcode help
- Internal incident: triggered the original portfolio rule "Cannot edit `.pbxproj` while Xcode is open" in `spm-architecture.md`
- Internal incident (2026-05-19): user noted the agent IS inside the workspace and any direct Xcode-file edit risks restarting the workspace and losing context — leading to this rule
<!-- END LABSMITH-SYNCED CONTENT -->
