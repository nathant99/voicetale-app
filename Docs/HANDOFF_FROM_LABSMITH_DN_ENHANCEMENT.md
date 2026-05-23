# Handoff from Labsmith — Distributed-Narrative ENHANCEMENT (Layered Methodology)

Direction: **labsmith → voicetale-app**. Companion to (not replacement of) the 2026-05-22 `HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` (Wave 9). Expands the named cast from 4 LESSONS-layer + Bramble mentor → 7 (4 LESSONS preserved + 2 net-new cluster-shared WORLD-layer voice-register characters + 1 optional flag). Bramble remains the protagonist + listener-anchor (Pattern B preserved with VoiceTale's listener-inversion intact).

**Status**: Specification handoff. Phase D asset generation INHERITED from LyricForge handoff #304 — VoiceTale consumes 2 of the 4 cluster-shared WORLD-layer assets (Heralda + Vesperline) at **$0 marginal cost**. Existing 4-character LESSONS-layer cast assets (Lean / Slow / Pivot / Refrain) PRESERVED — no regeneration required. **Optional Narrator META char defer recommended (see § 3.3) — net cluster cost target: $0.**

**Round**: 59 · **Queue item**: #318 · **Date**: 2026-05-23 · **Wave**: Writing-craft cluster layered-DN Wave 1, Session 2
**Source plan**: `labsmith/Docs/PLAN_DN_ENHANCEMENT_WRITING_CRAFT_CLUSTER.md` (queue #279)
**Cluster-canonical asset-gen handoff**: `lyricforge-app/Docs/HANDOFF_FROM_LABSMITH_DN_ENHANCEMENT.md` (queue #304 — generates the 4 cluster-shared WORLD-layer characters; VoiceTale inherits 2 of the 4)
**Methodology spec**: `labsmith/Docs/GUIDE_DISTRIBUTED_NARRATIVE_METHODOLOGY.md` + `labsmith/Docs/PLAN_GAMBITTALES_DN_ENHANCEMENT.md` (Storytime-Chess-inspired layered methodology)
**Previous handoff**: `Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` (Wave 9, 2026-05-22 — Bramble + 4-char LESSONS-layer cast: Lean / Slow / Pivot / Refrain)

---

## 1. Why layered-DN now (Pattern B note — with listener-inversion preserved)

VoiceTale's Wave-9 retrofit shipped Bramble + 4 oral-craft LESSONS-layer companions (Lean / Slow / Pivot / Refrain — embodying hook / pacing / turn / callback). Labsmith's 2026-05-22 study of the user-provided **Storytime Chess** curriculum surfaced a more complete narrative architecture: alongside LESSONS-layer characters embodying *what is being taught*, a **WORLD-layer** can personify *the medium in which the teaching happens* — for oral storytelling, that medium is the **voice register** the teller adopts when narrating (the same Northrop Frye / Aristotle taxonomy: Epic / Lyric / Comic / Tragic, refracted through ORAL form).

**VoiceTale is about narrative voice — the register in which a tale gets TOLD (not written).** Heralda's epic-bardic register and Vesperline's tragic-pastoral register are the two most-narratively-coded archetypes in oral form: epic-bardic IS the foundational oral tradition (Homer, griot praise-song, Celtic seanchaí mythic-cycle); tragic-pastoral IS the elegiac register of grief-tales + memorial-stories. Murmur (lyric-confessional) and Quip Goodfellow (comic-vernacular) are SECONDARY — they appear as cameo-referenced rather than as native VoiceTale cast (lyric-confessional fits LyricForge/HaikuQuest better; comic-vernacular fits DialogueQuest/CharacterForge better). VoiceTale consumes 2 of the 4 cluster-shared WORLD chars.

**Critical: VoiceTale is a Pattern B app with a UNIQUE listener-inversion** per `.claude/rules/distributed-narrative.md` § Hero mascot vs. cast + § 3 of the Wave-9 retrofit. Bramble stays the PRIMARY PROTAGONIST + LISTENER-ANCHOR. The WORLD-layer characters are explicitly framed as "tellers Bramble brings to the hedgerow fire — tellers whose own narrative voice exemplifies one register." Bramble walks the kid around to listen to each register; Bramble is still the EAR (the listener), the WORLD chars are GUEST TELLERS who tell short demo-tales in their native register. The kid is still always the protagonist-teller; Bramble + LESSONS cast + WORLD chars are all variations on the audience role.

**Why this listener-inversion still works with WORLD chars added**: in oral form there's a structural distinction between THE TELLER and THE TELLING-VOICE. The kid is always the teller. The WORLD chars are personified tellings — they demonstrate "this is how a heroic register sounds when said aloud," "this is how a tragic register sounds when said aloud." Bramble's listener-anchor role is preserved because Bramble listens to the WORLD chars' demo-tales WITH the kid, then reflects with the kid on what the kid heard. The triad is: kid-as-teller, WORLD-chars-as-exemplar-tellers, Bramble-as-fellow-listener.

| Layer | Purpose | VoiceTale mapping |
|---|---|---|
| **MENTOR (= hero in Pattern B)** | Bramble — AI listening coach + on-screen protagonist + listener-anchor; hero doubles as mentor | Bramble (PRESERVED — chunky-cartoon thornbush sprite with one big curious eye + tiny ear-leaf; receptive-listener register) |
| **LESSONS layer** | One character per oral-craft primitive (hook / pacing / turn / callback) | Lean / Slow / Pivot / Refrain (PRESERVED — Wave 9 retrofit) |
| **WORLD layer** | One character per voice register the tale is TOLD in | NEW — 2 of the 4 cluster-shared voice-register archetypes (Heralda primary; Vesperline secondary). Murmur + Quip Goodfellow SKIPPED for VoiceTale-native cast — referenced as kit-13+ cross-app cameos via LyricForge / DialogueQuest sibling reference |
| **META layer** | NOT USED in VoiceTale per default (see § 3.3) | — |

The methodology test for adding a WORLD layer (`PLAN_DN_ENHANCEMENT_WRITING_CRAFT_CLUSTER.md` § 1.4):

1. **Voice register is pedagogically load-bearing in oral form?** ✅ Epic-bardic IS the foundational oral tradition; tragic-pastoral IS the elegiac oral register; tellers shift register as they tell. Register is the medium of oral form.
2. **Working-memory ceiling allows expansion?** ✅ VoiceTale at 5 cast (Bramble + 4 LESSONS) — adding 2 WORLD characters lands at 7 visible characters, well under the 14-character methodology ceiling.
3. **Cluster-shared cross-app coherence?** ✅ Heralda appears in LyricForge / CharacterForge / DialogueQuest / VoiceTale + others — kids meet the same archetype across forms (and across written-vs-oral).
4. **Pattern B + listener-inversion preserved?** ✅ Voice-register characters are GUEST TELLERS Bramble brings to the hedgerow fire; they appear at most 1 per kit; Bramble is the primary listener in every kit (16/16). Density rule per § 4. The kid is always the protagonist-teller.

Net cast: **5 → 7 visible characters** (Bramble + 4 LESSONS + 2 WORLD). Tight density preserves Bramble's listener-anchor register.

**Why only 2 of the 4 cluster-shared WORLD characters?**
- **Heralda (Epic)** PRIMARY — epic-bardic IS oral storytelling's foundational register (Homer, griot, seanchaí mythic cycle); Heralda is the natural register-anchor for the bardic-tradition kits (9 + 11)
- **Vesperline (Tragic / Pastoral)** SECONDARY — elegiac oral tradition (memorial telling, grief-tales, the imperfect-past register); Vesperline anchors the deeper-register kits (12 — Indigenous oral histories + cultural-elegy-handling)
- **Murmur (Lyric)** SKIPPED for native cast — lyric-confessional fits the written-page lyric forms (LyricForge / HaikuQuest) more naturally than the oral form. Murmur MAY appear in kit-13+ cross-app cameos referencing LyricForge.
- **Quip Goodfellow (Comic)** SKIPPED for native cast — comic-vernacular is more native to written dialogue (DialogueQuest) and stand-up comedy (JestForge) than to oral storytelling tradition. Quip MAY appear in kit-13+ cross-app cameos via DialogueQuest.

---

## 2. State at this handoff's commit

Already shipped to VoiceTale:

- **Bramble** as the AI listening coach AND on-screen protagonist + listener-anchor (per `Docs/CONTENT_STYLE_GUIDE.md` [pending Tier-2 doc authorship] — receptive-listener register; thornbush sprite + ear-leaf coding)
- **4 LESSONS-layer cast** (Lean / Slow / Pivot / Refrain) per `Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md`
- **Bootstrap-stage Docs/** (Tier-2 docs pending labsmith authorship per Wave 9 retrofit § 2)
- **AdventureHub Level-1 config**: Voice Studio zone (planned)

Not yet shipped: any of the 2 net-new WORLD-layer cluster-shared characters. This handoff is a layered ADDITION on top of the existing Wave-9 cast.

---

## 3. The 2 net-new WORLD-layer characters (cluster-shared, inherited) + optional META

Each WORLD character follows the labsmith chunky-cartoon aesthetic per `labsmith/Docs/DESIGN_AVATAR_AESTHETIC.md` (Toca-Boca / Animal-Crossing register; bold `#2A1F1A` outlines; warm flat-vector fills). VoiceTale's hero color (`#1B7B8C` ocean teal) provides the hedgerow-fire palette overlay; the WORLD-layer characters themselves are PALETTE-NEUTRAL chunky-cartoon human-coded figures (NOT animal-coded — distinct from LESSONS-layer's badger/tortoise/owl/mockingbird cast). This is intentional — WORLD-layer chars read as "older mentor-friends Bramble brings to the hedgerow fire to tell short demo-tales"; LESSONS-layer reads as "woodland creatures gathered around the fire who listen alongside Bramble."

### 3.1 WORLD layer (2 net-new — cluster-shared inherited assets)

| Slug | Name | Voice register | Personality + voice | Static catchphrase (≤8 words) | First kit |
|---|---|---|---|---|---|
| `voice_epic` | **Heralda the Loud** | Epic / High Heroic | Bard-warrior who tells of mighty deeds across long ages. Speaks in third-person omniscient. Carries a traveling drum. **NATIVE to oral form** — epic-bardic IS oral storytelling's foundational register; Heralda is the foundational guest-teller in the bardic-tradition kits. Anchors heroic-register demo-tales (Beowulf-pattern, Homeric-pattern, griot-praise-song-pattern). | _"And SO the great tale begins."_ | Kit 3 |
| `voice_tragic` | **Vesperline** | Tragic / Pastoral | Twilight-walker who tends grief and longing without sentimentality. Speaks in the imperfect past. Carries a small lit lantern. Anchors elegiac-register demo-tales (memorial telling, grief-tales, imperfect-past register). | _"It was. And then it wasn't."_ | Kit 9 |

**Both characters are CLUSTER-SHARED** — identical assets to LyricForge / HaikuQuest / CharacterForge / DialogueQuest / etc. (per `lyricforge-app/Docs/HANDOFF_FROM_LABSMITH_DN_ENHANCEMENT.md` § 3.2 visual prompts). Bundle path: `labsmith/Branding/Cluster/WritingCraft/voice_epic.webp` + `voice_tragic.webp`.

**Listener-inversion preserved**: Heralda + Vesperline don't speak via FoundationModels in their own voice. They appear with their static catchphrase + a SHORT scripted demo-tale (≤3 lines) that Bramble listens to alongside the kid. The kid then hears Bramble reflect on what they heard — kid practices their own register-variant. Heralda + Vesperline NEVER ask the kid to perform; they perform briefly so the kid can hear the register, then exit.

### 3.2 Cultural-sensitivity gate (preserved + extended)

VoiceTale's Wave-9 retrofit established a HIGH cultural-sensitivity bar (kit 12 Indigenous American Oral Histories requires external Indigenous-community sensitivity reviewer; kits 9-11 RECOMMENDED reviewers). The WORLD-layer addition extends + clarifies:

1. **Heralda is NOT a tradition-holder.** Heralda's epic-bardic register is the STRUCTURAL register (third-person-omniscient narration with grand stakes); she is NOT West African griot, Irish seanchaí, Japanese rakugo, Indigenous American oral historian, or any specific named tradition's teller. Cultural traditions remain attributed to source communities in kit framing copy via Bramble's voice; Heralda demonstrates the structural register only.
2. **Vesperline is NOT a tradition-holder.** Same rule. Vesperline's tragic-pastoral register is structural; she does not embody specific cultural traditions of elegy-telling.
3. **Kit 12 Indigenous-American-oral-histories framing remains GATED on external sensitivity reviewer.** Vesperline's appearance at kit 9 (earlier in the tradition arc) does NOT bypass the kit-12 review gate. Reviewer sign-off is required before the WORLD chars appear in tradition-layer kits.
4. **The cast NEVER tells stories FROM specific traditions.** Heralda's demo-tales are GENERIC heroic-register stories ("AND SO the great storm came. The villagers gathered. The hero spoke."); they reference no specific culture's hero-cycle. Vesperline's demo-tales are GENERIC tragic-pastoral stories ("It was. And then it wasn't. The lantern dimmed."); they reference no specific culture's elegy tradition.
5. **All tradition-specific content stays with Bramble's framing copy.** Bramble attributes the griot tradition to specific West African communities; the seanchaí tradition to specific Irish communities; etc. The WORLD chars demonstrate structural register; Bramble situates that register within specific traditions.

### 3.3 Optional META character — Narrator (RECOMMEND DEFER)

The task spec proposes an optional **Narrator** META character (the unreliable-narrator / authorial-voice primitive — ~$0.27 if added). Labsmith's recommendation: **DEFER this addition.** Rationale:

1. **VoiceTale's listener-inversion already covers the META stance.** In oral form, the META question is "who is telling this tale, and from what perspective?" — but Bramble's listener-anchor role already surfaces this. When Bramble listens to the kid's tale, Bramble's reflection IS the META stance ("I heard you tell that as if you were inside the moment — was that what you wanted me to hear?"). Adding a Narrator character would duplicate Bramble's META function.
2. **Pattern B + listener-inversion is a CRITICAL design property.** Adding a Narrator character risks displacing Bramble's listener-anchor — the Narrator-as-authorial-voice would compete with Bramble for the "who is reflecting on the tale" slot.
3. **Cluster plan § 3 puts no META char in VoiceTale's default cast.** The cluster-shared META archetypes (Editor Penn / Audience Aria) are reserved for written-form apps where editorial-revision or audience-reception is load-bearing META. VoiceTale's META is structurally different — it lives in Bramble's listener-anchor role.
4. **Cost: $0.27 saved.** Marginal cost saved is small but cumulative across cluster.

**If the implementing session disagrees** — i.e., finds in kit 11-12 that an unreliable-narrator / multiple-perspective META char would surface oral-form META in a way Bramble can't — file `HANDOFF_FROM_APP_NARRATOR_META_ADDITION.md` and labsmith will reconsider. Default plan: skip Narrator; preserve listener-inversion.

### 3.4 Cluster-shared asset strategy

**VoiceTale INHERITS cluster-shared WORLD-layer assets from LyricForge handoff #304** (the canonical first-generation site). Heralda + Vesperline WebPs are generated ONCE in LyricForge's Phase D wave (~$1.08 cluster-total for all 4 voice-register archetypes including Murmur + Quip Goodfellow which VoiceTale doesn't consume natively).

- Asset path: `labsmith/Branding/Cluster/WritingCraft/voice_epic.webp` + `voice_tragic.webp`
- Per-app distribution: `scripts/copy_cluster_assets_to_repos.sh --cluster writing-craft --app voicetale` copies the 2 WebP files into `voicetale-app/Docs/HandoffAssets/distributed_narrative_v2/cluster_shared/`
- VoiceTale's `IllustrationRegistry.register(...)` resolves `voice_epic` and `voice_tragic` to the canonical WebPs via `ForgeIllustrations` multi-bundle resolution
- **VoiceTale's marginal asset cost: $0** (inheritance only; Narrator META deferred — see § 3.3)

This compounds Bruner narrative learning across the cluster — kids meet the same Heralda archetype in LyricForge (kit 7 epic-as-meta-narrative), CharacterForge (kit 4 epic-coded characters), DialogueQuest (kit 5 epic-register dialogue), VoiceTale (kit 3 epic-bardic oral tradition) — and consolidate the Epic register as a stable concept across forms AND across written-vs-oral modes.

### 3.5 Cast access pattern — suggested Swift API (advisory only)

The implementing session has final say on naming + access patterns. Labsmith does not write Swift. The shape below is a suggestion based on the methodology spec.

```swift
public enum VoiceTaleCharacter: String, CaseIterable, Sendable {
    // Hero / mentor (PRESERVED)
    case bramble                // hero mascot + AI listening coach + listener-anchor

    // LESSONS layer (PRESERVED — Wave 9)
    case lean                   // hook / leanability
    case slow                   // pacing
    case pivot                  // turn
    case refrain                // callback

    // WORLD layer (NEW — cluster-shared assets)
    case voiceEpic              // Heralda the Loud — epic/heroic register
    case voiceTragic            // Vesperline — tragic/pastoral register

    public var layer: Layer { /* .hero | .lessons | .world */ }
    public var catchphrase: String? { /* static for cast; nil for Bramble (FoundationModels) */ }
    public var assetSlug: String { /* resolves to cluster-shared bundle for .world cases */ }
    public var role: Role { /* .listener (Bramble) | .lessonsListener (LESSONS) | .guestTeller (WORLD) — preserves listener-inversion */ }
}

public enum Layer: String, Sendable {
    case hero, lessons, world
}

public enum Role: String, Sendable {
    case listener           // Bramble — the primary listener-anchor
    case lessonsListener    // Lean / Slow / Pivot / Refrain — listeners with one craft-primitive each
    case guestTeller        // Heralda / Vesperline — short demo-tales in their register, then exit
}
```

7 cast entries total (1 hero + 4 LESSONS + 2 WORLD). The `Role` discriminator preserves VoiceTale's listener-inversion in code.

### 3.6 Collision check

Grepped `labsmith/Docs/REGISTRY_PORTFOLIO_CHARACTER_NAMES.md` + Wave 1-58 shipped DN handoffs on 2026-05-23:

- **Heralda** — no collision (cluster-shared reservation, registered via LyricForge handoff #304)
- **Vesperline** — no collision (cluster-shared reservation, registered via LyricForge handoff #304)

Both names available. Cluster-shared registration handled in LyricForge handoff #304 — VoiceTale's REGISTRY entry references the cluster-shared reservation as a CONSUMER, not a re-registration.

---

## 4. Kit-recurrence schedule (16-kit pacing, Pattern B density caps + listener-inversion)

Per `GUIDE_DISTRIBUTED_NARRATIVE_METHODOLOGY.md` + Pattern B pacing rule (`PLAN_DN_ENHANCEMENT_WRITING_CRAFT_CLUSTER.md` § 4.1):

- **Every kit features Bramble** (16/16) — Bramble is the through-line + listener-anchor
- **WORLD-layer characters appear at most 1 per kit** in kits 1-9; potential pairing in kit 12 if tradition layer permits
- **LESSONS-layer characters appear at most 2 per kit** — preserved from Wave 9 retrofit
- **Density rule**: max 3 cast members visible per kit; cast fades by kit 12 (Wave 9 schedule preserved)
- **Listener-inversion preserved**: WORLD chars appear as GUEST TELLERS who briefly perform their register, then exit; Bramble + the kid remain the listener-anchor + the protagonist-teller respectively

### 4.1 Introduction schedule

| Kit | Topic (approx) | New character(s) introduced | Returning cast | Notes |
|---|---|---|---|---|
| 01 | Record-a-Tale Basics — Hook + 60-second tale (gr 4-5) | Bramble re-intro · Lean (PRESERVED Wave 9) | — | Hook + leanability anchor preserved |
| 02 | Hook Deepening — first-5-seconds craft (gr 4-5) | — | Bramble, Lean | LESSONS-focal |
| 03 | Setup + Rising Action — beats 2+3 (gr 4-5) | **Heralda the Loud** (Epic register) | Bramble, Lean | Heralda enters at the setup/rising-action work — epic-bardic IS the foundational sustained-rising-action register; Heralda demonstrates "AND SO the great storm came. The villagers gathered. The hero spoke." — a 3-line demo-tale showing setup + rising in epic register |
| 04 | 5-Beat Arc — Pacing (gr 5-6) | Slow (Wave 9 intro) | Bramble, Lean, Heralda | LESSONS-focal — pacing introduced; Heralda's demo-tale from kit 3 reflected on as a pacing exemplar |
| 05 | Voice-Character Mode — Multi-Voice Recording (gr 5-6) | — (**kid-led**, preserved Wave 9) | Bramble, Slow, Lean | **CRITICAL preserved**: no cast-member voice-exemplar in this kit; kid records own voices; Bramble + LESSONS cast LISTEN; Heralda is RESTING this kit (no WORLD-char demonstration in voice-character work — voice-character is the kid's own invention) |
| 06 | Pacing Synthesis — multi-tempo tales (gr 6-7) | — | Bramble, Slow (lead), Lean, Heralda | Heralda returns; her epic-register demo-tale from kit 3 re-listened to, this time for tempo analysis |
| 07 | The Turn — Beat 4 Craft (gr 6-7) | Pivot (Wave 9 intro) | Bramble, Lean, Slow, Heralda | LESSONS-focal — turn introduced; Heralda's bardic-register turn ("...AND THEN — everything shifted") demonstrated |
| 08 | Turn Synthesis — multi-tale turn practice (gr 6-7) | — | Bramble, Pivot (lead), Slow, Lean | LESSONS-focal |
| 09 | Tradition Layer — West African Griot + epic-bardic tradition (gr 6-7) | **Vesperline** (Tragic / Pastoral register) | Bramble, Pivot, Heralda | Griot tradition attributed via Bramble's framing copy; Heralda's epic-bardic register exemplifies griot praise-song STRUCTURE (Bramble explicitly notes Heralda is NOT a griot — she demonstrates the structural register). Vesperline enters at the elegiac-register intro — kit 9 also touches on griot mourning-songs in tradition copy |
| 10 | Callbacks + Refrains — Oral Repetition Craft (gr 6-7) | Refrain (Wave 9 intro) | Bramble, Pivot, Vesperline | LESSONS-focal — callback introduced; Vesperline's "It was. And then it wasn't." as a tragic-callback exemplar |
| 11 | Tradition Layer — Irish Seanchaí + Japanese Rakugo (gr 6-7) | — | Bramble, Refrain (lead), Heralda | Seanchaí + rakugo traditions attributed; Heralda's epic-register revisited as seanchaí-mythic-cycle exemplar (structural register only — Heralda is NOT seanchaí) |
| 12 | Tradition Layer — Indigenous American Oral Histories (gr 7-8) | — (**fading kit + REQUIRED-reviewer kit, Wave 9 preserved**) | **Bramble + full ensemble final appearance — Heralda + Vesperline as last guest-tellers + LESSONS cast as last listeners** | **External Indigenous-community sensitivity reviewer REQUIRED before this kit's framing copy is finalized.** Heralda + Vesperline appear ONLY in the structural-register reflection segment (Bramble: "remember Heralda's epic register? Vesperline's elegiac register? Indigenous American oral history weaves both — but it's THEIR weave, not ours, and we honor it"). Cast farewell |
| 13 | Anthology Building (gr 7-8) | — | Bramble + (cameos only) | Cast faded; kid + Bramble carry the anthology |
| 14 | Cross-Form Experimentation — slam poetry + spoken-word (gr 7-8) | — | Bramble | Pure oral craft |
| 15 | Free-Form Telling — kid invents own form (gr 7-8) | — | Bramble + cross-app cameos | See § 5 |
| 16 | Sharing + Cluster Export (gr 7-8) | — | Bramble + capstone cameos | Cluster handoff |

### 4.2 Appearance count across all 16 kits

| Character | Kits featured | Frequency tier |
|---|---|---|
| Bramble | 16 / 16 | Always-present (Pattern B + listener-anchor requirement) |
| Lean | 7 / 16 | High (PRESERVED Wave 9) |
| Slow | 6 / 16 | Moderate (PRESERVED Wave 9) |
| Pivot | 6 / 16 | Moderate (PRESERVED Wave 9) |
| Refrain | 3 / 16 | Moderate-low (PRESERVED Wave 9) |
| Heralda the Loud | 6 / 16 | Moderate (NEW WORLD; epic-bardic-tradition kits) |
| Vesperline | 4 / 16 | Moderate-low (NEW WORLD; tragic-pastoral + tradition-layer kits) |

All cast members meet the methodology minimum of 3 kits (`GUIDE_DISTRIBUTED_NARRATIVE_METHODOLOGY.md` § 2 condition 4). No META char = no kit-count flag for that layer.

---

## 5. Cross-app cameo opportunities (kit 13-16 only)

Per Pattern B cameo policy: **all cameos are HERO-voiced** (Bramble narrates the cameo; cluster-shared WORLD characters don't count as cameos when they appear in another writing-craft app — they're cast natively in each app's manifest).

### 5.1 In-cluster cameos (kit 15-16 capstone)

| Sibling app | Sibling character / mascot | Bramble's cameo voicing |
|---|---|---|
| **LyricForge** | Pip (+ Murmur) | _"Pip in LyricForge writes lyrics in Murmur's register — lyric-confessional that doesn't fit easily in oral form. Same register, different medium."_ |
| **HaikuQuest** | Cherry (+ Murmur + Vesperline) | _"Cherry writes seventeen-syllable tales. Vesperline visits her too — the kireji cut IS Vesperline's quiet 'and then it wasn't.' Same elegiac register, miniature form."_ |
| **CharacterForge** | Ink | _"Ink builds characters' voices for the written page; we lift those voices into oral form. Heralda demonstrates the same epic-bardic register Ink works with."_ |
| **DialogueQuest** | Patter (+ Quip Goodfellow + Murmur) | _"Patter works dialogue in written form; Quip Goodfellow lives in DialogueQuest's comic-vernacular register. Our cousin-app — when your tale needs witty banter, Patter and Quip are where you'd practice."_ |
| **TaleForge** | Bram | _"Bram plots the story-arc in written form; we tell it aloud. The arc is the same; the medium shifts."_ |
| **SpeakForge** | Echo | _"Echo in SpeakForge does oral storytelling at a larger scale — auditoriums vs intimate listening at the hedgerow fire. Heralda visits both apps. Same epic register, different audience size."_ |

### 5.2 Stretch cross-cluster cameos (kit 13-14, lighter touch — optional)

| Sibling app | Sibling character | Bramble's cameo voicing |
|---|---|---|
| **MythForge** | (mentor) | _"Heralda lives in MythForge too — epic-bardic register tells mythic-scale tales. Same Heralda, mythic stakes."_ |
| **LoreQuest** | (mentor) | _"LoreQuest does folklore-cycle work; Vesperline's elegiac register appears there too. Our cousin-app for the longer cultural-memory work."_ |

### 5.3 Cameo policy (all clusters)

1. ALL cameos are BRAMBLE-VOICED (Pattern B convention + listener-inversion preserved).
2. Cameos CONSTRAINED to kits 13-16. NEVER kits 1-9.
3. Cluster-shared WORLD characters (Heralda / Vesperline) DON'T count as cameos in sibling writing-craft apps — they're cast natively in each app's manifest.
4. Murmur + Quip Goodfellow (cluster-shared WORLD chars NOT in VoiceTale's native cast) ARE cameos when referenced — Bramble's voicing references them as "characters who live in other apps."
5. Cultural-sensitivity gate preserved — kit 12 review still required; cameos do not bypass the gate.

---

## 6. Assets — delivery plan

### 6.1 Current state

| Asset class | Status | Location |
|---|---|---|
| Bramble mascot (5 poses) | PENDING Wave 9.2 asset gen | `Docs/HandoffAssets/distributed_narrative/` (pending creation) |
| Lean / Slow / Pivot / Refrain PNGs | PENDING Wave 9.2 asset gen | same |

### 6.2 Phase D — Cluster-shared WORLD inheritance

| Asset class | Count | Per-asset cost | Total | Source | Status |
|---|---|---|---|---|---|
| Cluster-shared WORLD (Heralda + Vesperline — both inherited from LyricForge handoff #304) | 2 | $0.00 (inherited) | **$0.00** | LyricForge handoff #304 generates the 4 WORLD chars at $1.08 cluster-total; VoiceTale consumes 2 of 4 at $0 marginal | INHERITED |
| Cluster-shared META — Narrator (RECOMMENDED DEFER per § 3.3) | 0 | $0.27 (deferred) | **$0.00** | Optional addition — implementing session reviews; default plan skips | DEFERRED |
| Regeneration buffer (15% Pro-tier failure rate, ~0 char) | 0 | — | — | budgeted at handoff level | — |
| **VoiceTale marginal Phase D cost** | **0** | — | **$0.00** | — | — |

**Output paths**:

```
labsmith/Branding/Cluster/WritingCraft/
├── voice_epic.png + voice_epic.webp        (Heralda — generated in LyricForge wave)
└── voice_tragic.png + voice_tragic.webp    (Vesperline — generated in LyricForge wave)

voicetale-app/Docs/HandoffAssets/distributed_narrative_v2/cluster_shared/
├── voice_epic.webp              (inherited)
└── voice_tragic.webp            (inherited)
```

Per-app distribution: `scripts/copy_cluster_assets_to_repos.sh --cluster writing-craft --app voicetale` copies both WebP files. The implementing session registers them via `IllustrationRegistry.register(bundle: clusterSharedBundle, slugs: ["voice_epic", "voice_tragic"])`.

### 6.3 Cultural-sensitivity guardrails (WORLD asset audit)

WORLD-layer guardrails inherited from LyricForge handoff #304 § 6.3 + cluster plan § 6.3 + Wave-9 retrofit § 3b (VoiceTale-specific):

1. Heralda's traveling drum is NOT a culturally-specific drum (no djembe, no taiko, no bodhrán) — chunky-cartoon generic-shaped drum
2. Vesperline's lantern is LIT (warmth/hope) — NOT funereal, NOT shadow-coded
3. Neither character carries culturally-specific costuming (no specific tradition's garb)
4. Vesperline's elegiac coding stays gentle — no death-coding, no romanticized melancholy
5. Per cluster plan § 6.3 — gender-presentation inclusive across both archetypes

Reject + regenerate if any fails (handled in LyricForge's generation wave; VoiceTale inherits the audited assets).

---

## 7. Bramble voicing — codified rules for layered cast (Pattern B + listener-inversion)

Per `PLAN_DN_ENHANCEMENT_WRITING_CRAFT_CLUSTER.md` § 9.2 + Wave-9 retrofit § 3. Bramble's existing voice (receptive-listener + warm + thornbush-sprite-coded) is PRESERVED. The layered ENHANCEMENT adds these voicing patterns:

1. **Bramble introduces WORLD-layer characters as guest-tellers, not register-authorities**: "Tonight at the fire, Heralda is visiting. She tells tales in a BIG voice — let's listen." Never "Heralda is the Epic register expert."
2. **Bramble remains the primary listener (≥60% of listening reactions across kits)**. WORLD-layer characters arrive with their static catchphrase + a short scripted demo-tale (≤3 lines); Bramble listens alongside the kid + reflects.
3. **WORLD chars do NOT speak via FoundationModels** — they have ONLY their static catchphrases (≤8 words) + their pre-authored demo-tales. Bramble's `@Generable VoiceStoryReflection` prompts can include `activeVoiceRegisterContext: VoiceRegister?` so Bramble frames reflection by register.
4. **Bramble's Pattern B + listener-inversion preserved**: hero stays primary listener; cast members (LESSONS + WORLD) are explicitly "fire-circle companions" not "experts I defer to." WORLD chars are GUEST TELLERS who briefly perform, then exit; LESSONS chars are listeners-with-a-craft-discipline who listen alongside Bramble.
5. **CRITICAL — WORLD chars are NOT comparison targets for the kid's tales.** Bramble never says "your tale sounded just like Heralda's!" — the WORLD-layer cast teaches register-archetypes through example; the kid's tale is their own. The kid can BORROW register-elements after hearing demo-tales, but Bramble never frames the kid's tale as fitting or failing Heralda's mold.
6. **CRITICAL — WORLD chars are NOT tradition-holders.** Bramble's framing copy explicitly says "Heralda demonstrates the STRUCTURE of an epic-bardic voice; West African griots, Irish seanchaí, Homer all use this structure differently and they own their traditions. Heralda is our exemplar of the structure only."
7. **Listener-inversion preserved in voice-character mode (kit 5)**: WORLD chars are RESTING in kit 5. Voice-character mode is the kid's own invention; no exemplar.

---

## 8. Asset-consumer audit — REQUIRED before closing this handoff

Per `.claude/rules/portfolio.md` § Asset Consumer Audit (standing rule 2026-05-20). When Phase D cluster-shared assets ship and you integrate them:

1. **Grep for consumer call sites** — every new slug must be rendered by at least one view:
   ```
   grep -rE 'IllustrationRenderer|MascotReactionView|VoiceRegisterCard|GuestTellerCard' \
     Libraries/Sources/
   ```
2. **Zero hits = shipped-but-dark** — `IllustrationRegistry.register(bundle: clusterSharedBundle, ...)` alone does NOT mean the asset is visible to users. File a follow-up wiring task before closing the handoff.
3. **Confirm Bramble's per-kit voicing scripts reference each WORLD character** at least once across the 16-kit arc per § 4.1 schedule (Heralda at kit 3 + recur; Vesperline at kit 9 + recur).
4. **NO orphaned registrations** — every registered slug has at least one consumer.
5. **Voice-character mode (kit 5) gate** — confirm WORLD chars are explicitly EXCLUDED from kit 5 framing copy + UI (no Heralda/Vesperline asset rendering in kit 5; preserved as kid-led kit).
6. **Cultural-sensitivity gate (kit 12)** — external Indigenous-community sensitivity reviewer signoff REQUIRED before kit 12 ships with WORLD-char appearances (Heralda + Vesperline appear in structural-register-reflection segment only; reviewer must confirm framing copy.)

---

## 9. Integration tasks (suggested order)

The implementing session owns the implementation. Suggested sequencing (builds on Wave 9 retrofit phases):

1. **Extend `OralCraftCompanion` → `VoiceTaleCharacter`** (or parallel enum with `.layer` + `.role` discriminators per § 3.5) — add 2 new `.world` cases.
2. **Wire static catchphrases + pre-authored demo-tales** into a `Character+Catchphrase` extension + `Character+DemoTale` extension. Catchphrases ≤8 words; demo-tales ≤3 lines each.
3. **Update kit-recurrence map** — extend the Wave 9 map with WORLD-character introductions per § 4.1.
4. **Bramble voicing scripts** — for each (kit, scene) tuple where a WORLD character appears, write Bramble's framing per § 7 rules. Particular care for kit 9 (Heralda framed as structural-register-exemplar, NOT griot) + kit 12 (sensitivity-reviewer gated).
5. **Confirm voice-character mode (kit 5) preserves kid-led design** — WORLD chars must be EXCLUDED from kit 5 UI.
6. **Wait for LyricForge Phase D cluster-shared asset wave** (queue #304). On arrival, register via `IllustrationRegistry.register(bundle: clusterSharedBundle, slugs: ["voice_epic", "voice_tragic"])` and wire through `MascotReactionView` per the consumer-audit standing rule.
7. **Test gates** — every WORLD character has ≥3 kit appearances; every cast member has at least one consumer call site; no cast member appears in kits 13-16 without first being introduced in kits 1-9; voice-character mode (kit 5) has zero WORLD-char assets; kit 12 sensitivity-reviewer signoff documented.

---

## 10. Cross-references

- `labsmith/Docs/PLAN_DN_ENHANCEMENT_WRITING_CRAFT_CLUSTER.md` — cluster plan (queue #279)
- `labsmith/Docs/RESEARCH_DN_LAYERED_ENHANCEMENT_PORTFOLIO_EXPANSION.md` — cluster research input (queue #277)
- `lyricforge-app/Docs/HANDOFF_FROM_LABSMITH_DN_ENHANCEMENT.md` — sibling cluster handoff (queue #304; canonical asset-gen site for the 4 cluster-shared WORLD chars)
- `haikuquest-app/Docs/HANDOFF_FROM_LABSMITH_DN_ENHANCEMENT.md` — sibling cluster handoff (queue #305)
- `characterforge-app/Docs/HANDOFF_FROM_LABSMITH_DN_ENHANCEMENT.md` — sibling cluster handoff (queue #306; canonical first-gen site for Editor Penn)
- `dialoguequest-app/Docs/HANDOFF_FROM_LABSMITH_DN_ENHANCEMENT.md` — sibling Session-2 handoff (queue #317; canonical first-gen site for Audience Aria)
- `inkquest-app/Docs/HANDOFF_FROM_LABSMITH_DN_ENHANCEMENT.md` — sibling Session-2 handoff (queue #319)
- `labsmith/Docs/GUIDE_DISTRIBUTED_NARRATIVE_METHODOLOGY.md` — DN methodology canonical spec
- `labsmith/Docs/REGISTRY_PORTFOLIO_CHARACTER_NAMES.md` — collision-prevention registry
- `labsmith/Docs/DESIGN_AVATAR_AESTHETIC.md` — chunky-cartoon style spec
- `labsmith/.claude/rules/distributed-narrative.md` — portfolio rule (Pattern B preservation)
- `labsmith/.claude/rules/trauma-informed-content.md` — cultural-sensitivity gate (kit 12 reviewer requirement)
- `labsmith/.claude/rules/portfolio.md` § Asset Consumer Audit — required step before closing
- `voicetale-app/Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` — previous handoff (Bramble + 4 LESSONS-layer cast)
- `voicetale-app/CLAUDE.md` — current app state
- `labsmith/Docs/VoiceTale/README.md` — concept doc

---

## 11. Open questions for the implementing session

1. **Cluster-shared asset bundle integration**: same question as LyricForge / HaikuQuest / CharacterForge / DialogueQuest handoffs — do you prefer (a) cross-bundle reference from `Branding/Cluster/WritingCraft/`, or (b) local copy into `Docs/HandoffAssets/distributed_narrative_v2/cluster_shared/`? Default (a).
2. **Optional Narrator META character**: § 3.3 RECOMMENDS DEFER. If you find in kit 11-12 that an unreliable-narrator / multiple-perspective META char would surface oral-form META in a way Bramble's listener-anchor can't, file `HANDOFF_FROM_APP_NARRATOR_META_ADDITION.md` for labsmith review. Default plan: skip Narrator; preserve listener-inversion.
3. **Heralda kit-3 intro vs kit-9 intro**: § 4.1 places Heralda at kit 3 (setup/rising-action work). Alternative: defer Heralda to kit 9 (tradition layer — when she's most contextually-rich for the griot/bardic tradition framing). Default plan: kit 3 (epic-bardic IS the foundational sustained-tale register; introducing Heralda early gives the kid 6 kits of exposure before tradition-layer kicks in). The implementing session has final say.
4. **Vesperline + kit-12 sensitivity-reviewer gating**: § 4.1 places Vesperline in kit 9 (tradition layer entry — Bramble's framing copy attributes elegiac-tradition mourning-songs to griot tradition). Vesperline's appearance in kit 12 (Indigenous American Oral Histories) is REQUIRED-reviewer-gated. Default plan: Vesperline's kit-9 appearance is reviewer-encouraged but not required; kit-11 (seanchaí/rakugo) is reviewer-recommended; kit-12 is reviewer-REQUIRED. Confirm with the founder before any tradition-layer kit ships.
5. **Voice-character mode (kit 5) preservation**: § 7 rule 7 + § 9 step 5 — WORLD chars must be EXCLUDED from kit 5. Verify in UI + framing copy. Test gate: any kit-5 rendering that includes a WORLD-char asset is a regression.
6. **WORLD-character non-tradition-holder rule**: § 7 rule 6 is load-bearing — Heralda and Vesperline are STRUCTURAL register exemplars, NOT tradition-holders. CONTENT_STYLE_GUIDE should codify this explicitly. Test gate: any Bramble-framing prompt that attributes a specific tradition to a WORLD char is a regression.
7. **Murmur + Quip Goodfellow as cross-app cameos**: § 5.1 lists them as cameo-references in kit 15-16. If your cluster-export work in kit 16 surfaces lyric-confessional or comic-vernacular oral traditions (e.g., slam poetry's lyric-confessional register), consider promoting Murmur or Quip to native cast in a future enhancement wave.

Respond via a `HANDOFF_FROM_APP_DN_ENHANCEMENT_REPLY.md` if any of these need labsmith input before you proceed.
