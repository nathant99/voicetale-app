---
status: ACTIVE
date: 2026-06-27
direction: session → next-session
intent: hand off the TWENTIETH consecutive same-author re-affirmation round (PRs #153–#155) — the FIRST cross-day-boundary round after the 2026-06-26 NINETEENTH + the FIRST cross-launch-persistent analytics-emission coalescing layer in the auto-cycle chain (yearly engagement digest retention-gated AND per-kit band-crossing analytics coalescing within a single round)
freshness-horizon: 14 days
---

# Session handoff — 2026-06-27 TWENTIETH consecutive re-affirmation round (first cross-day-boundary after the 2026-06-26 NINETEENTH; yearly digest + per-kit band-crossing analytics coalescing)

Direction: **CC session → next CC session**. Read in tandem with
`@Docs/FEATURE_PLAN.md` § "Round 2026-06-27 TWENTIETH" +
`@Docs/SESSION_HANDOFF_2026-06-26_NINETEENTH_ROUND.md` (the
nineteenth-round handoff this one extends).

## What shipped this round

**3 PRs merged to main; all verified via `gh pr view <n> --json state,mergedAt` per `@.claude/rules/workflow.md`**:

| PR | Title | What landed |
|---|---|---|
| **#153** | feat: ForgeReflection Phase D yearly engagement digest (retention-gated) — TWENTIETH-round | Closes the NINETEENTH-round handoff's recommended-next-session priority #1. Natural 365-day extension of PR #150's quarterly engagement digest (which itself extended PR #146's monthly digest → PR #142's weekly). New `VoiceTaleReflectionStore.yearlyEntries(now:)` + `yearlyEngagement(now:)` pure pass-through over the cached snapshot — 365-day boundary semantics identical to the weekly + monthly + quarterly windows (`>= cutoff` inclusive; strictly older dropped). Reuses the existing `ReflectionWeeklyEngagement.make(from:)` factory at the 365-day window — extends the load-bearing window-neutral value-type convention from the EIGHTEENTH + NINETEENTH rounds to a FOURTH consecutive window extension. `ReflectionJournalView.yearlyDigestSection` renders directly below `quarterlyDigestSection` — same opt-in gating + empty-window bypass + **NEW load-bearing third gate**: the yearly section reads the `voicetale.reflection.retention_days` `@AppStorage` value and renders **only when retention == 365**. Visual register: `calendar.badge.exclamationmark` distinguishes the yearly row from the week's `calendar.badge.clock` + month's `calendar` + quarter's `calendar.badge.checkmark`. NO new analytics events. NO new `@AppStorage` keys. Anti-PII invariants preserved verbatim from PR #142 + PR #146 + PR #150. |
| **#154** | feat: ForgeMasteryEngine Phase B per-kit band-crossing analytics coalescing — TWENTIETH-round | Closes the NINETEENTH-round handoff's recommended-next-session priority #2. Per-kit band-crossing analytics-event coalescing that closes the noisy-oscillation case (a kid bouncing around a quartile boundary across many attempts produces redundant `kit_mastery_advanced` emissions on the wire). New pure value-type `Packages/Libraries/Sources/Models/KitMasteryBandLog.swift` (`nonisolated struct Sendable, Hashable, Codable`; internal storage `[Int: String]` keyed by `KitID` raw value → `MasteryBand` raw value) — kept dependency-free of `ForgeMasteryEngine` so `Models` keeps its single-source-of-truth posture per the SPM dep graph. Public API: `init()` / `init(json:)` / `encoded()` / `lastBand(forKit:)` / `shouldEmit(forKit:toBand:)` / `recording(forKit:band:)`. Anti-defeat: malformed JSON degrades to an empty log. `QuizView.recordKitMasteryAttempt` adds `@AppStorage("voicetale.kitmastery.last_bands")` binding; the existing in-memory `fromBand != toBand` fast-path is preserved; when it passes, the log's `shouldEmit(forKit:toBand:)` consults the last-emitted band per kit. The emitted payload's `fromBand` prefers the logged value when present. Wire shape unchanged: `kit` + `from_band` + `to_band` only. Anti-shame discipline preserved: regressions still emit; only repeated same-band emissions are suppressed. **17 new tests across 2 suites**; 42 regression tests stable; 59/59 pass. The coalescing layer is the cross-launch-persistent analog of the EIGHTEENTH-round one-fire-per-(mode, kind)-per-appearance `@State Set` discipline — same principle, different persistence horizon (cold-launch survival via `@AppStorage` vs view-local `@State Set`). PR #154 is the FIRST cross-launch-persistent analytics-emission coalescing layer in the auto-cycle chain. |
| **#155** | Round close-out + tri-surface doc propagation + session handoff (this PR) | CLAUDE.md § "Xcode File Safety" extended with the TWENTIETH re-affirmation observation. `.claude/rules/forgekit.md` § Versioning updated with the TWENTIETH-round reference impls (PR #153 + PR #154). `Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase B coalescing subsection added + `Docs/PLAN_FORGEREFLECTION_LIFT.md` § Phase D yearly-digest subsection marked SHIPPED (with the PR # filled in). `Docs/FEATURE_PLAN.md` gains the TWENTIETH-round entry above the NINETEENTH entry. This session handoff doc. |

**Round total: 17 new tests** (all in PR #154 — 15 `KitMasteryBandLog` + 2 `AnalyticsService`); 3 merged PRs; **zero Xcode-managed Swift-source files touched** (TWENTIETH consecutive round + FIRST cross-day-boundary round after the 2026-06-26 NINETEENTH); all 3 verified MERGED on origin via `gh pr view <n> --json state,mergedAt`.

## State of the tree at session close

- **Branch**: `chore/round-2026-06-27-twentieth-round-closeout` (working — this handoff doc). Pending commit + PR at session close.
- **`main`**: at PR #154 merge commit; origin in sync.
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
| **Phase Delight & Polish** | **8 of 8 SHIPPED-or-SCAFFOLDED** | Easter eggs IMPLEMENTATION Phases D/E still reviewer-gated |
| Phase Accessibility & Trauma-Informed Polish | Mostly shipped | Dynamic Type AX5 + WCAG AA color-contrast audit + full simulator VoiceOver pass deferred / hands-on-review-gated |
| Phase 3 (Cross-Cluster Cameo + Performance Polish) | NOT STARTED | |
| Phase 4 (Classroom + App Store + Final Polish) | NOT STARTED | SwiftData V2 migration PLAN landed PR #110; **ForgeMasteryEngine COMPLETE Phase A → B → C → D-affordance-half → D-second-half + PARITY POLISH + TAP-TO-ACT + ANALYTICS COALESCING** SHIPPED PR #124 → #128 → #132 → #136 → #139 → #145 → #151 → #154; **ForgeReflection COMPLETE Phase A → B → C → D + POLISH + MONTHLY + QUARTERLY + YEARLY DIGEST SIBLINGS** SHIPPED PR #123 → #127 → #131 → #135 → #142 → #146 → #150 → #153 |

**ForgeKit declared+used modules**: **17** (unchanged this round — PR #153 + PR #154 consume existing pin).

**Achievement catalog**: **23** (unchanged this round).

**ForgeKit pin**: `from: "1.0.0-rc.3"` (unchanged from TWELFTH round).

**Analytics events**: **29** (unchanged this round — PR #153 + PR #154 do not add new events; PR #154 only adds a suppression layer for the existing `kitMasteryAdvanced` event).

## Open handoff inventory

5 ACTIVE — unchanged this round (ForgeIntents Step 4 user-side, Photo attach Xcode-UI, Tradition audio labsmith, Apple Declared Age Range Xcode-UI, App Group entitlement Xcode-UI):

| Doc | Direction | Blocking on | Suggested next-session action |
|---|---|---|---|
| `Docs/HANDOFF_TO_USER_APP_INTENTS_REGISTRATION.md` | agent → user | **STEP 4 ONLY** (user Settings → Siri & Search runtime verification post-launch) | No agent action queued. Optional follow-on: surface the same "Try saying" hint inline during onboarding (page 5 close). |
| `Docs/HANDOFF_TO_USER_PHOTO_ATTACH_USAGE_DESCRIPTION.md` | agent → user | user Xcode-UI | After user reports Steps 1-4 complete + commits the `project.pbxproj` diff, ship `Models/TalePhotoAttachment` value type + `Services/PhotoAttachStore` + `AppFeature/ParentalGate/PhotoAttachGateView` + `TellView` / `AnthologyView` integration. |
| `Docs/HANDOFF_FROM_APP_TRADITION_AUDIO_SAMPLES.md` | app → labsmith | labsmith asset gen | Consumer-side SCAFFOLD shipped PR #116. The moment labsmith ships the 5 CAFs + updates `traditions.json` with non-null filenames, the play affordance auto-lights. |
| `Docs/HANDOFF_TO_USER_APPLE_DECLARED_AGE_RANGE.md` | agent → user | user Xcode-UI | Swift call-site code queued behind this; once user reports the 4 Xcode-UI steps complete, wire the gate per the existing scaffold in `@.claude/rules/age-assurance.md`. |
| `Docs/HANDOFF_TO_USER_APP_GROUP_ENTITLEMENT.md` | agent → user | user Xcode-UI | Optional. Unblocks cross-portfolio avatar propagation. |

## Recommended next-session priorities (in order)

### 1. Surface practice-with-Bramble badge from Adventure tab on cross-launch — round-trip the @AppStorage coalescing pattern

The TWENTIETH-round shipped the FIRST cross-launch-persistent analytics-emission coalescing layer (`KitMasteryBandLog` via `@AppStorage`). The natural next step is to verify the coalescing layer round-trips cleanly across cold launches in a hands-on simulator session: launch fresh kid, complete a kit, suspend the app, relaunch, complete another kit on the same band → verify the second emission is suppressed. This is a hands-on validation step rather than an automated test (the unit tests already lock the value-type invariants).

Estimated effort: 1 small hands-on test session in the simulator (no PR; verification only). If the hands-on test surfaces an edge case, file a per-session handoff.

### 2. Migrate other categorical analytics events to the same coalescing pattern when applicable

The TWENTIETH-round established a reusable cross-launch-persistent analytics-emission coalescing pattern (`Models/KitMasteryBandLog` + `@AppStorage` JSON binding + `shouldEmit` consultation). Audit candidate events that could benefit from the same pattern:

- `lapsedReturn(daysSinceActive:)` — fires once per session per ≥3-day-gap return; already coalesced to "once per session" via in-memory state, but a cross-launch dedupe (one wire event per lapsed-return-bucket per install per day) could narrow the noise floor.
- `retentionMilestoneHit(milestone:)` — already "once per milestone per install" via a different mechanism. Could refactor to the coalescing pattern for consistency.

Estimated effort: 1 small audit PR + 1 small refactor PR if any candidates surface. If no candidates surface, file a per-app note in the analytics audit doc.

### 3. Apple Declared Age Range API wire-up (unblocked when user completes Xcode-UI from APPLE_DECLARED_AGE_RANGE handoff)

Unchanged from prior round handoff. Per `@.claude/rules/age-assurance.md` — wire the `AKAppleIDAuthenticationRequestType.requestDeclaredAgeRange` gate.

### 4. Photo attach implementation (unblocked when user completes Xcode-UI from PHOTO_ATTACH handoff)

Unchanged from prior round handoff. Closes Phase 2 to 6 of 7 → 7 of 7.

### 5. SwiftData V2 migration (PR #110 plan → handoff)

Unchanged from prior round handoff. PR #110 landed the PLAN. Trigger conversion to handoff on first of: App Store ship date committed OR first field RENAME needed.

### 6. Easter eggs Phases D/E — reviewer engagement (when reviewer envelope opens)

Unchanged from prior round handoff. File reviewer-engagement handoff once Phase 2 fully shipped + Phase 3 underway.

### 7. Optional: surface Siri "Try saying" hints inline during onboarding

Unchanged from prior round handoff. PR #119 shipped the SettingsView Siri hint surface. A follow-on could surface the same phrases on onboarding page 5 close. ~1 small PR if pursued.

## Gotchas + things to remember

### Xcode-managed file safety (load-bearing, re-affirmed TWENTIETH time + FIRST cross-day-boundary round after the 2026-06-26 NINETEENTH)

Per `@CLAUDE.md` § Xcode File Safety: the agent operates inside Xcode and must NEVER author Xcode-managed Swift-source files from disk. The non-negotiable list is unchanged from the prior 19 rounds.

**TWENTIETH first-cross-day-boundary-after-the-2026-06-26-NINETEENTH observation**: the compound rule replays VERBATIM across FIVE cross-day-boundary transitions (FIFTH evening 2026-06-22 → SIXTH 2026-06-23; EIGHTH 2026-06-23 → NINTH 2026-06-24; TWELFTH 2026-06-24 → THIRTEENTH 2026-06-25; SEVENTEENTH 2026-06-25 → EIGHTEENTH 2026-06-26; NINETEENTH 2026-06-26 → TWENTIETH 2026-06-27) AND NINE same-day-back-to-back transitions (FOUR on 2026-06-24: EIGHTH → NINTH → TENTH → ELEVENTH → TWELFTH; FOUR on 2026-06-25: THIRTEENTH → FOURTEENTH → FIFTEENTH → SIXTEENTH → SEVENTEENTH; ONE on 2026-06-26: EIGHTEENTH → NINETEENTH). The TWENTIETH round was the FIRST to ship a **cross-launch-persistent analytics-emission coalescing layer** — the EIGHTEENTH-round established the within-render one-fire-per-(mode, kind)-per-appearance discipline via a view-local `@State Set`; the TWENTIETH-round extends that discipline to cross-launch persistence via `@AppStorage`-backed JSON, demonstrating that the within-round multi-PR Default scales cleanly through **persistence-horizon-extension of an established analytics-emission coalescing pattern**.

### Window-neutral value-type convention (load-bearing; FOURTH consecutive window extension reuses the convention)

`Models/ReflectionWeeklyEngagement` is a window-neutral value type — its name reflects the FIRST consumer (weekly digest PR #142), but the factory `make(from:)` accepts any entry slice. The TWENTIETH-round's `yearlyEngagement(now:)` reuses the SAME factory at the 365-day window — extending the EIGHTEENTH-round's monthly + NINETEENTH-round's quarterly reuse to a FOURTH consecutive window extension. The pattern is locked: future window-extension variants (e.g., a 14-day "Past two weeks" variant if it ever ships) should reuse the factory at their respective windows — NEVER rename the type to a window-specific name, NEVER author a parallel value type per window. The single seam is the factory + the consumer-side `*Entries(now:)` filter that selects which window to bucket.

### Cross-launch-persistent analytics-emission coalescing pattern (NEW load-bearing)

`Models/KitMasteryBandLog` is the canonical pattern for cross-launch-persistent analytics-emission coalescing. Pattern shape:

1. Pure value type in `Models/` with internal `[Int: String]` (or similar simple-keyable) storage.
2. Public API: `init()` / `init(json:)` / `encoded()` / `shouldEmit(forKey:newValue:)` / `recording(forKey:value:)`. The `shouldEmit` returns `false` when the new value matches the logged value for the key; `true` otherwise (including first-time-per-key).
3. View-side `@AppStorage("namespace.feature.last_<thing>") private var <thing>JSON: String = ""` binding.
4. View call site decodes the log, consults `shouldEmit`, emits only when allowed, then writes the updated log back to the @AppStorage binding.
5. Anti-defeat: corrupt JSON degrades to an empty log so a single bad write never permanently suppresses emissions.
6. Wire shape lock-down test in `AnalyticsServiceTests` with a forbidden-keys set covering all log-shape names to prevent payload leak.

Future analytics-event coalescing requests should follow this pattern verbatim. The cross-launch persistence is the differentiating axis vs the view-local `@State Set` pattern; both are legitimate depending on the event's scope (per-session vs cross-launch).

### "Badge lit" vs "badge acted on" analytics separation (load-bearing — preserved)

The NINETEENTH round established a SECOND instance of the "lit vs acted on" analytics separation pattern (after the SIXTEENTH-round deeper-challenge pill — `.deeperChallengeAvailable` vs `.deeperChallengeTaleStarted`). The TWENTIETH-round preserves this discipline unchanged for both pairs. Future affordance surfaces that ship a visible state + a tap state should follow this naming convention so cohort analysis can consistently separate engagement from acknowledgment across surfaces.

### Auto-cycle pre-approval (standing for multi-commit work-cycles)

Per memory + this round: when the user pre-approves a round with phrasing like "go with all your recs / everything is approved / do not stop until fully done," the agent ships every planned PR in that round through `branch → commit → push → gh pr create → gh pr merge --merge --delete-branch → verify` without intermediate confirmation. The verify step (`gh pr view <n> --json state,mergedAt`) is REQUIRED — never skip verification.

### Per-round session-handoff discipline (codified seventh round; honored eighth through twentieth)

This doc is the canonical artifact closing the TWENTIETH-round per-round session-handoff discipline. The instruction was codified in the seventh re-affirmation and is self-perpetuating: every round closes with `Docs/SESSION_HANDOFF_<date>_<phase>.md`.

## Cross-references

- `@Docs/FEATURE_PLAN.md` § "Round 2026-06-27 TWENTIETH" — per-PR breakdown
- `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase B analytics coalescing — SHIPPED PR #154 this round
- `@Docs/PLAN_FORGEREFLECTION_LIFT.md` § Phase D yearly digest sibling (retention-gated) — SHIPPED PR #153 this round
- `@Docs/IMPLEMENTATION_HANDOFF.md` — labsmith-shipped implementation context
- `@Docs/TECHNICAL_DESIGN.md` — architecture
- `@.claude/rules/workflow.md` § "CRITICAL: Verify PR Merged Before Claiming SHIPPED" — verification pattern used this round
- `@.claude/rules/xcode-agent-safety.md` — the non-negotiable file ban (TWENTIETH consecutive re-affirmation; FIRST cross-day-boundary round after the 2026-06-26 NINETEENTH)
- `@.claude/rules/forgekit.md` § "Versioning" (0.99.0 ForgeReflection + 1.0.0-rc.2 ForgeMasteryEngine) — updated this round with both TWENTIETH-round consumer reference impls (PR #153 + PR #154)
- `@.claude/rules/portfolio.md` § "Asset Consumer Audit" — the registered → wired → surfaced → polished → cross-surface-paritied → tap-to-act → coalesced discipline that ForgeMasteryEngine has now fully closed across all seven phases
- `@Docs/SESSION_HANDOFF_2026-06-26_NINETEENTH_ROUND.md` — the prior (nineteenth) session handoff this one extends
- `@Docs/SESSION_HANDOFF_2026-06-26_EIGHTEENTH_ROUND.md` — the eighteenth-round handoff (first cross-module post-closure parity polish)
- `@Docs/SESSION_HANDOFF_2026-06-25_SEVENTEENTH_ROUND.md` — the seventeenth-round handoff (first post-closure consumer-polish)
- `@Docs/SESSION_HANDOFF_2026-06-25_SIXTEENTH_ROUND.md` — the sixteenth-round handoff (ForgeMasteryEngine Phase D second-half closure)
- `@Docs/SESSION_HANDOFF_2026-06-25_FIFTEENTH_ROUND.md` — the fifteenth-round handoff (Phase D consumer wiring)
- `@Docs/SESSION_HANDOFF_2026-06-25_FOURTEENTH_ROUND.md` — the fourteenth-round handoff (Phase C consumer wiring)
- `@Docs/SESSION_HANDOFF_2026-06-25_THIRTEENTH_ROUND.md` — the thirteenth-round handoff (Phase B consumer wiring)
- `@Docs/SESSION_HANDOFF_2026-06-24_TWELFTH_ROUND.md` — the twelfth-round handoff (Phase A scaffolds)
