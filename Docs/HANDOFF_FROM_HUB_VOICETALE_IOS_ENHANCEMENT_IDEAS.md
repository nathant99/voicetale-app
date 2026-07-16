---
status: ADVISORY
date: 2026-07-16
direction: hub → app
intent: 💡 iOS-ENHANCE opportunities surfaced during the /play/voicetale clone build (NON-obligation)
freshness-horizon: 90 days
---

# Handoff to VoiceTale — 💡 iOS-ENHANCE ideas (advisory, non-obligation)

Direction: **hub → app**. This is an **advisory** opportunities doc, NOT a parity obligation — there is
**no 🟡 ledger row** for these. The `/play/voicetale` clone build re-mined the domain per
R-WEB-CLONE-BACKPORT-MINING (§ "don't auto-zero Track-C" + the harvestforge/taletrail clauses). The
VoiceTale session triages these and may decline any of them.

## The mining question
VoiceTale's authoring modality is **oral** (record + speak) — which already owns the motor/embodied/oral
learning dimension a browser can't touch (that is exactly *why* mic capture is ⛔-waived on the web). So the
mining question is: **which learning MODALITY does VoiceTale's oral core NOT reach, that iOS could deliver
(and a browser can't, COPPA-safe)?** Two honest ideas surfaced (this is a modest, non-padded yield):

### 💡 1 — Storyboard the arc with PencilKit (drawing modality)
VoiceTale teaches + records the *told* tale, and (web-pioneered) the clone reconstructs the arc from
*text* beats — but neither surface has the child **draw**. A "storyboard your 5 beats" surface (PencilKit:
sketch a quick frame for hook / setup / rising / turn / close before telling) adds the **visual-planning /
drawing** dimension the oral+text core omits. Storyboarding-before-telling is a recognized oral-storytelling
prep technique. iOS-only (PencilKit); absent from the app today.
- **Web-native analog check:** the *structure* dimension already ships a web FILE (the 5-Beat Arc Builder —
  reconstruct from text). The **drawing** form is genuinely iOS-only; no additional web build is warranted.

### 💡 2 — Gesture rehearsal via Vision / CoreMotion (embodied-gesture modality)
Kit 11 (Gesture & Body Language) + the Flourish cast teach gesture as *knowledge*, and the clone's Delivery
drill reasons *about* gesture — but nothing lets the child **physically rehearse** a gesture and get feedback
("did your hands actually go wide for 'huge', small for 'tiny'?"). A CoreMotion/Vision on-device rehearsal
(all on-device, no upload) adds the **embodied-motor** dimension the oral+reasoning core doesn't reach.
iOS-only; absent from the app.
- **Web-native analog check:** the gesture-*knowledge* dimension is covered by the Delivery reasoning drill
  (item d8, "how can a GESTURE help"). The *embodied capture* form is genuinely iOS-only; no additional web
  build is warranted.

## Explicitly considered + NOT advised
- **Front-camera eye-contact / gaze feedback** (kit + the Gaze cast): even on-device, camera-gaze analysis
  of a child is COPPA-fraught and privacy-heavy for a kids' app — deliberately **not** advised.

## Status
Advisory only. No parity-ledger row, no obligation. If the VoiceTale session builds either, it becomes a
genuine iOS feature (and, if it later wants a web parity surface, that's a fresh web work item — but neither
is web-buildable today). Filed per R-WEB-CLONE-BACKPORT-MINING § 💡 iOS-ENHANCE.

## Cross-references
- `spark-anvil-hub/Docs/web/voicetale/RESEARCH.md` § Backport candidates
- `.claude/rules/spark-anvil-website.md` § R-WEB-CLONE-BACKPORT-MINING · § R-WEB-CLONE-DEVICE-FEATURE-SKIP
