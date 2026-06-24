---
status: ACTIVE
date: 2026-06-24
round: 2026-06-24 (EIGHTH consecutive re-affirmation round; PR #97)
freshness-horizon: 14 days
---

# Audit — Micro-delight 8-types coverage (2026-06-24)

Direction: **internal audit**. Closes the planning artifact called out as #1 next-session priority in `@Docs/SESSION_HANDOFF_2026-06-23_DEEP_EVENING.md` and unblocks the "Micro-delight 8-types coverage" box in `@Docs/FEATURE_PLAN.md` § Phase Delight & Polish.

## The 8-type canon

Per portfolio-wide micro-delight taxonomy (sourced from `@.claude/rules/forgekit.md` + the broader portfolio Delight & Polish convention): every shipped app should surface ALL 8 micro-delight types across its UX. The 8 types and the questions they answer for the player:

| Type | The player feels… | Canonical surface pattern |
|---|---|---|
| Celebration | "I did something that mattered" | Full-screen ForgeCelebration overlay; tiered (subtle / standard / epic) |
| Sensory | "The app feels alive" | Selection-trifecta haptics + sound on real value-changes |
| Personality | "Bramble knows ME" | Callbacks to player's favorite moods / patterns |
| Mastery | "I finally understood it" | Distinct chord / haptic on internalization moments |
| Discovery | "I found something hidden" | Rare prompts / new-encounter callouts |
| Surprise | "I didn't expect that" | Bramble notices an unusual combo / first-encounter |
| Social | "Someone else cares" | Cross-cluster cameos / shared moments (Phase 3) |
| Agency | "I'm steering this" | Kid-driven swaps / skips / explorations without judgment |

## VoiceTale coverage matrix at 2026-06-24

| Type | Current surface(s) | Status | Source of truth |
|---|---|---|---|
| **Celebration** | `CelebrationCoordinator.celebrate(.epic, ...)` on inaugural five-beat tale + per-beat boundary haptics + level-up celebrations | ✅ SHIPPED PR #86 | `Packages/Libraries/Sources/AppFeature/TellTab/TellView.swift` + `Services/HapticsBridge.swift` |
| **Sensory** | `HapticsBridge.fireSelection()` selection-trifecta on chip-style picks (mood / voice-character / anthology filter); record + save + level-up haptic seams | ✅ SHIPPED PR #87 + PR #66 + PR #61 | `Services/HapticsBridge.swift` |
| **Personality** | `Models/BrambleMoodMemory` favorite-mood callback woven into `BrambleMentor.reflect(...)` first observation | ✅ SHIPPED PR #93 | `Models/BrambleMoodMemory.swift` + `AIMentor/BrambleMentor.swift` |
| **Mastery** | `Models/MasteryMoment` 3 archetypes (`firstFiveBeat` / `sustainedArcStreak` / `voiceVariationMastery`) + `BrambleReflectionView.masteryMomentStrip` + `HapticsBridge.fireMasteryMoment()` | ✅ SHIPPED PR #94 | `Models/MasteryMoment.swift` + `SharedUI/BrambleReflectionView.swift` |
| **Discovery** | `DailyPromptView.resolved(sessionCount:)` rare-prompt rotation (every 5th session); 5-entry rare pool (`cast_ensemble` / `hidden_question` / `tradition_echo` / `wild_card` / `time_travel`); "Rare" pill rendered when a rare prompt surfaces | 🟡 PARTIAL — surface ships, but pool is small + no per-tradition first-encounter callout | `Packages/Libraries/Sources/AppFeature/Anthology/DailyPromptView.swift` |
| **Surprise** | None | 🔴 RED | — |
| **Social** | None (Phase 3 cross-cluster cameo work) | 🔴 DEFERRED (Phase 3) | — |
| **Agency** | None — kid cannot swap the daily prompt; no prompt-skip / prompt-bookmark affordance | 🔴 RED | — |

**Summary**: 4 ✅ + 1 🟡 + 2 🔴 (Surprise + Agency) + 1 deferred-to-Phase-3 (Social). The 2 reds + 1 yellow are the actionable surface this round addresses; Social is correctly deferred per the Phase 3 cross-cluster scope.

## Reds — Surprise

**The gap**: Surprise is the "I didn't expect that" feeling — distinct from Mastery (internalization) and Discovery (intentional hidden-content surfacing). Surprise fires when the system NOTICES something unusual about what the kid just did + names it back warmly. The canon examples that map to VoiceTale:

- **First-new-mood-explored**: kid tells their first scary tale after 12 funny ones. Bramble: "First time you've gone in the dark with me — that took something."
- **Tradition-echo**: kid told a tale, then opened the tradition gallery in the same session. Bramble notices the mood + region pairing. "That mood — there's a tradition from <region> that does the same thing. Want to listen?"
- **Voice-preset-fresh-use**: first time kid uses a non-narrator voice (ogre / sprite / sage / hero). Bramble: "New voice — felt different, didn't it?"

**The contract**: Surprise NEVER shames the absence of variety; it celebrates the presence of variety. Anti-shame copy guard required.

**Implementation sketch** (PR-C):

```swift
public enum SurpriseMoment: String, Codable, Sendable, CaseIterable {
    case firstNewMoodExplored
    case traditionEchoSameSession
    case voicePresetFreshUse

    public func copy(detail: SurpriseMomentDetail) -> String { /* … */ }
}

public struct SurpriseMomentInputs {
    let totalTales: Int
    let moodsEverTold: Set<VoiceTaleMood>
    let todayMood: VoiceTaleMood
    let recentTraditionRegion: TraditionRegion?
    let voicePresetsEverUsed: Set<String>
    let todayPresets: Set<String>

    static func derive(/* … */) -> SurpriseMoment?
}
```

Priority discipline: ONE surprise per reflection (same pattern as `MasteryMoment.derive`). Suppressed under distress chip + suppressed under mastery moment (mastery wins because it's the deeper signal).

Surface: `BrambleReflectionView.surpriseMomentStrip` matching the `masteryMomentStrip` `.thinMaterial` card pattern. New `HapticsBridge.fireSurpriseMoment()` reuses the selection-trifecta light haptic (not celebration tier — surprise is quiet).

## Reds — Agency

**The gap**: VoiceTale's daily prompt is presented as a single take-it-or-leave-it card. If a kid doesn't connect with today's prompt, the only path is to ignore it and freeform. That's a missed Agency moment — the kid should be able to TAP TO SWAP without judgment. Many kids stall when the only choice is "do exactly this" — the swap converts the stall into a small kid-driven decision.

**The contract**: The swap is NEVER framed as "skip" or "no thanks." It's framed as choosing a different prompt from the same kid-readable pool. The copy explicitly normalizes the swap: "These prompts are all yours to pick from."

**Implementation sketch** (PR-E):

- New `DailyPromptView.swapAffordance` — a small `glassEffect(.regular.tint(...).interactive(), in: .capsule)` pill below the prompt body: "Try a different one"
- On tap: rotate to a different prompt from the same pool (rare-pool excluded — don't let the kid swap PAST a rare moment; the rare moment is the discovery surface). If the current prompt is rare, the swap pill is hidden.
- New `VoiceTaleAnalyticsEvent.promptSwapped(slug:)` — categorical only; prompt text never travels
- Anti-shame copy guard test: swap pill copy + accessibility hint never contain shame tokens (`skip` / `no thanks` / `not for me` / etc.)

## Yellow — Discovery expansion

**The state**: rare-prompt pool ships with 5 entries; every 5th session rotates a rare prompt + "Rare" pill. The surface is solid; the pool size + per-tradition surface are thin.

**The expansion** (PR-D):

1. Add 3 more rare-pool entries: `voice_passport` (rare prompt that invites a tradition + voice-character pairing) / `mood_echo` (rare prompt that calls back to the kid's most-told mood) / `family_tradition` (gentle rare prompt that invites the kid to ask a family member for a story). Pool grows 5 → 8.
2. New `TraditionGalleryView.traditionDiscoveryCallout` — fires the first time a kid scrolls past a tradition card they haven't tapped before, with Bramble register one-liner ("Pull this one closer when you're ready."). Per-session deduplication (don't refire on every scroll). Uses `SessionTallyTracker` to track first-encounters.

## What this audit does NOT cover

- **Social** type — deferred to Phase 3 (cross-cluster cameo). Tracking only.
- **Easter eggs** — separately scoped via `Docs/PLAN_EASTER_EGGS_TRADITION_UNLOCKS.md` (PR-F this round). Easter eggs are a subtype of Discovery but distinct enough to warrant their own PLAN doc.
- **Implementation acceptance tests** — those land in the per-PR test suites (PR-C / PR-D / PR-E). This audit specs the surfaces; the tests verify them.

## Round-end coverage target

After PRs C/D/E ship:

| Type | Status |
|---|---|
| Celebration | ✅ |
| Sensory | ✅ |
| Personality | ✅ |
| Mastery | ✅ |
| Discovery | ✅ (yellow → green via PR-D) |
| Surprise | ✅ (red → green via PR-C) |
| Social | 🟡 DEFERRED to Phase 3 |
| Agency | ✅ (red → green via PR-E) |

**7 of 8 green; 1 properly deferred.** Closes the "Micro-delight coverage — All 8 types" box in `@Docs/FEATURE_PLAN.md` § Phase Delight & Polish (with the documented Phase 3 carry-over for Social).

## Cross-references

- `@Docs/FEATURE_PLAN.md` § Phase Delight & Polish — closes the 8-types box
- `@Docs/SESSION_HANDOFF_2026-06-23_DEEP_EVENING.md` § Recommended next-session priorities #1 — the source of this audit
- `Packages/Libraries/Sources/Models/MasteryMoment.swift` — reference impl for the priority-discipline pattern reused by `SurpriseMoment`
- `Packages/Libraries/Sources/Models/BrambleMoodMemory.swift` — reference impl for the anti-shame copy-guard test pattern
- `Packages/Libraries/Sources/AppFeature/Anthology/DailyPromptView.swift` — rare-prompt rotation surface (Discovery expansion + Agency swap target)
- `Packages/Libraries/Sources/AppFeature/TraditionLayer/TraditionGalleryView.swift` — Discovery callout surface
- `@.claude/rules/trauma-informed-content.md` — anti-shame copy guard rules
