---
status: ACTIVE-AWAITING-LABSMITH-ASSETS
date: 2026-06-21
last-updated: 2026-06-24 (consumer-side SCAFFOLD wire-up shipped via PR-E of the TENTH round — TraditionAudioCatalog resolver + gated play affordance + 10 scaffold tests)
direction: app → labsmith
intent: request 5 short public-domain or community-licensed audio CAFs (1 per Phase 1 tradition entry) for VoiceTale's tradition layer
freshness-horizon: 60 days
---

# Handoff from App — Tradition audio samples (Phase 1 ship-blocker)

Direction: **voicetale-app → labsmith**. Phase 1 exit criterion in `Docs/FEATURE_PLAN.md` (line 28 + line 62) requires *"1 audio sample per tradition (licensed or public-domain CAF)"* bundled into `Packages/Libraries/Sources/Services/Resources/Traditions/` for the `TraditionGalleryView` playback flow. The 5 `traditions.json` entries currently ship with `audioSampleFilename: null` — the catalog schema is in place; only the assets are pending.

Per `.claude/rules/portfolio.md` § Asset generation ownership (2026-05-19 standing rule, reinforced R410 #888): **labsmith owns portfolio-wide asset generation — ALL asset classes, no exceptions, including audio**. The audio pipeline is labsmith-owned; the app session files the request via this handoff.

## What we need

5 audio CAFs, one per tradition entry. Per `.claude/rules/audio-pipeline.md` portfolio convention: **44.1 kHz mono 16-bit PCM CAF**, ~10-30s each, suitable for kid-readable playback in a 9-14-year-old register.

| Slug | Tradition | Source-community attribution required | Duration target | Content character |
|---|---|---|---|---|
| `griot` | West African oral storytellers (Mandé peoples) | YES — Mandé / Mali / Senegal / Gambia / Guinea / Mauritania | 15-25s | Spoken-word excerpt OR kora-accompanied phrase, public-domain or community-licensed |
| `indigenous-american-oral-history` | Turtle Island oral histories — specific Indigenous nations | **HARD REQUIRED — sensitivity gate per ADR-016 + ADR-020** | 15-25s | NOT a story (those belong to the nations); a TEACHER speaking ABOUT the tradition is the safer pattern; OR a permissioned excerpt from a publicly-distributed teaching recording with explicit nation credit |
| `seanchai` | Irish storytellers (Irish-speaking communities) | YES — Ireland / Gaeltacht | 15-25s | Public-domain seanchaí recording (RTÉ / Irish Folklore Commission archive material lives in public domain) |
| `rakugo` | Japanese sit-down storytelling | YES — Japan | 15-25s | Public-domain rakugo performance excerpt (NHK World / older masters whose recordings are out of copyright) |
| `slam-poetry` | Modern slam poetry | YES — credit specific poet + venue | 15-25s | Permissioned excerpt OR Creative-Commons-licensed slam piece with attribution |

## Bundling target

Place CAFs at `Packages/Libraries/Sources/Services/Resources/Traditions/audio/<slug>.caf`. Update `traditions.json` per entry: replace `"audioSampleFilename": null` with `"audioSampleFilename": "audio/<slug>.caf"`. The existing `TraditionCatalogLoader` already reads `audioSampleFilename`; the `TraditionGalleryView` row will get a play affordance once the field is non-null.

## Trauma-informed + cultural-respect constraints (load-bearing)

Per `.claude/rules/trauma-informed-content.md` + `.claude/rules/distributed-narrative.md` § Cultural-sensitivity gates:

1. **Indigenous American oral history** — the sample audio MUST credit a specific nation + MUST NOT retell a sacred story that belongs to that nation. Safer pattern: a teaching-about-the-tradition excerpt from a publicly-distributed educator from the community, OR a permissioned recording with explicit nation credit. This entry is the highest-stakes of the 5; if a clean source can't be found, **ship the entry with `audioSampleFilename: null` permanently** and let the explainer carry the experience.
2. **Griot** — never frame as a "kids' costume." The CAF's accompanying caption (rendered by `TraditionGalleryView`) credits the Mandé peoples.
3. **All entries** — `culturalCreditNote` text already authored in `traditions.json` (per `ADR-016 standing approval` annotation atop the file). Audio captions can re-use the existing credit notes.

## What's NOT in scope

- Voice cloning / TTS synthesis of any tradition (load-bearing — see `.claude/rules/trauma-informed-content.md` § ADR-016 anti-evangelism + audio-axis discipline). All audio must be **real recordings** sourced from public-domain archives or community-licensed material.
- Kid-recorded synthetic "tradition voices" — the app does NOT ask kids to perform a tradition.
- Background music underneath the spoken excerpt — keep it spoken-word-clean per `.claude/rules/audio-pipeline.md`.

## State at this handoff's commit

- `Packages/Libraries/Sources/Services/Resources/Traditions/traditions.json` — 5 entries shipped (PR #24); each entry currently has `"audioSampleFilename": null`
- `TraditionCatalogLoader.swift` — Phase 1 loader; ready to consume the audio filename when present
- `TraditionGalleryView.swift` — Phase 1 grid; play affordance is wired (PR-E TENTH round) but silently absent until catalog returns a non-nil URL — kid never sees a broken-when-tapped button
- `Services/TraditionAudioCatalog.swift` — NEW PR-E (TENTH round): conservative-hide resolver — returns `nil` for nil / empty / whitespace / unknown / unbundled filenames. Pure-function + `nonisolated`. 10 scaffold tests lock the conservative-hide contract + the "hasPlayableSample == false for every shipped entry" invariant so the gallery's play-affordance gate stays inert until a CAF lands.

## Sequencing to unblock

1. Labsmith authors a `Docs/RESEARCH_TRADITION_AUDIO_SOURCING.md` planning doc identifying candidate public-domain / community-licensed sources per tradition + any access fees
2. Labsmith routes the Indigenous-American entry through `ADR-020` audio-trauma-gating discipline (per-app pre-listen audit + cultural-credit + descendant-community respect per `.claude/rules/distributed-narrative.md` § Cultural-sensitivity gates)
3. Labsmith generates / sources / licenses the 5 CAFs
4. Labsmith files `HANDOFF_FROM_LABSMITH_TRADITION_AUDIO.md` in this repo enumerating what shipped + which entries got non-null `audioSampleFilename` updates
5. App session updates `traditions.json` filenames + verifies `TraditionGalleryView` playback flow + adds a unit test for the loader's audio-filename decode

## What this doc does NOT cover

- The recording controls for kid-told tales (already shipped per `AudioRecorder` / `RecordingControlsView`)
- Bramble's voice (the AI listening coach — no TTS; reads via `BrambleReflectionView`'s text presentation)
- DN-S cast voicing (covered by `HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` Move D — text-only voicing via `CastDialog`; no audio synthesis)

## Cross-references

- `Docs/FEATURE_PLAN.md` § Phase 1 Data Layer + Tradition Layer (lines 28, 62 — the two ship-blocker rows)
- `Docs/IMPLEMENTATION_HANDOFF.md` § 6 — Bundled tradition layer ship requirement
- `Packages/Libraries/Sources/Services/Resources/Traditions/traditions.json` — current catalog
- `Packages/Libraries/Sources/Services/TraditionCatalogLoader.swift` — current loader
- `Packages/Libraries/Sources/AppFeature/TraditionLayer/TraditionGalleryView.swift` — current view
- `.claude/rules/portfolio.md` § Asset generation ownership — labsmith ownership
- `.claude/rules/trauma-informed-content.md` § ADR-016 + ADR-020 — trauma-gated audio + cultural-respect discipline
- `.claude/rules/distributed-narrative.md` § Cultural-sensitivity gates — Indigenous TEK + cultural-credit rules
- `.claude/rules/audio-pipeline.md` — portfolio audio CAF conventions
