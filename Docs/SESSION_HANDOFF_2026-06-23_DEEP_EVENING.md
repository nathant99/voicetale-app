---
status: ACTIVE
date: 2026-06-23
direction: session → next-session
intent: hand off the deep-evening 2026-06-23 round (PRs #91–#94) so the next CC session lands hot
freshness-horizon: 14 days
---

# Session handoff — 2026-06-23 deep evening

Direction: **CC session → next CC session**. Read in tandem with `@Docs/FEATURE_PLAN.md` § "Round close-out 2026-06-23 deep evening (PRs #91–#94)" + `@Docs/SESSION_HANDOFF_2026-06-23_LATE_EVENING.md` (the prior handoff this one extends).

## What shipped this round

**4 PRs merged to main; all verified via `gh pr view <n> --json state,mergedAt` per `@.claude/rules/workflow.md`**:

| PR | Title | What landed |
|---|---|---|
| **#91** | HANDOFF_TO_USER for AppIntents registration (PR #89 follow-on) | 4 Xcode-UI steps unblock the `AppIntent` + `AppShortcutsProvider` Swift wire-up (next session ships the Swift). |
| **#92** | HANDOFF_TO_USER for photo attach usage descriptions (Phase 2 unblock) | 4 Xcode-UI steps add `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` so Phase 2 photo attach can land. Kid-readable copy strings included. |
| **#93** | Bramble favorite-mood callback (Personality micro-delight) | New `Models/BrambleMoodMemory` + extends `BrambleMentor.reflect(...)` with optional `favoriteMood:`. 16 tests across `BrambleMoodMemoryTests` + `BrambleFavoriteMoodCallbackTests`. Closes the Personality box in Delight & Polish. |
| **#94** | Mastery-moment recognition surface (Delight & Polish) | New `Models/MasteryMoment` + 3 archetypes + `BrambleReflectionView.masteryMomentStrip` surface + `HapticsBridge.fireMasteryMoment()`. 10 tests. Closes the Mastery box in Delight & Polish. |

Round total: **26 new tests**; 4 merged PRs; **zero Xcode-managed files touched** (SEVENTH consecutive round honoring the named-file ban); all 4 verified MERGED on origin.

## State of the tree at session close

- **Branch**: `chore/round-2026-06-23-deep-evening-closeout` (working — this handoff doc + FEATURE_PLAN + CLAUDE.md + rule-file edits). Pending commit + PR at session close.
- **`main`**: at PR #94 merge commit; origin in sync.
- **Working tree before this commit**: clean (every PR's branch was deleted via `gh pr merge --delete-branch`).
- **No pending `feature/*` branches with un-merged work** — verified via `gh pr list --state open --author "@me"`.

## Phase scoreboard

| Phase | Status | Notes |
|---|---|---|
| Phase 1 (MVP) | **COMPLETE** | Only Apple Declared Age Range API gate is open — Xcode-UI handoff in flight (`@Docs/HANDOFF_TO_USER_APPLE_DECLARED_AGE_RANGE.md`) |
| Phase 1.1 (Voice-Character) | **EXIT-COMPLETE** | All 5 boxes shipped |
| Phase 2 (Anthology + Photo) | **5 of 7 shipped** | Remaining: **photo attach + parental gate** (Xcode-UI gated on `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` per `@Docs/HANDOFF_TO_USER_PHOTO_ATTACH_USAGE_DESCRIPTION.md`); the 7th is a curation polish item already shipped under a different banner |
| Phase Onboarding & Child Safety | Mostly shipped | Excellence-framework items mostly complete |
| Phase Engagement Foundation | **4 of 5 shipped** | Remaining: ambient ad-hoc tightening |
| **Phase Delight & Polish** | **5 of 7 shipped (THIS round added Personality + Mastery)** | Remaining: micro-delight 8-types coverage audit / easter eggs / published-tale certificates + anthology covers |
| Phase Accessibility & Trauma-Informed Polish | Mostly shipped | Dynamic Type AX5 + WCAG AA color-contrast audit + full simulator VoiceOver pass are deferred / hands-on-review-gated |
| Phase 3 (Cross-Cluster Cameo + Performance Polish) | NOT STARTED | |
| Phase 4 (Classroom + App Store + Final Polish) | NOT STARTED | |

**ForgeKit declared+used modules**: **15** (unchanged this round).

## Open handoff inventory

5 ACTIVE — 2 NEW this round, 3 carried from late-evening handoff:

| Doc | Direction | Blocking on | Suggested next-session action |
|---|---|---|---|
| `Docs/HANDOFF_TO_USER_APP_INTENTS_REGISTRATION.md` **(NEW)** | agent → user | user Xcode-UI | After user reports Steps 1-4 complete, ship `Apps/VoiceTale/VoiceTale/Intents/RecordNewTaleIntent.swift` + `VoiceTaleShortcuts.swift` (synchronized folder — safe to author from disk) wiring `VoiceTaleIntentRouter.tab(for:)` from PR #89. |
| `Docs/HANDOFF_TO_USER_PHOTO_ATTACH_USAGE_DESCRIPTION.md` **(NEW)** | agent → user | user Xcode-UI | After user reports Steps 1-4 complete + commits the `project.pbxproj` diff, ship `Models/TalePhotoAttachment` value type + `Services/PhotoAttachStore` + `AppFeature/ParentalGate/PhotoAttachGateView` + `TellView`/`AnthologyView` integration. |
| `Docs/HANDOFF_FROM_APP_TRADITION_AUDIO_SAMPLES.md` | app → labsmith | labsmith asset gen | Re-pull labsmith origin before assuming nothing has shipped. If audio CAFs landed at `Packages/Libraries/Sources/Services/Resources/Traditions/audio/`, wire `audioSampleFilename` in `traditions.json` + add a play affordance in `TraditionGalleryView`. |
| `Docs/HANDOFF_TO_USER_APPLE_DECLARED_AGE_RANGE.md` | agent → user | user Xcode-UI | Swift call-site code queued behind this; the moment the user reports the 4 Xcode-UI steps complete, the next session can wire the gate per the existing scaffold in `@.claude/rules/age-assurance.md`. |
| `Docs/HANDOFF_TO_USER_APP_GROUP_ENTITLEMENT.md` | agent → user | user Xcode-UI | Optional. Unblocks cross-portfolio avatar propagation. |

## Recommended next-session priorities (in order)

### 1. Micro-delight 8-types coverage audit (the planning artifact)

Per `Docs/FEATURE_PLAN.md` § Delight & Polish:
> Micro-delight coverage — All 8 types: celebration, surprise, personality, mastery, social, sensory, agency, discovery

With Personality + Mastery shipped this round, the 8-type coverage matrix is:
- ✅ **Celebration**: ForgeCelebration overlay + proportional tiers (PR #86)
- ✅ **Sensory**: ForgeSensory + juice-layer haptics (PR #87)
- ✅ **Personality**: PR #93 (this round) — favorite-mood callback
- ✅ **Mastery**: PR #94 (this round) — `MasteryMoment` surface
- 🟡 **Discovery**: rare-prompt pool already ships ("Rare" pill via DailyPromptView from PR #78) — could be expanded
- 🔴 **Surprise**: no dedicated surface yet
- 🔴 **Social**: deferred to Phase 3 (cross-cluster cameo)
- 🔴 **Agency**: deferred (kid-driven exploration paths)

Suggested first PR: an audit doc (`Docs/AUDIT_MICRO_DELIGHT_COVERAGE_2026-06-2X.md`) that catalogs the 8 types × VoiceTale's current surfaces + writes implementation sketches for the 2 reds (Surprise + Agency) + the 1 yellow (Discovery expansion). Then ship the implementation in follow-on PRs.

### 2. ForgeIntents follow-on Swift wire-up (unblocked when user completes Xcode-UI from PR #91)

Per the handoff doc in PR #91, the moment the user reports Info.plist + project.pbxproj diff complete:
- Add `Apps/VoiceTale/VoiceTale/Intents/RecordNewTaleIntent.swift` (synchronized folder; safe to author from disk)
- Add `Apps/VoiceTale/VoiceTale/Intents/VoiceTaleShortcuts.swift` declaring `struct VoiceTaleShortcuts: AppShortcutsProvider`
- Wire the 4 destinations from `VoiceTaleIntentRouter.tab(for:)` to the 4 intents
- Route the intent invocation through `AppRootView.AppTab` selection via the existing `@Observable` app coordinator

Estimated effort: 1 PR.

### 3. Photo attach implementation (unblocked when user completes Xcode-UI from PR #92)

Per the handoff doc in PR #92:
- Ship a `Models/TalePhotoAttachment` value type (additive Optional on `PersistentVoiceTaleEntry`)
- `AppFeature/ParentalGate/PhotoAttachGateView` that asks a parental math problem before unlocking attach
- `TellView` attach affordance + `AnthologyView` display

Estimated effort: 1 PR.

### 4. Easter eggs (Delight & Polish remaining)

Per `Docs/FEATURE_PLAN.md`:
> Easter eggs — Hidden tradition unlocks for curious explorers (rare cultures revealed after multi-session exploration; sensitivity-reviewed)

Sensitivity-reviewer-gated per ADR-016 — the tradition layer's cultural-context notes are load-bearing. Suggested: file the design as `Docs/PLAN_EASTER_EGGS_TRADITION_UNLOCKS.md` BEFORE implementing — the reviewer envelope matters here.

## Gotchas + things to remember

### Xcode-managed file safety (load-bearing, re-affirmed SEVENTH time this round)

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

When the task legitimately needs an Xcode-managed change, **file a `Docs/HANDOFF_TO_USER_<TOPIC>.md`** per the template in `CLAUDE.md` § "Instead — file a handoff doc". This round's 2 new HANDOFF_TO_USER docs (PRs #91 + #92) are reference impls.

### Auto-cycle pre-approval (standing for multi-commit work-cycles)

Per memory + this round: when the user pre-approves a round with phrasing like "go with all your recs / everything is approved / do not stop until fully done," the agent ships every planned PR in that round through `branch → commit → push → gh pr create → gh pr merge --merge --delete-branch → verify` without intermediate confirmation. The verify step (`gh pr view <n> --json state,mergedAt`) is REQUIRED — never skip verification.

### Per-round session-handoff discipline (NEW codification this round)

Per the SEVENTH re-affirmation's explicit user instruction ("create session handoff for the next CLAUDE session at the end of current session"): **every round closes with a `Docs/SESSION_HANDOFF_<date>_<phase>.md` artifact** captured for the next CC session. This doc is the canonical reference impl for the SEVENTH-round codification.

### Standard SPM folder structure

Per memory + `@.claude/rules/spm-architecture.md` § "Apps/Packages/Server monorepo": Swift files in SPM modules follow the standard project folder structure: `Packages/Libraries/Sources/<Target>/<Subdir>/<File>.swift`. Test files mirror at `Packages/Libraries/Tests/<Target>Tests/`. This round's new files: `Packages/Libraries/Sources/Models/BrambleMoodMemory.swift` + `Models/MasteryMoment.swift` + tests under `Tests/ModelsTests/` + `Tests/AIMentorTests/`. All comply.

### `RunSomeTests testIdentifier` is the suite struct name + `Tests` suffix

Per `@Docs/CLAUDE.md` § "Things That Will Bite You" (codified during PR #80): `RunSomeTests` indexes tests by Swift struct name, NOT the `@Suite("...")` display attribute. This round's additions (`BrambleMoodMemoryTests`, `BrambleFavoriteMoodCallbackTests`, `MasteryMomentTests`) followed the convention; tests resolved on first attempt after the rebuild.

### Anti-shame copy guard pattern (codified harder this round)

Both PR #93 + PR #94 ship copy-guard tests that scan generated text for a shame-token stoplist (`finally` / `still` / `always` / `again` / `missed` / `should` / etc.). The PR #93 guard caught real shame-coded words in my initial copy draft ("that one **always** pulls me in" + "let it loose **again**") — the tests are load-bearing. Future Bramble-register copy MUST honor the same stoplist. Reference impls: `BrambleMoodMemoryTests.everyCallbackAvoidsShameTokens` + `MasteryMomentTests.everyArchetypeCopyAvoidsShameTokens`.

## Cross-references

- `@Docs/FEATURE_PLAN.md` § "Round close-out 2026-06-23 deep evening" — per-PR breakdown
- `@Docs/IMPLEMENTATION_HANDOFF.md` — labsmith-shipped implementation context
- `@Docs/TECHNICAL_DESIGN.md` — architecture
- `@.claude/rules/workflow.md` § "CRITICAL: Verify PR Merged Before Claiming SHIPPED" — verification pattern used this round
- `@.claude/rules/xcode-agent-safety.md` — the non-negotiable file ban (SEVENTH consecutive re-affirmation this round)
- `@.claude/rules/forgekit.md` § "Module Catalog" — ForgeIntents at the 15th slot
- `@Docs/SESSION_HANDOFF_2026-06-23_LATE_EVENING.md` — the prior session handoff this one extends
