# Handoff from Labsmith — Pillar Deepening: VoiceTale (C1 Shippable Artifact (CAF voice export))

Direction: **labsmith → voicetale-app**. Round 82 #425 Wave 1 ships **C1 (Shippable Artifact (CAF voice export))** as the recommended Writing-craft / audio cluster deepening move for VoiceTale. Voice-narrated story recordings are the canonical use case for C1 per `PLAN_PILLAR_DEEPENING_METHODOLOGY.md` § 2.2. This handoff specifies how to wire the move against VoiceTale's existing surfaces.

**Filed**: 2026-05-26
**Round**: 82 queue #425 (Wave 1 — Writing-craft / audio cluster)
**Cluster wave**: Part of Round 82 #425 Wave 1 (Writing-craft / audio cluster batch)
**Companion docs (labsmith)**: `labsmith/Docs/PLAN_PILLAR_DEEPENING_METHODOLOGY.md` (§ 2.2 C1) + `labsmith/Docs/AUDIT_PILLAR_DEEPENING_PER_APP.md` (per-app row for voicetale)

---

## § 1 — Header: app context

| Field | Value |
|---|---|
| **App slug** | `voicetale` |
| **App name** | VoiceTale |
| **DN cluster** | Writing-craft / audio (§ 2.2) |
| **DN status** | Distributed-narrative handoff shipped — writing-craft / audio cluster per `Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` |
| **Mentor pattern** | Standard variant |
| **AI mentor** | per app's DN handoff |
| **Current pillar profile (audit)** | Create-PRIMARY |
| **Trauma-informed status** | per app's per-cluster TI status |
| **Implementation tier** | Docs-only / pre-scaffolding (verify Phase 1 scaffolding before adoption) |
| **App-side blockers** | Phase 1 scaffolding (Xcode project + Libraries SPM) precedes this work where applicable. **Build-ready when Phase 1 lands.** |

---

## § 2 — Why this deepening move now

VoiceTale's primary surface (voice-narrated story recordings) is **the canonical use case for C1** per `PLAN_PILLAR_DEEPENING_METHODOLOGY.md` § 2.2.

Writing-craft / audio cluster rationale (per `AUDIT_PILLAR_DEEPENING_PER_APP.md` § 2.2):

- The recommended top-move for VoiceTale per the audit catalog is C1 (this move).
- All required ForgeKit primitives shipped (see § 4 dependency check).
- The cast (from DN handoff) anchors the primitives this move surfaces; per the `writing-craft / audio cluster` DN pattern, the cast either stays as the protagonist (Pattern B) or supports the mentor (Standard variant).

**Strategic frame** (from methodology § 1.1):

> Adopting C1 achieves: modes.create: depth-at-ceiling; +1 marker for exportable artifact.

---

## § 3 — The move

**Move identifier**: `C1`
**Move name**: Shippable Artifact (CAF voice export)
**Pillar(s) deepened**: **Create** + **Reflect**
**Score delta**: modes.create: depth-at-ceiling; +1 marker for exportable artifact

### 3.1 What the move IS (operational definition)

