# Handoff from Labsmith — Distributed-Narrative Methodology Retrofit (Wave 9)

Direction: **labsmith → voicetale-app**. Round 45 #195 · 2026-05-22 · Wave 9 of the portfolio-wide distributed-narrative methodology rollout (per `labsmith/Docs/GUIDE_DISTRIBUTED_NARRATIVE_METHODOLOGY.md`). VoiceTale is one of 5 net-new writing-craft cluster apps spawned earlier this session; this handoff lands DN methodology BEFORE Phase 1 begins so the cast wires in from the start. **Special multi-tradition design**: VoiceTale teaches oral storytelling across MANY lineages (West African griot, Indigenous American oral history, Irish seanchaí, Japanese rakugo, modern slam poetry). Per `.claude/rules/trauma-informed-content.md` + `Docs/VoiceTale/README.md` cultural-sensitivity gate, **no character is named after a specific named storyteller from any tradition** — those traditions are foregrounded in kit metadata + framing copy, NEVER mascotized. The cast embodies *oral-craft primitives*, not *tradition-holders*.

## 1. Why VoiceTale gets a DN cast (with the mascot-vs-cast clarification)

VoiceTale already has a hero mascot — **Bramble**, the chunky-cartoon thornbush sprite with one big curious eye and a tiny ear-leaf cocked sideways (listening posture). Bramble is the AI listening coach + protagonist; the learner's relationship is with Bramble. **The DN cast does NOT replace or compete with Bramble.** Following the Wave 7 MotifLab pattern, the cast is formalized as **Bramble's named circle-around-the-fire companions** — each one a worked example of one oral-craft primitive Bramble teaches the kid to hear, feel, and use when telling aloud.

The four-condition adoption test (from `GUIDE_DISTRIBUTED_NARRATIVE_METHODOLOGY.md` § 2):

