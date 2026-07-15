# Handoff from Hub — VoiceTale Concept Question Kits (16×25 = 400 MC)

Direction: **hub → app**. Hub hand-authored a full oral-storytelling-craft multiple-choice curriculum; the app session wires the Concepts surface that renders it. **The existing 9 reflection/choice coaching kits are UNTOUCHED — they remain as a complementary layer.**

## The decision

VoiceTale (tween 9–14, oral-storytelling craft) ships **9 bespoke reflection/choice COACHING kits** (`Packages/Libraries/Sources/Services/Resources/QuestionKits/kit_01…kit_09.json`) — NOT the portfolio-standard 16×25 MC bank (and `kit_04`/`kit_06` are both "mood"). Per the portfolio rule `R-WEB-CLONE-KITS-OPUS-AUTHOR` (spark-anvil-hub) — which **superseded** the earlier "composition = no MC" waiver via the HaikuQuest precedent — a missing 16×25 MC set is an **authoring task, not a waiver**. Every kit-bearing portfolio app carries a Concepts MC surface at the portfolio standard.

Hub therefore **hand-authored** a 16-kit × 25-question oral-storytelling-craft curriculum with **in-session Opus (no Gemini gen)** and shipped it to `Resources/Questions/voicetale/`. **The 9 existing reflection kits stay exactly as they are** — they are a different, valuable content model (open reflection prompts + occasional choice for coaching a learner's own tellings). The new 16×25 MC set is a **complementary Concepts/recognition surface**, not a replacement.

## What shipped (this handoff)

- **`Resources/Questions/voicetale/kit_01…kit_16.json`** — 16 kits, 25 questions each (400 total), portfolio iOS kit schema:
  - top level: `id`, `name`, `description`, `gradeBand`, `topic`, `questions[]`, `standardsFramework: "CCSS"`
  - per question: `id` (deterministic uuid5), `prompt`, `correctAnswer`, `distractors[3]`, `bloomLevel`, `gradeBand`, `topic`, `subtopic`, `standard` (CCSS ELA Speaking & Listening SL.4/5/6 + narrative W.3), `hints[2]`, `explanation`, `version`
- **Unchanged:** the 9 reflection kits in `Services/Resources/QuestionKits/` (the coaching layer).
- Deterministic ids + content: re-running the hub porter regenerates byte-identical JSON.

## Curriculum (ages 9–14, scaffolded gr4→gr8)

| # | Kit | Grade band |
|---|---|---|
| 1 | What Is Storytelling? | gr4-5 |
| 2 | The Hook | gr4-5 |
| 3 | Story Structure | gr4-5 |
| 4 | Setting the Scene | gr4-5 |
| 5 | Sensory Details | gr5-6 |
| 6 | Characters in a Told Tale | gr5-6 |
| 7 | Mood & Tone | gr5-6 |
| 8 | Tension & Suspense | gr5-6 |
| 9 | Pacing | gr6-7 |
| 10 | Voice & Delivery | gr6-7 |
| 11 | Gesture & Body Language | gr6-7 |
| 12 | The Surprise / Twist | gr6-7 |
| 13 | Audience Awareness | gr7-8 |
| 14 | Repetition & Refrain | gr7-8 |
| 15 | Oral Tradition & History | gr7-8 |
| 16 | Capstone: Telling a Whole Story | gr7-8 |

The arc mirrors VoiceTale's oral-storytelling thesis: kits 1–4 establish the craft (storytelling, hook, structure, setting); 5–8 the tools of vividness (sensory detail, character, mood, tension); 9–12 delivery + the unexpected (pacing, voice, gesture, twist); 13–16 audience, oral patterns, tradition, and a whole-telling capstone.

## App-side integration tasks (owned by the app's own CC session)

1. **Load the kits** — point the app's question-loading service at `Resources/Questions/voicetale/` (a `.process("Resources")` SPM target resource, or the app-shell bundle, per this repo's convention). The schema matches the portfolio kit shape used across sibling apps.
2. **Wire a Concepts / Practice surface** — add a lightweight MC-round view (ForgeUI + the portfolio MC-round pattern) that plays a kit (round size ~10, first-try scoring, articulate-before-hint: show `hints[0]` only after a first miss, then `explanation` on reveal). Anti-shame register.
3. **Keep the reflection kits** — the new MC Concepts surface complements, not replaces, the existing 9 reflection coaching kits. Consider surfacing both: "Concepts" (MC recognition) alongside the reflection-driven coaching.
4. **Standards mapping** — `standard` is a CCSS ELA Speaking & Listening (or W.3 narrative) code per item.

## What this handoff does NOT cover

- The Swift MC-round view / loader (hub never writes Swift — the app session implements it).
- Any change to the 9 existing reflection coaching kits (untouched).
- A web Concepts surface (no `/play/voicetale` clone exists yet; the porter is ready to emit one when it does).

## Parity / backport

A 🟡 iOS-backport row is tracked in the V222 kit-coverage audit (`spark-anvil-hub/Docs/AUDIT_QUESTION_KIT_COVERAGE_2026-07-14.md`) for the VoiceTale Concepts surface. It closes to ✅ when the app session ships the surface back.

## Related

- Porter (source of truth): `spark-anvil-hub/scripts/port_voicetale_kits_to_web.py` — edit the porter, never the JSON.
- Rule: `spark-anvil-hub/.claude/rules/spark-anvil-website.md` § R-WEB-CLONE-KITS-OPUS-AUTHOR.