1. **Real-world-format CAF audio export**: At end of session, kid can EXPORT the voice-narrated story as a CAF audio file (44.1kHz, mono, 16-bit PCM per portfolio audio convention).
2. **Cast-anchored recording prompts**: Each cast member voices a per-kit recording prompt (e.g., 'now narrate this passage in [cast-name]'s voice'). Recording captures kid voice into the artifact.
3. **Family-share flow**: Parent receives the CAF (or auto-converted MP3 for share-compatibility) via the parent-shared library per `.claude/rules/age-assurance.md`.

### 3.2 What the move IS NOT (anti-pattern guard)

- ❌ **A screenshot of the recording UI** — must be the canonical CAF/audio format, per `.claude/rules/portfolio.md` § 7 (Custom-Art & Content Pipelines).
- ❌ **Public-share by default** — every external-share is parent-gated per `.claude/rules/age-assurance.md` 2026 amendments.
- ❌ **Force-recording with no prompt opt-out** — kid can record blank or skip a prompt.
- ❌ **Voice cloning of cast voices** — kid's voice is kid's voice; never synthesize cast voices from kid recordings (COPPA + identity risks).

### 3.3 Evidence baseline (from methodology § 2.2)

- **Resnick 'Projects' principle** — artifacts must be REAL artifacts, not exercises.
- **Maker-movement bias-toward-action** — voice recording IS active engagement.
- **Kafai/Burke Connected Code** — sharing is part of the learning.

---

## § 4 — ForgeKit dependency check

**Verified against `forgekit/Docs/CHANGELOG.md` (0.94.0 current).** All primitives SHIPPED.

| Primitive | Status |
|---|---|
| `AVFoundation` (`AVAudioRecorder` + `AVAudioEngine`) | ✅ native iOS 26 |
| `ForgeAudio` (audio playback + SFX management) | ✅ shipped |
| `ForgeAccessibility` (parental consent for any external share) | ✅ shipped |
| `SwiftData` (`@Model` for recordings) | ✅ native |
| `ImageRenderer` (for cover art) | ✅ native |

**Pin recommendation**: When `Libraries/Package.swift` is scaffolded, pin **`from: "0.94.0"`** to pick up all current ForgeKit primitives.

---

## § 5 — Implementation Phase A-D

### Phase A — Design finalization (1-2 days)

- [ ] Decide recording length cap: 30 seconds? 60 seconds? 5 minutes? (Recommendation: 60s per recording for tween attention + storage budget)
- [ ] Choose audio format target: CAF (Apple-canonical) OR MP3 (broader-share compat); recommendation: CAF native, optional MP3 conversion at export-time
- [ ] Identify cast-anchored recording prompts per kit (per DN handoff)
- [ ] Confirm UI surfaces: recording booth view, playback, gallery, export sheet

### Phase B — Core wiring (3-5 days)

- [ ] Wire `AVAudioRecorder` for capture (mono, 44.1kHz, 16-bit PCM CAF)
- [ ] Persist recordings as `@Model` `VoiceRecordingArtifact` with `(id, kitID, prompt, audioFileURL, durationSeconds, createdAt)`
- [ ] Add cast-anchored prompt overlay (per Phase A mapping)
- [ ] Wire playback with `AVAudioEngine`
- [ ] Update CLAUDE.md § 9: AVAudioSession category gotchas; FileManager URL persistence across launches

### Phase C — Surface + Asset Consumer Audit (3-5 days)

- [ ] Add gallery view of recordings (grouped by kit/date)
- [ ] Wire CAF export to share sheet (parent-gated per `.claude/rules/age-assurance.md`)
- [ ] **Asset Consumer Audit** per `.claude/rules/portfolio.md`:
  - `grep -rE 'AVAudioRecorder|VoiceRecordingArtifact|AVAudioEngine' Libraries/Sources/`
  - At least ONE view renders the recording booth + gallery + export

### Phase D — Instrumentation + accessibility (2-3 days)

- [ ] Wire `ForgeAnalytics`: `voice.recording.started` / `voice.recording.saved` / `voice.recording.shared`
- [ ] All events local-only per `.claude/rules/age-assurance.md`
- [ ] Document engagement claim: "VoiceTale kids record N narrations per week on average"
- [ ] Accessibility audit: VoiceOver hint for recording booth; visual waveform alternative

**Total estimate**: ~8-14 days per-app session work (assumes Phase 1 scaffolding complete).

---

## § 6 — Code-shape sketch

See per-move code-shape examples in:
- `labsmith/Docs/TEMPLATE_IMPLEMENTATION_HANDOFF_PILLAR_DEEPENING.md` § generic skeleton
- `labsmith/Docs/PLAN_PILLAR_DEEPENING_METHODOLOGY.md` § 2.2 for the C1 concrete primitives

Apply per-app customization in Phase B per `.claude/rules/spm-architecture.md` + `.claude/rules/concurrency.md` (mark Sendable value types `nonisolated`; `@Model` migrations per `.claude/rules/swiftdata.md`).

---

## § 7 — Failure-mode tests

### Universal failure-mode tests (apply to every deepening move)

1. **Cluster-coherence** — does this move work alongside the rest of the Writing-craft / audio cluster recipe? **YES**: cluster § 2.2 top-3 moves include C1; orthogonal to companion moves.
2. **Anti-dilution guard** — does this move push VoiceTale toward 3+ pillars at 2+? **Verify per § 1**: modes.create: depth-at-ceiling; +1 marker for exportable artifact.
3. **ForgeKit version verification** — was `forgekit/Docs/CHANGELOG.md` actually pulled + read? **YES**: 0.94.0 verified; primitives shipped + APIs match.
4. **Asset consumer audit** — at least one view actually renders the move surface. **PHASE C CHECKPOINT** (grep above).
5. **Score-delta accuracy** — does the proposed score delta match methodology § 2.2? **YES**: documented above.

### Move-specific failure-mode tests (C1)

6. **Audio format conformance test**: exported file is canonical 44.1kHz mono 16-bit PCM CAF (verify with `afinfo`).
7. **Length-cap enforcement test**: recordings capped at the Phase A duration.
8. **Storage management test**: 100+ recordings doesn't break app launch time per `.claude/rules/swiftdata.md` perf rules.
9. **Parent-share COPPA gate**: external-share routes through `ParentalConsentService`.
10. **Mic-permission graceful degradation**: kid can use the app without mic permission (just can't record).
11. **Background-audio test**: recording pauses correctly when app backgrounds; doesn't corrupt the file.
12. **No-voice-cloning test**: kid's voice is never used to synthesize cast voices.

---

## § 8 — Cross-references

### Labsmith
- `Docs/PLAN_PILLAR_DEEPENING_METHODOLOGY.md` § 2.2 (C1 move definition)
- `Docs/AUDIT_PILLAR_DEEPENING_PER_APP.md` § 2.2 + per-app row for voicetale
- `Docs/AUDIT_PORTFOLIO_PILLAR_TAGGING.md` — current pillar profile
- `Docs/RESEARCH_DISTRIBUTED_NARRATIVE_PORTFOLIO_EXPANSION.md` — DN methodology + cluster cast roster
- `Docs/REGISTRY_PORTFOLIO_CHARACTER_NAMES.md` — canonical cast registry (if cross-app cameos involved)
- `.claude/rules/forgekit.md` — ForgeKit module reference
- `.claude/rules/swiftdata.md` — schema versioning rules
- `.claude/rules/ai-content.md` — validate-first AI tone rule
- `.claude/rules/distributed-narrative.md` — DN methodology rules (writing-craft / audio cluster)
- `.claude/rules/portfolio.md` — Asset Consumer Audit rule + asset-delivery handoff rule

### App repo
- `Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` — cast roster + per-primitive embodiment
- `Docs/HANDOFF_FROM_LABSMITH_DN_ENHANCEMENT.md` — second-pass DN
- `Docs/IMPLEMENTATION_HANDOFF.md` — Phase 1 scaffolding baseline
- `Docs/TECHNICAL_DESIGN.md` — domain models reference
- `CLAUDE.md` — app overview + 18-section template

### ForgeKit
- `forgekit/Docs/CHANGELOG.md` — version log (currently 0.94.0)
- relevant modules per § 4 above

### External research
- Resnick *Lifelong Kindergarten* — Projects-not-Exercises
- Kafai & Burke *Connected Code* — sharing as part of learning
- Maker-movement bias-toward-action (Halverson & Sheridan 2014)

---

## § 9 — Sequencing for app session

1. **Read this handoff in full** (15 min)
2. **Read methodology** in `labsmith/Docs/PLAN_PILLAR_DEEPENING_METHODOLOGY.md` § 2.2 for C1 (15 min)
3. **Read Writing-craft / audio cluster recipe** in `labsmith/Docs/AUDIT_PILLAR_DEEPENING_PER_APP.md` § 2.2 (5 min)
4. **Verify Phase 1 scaffolding** is complete (Xcode project + `Libraries/Package.swift` present)
5. **Pin ForgeKit** `from: "0.94.0"` in `Libraries/Package.swift`
6. **Plan-mode session** (30-45 min) — work through Phase A design questions
7. **Phase A** → **Phase B** → **Phase C** → **Phase D** per § 5
8. **Asset Consumer Audit** at Phase C checkpoint (grep + render verification per `.claude/rules/portfolio.md`)
9. **Mark handoff CLOSED**

### Post-completion checklist

- [ ] Build zero errors zero warnings
- [ ] Unit tests pass per § 7 failure-mode tests
- [ ] UI tests pass: per-move surfaces
- [ ] CLAUDE.md § 9 Things-That-Will-Bite-You updated with move-specific gotchas
- [ ] FEATURE_PLAN.md sub-phase marked complete
- [ ] `apps.generated.ts` modes score updated by labsmith per § 3 score-delta

---

## § 10 — Labsmith follow-up after app session ships

1. Labsmith updates `apps.generated.ts` VoiceTale modes score per § 3
2. Labsmith updates `AUDIT_PILLAR_DEEPENING_PER_APP.md` row — mark `next_step` as "Adopted YYYY-MM-DD"
3. Labsmith files cluster-wave-2 inbound for next-app in the Writing-craft / audio cluster (if any remain)
4. If pilot reveals a gap in methodology, labsmith updates `PLAN_PILLAR_DEEPENING_METHODOLOGY.md` § 2.2

---

**End of pillar-deepening handoff.**

**Wave status**: Round 82 #425 Wave 1 — Writing-craft / audio cluster batch. Per-app sessions begin implementing post-handoff once Phase 1 scaffolding lands.
