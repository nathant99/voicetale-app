---
status: PROPOSED
date: 2026-06-24
adr-id: A-VT-002
direction: planning
intent: enumerate the candidate paths for adopting ForgeKit 0.99.0+'s ReflectionPromptModifier + ReflectionPromptStorage into VoiceTale, and ADR-decide replace vs add-on vs defer
freshness-horizon: 14 days
---

# Plan — `ForgeReflection` lift

> Forward planning only. No Swift changes in this PR. The integration
> work — if approved — ships as Phase A-D follow-on PRs scoped against
> the surfaces enumerated below.

## Context

ForgeKit 0.99.0 shipped a portfolio-canonical reflection surface in
`ForgeUI` + `ForgePersistence`:

| Type | Module | Purpose |
|---|---|---|
| `ReflectionPromptConfig` | ForgeUI | 1-2 questions + allowed modalities (text / voice / drawing / emoji / **must-include `.skip`**) + per-app identifier + optional parent-visible opt-in |
| `ReflectionPromptModifier` | ForgeUI | View modifier that presents the sheet via `isPresented:` binding; onComplete callback receives a `ReflectionEntry` |
| `ReflectionPromptSheet` | ForgeUI | Default sheet UI; 4 modalities + `.skip` button; swipe-dismissable; autocorrect-off + autocomplete-off on text input (no PII surfacing) |
| `ReflectionEntry` / `ReflectionResponseModality` | ForgeModels | Value-type record; modality enum (`.text` / `.voice` / `.drawing` / `.emoji` / `.skip`) |
| `ReflectionPromptStorage` | ForgePersistence | Actor-isolated SwiftData-backed store; `save(_:)` / `entries(forApp:)` / `parentVisibleEntries(...)` / `purge(olderThan:)` |

Designed for ~22 Reflect-pillar apps per `@.claude/rules/forgekit.md`
§ Versioning. Per the engine's docs:

> COPPA + trauma-informed invariants enforced:
> - `.skip` is always available (precondition on `ReflectionPromptConfig`)
> - Voice + drawing responses stay on-device (`assetFileURL` is local)
> - Text input has no autocorrect + no autocomplete (no PII surfacing via predictive text)
> - The sheet is swipe-dismissable (Apple HIG default)

VoiceTale's current reflection surface is **`BrambleReflectionView`**
(`Packages/Libraries/Sources/AppFeature/TellTab/BrambleReflectionView.swift`)
which renders Bramble's hold-space register — 1-2 craft observations + 1
Socratic prompt — alongside layered enrichments (distress chip / voice-
variation callout / mastery moment / surprise moment / cast-voicing
chip / cameo strip / action row). The kid LISTENS to Bramble; they do
not currently type a response.

This planning doc enumerates the candidate paths for landing the
ForgeReflection lift, and ADR-decides per-candidate.

## The register-mismatch caveat (LOAD-BEARING)

`ForgeReflection`'s sheet is a **journaling surface** — the kid responds
to a question by typing / voicing / drawing / emoji-tagging. The kid is
the speaker.

`BrambleReflectionView` is the **listening-back surface** — Bramble is
the speaker; the kid hears the reflection. The kid is the listener.

**Direction-of-register-flow is opposite.** A naive lift (replace
Bramble's listening-back surface with ForgeReflection's journaling sheet)
would change the entire app register. VoiceTale's core invariant is
"Bramble listens back to your tale"; replacing that with "now type a
journal entry" would dilute the register.

The salvageable lift surface is **additive, not substitutive**:
surface ForgeReflection's sheet AFTER Bramble's listening-back as an
OPT-IN response affordance to Bramble's open Socratic question. This
preserves the listening-back register (Bramble still speaks first +
asks the open question) while letting the kid record their answer if
they want to (the `.skip` precondition guarantees they're never
required to).

## Candidate surfaces

### Surface 1 — `BrambleReflectionView` "answer Bramble" opt-in response affordance

**Today**: `BrambleReflectionView.actionRow` ships two buttons — "Tell
again" and "Add to my anthology". The kid never types a response;
Bramble's Socratic prompt is read-and-move-on.

