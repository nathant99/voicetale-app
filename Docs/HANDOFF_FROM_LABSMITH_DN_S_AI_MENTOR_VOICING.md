---
status: PARTIALLY-DONE
date: 2026-06-01
implementation-status-updated: 2026-06-21
round: Round 405 #828 (labsmith DN-S Integration Phase 1D portfolio rollout — voicetale)
parent-decision: labsmith/Docs/DECISION_DN_S_AI_MENTOR_PORTFOLIO_ROLLOUT.md
parent-plan: labsmith/Docs/PLAN_DN_S_PORTFOLIO_ROLLOUT_WAVES_2026-06-01.md
template-source: labsmith/Docs/TEMPLATE_HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md
forgekit-version-required: 0.97.0 (CastDialog API)
trauma-gating: NONE
moderation-sensitivity: .normal
---

# Handoff from Labsmith — DN-S AI-Mentor Voicing for Voicetale

Direction: **labsmith → voicetale-app**. Operationalizes Option D of labsmith's `PLAN_DN_S_INTEGRATION_PHASES_2026-06-01.md` (ADR-019; Phase 1D approved per `DECISION_DN_S_AI_MENTOR_PORTFOLIO_ROLLOUT.md` R394 #818) for voicetale.

## What this handoff delivers

A per-app `CastVoiceRegistry` (Swift) mapping voicetale's 4 cast members' chapter voice-register cards into `CastVoiceProfile` instances consumable by ForgeKit 0.97.0's `CastDialog` API. When wired, the AI mentor can speak AS any cast member in the character's voice register.

## Pre-requisites

- [ ] ForgeKit pin in `Libraries/Package.swift` is `from: "0.97.0"` or higher
- [x] `Docs/dn-s/chapters/*.md` files exist for every cast member (4 of 4 shipped; total 3788 words)
- [ ] App's existing AI mentor service uses `FoundationModels.LanguageModelSession`
- [x] App is in the Phase 1D portfolio rollout (post-pilot trio)

## Voicetale cast inventory + voicing priority

| Order | Character | Slug | Primitive embodied | Chapter words | Priority rationale |
|---|---|---|---|---|---|
| 1 | Lean | `lean` | (derive from chapter) | 1110 | Lead — establishes CastVoiceRegistry baseline; voice-clarity heuristic |
| 2 | Pivot | `pivot` | (derive from chapter) | 935 | Secondary lead — order 2 |
| 3 | Refrain | `refrain` | (derive from chapter) | 908 | Secondary lead — order 3 |
| 4 | Slow | `slow` | (derive from chapter) | 835 | Wave-batch — order 4 |

**Cast total**: 4 chapters; 3788 words.

## Implementation steps

Follow `labsmith/Docs/TEMPLATE_HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` § Implementation, customized to voicetale's cast:

1. [x] Derive `CastVoiceProfile` per chapter using `labsmith/Docs/SCHEMA_CAST_VOICE_REGISTRY.md` — DONE (PR #22 shipped `AIMentor.CastVoiceRegistry` with all 4 profiles)
2. [x] Build `CastVoiceRegistry` at app launch — DONE (`CastVoiceRegistry.register(into:)` exposed; awaiting `BrambleMentor` `CastDialog` wiring per Phase 1.1)
3. [ ] Wire AI mentor call sites to invoke `castDialog.respondAs(.character(slug), prompt:, context:)` — deferred to Phase 1.1 (requires `BrambleMentor` to upgrade from `LanguageModelSession` → `CastDialog`-backed session)
4. [ ] Feature-flag via `ForgeExperiments.castVoicing` (default off; TestFlight enable) — deferred (depends on step 3)
5. [ ] Regression-test moderation pipeline (100 sample interactions across diverse contexts) — deferred (depends on step 3 + 4)

**PR 4 (2026-06-21) status**: steps 1 + 2 complete and tested (6 tests in `CastVoiceRegistryTests` + 4 profiles registered via `CastDialog`). Steps 3-5 are scoped to Phase 1.1 / 1D-follow-on PR — the existing `BrambleMentor.LanguageModelSession` path stays in place; the upgrade to `CastDialog` is a non-trivial mentor-API swap that warrants its own PR and ~14d telemetry observation per the parent decision.

## Pilot-derived learnings (codified per `DECISION_DN_S_AI_MENTOR_PORTFOLIO_ROLLOUT.md`)

1. **Prompt-budget calibration FIRST** — for any app with chapters > 1500w, measure input tokens before authoring all profiles
2. **12-profile perf ceiling validated** — `CastVoiceRegistry` at 12-profile scale fits on iPad Mini 2026
3. **Paired-voicing API works without extension** — `respondAs(.character(slug), ...)` handles "we"/plural automatically for paired chapters
4. **Crisis-keyword fallback is universal** — ForgeKit's built-in moderation handles distress signals
5. **Voicing-priority order matters** — start with most-formal-register character

## Success criteria

- [ ] Voice fidelity: 100 sample audit; ≥ 90% rated "clearly this character" for each profile
- [ ] Character drift rate: < 2% per session
- [ ] Engagement parity: session length / kit completion / hint frequency ≥ baseline single-mentor
- [ ] Crisis-keyword fallback verified
- [ ] Feature-flag shipped (default off)

## Effort estimate

- 4 `CastVoiceProfile`s × ~15-20 min/profile derivation = ~2-4h
- Registry + wiring + regression-test = ~1-2h
- Total per-app CC session: ~3-7h
- ~14d telemetry observation (optional; gated on app-side decision)

## Cross-references

- `labsmith/Docs/DECISION_DN_S_AI_MENTOR_PORTFOLIO_ROLLOUT.md` — parent decision (R394 #818)
- `labsmith/Docs/PLAN_DN_S_PORTFOLIO_ROLLOUT_WAVES_2026-06-01.md` — rollout sequencing
- `labsmith/Docs/TEMPLATE_HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` — template
- `labsmith/Docs/SCHEMA_CAST_VOICE_REGISTRY.md` — `CastVoiceProfile` schema
- `labsmith/Docs/ADR-019_DN_S_INTEGRATION_OVER_ENSEMBLE_STORIES.md` — decision rationale
- `forgekit/Docs/CHANGELOG.md` (0.97.0) — `CastDialog` API
- `.claude/rules/distributed-narrative.md` § DN-S Integration — portfolio rule
- `.claude/rules/foundationmodels.md` — FoundationModels safety patterns


- Local: `Docs/dn-s/chapters/*.md` (4 chapters, 3788 words total) — source content

---

**Disposition**: ✅ HANDED OFF — implementation belongs to voicetale-app's CC session. No retrospective required (portfolio rollout proceeds without per-app retrospective gating).
