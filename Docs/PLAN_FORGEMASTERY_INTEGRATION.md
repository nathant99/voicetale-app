---
status: PROPOSED
date: 2026-06-24
adr-id: A-VT-001
direction: planning
intent: enumerate the candidate paths for adopting ForgeKit 1.0.0-rc.2's `ForgeMasteryEngine` into VoiceTale, and ADR-decide migrate vs wrap vs defer
freshness-horizon: 14 days
---

# Plan — `ForgeMasteryEngine` integration

> Forward planning only. No Swift changes in this PR. The integration
> work — if approved — ships as Phase A/B/C/D follow-on PRs scoped against
> the surfaces enumerated below.

## Context

ForgeKit 1.0.0-rc.2 ships **`ForgeMasteryEngine`** in
`Sources/Client/ForgeMasteryEngine/`. Five public types:

| Type | Purpose |
|---|---|
| `MasteryGraph<Topic>` | DAG of curricular topics with prerequisite edges + Bloom level + topological order |
| `TopicMasteryState` | Per-(student, topic) FSRS-6 retention + attempt count + rolling `recentOutcomes` window; derived `masteryScore` (60% FSRS retrievability + 40% recent accuracy) + `isRacingAhead` / `isStuck` convenience flags |
| `AttemptOutcome` | `.correctFirstTry(elapsed:)` / `.correctWithHints(...)` / `.incorrect(elapsed:)` / `.skipped` |
| `NextProblemPicker<Topic, ProblemID>` | Returns up to three recommendations (`extend` / `consolidate` / `stretch`) framed in the AlcumusForge three-card surface |
| `MasteryUpdater` | Side-effect-free recorder: take a state + outcome, return new state |

Pure value-type API; all `nonisolated`. Edge-of-competence heuristic per
Vygotsky ZPD (target difficulty band [mastery + 0.10, mastery + 0.20]).
First consumer: AlcumusForge.

VoiceTale's current adaptive surface is **`DifficultyController`**
(`Packages/Libraries/Sources/Services/DifficultyController.swift`) — a
3-tier saved-tale-count mapper:

| Tier | Tales saved | Effect on Bramble |
|---|---|---|
| `.gentle`   | 0–3   | Validation-only register; Socratic prompts framed as wonder |
| `.standard` | 4–12  | Current production behaviour; one observation + one Socratic question |
| `.deep`     | 13+   | Deeper second observation + nested sub-questions |

The tier is INVISIBLE to the kid; only Bramble's instruction body shifts.

This planning doc enumerates the candidate VoiceTale surfaces where
`ForgeMasteryEngine` could replace or augment the current state-of-the-
world, and ADR-decides migrate vs wrap vs defer for each.

## Candidate surfaces

### Surface 1 — `BrambleMentor` reflection depth (currently DifficultyController-driven)

**Today**: `BramblePromptBuilder.instructions(for:tier:)` reads
`DifficultyController.tier(forTalesCount:)` and emits 3 different
instruction bodies. The signal is **saved-tale count** — a single global
counter.

**ForgeMasteryEngine fit**: ⚠️ POOR. Narrative authoring is not an
"is this answer correct" surface — there's no `AttemptOutcome` to
record. The current `.gentle`/`.standard`/`.deep` register doesn't
naturally derive from a per-topic mastery score.