**ForgeReflection fit**: ✅ STRONG. The Socratic prompt is a natural
`ReflectionPromptConfig.questions[0]`. The 4-modality + `.skip`
contract directly maps to "you can answer Bramble's question in
whatever way feels right — or just move on". The trauma-informed
`.skip` precondition matches VoiceTale's anti-shame discipline.

**Recommendation**: **ADOPT (Phase A-D)**. Phase A authors a
`VoiceTaleReflectionConfigCatalog` mapping per-(mood × beat × kit)
contexts onto `ReflectionPromptConfig` instances. Phase B wires the
modifier into `BrambleReflectionView` behind a small "Answer Bramble"
button on the action row (kid taps → sheet presents → kid responds
or skips → entry persists). Phase C ships `ReflectionPromptStorage`
+ the per-app retention purge. Phase D ships parent-dashboard
read-back (gated on per-config `parentVisible: true` opt-in).

#### Proposed config catalog

```swift
nonisolated public enum VoiceTaleReflectionConfigCatalog {
    public static let appIdentifier = "com.sparkanvil.voicetale"

    /// Build a config for "answer Bramble" — uses Bramble's open
    /// Socratic question as `questions[0]` so the sheet doesn't need
    /// a static question pool. Optional kit number lets per-kit
    /// retention policy diverge if needed.
    public static func forSocraticPrompt(
        _ prompt: String,
        kitNumber: Int? = nil
    ) -> ReflectionPromptConfig {
        ReflectionPromptConfig(
            id: "bramble.socratic.\(kitNumber.map(String.init) ?? "freeform")",
            questions: [prompt],
            allowedModalities: [.text, .voice, .emoji, .skip],
            appIdentifier: appIdentifier,
            kitNumber: kitNumber,
            parentVisible: false  // default off; per-config opt-in for parent dashboard
        )
    }
}
```

(`.drawing` deliberately omitted from V1 — adds PencilKit
dependency + a per-frame canvas. Defer to Phase D if telemetry
favours it.)

### Surface 2 — `QuizMachine` `.reflection` items currently capturing transient text

**Today**: `QuizView` for `.reflection` items captures a text response
in transient `@State` that's never persisted ("Bramble keeps the
listening private").

**ForgeReflection fit**: 🟡 SPECULATIVE. The `.reflection` items
ARE a journaling surface — text response captured + intentionally
discarded. Persisting via `ReflectionPromptStorage` would give the
kid a per-kit reflection history but also change the
"private-by-default" register that's load-bearing for anti-shame.

**Recommendation**: **DEFER**. The "Bramble keeps the listening
private" invariant is a deliberate trust signal; flipping it to
"Bramble can show you a year of your reflections" requires a per-
kid + per-parent opt-in conversation that V1 doesn't have UI for.
Revisit when the per-app onboarding adds explicit "Save your
reflections?" toggle.

### Surface 3 — `SessionCloserView` end-of-session reflection prompt

**Today**: `SessionCloserView` surfaces at the end of a session
(10-15 min cap) with a session tally + a "Wrap up?" affordance. No
text reflection.

