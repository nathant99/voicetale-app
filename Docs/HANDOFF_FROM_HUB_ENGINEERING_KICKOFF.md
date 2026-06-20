---
status: ACTIVE
date: 2026-06-19
direction: hub → app
intent: engineering kickoff — voicetale sits in the Tier 3 ELA cluster cohort (composite 60.0) on the 2026-06-19 docs-only ranking; full docs-only content stack shipped but IMPLEMENTATION_HANDOFF.md is a stub awaiting Tier-2 doc-wave fill-in
freshness-horizon: 14 days
---

# Handoff from Hub — VoiceTale Engineering Kickoff

Direction: **hub → app**. The docs-only phase is complete on the content axes; the engineering CC session can open voicetale in Xcode and begin Phase 1 implementation — BUT must first author the full `IMPLEMENTATION_HANDOFF.md` content per the standard 9-section pattern (it's a stub today).

## Why this kickoff is happening now

Per the 2026-06-19 docs-only ranking refresh (`spark-anvil-hub/Docs/AUDIT_DOCS_ONLY_APP_RANKING_2026-06-19.md`), voicetale sits in the **Tier 3 ELA cluster cohort at composite 60.0** — alongside characterforge / dialoguequest / haikuquest / lyricforge.

## Cluster context — ELA writing-craft cluster (Pattern B)

VoiceTale sits in the ELA writing-craft cluster. Pattern B applies — hero mascot stays PRIMARY protagonist; cast members (lean / pivot / refrain / slow) are explicitly framed as the hero's friends who each embody one narrative-voice-craft primitive. **Pattern B verification is FLAGGED for engineering session per predecessor's Wave 3 ELA audit** — confirm cast members embody distinct voice/POV craft primitives.

## What hub has shipped (content + handoff inventory)

### Content (`Resources/`)

| Class | Count |
|---|---|
| Audio dramas | 12 |
| Cast portraits | 4 |
| Custom art (book covers) | 2 |
| Illustrations | 13 |
| Companion pack | 4 |
| Chapter MDs | 4 (`Docs/dn-s/chapters/{lean,pivot,refrain,slow}.md`) |

### Per-axis handoff docs (12 total)

| Handoff | What it covers |
|---|---|
| `HANDOFF_FROM_LABSMITH_FORGEKIT_BOOTSTRAP.md` | **Step 0** — read FIRST |
| `HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` | DN cast definition + Pattern B framing |
| `HANDOFF_FROM_LABSMITH_DN_ENHANCEMENT.md` | Cluster-coherence enhancements |
| `HANDOFF_FROM_LABSMITH_DN_S_STORY_PER_CHARACTER.md` | Chapter-depth (800-1500w) per character + Tier-2 advanced |
| `HANDOFF_FROM_LABSMITH_DN_SECOND_PASS_DEEPENING.md` | Cast pacing schedule |
| `HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` | Move D voicing (R-CASTDIALOG-ASKS-QUESTIONS 3:1 asks-vs-states) |
| `HANDOFF_FROM_LABSMITH_CHAPTER_ILLUSTRATIONS_WAVE.md` | Path A → Path B multi-beat illustration consumption |
| `HANDOFF_FROM_HUB_CAST_PORTRAITS.md` | Cast portrait consumption + R-CAST-PORTRAIT-SLUG |
| `HANDOFF_FROM_HUB_BOOK_COVERS.md` | Per-app PDF book cover treatment |
| `HANDOFF_FROM_LABSMITH_AVATAR_SIMPLIFIED_MIGRATION.md` | Avatar editor (writing-craft cluster) |
| `HANDOFF_FROM_LABSMITH_COMPANION_PACK.md` | Parent letter + cast poster bundling |
| `HANDOFF_FROM_LABSMITH_PILLAR_DEEPENING_C1_VOICE_EXPORT.md` | Pillar-deepening C1 — voice export hook (export character-voice profile for cross-app reuse in TaleForge / CharacterForge / DialogueQuest) |

## Implementation sequence

### Phase 0 — Author full `IMPLEMENTATION_HANDOFF.md` (PREREQUISITE)

The current `IMPLEMENTATION_HANDOFF.md` is a STUB ("Phase 1 Scope (Summary — Pending Detail)") awaiting Tier-2 doc-wave fill-in. Engineering session OR hub session must author the 9-section structure per `labsmith/Docs/PORTFOLIO_PATTERNS.md`:

1. Overview (narrative voice / POV craft primitive)
2. Phase 1 Scope (specific surfaces to build)
3. Domain Types (`VoiceTaleSession` etc.)
4. Rendering Decision (SwiftUI only — pure interaction-driven)
5. AI Mentor Persona (mascot — pending detail; consult DN handoffs for hero name)
6. Question Kits / Content (Phase 1 inline scaffolds; hub kits lazy-not-eager)
7. ForgeKit Modules to Wire
8. Constraints (iOS 26 / Swift 6 / no Combine / etc.)
9. Definition of Done

If engineering session prefers to defer this to hub, file `Docs/HANDOFF_FROM_APP_IMPLEMENTATION_HANDOFF_FILL_IN.md` back to hub.

### Step 0 — ForgeKit Bootstrap (~30-60 min)

Per `HANDOFF_FROM_LABSMITH_FORGEKIT_BOOTSTRAP.md` § "greenfield". Pin: `from: "0.99.0"`.

### Steps 1-N — Phase 1 feature work

To be defined in Phase 0 IMPLEMENTATION_HANDOFF.md fill-in. Initial estimate based on narrative-voice-craft primitive:

1. **POV / voice selector** — first-person / third-person-limited / third-person-omniscient / unreliable / etc.
2. **Per-passage voice editor** — line-by-line authoring with voice-consistency feedback
3. **AI voice-consistency check** — @Generable `VoiceCheck` schema for per-POV consistency
4. **Voice export** (C1 pillar deepening) — cross-app surface to TaleForge / CharacterForge / DialogueQuest via ForgeSync `AppGroupStore`
5. **Anthology of authored passages** with POV / voice tags

## Reference impls from sister apps

| Sister app | Why relevant |
|---|---|
| CharacterForge | Closest cluster sibling — character craft + voice craft naturally pair; voice-check schema lifts |
| DialogueQuest | Cluster sibling — dialogue craft × voice craft layered authoring surface |
| QuillSpell | Play-PRIMARY writing-craft register; 8-accessory portfolio-canonical pack; R3 segmented avatar |

## Open questions for the engineering session

1. **Phase 0 fill-in ownership** — engineering session authors IMPLEMENTATION_HANDOFF.md OR hub authors? Recommendation: hub authors in next session if engineering session prefers (faster turnaround; hub has DN-S + Pattern B context).
2. **Pattern B verification** — predecessor's Wave 3 ELA audit flagged Pattern B verification for voicetale. Confirm hero mascot identity + cast-as-friends framing in DN handoffs vs current state.
3. **R-DN-PARITY swap test** — Predecessor Wave 3 ELA audit flagged R-DN-PARITY swap test as "needs manual review for voicetale". Verify each cast member (lean / pivot / refrain / slow) embodies one distinct voice-craft primitive.
4. **C1 voice export schema design** — `HANDOFF_FROM_LABSMITH_PILLAR_DEEPENING_C1_VOICE_EXPORT.md` ships cross-app export hook. Engineering session decides schema field set: POV + voice register + signature phrases + cadence markers? Phase 1 surface OR Phase 2?
5. **Cross-cluster voicing schema reuse** — `VoiceCheck` schema can lift from CharacterForge / DialogueQuest if those ship first. Engineering session decides whether to extract shared schema in Phase 1 OR adopt CharacterForge's once it ships.

## What this doc does NOT cover

- **IMPLEMENTATION_HANDOFF.md content** — that's the Phase 0 stub-fill-in
- **Server-side work** — solo Phase 1 (no Tier 1/2 server cell)
- **App Store submission** — covered in Phase 1 DoD when authored

## Acceptance criteria (Phase 1 done state — pending IMPLEMENTATION_HANDOFF.md fill-in)

Standard Phase 1 DoD pattern (full list lives in IMPLEMENTATION_HANDOFF.md when authored):

- [ ] Build clean (all targets, zero warnings)
- [ ] Unit tests + UI tests covering POV selector + voice editor + voice-check
- [ ] First 60 seconds reaches aha moment (first authored passage + mascot voice-check feedback)
- [ ] App icon (6-variant Liquid Glass set)
- [ ] COPPA-2025 parental consent functional
- [ ] Composable avatar editor adopts per cluster pattern
- [ ] Performance budget targets met
- [ ] CLAUDE.md § "Things That Will Bite You" updated

## Cross-references

- `spark-anvil-hub/Docs/AUDIT_DOCS_ONLY_APP_RANKING_2026-06-19.md` — Tier 3 ELA cluster placement
- `spark-anvil-hub/Docs/CONTEXT_HANDOFF_2026-06-19_THREE_WAVE_EXECUTION_CLOSE.md` — predecessor session close-out
- `spark-anvil-hub/.claude/rules/forgekit.md` — module catalog + 0.99.x API surface
- `spark-anvil-hub/.claude/rules/distributed-narrative.md` — DN methodology + DN-S + Pattern B + R-CASTDIALOG-ASKS-QUESTIONS + R-DN-PARITY swap test
- `labsmith/Docs/PORTFOLIO_PATTERNS.md` — 9-section IMPLEMENTATION_HANDOFF.md structure

---

**Welcome to engineering.** Phase 0 (full IMPLEMENTATION_HANDOFF.md fill-in) precedes Step 0 (ForgeKit bootstrap). Hub remains available to author Phase 0 fill-in on request via per-app handoff protocol.
