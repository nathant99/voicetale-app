---
status: ACTIVE
date: 2026-06-23
direction: session → next-session
intent: hand off the late-evening 2026-06-23 round (PRs #86–#89) + queued follow-ups so the next CC session lands hot
freshness-horizon: 14 days
---

# Session handoff — 2026-06-23 late evening

Direction: **CC session → next CC session**. Read in tandem with `@Docs/FEATURE_PLAN.md` § "Round close-out 2026-06-23 late evening (PRs #86–#89)" + `@Docs/IMPLEMENTATION_HANDOFF.md` § same.

## What shipped this round

**4 PRs merged to main; all verified via `gh pr view <n> --json state,mergedAt` per `@.claude/rules/workflow.md`**:

| PR | Title | What landed |
|---|---|---|
| **#86** | proportional celebration — first 5-beat tale | Subtle beat-boundary haptic on every 5-beat transition + epic full-screen celebration on inaugural five-beat tale + new `first_five_beat_tale` achievement (XP 75, CCSS-ELA SL.6.4). Catalog 22 → 23 entries. |
| **#87** | juice layer — selection haptic on chip picks | `HapticsBridge.fireSelection()` wired into mood / voice-character / filter chip surfaces. Only fires on real value changes. |
| **#88** | mood retrospective card in anthology | Per-mood Bramble-register retrospective surfaces when ≥3 tales of the filter-active mood exist. 12 copy variants × anti-shame guard. |
| **#89** | ForgeIntents foundation (15th module) | Typed `VoiceTaleIntentDestination` + `VoiceTaleIntentRouter` + canonical Siri shortcut phrases. Foundation only — `AppIntent` registration deferred. |

Round total: ~22 new tests; 4 merged PRs; 0 Xcode-managed files touched; all 4 verified MERGED on origin.

## State of the tree at session close

- **Branch**: `chore/round-2026-06-23-late-evening-closeout` (working — this handoff doc + FEATURE_PLAN / IMPLEMENTATION_HANDOFF doc edits). Pending commit + PR at session close.
- **`main`**: at `2e02108` (PR #89 merge commit); origin in sync.
- **Working tree before this commit**: clean (10 prior uncommitted files were the PR #86 implementation; all shipped + merged).
- **No pending `feature/*` branches with un-merged work** — every branch this round was deleted via `gh pr merge --delete-branch`.

## Phase scoreboard

| Phase | Status | Notes |
|---|---|---|
| Phase 1 (MVP) | **COMPLETE** | Only Apple Declared Age Range API gate is open — Xcode-UI handoff in flight (`@Docs/HANDOFF_TO_USER_APPLE_DECLARED_AGE_RANGE.md`) |
| Phase 1.1 (Voice-Character) | **EXIT-COMPLETE** | All 5 boxes shipped |
| Phase 2 (Anthology + Photo) | **5 of 7 shipped** | Remaining: **photo attach + parental gate** (Xcode-UI gated on `NSCameraUsageDescription`); the 7th is a curation polish item already shipped under a different banner |
| Phase Onboarding & Child Safety | Mostly shipped | Excellence-framework items mostly complete |
| Phase Engagement Foundation | **4 of 5 shipped** | Remaining: ambient ad-hoc tightening |
| **Phase Delight & Polish** | **3 of 7 shipped (this round)** | Remaining: micro-delight coverage / Bramble personality callbacks / mastery moments / easter eggs / published-tale certificates + anthology covers |
| Phase Accessibility & Trauma-Informed Polish | Mostly shipped | Dynamic Type AX5 + WCAG AA color-contrast audit + full simulator VoiceOver pass are deferred / hands-on-review-gated |
| Phase 3 (Cross-Cluster Cameo + Performance Polish) | NOT STARTED | |
| Phase 4 (Classroom + App Store + Final Polish) | NOT STARTED | |

**ForgeKit declared+used modules**: **15** (Phase 2 round added ForgeSpotlight as #14; this round added ForgeIntents as #15).

## Open handoff inventory

All three remain ACTIVE and unblock independent work:

| Doc | Direction | Blocking on | Suggested next-session action |
|---|---|---|---|
| `Docs/HANDOFF_FROM_APP_TRADITION_AUDIO_SAMPLES.md` | app → labsmith | labsmith asset gen | Re-pull labsmith origin before assuming nothing has shipped. If audio CAFs landed at `Packages/Libraries/Sources/Services/Resources/Traditions/audio/`, wire `audioSampleFilename` in `traditions.json` + add a play affordance in `TraditionGalleryView`. |
| `Docs/HANDOFF_TO_USER_APPLE_DECLARED_AGE_RANGE.md` | agent → user | user Xcode-UI | The Swift call-site code is queued behind this; the moment the user reports the 4 Xcode-UI steps complete, the next session can wire the gate per the existing scaffold in `@.claude/rules/age-assurance.md`. |
| `Docs/HANDOFF_TO_USER_APP_GROUP_ENTITLEMENT.md` | agent → user | user Xcode-UI | Optional. Unblocks cross-portfolio avatar propagation. |

## Recommended next-session priorities (in order)

### 1. ForgeIntents follow-on: register a real `AppIntent` for "Tell a tale" (Xcode-UI handoff first)

The foundation drop from PR #89 ships the typed destination + router. The next-step PR registers a concrete `AppIntent` (e.g., `RecordNewTaleIntent`) that opens VoiceTale from a Siri shortcut. **This needs a `HANDOFF_TO_USER_*.md` first** — `AppShortcutsProvider` declaration + Info.plist `INIntentsSupported` entries are Xcode-UI-gated per `@.claude/rules/xcode-agent-safety.md`. Suggested sequencing:
- File `HANDOFF_TO_USER_APP_INTENTS_REGISTRATION.md` documenting the Xcode-UI steps
- Wait for user to complete steps + report back
- Ship the `AppIntent` struct under `Apps/VoiceTale/VoiceTale/` (synchronized folder — safe to author per `@Docs/CLAUDE.md` § "Always safe to write")
- Use the existing `VoiceTaleIntentRouter.tab(for:)` + Siri phrases from PR #89

Estimated effort: 1 PR for the handoff doc + 1 PR for the wire-up post-user-completion.

### 2. Delight & Polish — "Micro-delight coverage" (the 8-types audit)

Per `Docs/FEATURE_PLAN.md` § Delight & Polish:
> Micro-delight coverage — All 8 types: celebration, surprise, personality, mastery, social, sensory, agency, discovery

Current state matrix:
- ✅ **Celebration**: covered by ForgeCelebration overlay + this round's proportional tiers (PR #86)
- ✅ **Sensory**: covered by ForgeSensory module + the new juice-layer haptics (PR #87)
- 🟡 **Personality**: Bramble register is consistent, but explicit "Bramble remembers your favorite mood" callbacks haven't shipped. Add a `Models/BrambleMoodMemory` value type + wire into `BrambleMentor.reflect` per the FEATURE_PLAN note "callbacks to player's favorite moods + recurring prompts"
- 🟡 **Mastery**: covered by the achievement catalog but no dedicated "mastery moment" UI (FEATURE_PLAN: "Distinct screen ripple + chord when child internalizes story arc intuition")
- 🟡 **Discovery**: rare-prompt pool already ships ("Rare" pill via DailyPromptView from PR #78) — could be expanded
- 🔴 **Surprise**: no dedicated surface yet
- 🔴 **Social**: deferred to Phase 3 (cross-cluster cameo)
- 🔴 **Agency**: deferred (kid-driven exploration paths)

Suggested first PR: an audit doc (`Docs/AUDIT_MICRO_DELIGHT_COVERAGE_2026-06-2X.md`) that catalogs the 8 types × VoiceTale's current surfaces. Then ship the 1-2 missing pieces in follow-on PRs (mastery moment + surprise) per the audit.

### 3. Delight & Polish — Bramble personality callbacks (the "favorite mood" callback)

FEATURE_PLAN bullet: *"Character personality — Bramble with warm grandmother register (per DN voice register card); callbacks to player's favorite moods + recurring prompts."*

Implementation sketch:
- New `Models/BrambleMoodMemory.swift` pure-function helper: derive a kid's "favorite mood" from the per-mood tale count (already exposed via `filteredTales` + `voiceCharacterSummary`). Threshold: ≥ 3 tales of the same mood.
- Extend `BramblePromptBuilder` with a `favoriteMoodCallback(_:)` clause that surfaces ONLY when the mood being told today matches the favorite (anti-shame: never call out a non-favorite as "still your funny mood?" — that's regret-coded)
- `BrambleReflectionView` could surface a small callout strip with the callback line, anti-clobber the existing reflection bubble.

Estimated effort: 1 PR.

### 4. Photo attach + parental gate (Phase 2 remaining)

Photo attach is **Xcode-UI gated on `NSCameraUsageDescription` Info.plist key**. File `HANDOFF_TO_USER_PHOTO_ATTACH_USAGE_DESCRIPTION.md` analogous to the Apple Declared Age Range doc. After the user adds the key:
- Ship a `Models/TalePhotoAttachment` value type (additive Optional on `PersistentVoiceTaleEntry`)
- `AppFeature/ParentalGate/PhotoAttachGateView` that asks a parental math problem before unlocking attach
- `TellView` attach affordance + `AnthologyView` display

Estimated effort: 1 Xcode-UI handoff PR + 1 implementation PR.

## Gotchas + things to remember

### Xcode-managed file safety (load-bearing, re-affirmed SIXTH time this round)

Per `@CLAUDE.md` § Xcode File Safety: the agent operates inside Xcode and must NEVER author Xcode-managed files from disk. The non-negotiable list:
- `*.xcodeproj/project.pbxproj`
- `*.xcworkspace/contents.xcworkspacedata`
- `*.xcscheme` (anywhere)
- `*.xctestplan`
- `*.xcassets/Contents.json`
- `*/Info.plist` (app-target)
- `*.entitlements`
- `*.xcdatamodeld/`
- `xcuserdata/`
- `Package.resolved`
- `.swiftpm/`

When the task legitimately needs an Xcode-managed change, **file a `Docs/HANDOFF_TO_USER_<TOPIC>.md`** per the template in `CLAUDE.md` § "Instead — file a handoff doc".

### Auto-cycle pre-approval (standing for multi-commit work-cycles)

Per memory + this round: when the user pre-approves a round with phrasing like "go with all your recs / everything is approved / do not stop until fully done," the agent ships every planned PR in that round through `branch → commit → push → gh pr create → gh pr merge --merge --delete-branch → verify` without intermediate confirmation. The verify step (`gh pr view <n> --json state,mergedAt`) is REQUIRED — never skip verification.

### Standard SPM folder structure

Per memory + `@.claude/rules/spm-architecture.md` § "Apps/Packages/Server monorepo": Swift files in SPM modules follow the standard project folder structure: `Packages/Libraries/Sources/<Target>/<Subdir>/<File>.swift`. Test files mirror at `Packages/Libraries/Tests/<Target>Tests/`. This round's new directories: `Packages/Libraries/Sources/AppFeature/Intents/` (PR #89). Avoid flat `Sources/<Target>/` dumping — subdirectories help future maintainability.

### `RunSomeTests testIdentifier` is the suite struct name + `Tests` suffix

Per `@Docs/CLAUDE.md` § "Things That Will Bite You" (codified during PR #80): `RunSomeTests` indexes tests by Swift struct name, NOT the `@Suite("...")` display attribute. New suites land with `<Concept>Tests` naming. This round's additions (`MoodRetrospectiveTests`, `VoiceTaleIntentRouterTests`, `VoiceTaleIntentDestinationTests`) followed the convention; tests run on first attempt after the rebuild.

**Subtle**: the first `RunSomeTests` call against a brand-new test file returns "Test not found in target" until a fresh `BuildProject` runs. The build registers the new file in the SPM target; subsequent `RunSomeTests` calls then resolve. Pattern: write test → BuildProject → RunSomeTests (in order). This round's PR #89 hit this — added a clarifying line in the handoff.

## Cross-references

- `@Docs/FEATURE_PLAN.md` § "Round close-out 2026-06-23 late evening" — per-PR breakdown
- `@Docs/IMPLEMENTATION_HANDOFF.md` § same — catalog deltas + test coverage delta
- `@Docs/TECHNICAL_DESIGN.md` — architecture
- `@.claude/rules/workflow.md` § "CRITICAL: Verify PR Merged Before Claiming SHIPPED" — verification pattern used this round
- `@.claude/rules/xcode-agent-safety.md` — the non-negotiable file ban
- `@.claude/rules/forgekit.md` § "Module Catalog" — confirm ForgeIntents at the 15th slot
