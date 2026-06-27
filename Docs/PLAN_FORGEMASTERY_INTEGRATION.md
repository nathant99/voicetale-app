---
status: SHIPPED (Phase A → B → C → D-affordance-half → D-second-half across PR #124 / #128 / #132 / #136 / #139; six consecutive same-day-or-cross-day rounds 2026-06-24 → 2026-06-25)
date: 2026-06-24
last-updated: 2026-06-25
adr-id: A-VT-001
direction: planning → shipped reference
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

**Bramble-register shift on reflection (Phase D's second half — ✅ SHIPPED PR #139 (2026-06-25 SIXTEENTH round))**:

- ✅ Bramble's reflection on a deeper-challenge tale opens with a specific "Bramble noticed you [verbed] this time" register (additive to the existing `.deep` tier register; sourced from `KitMasteryCopyCatalog` via the new `.deeperChallengeOpener` `Kind` — 9 vetted lines, one per kit).
- ✅ New `Models/TaleRecordingContext` value type (pure `nonisolated struct` carrying optional `deeperChallengeKit: KitID?`) + new `Services/Adaptive/RecordingContextCoordinator` (`@MainActor @Observable` process-singleton mirroring `IntentTabCoordinator` — one-shot consume + clear semantics) thread the Adventure-card pill-tap signal into `TellMachine.recordingContext` → `TellView.runReflection` → `BrambleMentor.reflect(..., deeperChallengeOpener:)`.
- ✅ `BramblePromptBuilder.reflectionPrompt(..., deeperChallengeOpener:)` injects a "prepend verbatim" directive into the LM prompt body; `BrambleMentor.applyDeeperChallengeOpener(_:opener:)` (public static helper mirroring `applyFavoriteMoodCallback`) belt-and-braces prepends the opener to the first craft observation (idempotent against already-prefixed observations — the LM may obey the prompt OR may not).
- ✅ `AdventureTabView` affordance pill becomes a `Button` — tap posts the kit to `RecordingContextCoordinator` + routes the kid to the Tell tab via `IntentTabCoordinator.shared.request(destination: .tell)`.
- ✅ New categorical `deeperChallengeTaleStarted(mode:)` analytics event fires on pill-tap (distinct from the existing `.deeperChallengeAvailable(mode:)` which fires on pill-surface) — mode raw value travels; the dominant kit + mastery score + Bramble register-shift opener NEVER travel (anti-fingerprinting + COPPA-2026 anti-PII discipline replays the affordance-half wire shape).
- ✅ Suppression: distress paths bypass the opener entirely (the hold-space register comes first); retell + beat-skipped paths bypass too (those surfaces are themselves register shifts; layering the opener would muddy the register).
- ✅ **38 new tests across 5 suites** (`TaleRecordingContextTests` (6) + `KitMasteryCopyCatalogDeeperChallengeOpenerTests` (9) + `RecordingContextCoordinatorTests` (8) + `BrambleDeeperChallengeOpenerTests` + sibling `BramblePromptBuilderDeeperChallengeOpenerTests` (12) + `AnalyticsServiceTests` additions (3)); 48 regression tests across `ModeMasteryMappingTests` / `KitMasteryTopologyTests` / `DeeperChallengeAffordanceTests` / `BrambleFavoriteMoodCallbackTests` / `BrambleMentorTests` / `BramblePromptBuilderTierTests` all stable; `KitMasteryRecommenderTests.catalogIsComplete` auto-extends to 4 kinds × 9 kits = 36 entries; `copyCatalogAvoidsShameTokens` auto-covers all 36 entries including the 9 new opener lines.

**Phase D second-half closure completes the full Phase A → B → C → D-affordance-half → D-second-half consumer-wiring lifecycle for ForgeMasteryEngine across a six-round chain (PR #124 → #128 → #132 → #136 → #139) — the first complete CLOSURE of a ForgeKit module's consumer-wiring lifecycle in the auto-cycle chain. ForgeMasteryEngine VoiceTale integration is now COMPLETE per this plan; future enhancements (Surface 1's Bramble reflection depth via per-beat mastery; Surface 4's daily-prompt rare-pool calibration) remain DEFERRED per the original Surface-vs-Surface ADR.**

### Phase D parity polish — Adventure-card extend/consolidate badge ✅ **SHIPPED PR #145 (2026-06-26 EIGHTEENTH round)**

Cross-day-boundary post-closure consumer-polish parity that completes the recommended-next-session priority #1 from the SEVENTEENTH-round handoff. NOT a new phase — extends the existing Phase D affordance surface (`AdventureTabView`) with a small in-context badge that brings the broader `KitMasteryRecommender` surface (previously visible only on `ProgressTabView`'s `practiceSurface` three-card stack per PR #132) onto each unlocked Adventure mode-card.

- ✅ New pure value-type service `Packages/Libraries/Sources/Services/Adaptive/PracticeWithBrambleBadge.swift` (`nonisolated enum`; mirrors `DeeperChallengeAffordance` shape). Delegates to the existing `KitMasteryRecommender` — NO new threshold logic; the engine's bands stay canonical.
- ✅ `badge(for:masteryStates:recommender:)` returns the first `(extend | consolidate)` recommendation matching the requested kit; returns `nil` for `.stretch` so the existing sparkles pill stays the sole stretch-band affordance (no double-render on the same card).
- ✅ `AdventureTabView.practiceBadgeView(badge:tint:)` — small-register Label below the existing deeper-challenge pill slot. NOT a `Button` (informational; the Progress tab's three-card surface owns the tap-to-act path). Symbol comes from `KitMasteryCopyCatalog.Kind.symbolName` (`leaf.fill` for extend; `arrow.clockwise.circle.fill` for consolidate).
- ✅ New categorical analytics event `practiceWithBrambleAvailable(mode:kind:)` mirrors `deeperChallengeAvailable(mode:)` wire shape — mode raw value + kind raw value (`extend` / `consolidate`) travel; the dominant kit + mastery score + Bramble copy NEVER travel (anti-fingerprinting per COPPA-2026 anti-PII).
- ✅ One-fire-per-(mode, kind)-per-appearance via a new `@State Set` keyed by `"<mode>|<kind>"`. The existing deeper-challenge analytics surface stays unchanged.
- ✅ Anti-shame invariants (locked at the test layer): Tale Trial NEVER lights (unmapped per `ModeMasteryMapping`); `.stretch` deferred to `DeeperChallengeAffordance` (no double-render); catalog single-seam preserved; SF Symbols sourced from the catalog's anti-judgment shape register (no trophy / star / medal / rosette).
- ✅ 11 new tests (8 in `PracticeWithBrambleBadgeTests` — Tale Trial unmapped / no double-render with stretch pill / mid-band kit surfaces extend or consolidate / catalog single-seam / exhaustive anti-shame blocklist over `(.extend, .consolidate) × KitID` / symbol register lock-down / cold-launch nil / no cross-kit leak + 3 in `AnalyticsServiceTests`); 0 regressions; 29/29 ServicesTests covered + 26/26 AnalyticsServiceTests pass.

### Phase D parity polish tap-to-act — Adventure-card badge becomes a `Button` ✅ **SHIPPED PR #151 (2026-06-26 NINETEENTH round)**

Scope-reversal follow-on to PR #145 — the badge that landed informational (NOT a `Button`) in the EIGHTEENTH round is promoted to a tap-affordance. The Progress-tab three-card surface stays canonical for cross-tab discovery; this PR adds a parallel same-tab tap-to-act path for kids who land on the Adventure tab first.

- ✅ `AdventureTabView.practiceBadgeView(badge:tint:gateID:)` becomes a `Button`. Tap fires the new categorical analytics event AND presents `QuizView(preselectedKit: badge.kit)` via a new `.sheet` (mirrors `ProgressTabView.recommendationCard(_:)` from Phase C).
- ✅ New `@State pendingPracticeKit: KitID?` + `@State isPracticePresented: Bool` mirror `ProgressTabView`'s sheet-presentation pattern. Sheet `onDismiss:` clears `pendingPracticeKit` so the next tap re-evaluates against the latest mastery snapshot.
- ✅ New categorical analytics event `practiceWithBrambleStartedFromAdventure(mode:kind:)` mirrors the wire shape of `practiceWithBrambleAvailable(mode:kind:)` — mode + kind raw values travel; dominant kit + mastery score + Bramble copy NEVER travel (anti-fingerprinting per COPPA-2026 anti-PII).
- ✅ Distinct event name lets cohort analysis separate "badge lit" (`practiceWithBrambleAvailable`) from "badge acted on" (`practiceWithBrambleStartedFromAdventure`) — same separation pattern as the `.deeperChallengeAvailable` ↔ `.deeperChallengeTaleStarted` split from Phase D second-half.
- ✅ Anti-shame invariants preserved unchanged: Tale Trial NEVER lights (unmapped per `ModeMasteryMapping`); `.stretch` defers to `DeeperChallengeAffordance` (no double-render); catalog single-seam discipline preserved; copy still flows through `KitMasteryCopyCatalog.line(for:kit:)`.
- ✅ 4 new tests in `AnalyticsServiceTests` (name stability + properties carry mode + kind only + name differs from badge-available + name differs from deeper-challenge-started). 0 regressions; 30/30 AnalyticsServiceTests + 8/8 PracticeWithBrambleBadgeTests pass.

### Phase B analytics coalescing — per-kit band-crossing emission gate ✅ **SHIPPED PR #154 (2026-06-27 TWENTIETH round)**

Cross-launch-persistent analytics-emission coalescing layer that closes the noisy-oscillation case the NINETEENTH-round handoff identified as priority #2. NOT a new phase — extends the existing Phase B `kitMasteryAdvanced(kit:fromBand:toBand:)` surface with a per-kit last-emitted-band log so a kid bouncing across a quartile boundary across many attempts doesn't produce a noisy wire surface (repeated `meeting → deepening` / `deepening → meeting` pairs as the score wobbles).

- ✅ New pure value-type `Packages/Libraries/Sources/Models/KitMasteryBandLog.swift` (`nonisolated struct Sendable, Hashable, Codable`). Internal storage `[Int: String]` keyed by `KitID` raw value → `MasteryBand` raw value. Kept dependency-free of `ForgeMasteryEngine` so `Models` keeps its single-source-of-truth posture per the SPM dep graph (`Models` targets cannot import ForgeKit modules).
- ✅ Public API: `init()` / `init(json:)` / `encoded()` / `lastBand(forKit:)` / `shouldEmit(forKit:toBand:)` / `recording(forKit:band:)`.
- ✅ Anti-defeat: malformed JSON (corrupt `@AppStorage` write / future migration that changes the key shape / partial write) degrades to an empty log so a single bad write never permanently suppresses emissions. The worst case is a few one-time re-emissions on next launch. Mirrors the `ReflectionRetentionPolicy.clampedRetentionDays(_:)` discipline.
- ✅ `QuizView.recordKitMasteryAttempt` adds `@AppStorage("voicetale.kitmastery.last_bands") private var lastBandsJSON: String = ""`. The existing in-memory `fromBand != toBand` fast-path is preserved; when it passes, the log's `shouldEmit(forKit:toBand:)` consults the last-emitted band per kit. Emission proceeds only when the new `toBand` differs from the logged value.
- ✅ The emitted payload's `fromBand` prefers the logged value when present so cohort analysis sees the actual session-spanning transition rather than the in-memory snapshot from a few attempts ago. Falls back to the in-memory `fromBand` when the log has no prior entry for the kit (first-emission-per-install case).
- ✅ Anti-PII discipline preserved: the wire shape stays `kit` + `from_band` + `to_band` only. No log JSON travels, no raw scores travel, no `@AppStorage` payload travels. Locked in a new `AnalyticsServiceTests.kitMasteryAdvancedWireShapeIsUnchangedByCoalescing` test with a forbidden-keys set covering `last_bands_json` / `last_band` / `coalesced` / `suppressed_count` / `raw_score` / `elapsed`.
- ✅ Anti-shame discipline preserved: regressions still emit (the wire surface supports both directions); only repeated same-band emissions are suppressed. Cohort analysis can still see "kid bounced from `meeting` back to `developing`" as a legitimate signal — what we suppress is `developing → developing` repeats across launches.
- ✅ 17 new tests across 2 suites (15 in `ModelsTests/KitMasteryBandLogTests` — empty-log behavior (3) + JSON round-trip + corrupt-input degradation (3) + `shouldEmit` invariants (4) + `recording` immutability (3) + end-to-end oscillation-suppression scenario (1) + Codable round-trip (1); 2 in `AnalyticsServiceTests` locking wire-shape + from-band-prefer-logged invariants); 42 regression tests stable; 59/59 pass.

The coalescing layer is the cross-launch-persistent analog of the EIGHTEENTH-round one-fire-per-(mode, kind)-per-appearance `@State Set` discipline established on the Adventure-card practice-with-Bramble badge — same principle (one wire event per categorical state change), different persistence horizon (cold-launch survival via `@AppStorage` vs view-local `@State Set`). The TWENTIETH-round PR is the FIRST cross-launch-persistent analytics-emission coalescing layer in the auto-cycle chain.

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