**ForgeReflection fit**: 🟡 PROMISING. End-of-session is a natural
journaling moment ("How did today's session feel?"). The
`ReflectionPromptConfig` for SessionCloser would use a static
question pool ("What's one thing you liked telling?" / "What
surprised you?" / "What do you want to try next time?") rotated
day-of-year.

**Recommendation**: **PHASE E (after Surface 1 ships)**. Wait
for Surface 1 to validate the kid-response register; if telemetry
shows healthy engagement with "Answer Bramble", add the session-
closer variant. If telemetry shows kids consistently `.skip`-ing,
de-prioritize Surface 3.

### Surface 4 — Tradition Gallery "What stuck with you?" affordance

**Today**: `TraditionGalleryView` surfaces per-tradition explainers +
cultural-credit notes. The kid reads + moves on.

**ForgeReflection fit**: ⚠️ POOR. Tradition cards are anti-
appropriation surfaces — the kid is meant to LEARN about a tradition,
not reflect on it (which risks the register tipping toward
appropriation-flavoured "what does this tradition mean to YOU"
journaling). The trauma-informed cultural-respect framing in
`@.claude/rules/distributed-narrative.md` and ADR-016 makes this
candidate explicitly off-limits.

**Recommendation**: **REJECTED**. Reflection on tradition content
must come from a credentialed-source-community voice, not the kid's
typing surface.

## ADR — replace vs add-on vs defer per surface

| Surface | Verdict | Rationale |
|---|---|---|
| 1. `BrambleReflectionView` "answer Bramble" affordance | **ADOPT (Phase A-D)** | Natural register fit; trauma-informed `.skip` precondition matches anti-shame; biggest engine-integration win |
| 2. `QuizMachine` `.reflection` item persistence | **DEFER** | "Bramble keeps the listening private" register is load-bearing; flipping needs explicit parent opt-in UI |
| 3. `SessionCloserView` end-of-session reflection | **PHASE E (after Surface 1)** | Telemetry-gated on Surface 1's "answer Bramble" engagement |
| 4. `TraditionGallery` reflection | **REJECTED** | Cultural-respect framing forbids kid-reflection on tradition content |

## Implementation phases (if approved)

### Phase A — `VoiceTaleReflectionConfigCatalog` + storage bootstrap

- New `Packages/Libraries/Sources/Models/VoiceTaleReflectionConfigCatalog.swift` exposing per-context config builders
- New `Packages/Libraries/Sources/Services/VoiceTaleReflectionStore.swift` — `@MainActor @Observable` wrapper around `ReflectionPromptStorage` that caches results into a value-type `[ReflectionEntryData]` array (mirrors the `VoiceTaleStore` zero-`@Query` pattern per `@.claude/rules/swiftdata.md`)
- Bootstrap the storage actor at app launch in `AppRootView.task` with the `ModelContainer` already in scope
- Unit tests for the config builder + the storage wrapper round-trip
- ADR-016 + COPPA invariant checks codified as compile-time preconditions (matches the existing pattern in `PublishedTaleCertificate.headlineNeverNamesShameTokens`)

### Phase B — `BrambleReflectionView` "Answer Bramble" button + sheet

- New `BrambleReflectionView.answerBrambleButton` in `actionRow` — surfaces ONLY when `reflection?.socraticPrompt` is non-empty
- `@State private var isAnsweringBramble = false` + `.reflectionPrompt(...)` modifier on the view
- `onComplete` callback persists via `VoiceTaleReflectionStore.save(_:)` + emits a new categorical analytics event `brambleAnswered(modality:)` (mood + modality only — never the text payload)
- Anti-shame fallback: skipped entries (`.skip`) DO persist (so the parent dashboard can show "kid engaged with the question") but DO NOT travel any text payload
- Tests for the button visibility + the sheet → entry → store wiring + the `.skip` persistence shape

### Phase C — Retention policy + purge wiring

- `VoiceTaleReflectionStore.purgeOlderThan(_:)` wired to `AppRootView.task` weekly (per FTC 2026 COPPA amendment data-retention rule per `@.claude/rules/age-assurance.md`)
- Default retention horizon: **180 days** (kid-readable as "around half a year"); configurable via `@AppStorage("voicetale.reflection.retention_days")` for the grown-up settings surface
- Tests for the purge round-trip + the 180-day default

### Phase D — Parent-dashboard opt-in read-back

- New `Packages/Libraries/Sources/AppFeature/ProfileTab/ReflectionJournalView.swift` — grown-up-facing surface in `SettingsView` that lists `parentVisibleEntries(forApp:promptVisibility:)` from the storage actor
- Per-config `parentVisible: true` opt-in lives in the catalog (Phase A); V1 ships all configs at `parentVisible: false` (kid-only) and parent opt-in is a Phase D explicit UI toggle
- Tests for the opt-in filter behaviour

## Scope discipline (what this plan EXCLUDES)

- **DOES NOT** replace `BrambleReflectionView`'s listening-back register with the journaling sheet — Surface 1 is ADDITIVE, never substitutive
- **DOES NOT** persist `QuizMachine` `.reflection` text payloads — Surface 2 verdict = DEFER (anti-shame trust signal)
- **DOES NOT** add a reflection surface to the Tradition Gallery — Surface 4 verdict = REJECTED (cultural-respect framing)
- **DOES NOT** add the `.drawing` modality in V1 — PencilKit dependency + per-frame canvas justify deferral
- **DOES NOT** ship a new `VersionedSchema` (`ReflectionPromptStorage` registers its own `ReflectionEntryRecord` `@Model` class in the shared container; no app-side schema changes)
- **DOES NOT** ship parent-dashboard opt-in UI in Phase B — `parentVisible` configs are all false in V1 (Phase D is the explicit opt-in surface)

## Open questions

1. **Does the kid's response travel into Bramble's NEXT reflection?**
   The richest version would feed the kid's answer back into the
   `BramblePromptBuilder` for the next tale's reflection — Bramble
   would notice ("you said last time you wanted to try X — let's
   see how that went"). But this requires a per-tale linking model
   that doesn't exist today + raises trauma-informed surface area
   (Bramble references something the kid wrote weeks ago could
   feel surveilled). V1 ships isolated — kid's answer goes into the
   journal, not into Bramble's next prompt context.

2. **`.voice` modality file location.** `ReflectionEntry.assetFileURL`
   is a local sandboxed URL. VoiceTale's existing voice exporter
   (`VoiceTaleExporter`) writes CAFs to a known sandbox location.
   Phase A storage wiring MUST point `ReflectionVoiceRecorderModel`
   at a separate subdir so reflection voice doesn't accidentally
   land in the same surface as recorded tales (which share via the
   anthology). Suggested path: `Library/Reflection/voice/<entryID>.m4a`.

3. **Retention default = 180 days vs longer.** The FTC 2026 COPPA
   amendment requires a defined retention period. 180 days is the
   common floor for engagement-related kid data; some advocates
   argue for 90 days. The trade-off: longer retention = richer
   parent-dashboard view; shorter retention = stronger privacy
   posture. Phase A ships the default + the settings-surface
   override; the actual default is a Phase A decision moment.

4. **Analytics — bucketed vs categorical for `brambleAnswered`.**
   The proposed event ships mood + modality only (no text payload).
   Bucketing the text length (none / short / medium / long) would
   give cohort-engagement signal without leaking the actual content,
   but introduces a fingerprintability axis. V1 ships modality-only.

## Cross-references

- `@Docs/SESSION_HANDOFF_2026-06-24_TENTH_ROUND.md` § "Recommended next-session priorities" → 4. ForgeReflection lift
- `forgekit/Sources/Client/ForgeUI/Reflection/*.swift` — ForgeUI surface
- `forgekit/Sources/Client/ForgePersistence/Reflection/ReflectionPromptStorage.swift` — storage actor
- `@.claude/rules/forgekit.md` § "Module catalog" → ForgeReflection
- `@.claude/rules/age-assurance.md` § "2026 FTC COPPA Rule Amendments" — data retention policy
- `@.claude/rules/trauma-informed-content.md` § "refer up" / "off-ramp" — anti-shame + `.skip` invariants
- `@Docs/ADR-016_DN_S_TRAUMA_GATED_STORY_AXIS_APPROVAL.md` — cultural-respect framing (rules out Surface 4)
- `@Packages/Libraries/Sources/AppFeature/TellTab/BrambleReflectionView.swift` — Surface 1 wiring point
- `@Packages/Libraries/Sources/AppFeature/QuizTab/QuizMachine.swift` — Surface 2 (deferred)
- `@Packages/Libraries/Sources/AppFeature/SessionCloser/SessionCloserView.swift` — Surface 3 (Phase E)
- `@Packages/Libraries/Sources/AppFeature/TraditionLayer/TraditionGalleryView.swift` — Surface 4 (rejected)
- `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` — sister planning doc (PR-C ELEVENTH round); shipped same round
