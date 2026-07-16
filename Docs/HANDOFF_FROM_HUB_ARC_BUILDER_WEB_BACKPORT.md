---
status: ACTIVE
date: 2026-07-16
direction: hub → app
intent: backport the web-pioneered "Build the 5-Beat Arc" reconstruct-the-structure surface to iOS
freshness-horizon: 60 days
---

# Handoff to VoiceTale — backport the 5-Beat Arc Builder (web-pioneered)

Direction: **hub → app**. The `/play/voicetale` web clone shipped a learning surface the iOS app
does not have; per R-CLONE-BIDIRECTIONAL-BACKPORT it must be backported to iOS or explicitly waived.
Hub never writes Swift — this handoff specifies the feature + the web reference impl + a proposed iOS
surface for VoiceTale's own session to implement.

## The feature — "Build the 5-Beat Arc"

A deterministic, first-try-scored **reconstruct-the-arc** puzzle: the learner is shown the five beats
of a short mini-tale **scrambled**, and taps them into the canonical arc order **hook → setup → rising
→ turn → close**. Exactly one best ordering; a hint appears only after a first wrong attempt
(articulate-before-hint); anti-shame (the round always advances).

## Why it's a backport (not already in iOS)

VoiceTale iOS teaches the 5-beat arc as a **recording TIMER** (`BeatTimer`: Hook 10s / Setup 20s /
Rising 30s / Turn 30s / Close 20s) — the learner *tells against* the arc. It does **not** have a
standalone surface where the learner **reasons about arc STRUCTURE** by reconstructing a scrambled tale.
The cross-platform domain research (Rory's Story Cubes + Freytag's Pyramid classroom scaffolds; Story
Cubes prompt *generation* but never grade *structure*) confirms this reconstruct-the-arc reasoning
mechanic is absent from the domain's best-in-class — the web pioneered it. It is deterministic +
on-device (an authored bank; no NLP) → a clean iOS fit.

## Web reference implementation

- `spark-anvil-site/src/lib/play/voicetale/mechanics/arcBuilder.ts` — the mechanic + the hand-authored
  `ARC_BANK` (8 mini-tales; each a `{ id, title, beats[5] (canonical order), hint }`) + `ARC_ROLES`.
- `arcBuilder.test.ts` — the bank invariants (exactly 5 distinct beats; the ordered exact-match check
  accepts only the canonical order).
- Route `src/pages/play/voicetale/arc.astro`; rides the shared custom-round shell (progress / results /
  articulate-before-hint).

## Proposed iOS surface

A new practice mode (alongside the QuizTab Concepts + the Tell recorder): render the five beat-cards
shuffled; the learner drags/taps them into a labeled 5-slot arc strip (Hook…Close); check exact order;
score first-try; hint after a first miss. The `ARC_BANK` mini-tales port directly as a bundled JSON
resource (author more for iOS as desired). Anti-shame register throughout. This pairs naturally with the
existing `BeatTimer` — reconstruct the arc, *then* tell against it.

## Status
🟡 open (backport filed) in `spark-anvil-hub/Docs/web/voicetale/PARITY_WEB_VS_IOS.md`. Closes when the
VoiceTale session ships the mode (or replies with a documented waiver). Filing this handoff is the START
of the obligation, not its completion.

## Cross-references
- `spark-anvil-hub/Docs/web/voicetale/{RESEARCH,PARITY_WEB_VS_IOS,FEATURE_PLAN}.md`
- `.claude/rules/spark-anvil-website.md` § R-WEB-CLONE-BACKPORT-MINING / § R-CLONE-BIDIRECTIONAL-BACKPORT