**Recommendation**: **DEFER**. Keep `DifficultyController` as the
canonical Bramble-tier source. If a future content axis ships
discrete-correctness signals (e.g., "the kid hit all five beats
within tolerance N times in a row"), revisit with a per-beat
`MasteryGraph` and `MasteryUpdater.recordAttempt(.correctFirstTry(...))`.

### Surface 2 — `QuizMachine` kit rotation (Adventure mode + Practice card)

**Today**: `QuestionKitLoader.loadKitForRotation(seed:)` picks one of
the 9 kits keyed off `Calendar.current.component(.weekOfYear,...)`.
The rotation is deterministic-by-week, not mastery-driven. Each kit
has `.choice` / `.reflection` / `.rewrite` items; choices feed
`ForgePedagogy.PedagogySession.recordAnswer(concept-id, isCorrect)`
which is local-only and per-session.

**ForgeMasteryEngine fit**: ✅ STRONG. Each `.choice` item IS a discrete
correctness signal. Each kit is a coherent topic (hook craft / sensory
detail / arc completeness / mood / voice character / mood-2 / pacing /
surprise / closing). The 9 kits compose a natural prerequisite chain
(arc completeness builds on hook + sensory; closing builds on
surprise + arc).

**Recommendation**: **ADOPT** as the canonical kit-rotation engine
behind a clean migration. Phase A authors `KitMasteryTopology` (the
`MasteryGraph<KitID>` instance), phase B wires
`MasteryUpdater.recordAttempt(...)` into `QuizMachine.answerChoice`,
phase C consumes `NextProblemPicker.recommendations(...)` from
`QuestionKitLoader.loadKitForRotation(seed:)` (replaces week-of-year
keying with extend-or-consolidate-or-stretch choice), phase D unit
+ UI tests + analytics events for the new selection rationale.

#### Proposed topology

```
                         arc_completeness  ──┐
                                            ├──► closing_grace
                       mood_anchor   ────► surprise_pivot
                       ↑                    │
hook_craft  ────► sensory_detail            │
                       │                    │
                       └─► voice_character ─┘
                       │
                       └─► pacing_rhythm
                       │
                       └─► mood_reprise
```

(9 nodes; depth-3 DAG; the existing `.kit_1` … `.kit_9` raw values
become the `Topic` type. `MasteryGraph.topologicalOrder` falls out
deterministically; `NextProblemPicker.stretchRecommendation` lights
the moment the kid masters the appropriate prerequisites.)

### Surface 3 — `VoiceTaleProgressionGate` Adventure mode-card unlocks

**Today**: 3 / 5 / 7 saved-tales `SecondaryCriterion` thresholds gate
4 mode-cards (Hook Builder / Pacing Walk / Turn Drill / Callback
Refrain). Same saved-tales global counter, deterministic mapping.

**ForgeMasteryEngine fit**: ⚠️ MEDIUM. Saved-tales is a usage signal;
mastery is a competence signal. The current gates are usage-keyed (the
kid has put in the time), not competence-keyed. Routing them through
`MasteryGraph` would shift the register from "you've used the app
enough to unlock this" to "you've demonstrated craft in [topic]" —
which is a richer + more diagnostic gate, but ALSO carries a higher
risk of gating out kids who use the app a lot but get low mastery
scores (anti-shame surface; trauma-informed regression risk).

**Recommendation**: **WRAP** rather than migrate. Keep the 3/5/7
saved-tales gates as the primary unlock; surface mastery-driven
"deeper challenge" affordances on top of the unlocked cards
(e.g., "Try the Turn Drill with a tender mood — Bramble noticed you
nail the funny ones"). This wraps the engine without changing the
canonical unlock criterion.

### Surface 4 — `DailyPromptView` rare-pool calibration

**Today**: `DailyPromptView.prompts` rotates through 30 starter prompts
keyed off day-of-year. The `rarePromptSurfaced(category:)` analytics
event hints at a future "rare prompt" surface but is currently not
wired beyond emission.

**ForgeMasteryEngine fit**: 🟡 SPECULATIVE. The "rare prompt" surface
would benefit from mastery state — surface a more-challenging prompt
to a kid showing high competence; surface a softer prompt to a kid
showing low competence. But the current daily-prompt pool is small
(30 starter prompts) and the rotation is deterministic-by-date — not
mastery-driven.

**Recommendation**: **DEFER until Phase 3** (cross-cluster cameo +
performance polish). The rare-pool calibration becomes worth wiring
when the prompt pool grows large enough that mastery-driven
calibration produces measurably better selection than date-keyed.

## ADR — migrate vs wrap vs defer per surface

| Surface | Verdict | Rationale |
|---|---|---|
| 1. Bramble reflection depth | **DEFER** | Narrative authoring lacks `AttemptOutcome` signal; `DifficultyController` is the right shape for this surface |
| 2. `QuizMachine` kit rotation | **ADOPT (Phase A-D)** | Discrete correctness signal + natural prerequisite DAG; biggest engine-integration win |
| 3. `VoiceTaleProgressionGate` mode-cards | **WRAP** | Preserve canonical saved-tales gate; surface mastery-driven challenge affordances on top |
| 4. `DailyPromptView` rare-pool | **DEFER** | Speculative; revisit at Phase 3 when prompt pool grows |

## Implementation phases (if approved)

### Phase A — `KitMasteryTopology` + `Sources/Adaptive/`

- New `Packages/Libraries/Sources/Models/KitMasteryTopology.swift` declaring the `MasteryGraph<KitID>` per the proposed topology above
- New `Packages/Libraries/Sources/Services/Adaptive/KitMasteryStore.swift` (`@MainActor @Observable` wrapper) persisting per-(kid, kit) `TopicMasteryState` in SwiftData via additive Optional `encodedMasteryState: Data` on `PersistentPlayerProgress`
- Unit tests for the topology (cycle-free; topological order matches the expected chain; every kit has a valid `Topic`)

### Phase B — `QuizMachine` wires `MasteryUpdater.recordAttempt(...)`

- `QuizMachine.answerChoice` calls `MasteryUpdater.recordAttempt(state: ..., outcome: .correctFirstTry(elapsedSeconds: ...))` on right answers and `.incorrect(elapsedSeconds: ...)` on wrong
- New analytics event `kitMasteryAdvanced(kit:fromScore:toScore:)` (bucketed; never raw scores)
- Tests for the update path + analytics event

### Phase C — `QuestionKitLoader.loadKitForRotation` consumes `NextProblemPicker.recommendations`

- Replace week-of-year keying with `NextProblemPicker.recommendations(state:excluding:recentlyMasteredTopics:)`
- "Practice with Bramble" card on `ProgressTabView` becomes the extend/consolidate/stretch surface (mirrors the AlcumusForge three-card pattern)
- Tests for the picker output + the rationale-to-kit mapping

### Phase D — `VoiceTaleProgressionGate` mastery-driven challenge affordances

**Affordance half ✅ SHIPPED PR #136 (2026-06-25 FIFTEENTH round)**:

- ✅ Each unlocked Adventure mode-card surfaces a "deeper challenge" affordance when the kid's mastery on the corresponding kit's topic crosses an edge-of-competence threshold (mastery score ≥ 0.80 per the engine's Vygotsky-ZPD floor).
- ✅ New `Models/ModeMasteryMapping` is the canonical mode-card → KitID table (Hook Builder → `.hookCraft`, Pacing Walk → `.pacingRhythm`, Turn Drill → `.surprisePivot`, Callback Refrain → `.closingGrace`). Tale Trial is intentionally unmapped — a mastery hint on a blind-judged surface would defeat the rubric.
- ✅ New `Services/Adaptive/DeeperChallengeAffordance` is a pure value-type service: `shouldSurface(masteryScore:)` (nil-safe; cold-launch kid renders unadorned mode-card) + `brambleCopy(for:)` (delegates to `KitMasteryCopyCatalog.line(for: .stretch, kit:)` — single seam preserves anti-shame token blocklist enforcement) + `symbolName` (`sparkles` — matches the Practice-with-Bramble stretch card; trophy / star / medal / rosette explicitly blocked at the unit-test layer).
- ✅ `AdventureTabView` reads the env-injected `KitMasteryStore` and renders the affordance pill below the subtitle on each unlocked + mapped mode-card.
- ✅ New categorical `deeperChallengeAvailable(mode:)` analytics event travels the mode raw value only — never the kit, the mastery score, or the Bramble copy (anti-fingerprinting per COPPA-2026 anti-PII). One-fire-per-mode-per-appearance via a `@State Set`.
- ✅ 19 new tests across the model mapping (9 in `ModeMasteryMappingTests`), the affordance service (8 in `DeeperChallengeAffordanceTests` — threshold gating at 0.79/0.80/1.0/nil, catalog single-seam delegation, anti-shame blocklist on every per-kit line, sparkles symbol + anti-judgment blocklist, threshold constant), and the analytics event (2 in `AnalyticsServiceTests`).

**Bramble-register shift on reflection (Phase D's second half — DEFERRED to next round)**:

- Bramble's reflection on a deeper-challenge tale opens with a specific "I noticed you went deeper there" register (additive to the existing `.deep` tier register; uses `KitMasteryCopyCatalog`)
- Touches the TellMachine + BramblePromptBuilder + reflection-render layer; scoped out of PR #136 to keep that PR focused on the Adventure surface
- Tests for the register shift

## Scope discipline (what this plan EXCLUDES)

- **DOES NOT** migrate `DifficultyController` to ForgeMasteryEngine (Surface 1 verdict = DEFER)
- **DOES NOT** change the canonical 3/5/7 saved-tales gates on Adventure mode-cards (Surface 3 verdict = WRAP)
- **DOES NOT** change `BrambleMentor`'s public surface; the engine integration is on the kit-rotation axis, not the Bramble-reflection axis
- **DOES NOT** ship a new `VersionedSchema` (additive Optional `encodedMasteryState: Data` is back-compat per `@.claude/rules/swiftdata.md` § "Pre-App Store: don't create new VersionedSchema for unreleased models")
- **DOES NOT** introduce parent-visible mastery surfaces in Phase A-D (every recommended phase keeps the engine integration kid-invisible, mirroring how `DifficultyController` operates today)

## Open questions

1. **Where does `studentProfileID` come from?** ForgeMasteryEngine's
   per-student state model assumes a `StudentProfile.id`. VoiceTale
   doesn't yet have a multi-profile surface; the single-profile
   default would map to `getOrCreateForgeID().id`. If multi-profile
   ships later (e.g., siblings sharing a device), the migration is
   a straightforward fanout over the existing per-kid Models layer.

2. **Should `kit_05_voice_character` introduce a multi-prerequisite
   path?** The current proposal has it depend on `sensory_detail`
   alone, but the kit content also touches mood + arc completeness.
   Phase A authoring should look at the actual kit JSON to decide
   whether the prereq set is 1, 2, or 3 nodes.

3. **Anti-shame regression risk on stretch recommendations.** If the
   kid is racing ahead AND the stretch rationale surfaces a topic
   they actually struggle with, the "Try this one — it's harder"
   framing could shame a kid who pushes themselves and then misses.
   Phase B-C MUST cover anti-shame copy on the stretch surface (24-arm
   matrix per `Tests/AppFeatureTests/PublishedTaleCertificateTests`).

## Cross-references

- `@Docs/SESSION_HANDOFF_2026-06-24_TENTH_ROUND.md` § "Recommended next-session priorities" → 3. ForgeMasteryEngine integration plan
- `forgekit/Sources/Client/ForgeMasteryEngine/*.swift` — engine source
- `forgekit/Docs/HANDOFF_FROM_FORGEKIT_FORGEMASTERYENGINE_SHIPPED.md` — engine ship handoff
- `@Docs/TECHNICAL_DESIGN.md` § "Adaptive surface" — current `DifficultyController` topology
- `@.claude/rules/forgekit.md` § "Module catalog" → ForgeMasteryEngine
- `@Packages/Libraries/Sources/Services/DifficultyController.swift` — current 3-tier surface (kept for Surface 1)
- `@Packages/Libraries/Sources/AppFeature/QuizTab/QuizMachine.swift` — Surface 2 wiring point
- `@Packages/Libraries/Sources/AppFeature/AdventureTab/VoiceTaleProgressionGate.swift` — Surface 3 wiring point
- `@Packages/Libraries/Sources/AppFeature/Anthology/DailyPromptView.swift` — Surface 4 (deferred)
