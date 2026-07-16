---
status: ACTIVE
date: 2026-07-16
direction: hub → app
intent: backport the web-pioneered "Coach the Delivery" deterministic delivery-reasoning drill to iOS
freshness-horizon: 60 days
---

# Handoff to VoiceTale — backport the Delivery / Turn-Craft reasoning drill (web-pioneered)

Direction: **hub → app**. The `/play/voicetale` web clone shipped a scored delivery-reasoning surface
the iOS app does not have; per R-CLONE-BIDIRECTIONAL-BACKPORT it must be backported to iOS or waived.
Hub never writes Swift — this specifies the feature + web reference impl + a proposed iOS surface.

## The feature — "Coach the Delivery"

A deterministic, first-try-scored **pick-the-strongest-delivery** drill. For a short told-tale excerpt at
a given beat, the learner chooses the strongest delivery move — where to **pause**, when to go **quiet /
loud**, how fast to **pace**, where the **turn** lands, when to use a **refrain / gesture / eye-contact**,
how to **recover** a lost place. Articulate-before-hint (hint only after a first wrong try); explanation on
reveal; anti-shame (never a harsh red).

## Why it's a backport (not already in iOS)

VoiceTale iOS coaches delivery via **Bramble** — open-ended on-device FoundationModels Socratic reflection
on the learner's recorded transcript. That is wonderful *formative* feedback, but there is **no scored,
deterministic delivery-reasoning PRACTICE surface** on either the app or the web today. The web builds the
deterministic drill (a browser has no on-device FoundationModels), and it is a genuinely new *scored
practice* mode — not a re-render of the open-ended chat. Delivery craft (pause/volume/pace/turn/gesture/
eye-contact/recovery) maps 1:1 to VoiceTale's own delivery cast (Hush/Boom/Slow/Pivot/Flourish/Gaze/
Recover), so the app can theme each item to a cast member.

## Web reference implementation

- `spark-anvil-site/src/lib/play/voicetale/mechanics/delivery.ts` — the mechanic + the hand-authored
  `DELIVERY_BANK` (12 items; each a `{ id, beat, excerpt, question, correct, distractors[3], hint,
  explanation }`), rendered through the shared prominent MC round.
- `delivery.test.ts` — bank invariants (exactly one correct ∈ options; 3 distinct distractors; correct ∉
  distractors; non-empty fields).
- Route `src/pages/play/voicetale/delivery.astro`.

## Proposed iOS surface

A "Coach the Delivery" practice mode: show the excerpt + beat tag as a prominent stem, four choice cards,
first-try scoring, hint-after-first-miss, explanation on reveal. Bundle `DELIVERY_BANK` as JSON (expand
for iOS as desired). Optionally attribute each item to its delivery cast member (Hush/Boom/…) so the drill
reinforces the DN cast. Sits naturally between the QuizTab Concepts (what the terms mean) and the Tell
recorder (do it yourself) — this is *reason about how to tell it*.

## Status
🟡 open (backport filed) in `spark-anvil-hub/Docs/web/voicetale/PARITY_WEB_VS_IOS.md`. Closes when the
VoiceTale session ships the mode (or replies with a documented waiver).

## Cross-references
- `spark-anvil-hub/Docs/web/voicetale/{RESEARCH,PARITY_WEB_VS_IOS,FEATURE_PLAN}.md`
- `.claude/rules/spark-anvil-website.md` § R-WEB-CLONE-BACKPORT-MINING / § R-CLONE-BIDIRECTIONAL-BACKPORT