1. **Finite catalogue of named patterns?** ✅ Oral-storytelling craft decomposes into a small set of teachable primitives: **the hook** (the opening that makes the listener lean in), **pacing** (the deliberate slowing and quickening across the 5-beat arc), **the turn** (the moment the story pivots), **voice-character** (when the teller becomes a character with a different voice), and **the callback** (the recurring tag/refrain that creates the oral-tradition's signature repetition). Each is discriminable in real recordings.
2. **Pattern discrimination is core?** ✅ Every kit asks the learner to identify or build one of these primitives ("where's your hook?" / "did the listener feel the turn?" / "did your old-wise-one voice stay consistent?"). Without character coding, this is rote labeling.
3. **Cast size 4–14?** ✅ Wave 9 stays at **4 supporting characters** (Bramble as hero brings the total to 5). Adding more would compete with Bramble for relational airtime in a voice-first app where the *listener*'s presence is structurally load-bearing.
4. **Patterns recur ≥3 times?** ✅ Each primitive appears across the 16-kit arc (Record-a-Tale Basics → 5-Beat Arc → Voice-Character Mode → Tradition Layer → Anthology). Each companion recurs ≥4 times.

Habgood intrinsic-integration test: **each companion's body and behavior IS the oral primitive they embody**. Lean doesn't *represent* "hook" — she literally leans forward whenever Bramble or the kid starts a story, and the visual lean IS the listener-pulled-in moment a hook creates. Remove the primitive and the character vanishes.

**Special VoiceTale design note**: oral-storytelling lives in the *gap between teller and listener* — without a listener, there is no oral story. Bramble's whole design is **the perfect listener** (one ear-leaf, one big eye, no interruptions). The cast members are *also* listeners by default — they sit around Bramble's hedgerow fire — but each one *demonstrates* one primitive by their listening posture. They are not co-tellers competing with the kid. **The kid is always the teller; Bramble + cast are always the audience.** This inverts the usual mentor-as-performer pattern in a way that's structurally honest to oral form.

## 2. State at this handoff's commit

Already shipped to VoiceTale:

- **Bramble** as the AI listening coach AND mascot (`mascot: Bramble`; thornbush sprite + ear-leaf per `Docs/README.md` + `labsmith/Docs/VoiceTale/README.md`).
- **Ocean teal** hero color (`#1B7B8C`) registered in `REGISTRY_APP_HERO_COLORS.md`.
- **Bootstrap-stage Docs/**: README.md (scaffold), IMPLEMENTATION_HANDOFF.md (placeholder). **Tier 2 docs (TECHNICAL_DESIGN.md / FEATURE_PLAN.md / CONTENT_STYLE_GUIDE.md / TESTING_STRATEGY.md / PERFORMANCE_BUDGET.md / KIDSAFE_PREPARATION.md / DOCUMENT_CATALOG.md) are pending labsmith authorship in a future wave** — this handoff predates the full Tier-2 set.
- **AdventureHub Level-1 config**: Voice Studio zone (planned per `labsmith/Docs/VoiceTale/README.md`).
- **Mentor reconciliation needed**: site `apps.generated.ts` currently lists `"mentor": "Loresinger Mae"` (a stale earlier proposal). Per `Docs/README.md` + concept doc, the canonical AI listening coach is **Bramble** (matching the mascot — Bramble IS the coach). Site PR flips `Loresinger Mae` → **Bramble** in the Wave 9 batch.

Not yet shipped: the 4 supporting cast companions, AND the Tier-2 doc set. This handoff is net-new (introduces the cast before Phase 1 begins — the cast spec can be referenced by the future Tier-2 docs as the canonical source).

## 3. The 4-character oral-craft cast

Each character follows the labsmith chunky-cartoon aesthetic per `labsmith/Docs/DESIGN_AVATAR_AESTHETIC.md` (Toca-Boca / Animal-Crossing register, bold `#2A1F1A` outlines, warm flat-vector fills) adapted to VoiceTale's hero color (`#1B7B8C` ocean teal) — hedgerow-fire palette: teal + warm-cream + ember-amber accents. Cast members read as **woodland creatures gathered around Bramble's hedgerow fire** — each one a worked example of one oral-craft primitive Bramble teaches the kid to use. **All are animals, not human-coded.**

| # | Name | Oral-craft primitive embodied | Personality + voice | Catchphrase | Visual hook | First kit |
|---|---|---|---|---|---|---|
| 1 | **Lean** | **The hook** — the opening line/image/sound that makes a listener lean in (the leanability of the first 5 seconds) | A curious badger-tween who, whenever a story begins, visibly tips her body forward an inch — never claims one hook is "best," only that "I can feel my body decide; I either lean in or I don't" — patient, never-fakes-a-lean | "I lean. Or I don't. Tell me again — does the first sentence MAKE me lean?" | Cream-and-charcoal badger-tween in a small earth-toned vest + a tiny notebook strapped to her chest; whole upper body visibly tilted forward whenever a story is being told; if the hook is weak she gently rocks back to neutral as a soft visual cue | Kit 1 (Record-a-Tale Basics, gr 4-5) |
| 2 | **Slow** | **Pacing** — the deliberate slowing and quickening across the 5-beat arc (Hook 10s · Setup 20s · Rising 30s · Turn 30s · Close 20s); the tempo *is* the storytelling tool | A serene tortoise-elder who carries a small wooden hourglass and whose own movements visibly slow during rising-action and speed up at the turn — never claims fast is bad / slow is good; treats pacing as *a choice you make on purpose* | "Slow on the setup. Faster on the rising. Hold the turn. The story has feet. Walk it on purpose." | Russet-and-cream box-tortoise-elder in a knitted vest + a small wooden hourglass hanging from a leather cord; ambient dotted-line "tempo trail" behind her that visibly stretches (slow) or bunches (fast) | Kit 4 (5-Beat Arc — Pacing, gr 5-6) |
| 3 | **Turn** | **The pivot** — the load-bearing moment in beat 4 where the story turns (a revelation, reversal, recognition); without a turn, the tale is a list of events | A wide-eyed barn-owl-tween whose head visibly rotates 180° at the exact moment a story turns — never claims a turn must be "big," only that "something must shift, or the listener stays where they started" | "I turn my head. The story turns. The listener turns. All three at once. That's the turn." | Warm-cream-and-russet barn-owl-tween in a small velvet cloak with a constellation pattern; head visibly rotates fully around at story-turns (gentle animation cue); eyes large + reflective like a pair of small moons | Kit 7 (The Turn — Beat 4 Craft, gr 6-7) |
| 4 | **Echo** → **Refrain** | **The callback / refrain** — the recurring tag/phrase/sound that creates the oral tradition's signature repetition (the "and that's when..." tag, the "once again the X did Y" refrain, the bookended opening-and-closing line) | A patient mockingbird-tween who picks ONE phrase from each tale and repeats it back identically at the closing — never with a variation, always with the same exact shape; treats repetition as *the oral tradition's signature gift* | "Same words. Same shape. Said again. Said better. That's how the story remembers itself." | Warm-grey-and-cream northern-mockingbird-tween in a small librarian-vest; carries a tiny carved-wood phrase-token in her beak that visibly mirrors the kid's chosen refrain; one wing perpetually cupped at her ear (listening for the repeated phrase) | Kit 10 (Callbacks + Refrains, gr 6-7) |

**WAIT** — collision detected. "Echo" appears in the cumulative DN taken-names list (per task spec). Resolution: rename to **Refrain** (still embodies the callback/repetition primitive; one-word; sensory-musical; no collision verified).

**Final cast**: Lean, Slow, Turn, Refrain.

### 3a. Why these 4 (and not 5)

| Decision | Rationale |
|---|---|
| 4 characters, not 5 | Bramble is the protagonist + listener-anchor + cultural-tradition-holder. A 5-character supporting cast would compete with Bramble for the listener-presence slot — which is structurally load-bearing in voice-first form. 4 is the smallest cast that covers the load-bearing oral primitives. |
| No "voice-character" cast member | Voice-character mode (the kid switching voices for narrator vs old-wise-one vs tiny-squeaky-friend) is taught by **the kid themselves doing it** — never modeled by a cast member with their own character-voice. Otherwise the kid would imitate the cast member instead of inventing. Voice-character is a *whole-app primitive* taught by direct practice + Bramble's reflection, not by exemplar. |
| Lean + Slow as the first two anchors | Hook + pacing are the two primitives a kid can hear in their *very first* recording. Lean enters kit 1 because the hook is immediate-feedback craft; Slow enters kit 4 because pacing requires the 5-beat arc to be visible. |
| Turn at Kit 7 | The turn is the most teachable single moment in oral storytelling — once the kid has a hook + pacing, the turn becomes both possible and load-bearing. |
| Refrain at Kit 10 | Callbacks/refrains are the oral tradition's most universal device — present in griot, seanchaí, rakugo, slam — but require the kid to have built tales with structure first. Refrain enters when the tradition layer (kits 9-12) opens. |
| Names are sensory-verbs, not the craft term | Per methodology guide: don't name a character "Hook" — instead, "Lean the Forward-Tipping Badger." Each name (Lean / Slow / Turn / Refrain) is a concrete sensory verb that *enacts* the primitive. **NO character is named after a tradition-specific term** (no "Griot", no "Seanchaí", no "Rakugo-X") — those terms belong to the traditions, not to a mascot. |

### 3b. Cultural representation note (LOAD-BEARING)

**This section is the failure-mode-test gate for the cultural-sensitivity audit. Founder must sign off before any asset generation. Sensitivity reviewer RECOMMENDED ($300–$500) for kits 9-12 (tradition layer).**

- **No human-coded characters.** All 4 are anthropomorphic animals. No tradition-coded ethnicity, no tradition-coded visual styling, no "African mask," no "Asian fan," no Indigenous regalia, no Celtic knotwork, no rakugo-fan.
- **No named historical storytellers.** The traditions cited in `Docs/VoiceTale/README.md` (West African griot, Indigenous American oral history, Irish seanchaí, Japanese rakugo, modern slam poetry) are foregrounded in kit metadata + framing copy as **lineages** — never mascotized. Specific named storytellers (e.g., individual griots, recorded seanchaí, rakugo masters, slam champions) are referenced as practitioners IF AND ONLY IF the kit's framing copy attributes them with full name + tradition + dates + permission/public-domain status — NEVER as cast inspirations.
- **Tradition-specific terms (griot / seanchaí / rakugo / etc.) are taught explicitly** in kit framing copy, attributed to their originating community — NEVER renamed or anglicized. The character is called "Refrain" (English sensory-verb); the *concept* the character teaches is called "callback" generically and "the griot's praise-name return" or "the rakugo punchline-callback" in tradition-specific kits.
- **Indigenous American oral history requires the highest care.** Indigenous oral traditions are often sacred, community-held, and not for outside use. Kit 12 (Tradition Layer — Indigenous American Oral Histories) MUST: (a) attribute to specific named nations (NOT "Native American" as a monolith); (b) cite public-domain or community-licensed sources only; (c) frame oral history as *living tradition still practiced by specific communities*; (d) explicitly say "this is a tradition we honor — we don't claim it"; (e) NEVER ask the kid to "tell an Indigenous story" — only "tell YOUR story in the way you've learned"; (f) external Indigenous-community sensitivity reviewer for kit 12 is **REQUIRED, not optional**, before any external playtest.
- **No appropriation in the kid's own tales.** Kids may genuinely be from any tradition. Bramble's listening register is *receptive* — the kid's tradition (or no tradition) is honored as-is. The cast NEVER frames the kid's tale as needing to fit a tradition.
- **Founder-review every tradition-layer kit (kits 9-12)** before any kit content goes to playtest. Sensitivity reader BUDGET allocated separately from labsmith asset-gen budget.

Gender balance: 4 girl-coded; recommend implementing-session flex Lean or Turn to they/them.

### 3c. Collision check

Grepped `labsmith/Docs/REGISTRY_PORTFOLIO_CHARACTER_NAMES.md` + all 33 shipped DN handoff docs (Waves 1-8) + Wave 9 cluster siblings (CharacterForge / DialogueQuest / HaikuQuest / LyricForge — checked in-flight 2026-05-22):

- **Lean** — no collision verified (sensory-verb; clear)
- **Slow** — no collision verified (sensory-verb; clear)
- **Turn** — collision with LyricForge Wave 9 cluster sibling (Turn = the crow-tween bridge character) AND DialogueQuest may use related verbs. Resolution: rename to **Pivot**. Verified no Pivot in registry — clear (distinct from FunctionForge Wave 4 reject list note; was REJECTED there but not USED; cross-confirmed clear in current registry).
- **Pivot** — no collision verified (clear)
- **Echo** — collision (in cumulative taken-names list); renamed to **Refrain** above
- **Refrain** — no collision verified (musical-oral register; clear)

**Final cast (post-collision)**: **Lean, Slow, Pivot, Refrain.**

Register in `REGISTRY_PORTFOLIO_CHARACTER_NAMES.md` § "Distributed-Narrative retrofits — proposed casts" → add new section "VoiceTale — oral-craft cast (Wave 9, SHIPPED 2026-05-22)" with these 4 names + Bramble (mentor + mascot) once retrofit lands.

### 3d. Writing-craft cluster cross-app cameo opportunities (Wave 9.4 nice-to-have)

VoiceTale + CharacterForge + DialogueQuest + LyricForge + HaikuQuest + TaleForge + QuillSpell + SpeakForge cluster siblings. Suggested cross-app hooks (out of scope for this handoff; polish-pass):

- **Lean** (VoiceTale) cameos in CharacterForge kit 4 (Signature Phrase) AND TaleForge kit 1 (Opening Lines): the hook primitive crosses written + oral form.
- **Slow** (VoiceTale) cameos in HaikuQuest kit 3 (the Cut / kireji): pacing-as-craft applies to ultra-short oral forms too — the kireji is a pacing tool.
- **Pivot** (VoiceTale) cameos in DialogueQuest kit 1 (Dialogue Basics — branch-meaning, Sprig's territory): a dialogue branch IS the oral turn.
- **Refrain** (VoiceTale) cameos in LyricForge kit 5 (Chorus + Hook Building) AND HaikuQuest kit 11 (Sijo + Ghazal-Light): the chorus, the ghazal radif, and the oral callback are sibling primitives.
- **Click** (CharacterForge Wave 9 sibling) cameos in VoiceTale kit 5 (Voice-Character Mode): voice as character signature is the same primitive across typed + oral form.
- **Brogue** (DialogueQuest Wave 9 sibling) cameos in VoiceTale kit 5 (Voice-Character Mode): Brogue's signature-words demo is the dialogue-side of the voice-character primitive.

Shared illustration style means **zero new asset generation** for cross-appearances.

```json
"dnCast": {
  "intro": "VoiceTale's 4-character cast embodies oral-storytelling craft primitives — hook / leanability (Lean), pacing across the 5-beat arc (Slow), the pivot / turn (Pivot), and the callback / refrain (Refrain). Bramble (mentor reconciliation pending: site → Bramble) remains the protagonist + listener-anchor + cultural-tradition holder; cast embodies oral-craft primitives Bramble teaches around the hedgerow fire. Multi-tradition cultural-sensitivity gate enforced (CRITICAL — UNIQUE to VoiceTale): all 4 cast names are English sensory-verbs (Lean / Slow / Pivot / Refrain); NO tradition-specific terms mascotized (no Griot / Seanchaí / Rakugo-X / Slam-X); NO named historical storytellers as cast; griot / seanchaí / rakugo / slam / Indigenous-American-oral-history attributed to source communities in kit metadata + framing copy; kit 12 (Indigenous American Oral Histories) requires external Indigenous-community sensitivity reviewer BEFORE playtest (not optional). Voice-character mode (kit 5) is taught by the kid doing it themselves, NOT by a cast-member exemplar — preserves voice-craft as the kid's own invention. Bramble's listener-protagonist register inverts the usual mentor-as-performer pattern (structurally honest to oral form). External oral-storytelling-pedagogy + Indigenous-cultural sensitivity reviewer REQUIRED ($500–$1000 across kits 9-12) before any asset generation.",
  "members": [
    { "name": "Lean", "role": "Hook / leanability — does the listener tip forward at second 5? The body's vote is the truth" },
    { "name": "Slow", "role": "Pacing across the 5-beat arc — slow setup / fast rising / hold the turn; tempo is a choice on purpose" },
    { "name": "Pivot", "role": "The turn at beat 4 — the load-bearing moment when story / teller / listener turn at once" },
    { "name": "Refrain", "role": "Callback / refrain — same words, same shape, said again, said better; oral tradition's signature gift" }
  ]
}
```

## 4. Per-kit introduction + fading schedule

VoiceTale's 16-kit arc maps roughly to: Record-a-Tale Basics (1-4), 5-Beat Arc Deepening (5-8), Tradition Layer (9-12), Anthology + Cross-Cluster Export (13-16). Cast **fades by kit 12** so kits 13-16 (anthology + cross-form + Indigenous-tradition-layer + free-form telling) read as integrative + tradition-honoring.

| Kit | Topic (approx) | New character | Returning cast | Notes |
|---|---|---|---|---|
| 1 | Record-a-Tale Basics — Hook + 60-second tale (gr 4-5) | **Lean** | — | Lean introduced as the listener-who-tips-forward; kid records first 60-second tale; Lean reacts to the hook |
| 2 | Hook Deepening — first-5-seconds craft (gr 4-5) | (no new) | Lean | Bramble walks the kid through hook variations; Lean's lean-meter visible |
| 3 | Setup + Rising Action — beats 2 + 3 (gr 4-5) | (no new) | Lean | Lean's leanability extends past the hook; kid practices sustained engagement |
| 4 | 5-Beat Arc — Pacing (gr 5-6) | **Slow** | Lean | Slow introduces tempo; her hourglass becomes the pacing-UI affordance |
| 5 | Voice-Character Mode — Multi-Voice Recording (gr 5-6) | (no new — **kid-led**) | Lean, Slow | **CRITICAL: no cast-member exemplifies voice-character.** Kid records 2-3 voices themselves; Bramble + cast LISTEN and reflect. Voice-character craft is the kid's own invention |
| 6 | Pacing Synthesis — multi-tempo tales (gr 6-7) | (no new) | Slow (lead), Lean | Slow's tempo-trail visible; kid practices speed variation |
| 7 | The Turn — Beat 4 Craft (gr 6-7) | **Pivot** | Lean, Slow | Pivot introduced; her head-rotate becomes the turn-marker UI affordance |
| 8 | Turn Synthesis — multi-tale turn practice (gr 6-7) | (no new) | Pivot, Slow, Lean | Full ensemble teaching moment; Pivot leads |
| 9 | Tradition Layer — West African Griot (gr 6-7) | (no new) | Pivot, Slow, Lean | Griot tradition attributed; kit metadata cites specific cultures; Refrain not yet introduced (callback intro is kit 10) |
| 10 | Callbacks + Refrains — Oral Repetition Craft (gr 6-7) | **Refrain** | Pivot, Slow, Lean | Refrain introduced as the callback primitive; her carved-wood phrase-token becomes the refrain-UI affordance |
| 11 | Tradition Layer — Irish Seanchaí + Japanese Rakugo (gr 6-7) | (no new) | Refrain (lead), full cast | Seanchaí + rakugo traditions attributed; Refrain anchors callback variations across traditions |
| 12 | Tradition Layer — Indigenous American Oral Histories (gr 7-8) | (no new — **fading kit + REQUIRED-reviewer kit**) | **Full ensemble final appearance** | **External Indigenous-community sensitivity reviewer REQUIRED before this kit's framing copy is finalized.** Cast farewell — Bramble takes over as the kid moves into anthology + their own tradition |
| 13 | Anthology Building (gr 7-8) | — | (cameos only) | **Cast faded**; Bramble + the kid's own tales carry the anthology |
| 14 | Cross-Form Experimentation — slam poetry + spoken-word (gr 7-8) | — | — | Slam tradition attributed; pure oral craft |
| 15 | Free-Form Telling — kid invents own form (gr 7-8) | — | — | Form discipline loosens; kid invents their own oral form |
| 16 | Sharing + Cluster Export (gr 7-8) | — | — | Friend-code share (audio + transcript opt-in) + CharacterForge / LyricForge / TaleForge export hooks |

**Why the fade**: by kit 12 the learner has met each companion ≥4 times and has built ~12 tales. The anthology + free-form + cross-tradition lessons (13-16) require the kid's own voice to take center — if Lean/Slow/Pivot/Refrain stay through, they crowd out the kid's own oral invention. The fade IS the pedagogy: the cast's job was to teach the primitives; the integration is the kid telling their own tales aloud, with Bramble as the perfect listener.

## 5. Six failure-mode tests (writing-craft + oral-craft + multi-tradition profile)

Founder-led audit; document in `Docs/AUDIT_DISTRIBUTED_NARRATIVE_VOICETALE.md` (to-be-authored before retrofit ships).

1. **Writing-anxiety amplification (oral-form variant)** — Voice-recording anxiety is real ("what if my voice sounds bad?" / "what if my story is dumb?"). Does any cast member ever *shame* a learner's recording? Reference check: when a learner's hook is weak, Lean should never say "I didn't lean — bad hook"; Lean should say "I didn't lean yet — let's try a different opening; what if you started in the middle?" Cast inherits Bramble's *receptive listener* register + an explicit anti-voice-shame rule. **Special VoiceTale test**: voice is a deeply personal medium for tweens — extra care on never-mocking timbre / accent / volume / lisp / stutter / non-native-English-accent. Bramble's listening register is the floor; cast must match.
2. **Gender / cultural representation balance** — Cast is 4 girl-coded; recommend implementing-session flex Lean or Pivot to they/them. **Cultural representation is the HIGHEST-stakes gate in VoiceTale** — see § 3b. Kit 12 (Indigenous American Oral Histories) has REQUIRED external sensitivity reviewer; kits 9-11 (griot / seanchaí / rakugo / slam) have RECOMMENDED reviewers. Founder-review every tradition-layer kit before any asset generation. No human-coded cast; no tradition-coded visual styling.
3. **Hero-mascot dilution risk (listener-protagonist variant)** — Does the supporting cast steal listener-presence from Bramble? Test: across all 12 active kits, Bramble must remain the primary listener (≥60% of listening reactions), with companions introduced as "here's Lean — she sits next to me at the fire" framing. **Special VoiceTale test**: in voice-first form the *listener* is more load-bearing than the *teller* (the teller is the kid, always). If the implementing session finds cast members "listening" for Bramble (i.e., the kid talks to the cast instead of Bramble), stop and re-balance. Bramble is the primary ear; cast are supporting ears.
4. **Mascotizing the concept (don't name a character after the primitive — and don't name after a tradition)** — None of the 4 names ARE the craft term ("Lean" not "Hook"; "Slow" not "Pacing"; "Pivot" not "Turn-of-the-arc"; "Refrain" not "Callback"). **AND none are tradition-specific terms** (no "Griot", no "Seanchaí", no "Rakugo-X", no "Slam-X"). Confirm both stay true through implementation. **Especially watch Pivot** — implementing session may be tempted to rename to "Turn" for clarity; that's a regression AND collides with LyricForge Wave 9.
5. **Cluster coherence with QuillSpell + GrammarForge + LinguaQuest + ReadQuest existing word-woods + Wave 9 writing-craft siblings (CharacterForge / DialogueQuest / HaikuQuest / LyricForge) + voice-cluster sibling (SpeakForge)** — VoiceTale bridges writing-craft AND voice-cluster. Visual coherence: chunky-cartoon animal proportions, palette in the warm teal-and-ember range, bold `#2A1F1A` outlines. Cross-app cameos (§ 3d) anchor both clusters. **Special VoiceTale test**: in oral form the visual register is *less* present (audio is the medium) — cast must still pass visual-coherence tests for menu / intro-card / pause-screen surfaces, but the kid's primary experience is *aural*. Audio voice-direction for each cast member's "listening sound" (the small "oh?" / "and then?" cues Bramble makes) — cast members should have their own subtle audio fingerprint (Lean's small inhale, Slow's slow breath, Pivot's quiet hoot, Refrain's hum). Audio-direction spec is OUT OF SCOPE for this handoff but flagged for the implementing session.
6. **Curriculum-integrity check (oral + tradition variant)** — Does adding the cast obscure oral-storytelling craft or surface it? Specifically: does the kit JSON need to change to accommodate the characters? **No.** The cast is a framing layer on top of the existing 16 kits (when those kits are authored). Question prompts and answers stay identical. The cast appears via intro cards + `MascotReactionView` overlays + Bramble's prompt seeds + per-cast subtle audio cues. **If the implementing session finds itself rewriting kit framing copy to make the cast tell the tradition stories, STOP and re-scope.** The cast teaches primitives; the *traditions* are taught by Bramble's framing copy, attributed to source communities, NEVER by the cast members. *Special VoiceTale test*: voice-recording UI affordances (record button, 5-beat timer, pause/resume, playback waveform) must remain functional + accurate regardless of which cast member is "active" — Lean's leanability-meter is *decorative* on top of the hook-craft prompt, not a replacement for it.

## 6. Implementation path (4 phases, $0 cost — defers asset gen)

Per the methodology guide's TRUE Spark & Anvil cost model (~$3–5 cash + 1–2 founder hours per app; PLUS $500-$1000 sensitivity-reviewer budget for tradition-layer kits). VoiceTale's per-app costs:

- **Mascot generation**: 4 supporting cast × $0.27 (Nano Banana Pro) = **~$1.08** (deferred to Wave 9.2 asset gen). Bramble's 4 additional poses (demonstrating, praising, thinking, working) also queued per `Docs/AUDIT_MASCOT_COVERAGE.md`.
- **Supporting illustrations**: ~12 (3 per character × 4) × $0.045 (Flash) = **~$0.54** (Wave 9.2)
- **Audio cast-fingerprint** (4 subtle listening sounds × ~$0.10 Lyria 3 Clip) = **~$0.40** (Wave 9.3 — separate audio handoff; SCOPE OUT for this doc)
- **Total cash**: **~$1.62 visual + ~$0.40 audio = ~$2.02** (defers; this handoff is $0)
- **External sensitivity reviewers**: $500-$1000 across kits 9-12 (NOT labsmith budget — separate)

| Phase | Owner | Deliverable | Gating |
|---|---|---|---|
| **A — Cast finalization** | VoiceTale CC session (after Tier-2 docs are authored) | Accept this handoff. When `Docs/TECHNICAL_DESIGN.md` is authored, include new § "Supporting Cast — Bramble's Hedgerow-Fire Companions" referencing this handoff. No code yet | This handoff merged + Tier-2 docs authored |
| **B — Kits 1-4 introduction** | VoiceTale CC session | Wire Lean intro at kit 1; Slow intro at kit 4. Add `OralCraftCompanion` enum with case-per-primitive. `IllustrationRegistry` registers `voicetale-cast` bundle with placeholder assets until Wave 9.2 ships | Phase A merged + Phase 1 voice-recording scaffold done |
| **C — Kits 5-8 + Pivot intro + voice-character mode** | VoiceTale CC session | Wire Pivot intro at kit 7. **Voice-character mode (kit 5) must NOT instantiate a cast-member voice-exemplar** — kid records their own voices; cast LISTENS. Extend Bramble's `@Generable VoiceStoryReflection` prompts to include `activeCompanionContext` parameter so Bramble frames reflection via the active companion. Wire `MascotReactionView` (Bramble + active companion) into the record-a-tale flow + anthology gallery | Phase B merged |
| **D — Kits 9-12 tradition layer + Refrain intro + cast fading** | VoiceTale CC session, **gated on external sensitivity reviewer sign-off for kit 12** | Wire Refrain intro at kit 10. Kit 12's "cast farewell" pacing — Bramble takes over for Indigenous American oral histories framing. Cast assets remain in bundle but no new intro cards for kits 13-16. Asset consumer audit grep verifies `MascotReactionView` is actually wired in (per `.claude/rules/portfolio.md` § Asset Consumer Audit) | Phase C merged + external reviewer cleared kit 12 |

**Labsmith side (Wave 9.2 — separate handoff)**: generate the 4 supporting cast mascots + ~12 supporting illustrations via `scripts/gen_app_illustrations.py`; visual-audit per Pro-tier 5–10% artifact rate; ship to VoiceTale via `scripts/copy_illustrations_to_repos.sh` + file `HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_MASCOT_GENERATION.md`. Wave 9.2 gated on founder review of this handoff AND sensitivity-reviewer sign-off for tradition-layer framing copy.

## 7. Cross-references

- `labsmith/Docs/GUIDE_DISTRIBUTED_NARRATIVE_METHODOLOGY.md` — methodology guide
- `labsmith/Docs/RESEARCH_DISTRIBUTED_NARRATIVE_PORTFOLIO_EXPANSION.md` — original research
- `labsmith/Docs/REGISTRY_PORTFOLIO_CHARACTER_NAMES.md` — name collision registry (Echo → Refrain rename, Turn → Pivot rename per § 3c)
- `labsmith/Docs/PLAN_WRITING_CRAFT_CLUSTER.md` — cluster strategic plan
- `labsmith/Docs/VoiceTale/README.md` — concept doc (Bramble mascot + oral-craft primitive + tradition layer + Phase 1 scope + COPPA-2025 voice-consent design)
- `motiflab-app/Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` — Wave 7 hero-as-protagonist template
- `characterforge-app/Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` — Wave 9 cluster sibling (reciprocal Click + Lean cameos)
- `dialoguequest-app/Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` — Wave 9 cluster sibling (reciprocal Brogue + Pivot cameos)
- `haikuquest-app/Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` — Wave 9 cluster sibling (reciprocal Pause + Slow cameos)
- `lyricforge-app/Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` — Wave 9 cluster sibling (reciprocal Holler + Refrain cameos)
- `loreqquest-app/Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` — Wave 5 multi-tradition-cultural treatment precedent (this handoff inherits)
- `labsmith/.claude/rules/trauma-informed-content.md` — cultural-sensitivity gate applies to VoiceTale tradition layer
- `labsmith/Docs/DESIGN_AVATAR_AESTHETIC.md` — chunky-cartoon art-style spec
- `labsmith/Docs/GUIDE_ILLUSTRATION_PIPELINE.md` — Nano Banana Pro / Flash workflow (used in Wave 9.2)
- `labsmith/.claude/rules/portfolio.md` § Asset Consumer Audit — grep-for-call-sites rule that closes Phase D
- `forgekit/Sources/Client/ForgeIllustrations/` — module source
- `voicetale-app/CLAUDE.md` — current architecture
- `voicetale-app/Docs/README.md` + `voicetale-app/Docs/IMPLEMENTATION_HANDOFF.md` — bootstrap-stage docs

## 8. What this doc does NOT cover

- **Mascot generation** for the 4 supporting cast. Labsmith runs Wave 9.2 (~$1.62 budget) after founder reviews this handoff AND sensitivity-reviewer sign-off for tradition-layer framing.
- **Audio cast-fingerprint generation** (4 subtle listening sounds). Defer to Wave 9.3 — separate audio handoff via Lyria 3 Clip pipeline. Audio direction spec out of scope here.
- **Tier-2 doc set** (TECHNICAL_DESIGN.md / FEATURE_PLAN.md / CONTENT_STYLE_GUIDE.md / TESTING_STRATEGY.md / PERFORMANCE_BUDGET.md / KIDSAFE_PREPARATION.md / DOCUMENT_CATALOG.md). Labsmith authors these in a future wave; this handoff predates them. When Tier-2 docs land, the cast spec here is the canonical source they reference.
- **Curriculum / kit JSON authoring**. The 16 kits are pending labsmith authorship; this handoff predates them. When kits are authored, the cast is a framing layer; question prompts stay identical.
- **Cross-app cameos** (Lean → CharacterForge, Slow → HaikuQuest, Pivot → DialogueQuest, Refrain → LyricForge + HaikuQuest, Click → VoiceTale, Brogue → VoiceTale). Defer to Wave 9.5 if pursued.
- **Bramble renaming**. Bramble is the canonical mentor + mascot name; site PR reconciles stale `Loresinger Mae` → Bramble in Wave 9 batch.
- **External sensitivity reviewers**. $500-$1000 across kits 9-12 — NOT labsmith asset-gen budget; separate founder-allocated funding required.
- **Voice-recording consent infrastructure**. `ParentalConsentService` voice-opt-in pattern is shared from LyricForge; orthogonal to the DN cast.
- **AdventureHub Level-2 overlay** — this handoff is for the app's *internal* DN cast, not the hub-side cosmetic layer.

## 9. Related commits / PRs

| Repo | Item | Status |
|---|---|---|
| labsmith | `Docs/GUIDE_DISTRIBUTED_NARRATIVE_METHODOLOGY.md` | shipped 2026-05-21 |
| labsmith | `Docs/REGISTRY_PORTFOLIO_CHARACTER_NAMES.md` (VoiceTale cast entry + Bramble mentor reservation + Echo → Refrain / Turn → Pivot resolutions) | shipping in Wave 9 retry batch 2026-05-22 |
| labsmith | This handoff file (now in voicetale-app) | shipping 2026-05-22 (Wave 9 retry) |
| labsmith | Wave 9.2 mascot generation (4 supporting cast × 5 poses + ~12 supporting illustrations + Bramble's remaining 4 poses) | pending founder review + sensitivity-reviewer sign-off |
| labsmith | Wave 9.3 audio cast-fingerprint (4 listening sounds via Lyria 3 Clip) | pending |
| voicetale-app | Tier-2 doc set (TECHNICAL_DESIGN / FEATURE_PLAN / CONTENT_STYLE_GUIDE / TESTING_STRATEGY / PERFORMANCE_BUDGET / KIDSAFE_PREPARATION / DOCUMENT_CATALOG) | pending labsmith future wave |
| voicetale-app | Phase A — cast finalization PR (gated on Tier-2 docs) | pending |
| voicetale-app | Phase B — kits 1-4 introduction PR | pending |
| voicetale-app | Phase C — kits 5-8 deepening + voice-character mode PR | pending |
| voicetale-app | Phase D — kits 9-12 tradition layer + Refrain intro + fading PR (asset-consumer-audit gate + sensitivity-reviewer gate for kit 12) | pending |
| spark-anvil-site | `distributedNarrative: true` flag for voicetale + dnCast block + mentor reconciliation (Loresinger Mae → Bramble) | shipping in Wave 9 retry site PR |
