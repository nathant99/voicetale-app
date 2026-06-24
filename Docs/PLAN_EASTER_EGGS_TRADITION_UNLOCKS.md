---
status: PLAN-ONLY (sensitivity-reviewer-gated per ADR-016)
date: 2026-06-24
round: 2026-06-24 (EIGHTH consecutive re-affirmation round; PR-F)
freshness-horizon: 60 days
---

# Plan — Easter eggs (hidden tradition unlocks for curious explorers)

Direction: **internal planning artifact**. Closes the "Easter eggs" box in
`@Docs/FEATURE_PLAN.md` § Phase Delight & Polish as a PLAN — implementation
is gated on external sensitivity-reviewer signoff per ADR-016.

> **Phase Delight & Polish line item**:
> *"Easter eggs — Hidden tradition unlocks for curious explorers (rare
> cultures revealed after multi-session exploration; sensitivity-reviewed)"*

## Why a PLAN ships before any code

VoiceTale's tradition layer is the most sensitivity-reviewed surface in the
app. The existing 5 traditions in `Services/Resources/Traditions/traditions.json`
each shipped with an explicit `culturalCreditNote` + optional `contentWarning`
per `@.claude/rules/trauma-informed-content.md` § Cultural-sensitivity gates.
ADR-016 (`Docs/ADR-016_DN_S_TRAUMA_GATED_STORY_AXIS_APPROVAL.md`) is the
canonical authority: trauma-gated cultural content REQUIRES external
reviewer signoff before the surface ships to kids.

Easter-egg tradition unlocks compound the surface area:
- **More entries** → more cultures referenced → more reviewer envelope
- **Hidden unlock conditions** → the kid stumbles into them; the discovery
  moment makes the cultural-credit framing MORE load-bearing, not less
- **Rare-cultures register** → entries that are MORE specific to particular
  community-held knowledge than the canonical 5; without rigorous review
  this is exactly the appropriation surface the tradition layer was
  designed to prevent

So: the plan ships now (locks the design), the implementation ships post-
reviewer-signoff.

## Design — what an easter egg IS in VoiceTale

An easter egg is a **rare 6th-or-later tradition card** that:
1. Surfaces in `TraditionGalleryView` only AFTER specific multi-session
   exploration thresholds are met (NOT first-session, NOT random)
2. Carries the same `culturalCreditNote` + optional `contentWarning`
   contract as the 5 base traditions
3. Ships with reviewer-signoff metadata in the JSON (reviewer name +
   review date + content scope) — auditable from disk
4. Is registered as a **distinct tier** in the tradition catalog so the
   base 5 + the easter-egg pool stay separable for analytics + reviewer
   scope

Three candidate archetypes for the unlock thresholds (final 3 chosen post-
reviewer review of the kid-readability of each):

| Threshold | What the kid did to unlock | Rationale |
|---|---|---|
| **Deep listener** | Expanded all 5 base traditions + saved ≥ 10 tales | Kid has demonstrated sustained engagement; the easter-egg layer rewards depth |
| **Cross-mood explorer** | Saved ≥ 1 tale in each of the 4 moods + completed ≥ 1 question kit | Kid has demonstrated breadth in their telling — the easter-egg surface rewards range |
| **Tradition revisitor** | Returned to ≥ 2 base traditions a second time (re-expanded) | Kid has demonstrated curiosity about specific traditions — the easter-egg surface rewards depth in a specific direction |

## What an easter egg is NOT

- ❌ A trivial "fun fact" — every tradition must carry the same cultural-
  credit + content-warning contract as the base 5
- ❌ An impersonal "achievement" — the surface is a tradition card, not a
  badge; the kid encounters a community's craft, not a XP reward
- ❌ A pop-up notification — the surface lives IN the tradition gallery;
  the kid finds it by scrolling, not by being interrupted
- ❌ Random — each unlock is gated on a SPECIFIC kid action (no chance-
  based RNG; predictable + earnable)
- ❌ Limited-time — once unlocked, the easter-egg card stays unlocked;
  the kid can return to it
- ❌ Permission-gating — base 5 traditions stay visible regardless of
  easter-egg state; easter eggs ADD to the gallery, never SUBTRACT

## Schema additions (post-reviewer)

`Models/TraditionEntry` already supports the metadata we need; the easter-
egg layer adds 3 additive Optional fields per the pre-App-Store additive
rule (`@.claude/rules/swiftdata.md` § "Pre-App Store: don't create new
VersionedSchema for unreleased models"):

```swift
nonisolated public struct TraditionEntry: Codable, Sendable, Hashable, Identifiable {
    // ... existing fields ...
    /// Set to `.easterEgg` for hidden unlocks; default `.base` for the
    /// canonical 5. Additive Optional defaults to `.base` on legacy
    /// JSON decode (per the pattern locked in VoiceTaleSchema.md).
    public let tier: TraditionTier?  // .base | .easterEgg
    /// Pre-condition predicate identifier for easter-egg unlocks. The
    /// gallery view resolves this via a pure-function `TraditionUnlock`
    /// helper. `nil` for base-tier entries (always visible).
    public let unlockCondition: String?  // "deep_listener" / "cross_mood_explorer" / etc.
    /// Reviewer-signoff metadata. For easter-egg entries, this MUST be
    /// non-nil and resolve to a known reviewer in the
    /// `traditions.json` reviewer roster. For base entries, optional.
    public let reviewerSignoff: ReviewerSignoff?
}

nonisolated public enum TraditionTier: String, Codable, Sendable {
    case base
    case easterEgg = "easter_egg"
}

nonisolated public struct ReviewerSignoff: Codable, Sendable, Hashable {
    public let reviewerName: String   // e.g. "Dr. <Name>"
    public let reviewedAt: Date       // ISO-8601 in JSON
    public let scope: String           // 1-line scope summary
}
```

New value-type helpers:

```swift
// Services/TraditionUnlockEvaluator.swift
nonisolated public enum TraditionUnlockEvaluator {
    public static func isUnlocked(
        condition: String,
        snapshot: TraditionUnlockSnapshot
    ) -> Bool
}

nonisolated public struct TraditionUnlockSnapshot: Sendable, Hashable {
    public let expandedBaseTraditions: Set<String>
    public let savedTales: Int
    public let moodsCovered: Set<VoiceTaleMood>
    public let kitsCompleted: Set<Int>
    public let traditionRevisitCount: [String: Int]
}
```

`TraditionGalleryView` filters the catalog entries through `isUnlocked(...)`
BEFORE rendering — hidden easter eggs never appear in the rendered list
until their condition is met. New entries render at the bottom of the
gallery with a soft "New" badge (single-fire per install; the
`PersistentTraditionEntry` `firstExploredAt` field already supports this
pattern).

## Implementation phasing (post-signoff)

| Phase | Scope | Effort | Gated on |
|---|---|---|---|
| **A — Schema** | Add additive Optional fields to `TraditionEntry`; ship empty `TraditionUnlockEvaluator`; lock the schema via `TraditionEntryTests` | ~0.5 day | None — pre-reviewer; safe to land as scaffold |
| **B — Evaluator + tests** | Implement `TraditionUnlockEvaluator.isUnlocked(...)` for the 3 conditions; lock predicate logic via pure-function tests | ~0.5 day | A |
| **C — Gallery filter** | Wire `TraditionGalleryView` to filter through the evaluator; render the soft "New" badge on first-encounter | ~0.5 day | B |
| **D — Sensitivity review** | Submit candidate easter-egg entries (3-5 tradition cards) to external reviewer per ADR-016 | ~1-2 weeks wall time | NEW — external reviewer |
| **E — Ship entries** | Add reviewer-signed `traditions.json` entries with `tier: "easter_egg"`; ship via standard PR | ~0.5 day | D signoff |
| **F — Achievement layer (optional)** | Add 1-3 achievements for unlocking easter eggs; categorical analytics surface | ~0.5 day | E |

Total dev effort: ~3 days net of reviewer wall-time. **Reviewer wall time is
the load-bearing schedule constraint.**

## Reviewer envelope (per ADR-016)

Per `Docs/ADR-016_DN_S_TRAUMA_GATED_STORY_AXIS_APPROVAL.md` § Reviewer-
budget specifics, the tradition layer's existing 5 entries consumed ~$1.5K
of the cumulative ~$5K cross-app reviewer envelope. Easter-egg entries
add new community-held knowledge; budget estimate per entry:

| Item | Estimate |
|---|---|
| Per-entry review fee (3-5 entries) | $200-400 / entry |
| Round-trip revision cycles (1-2 expected) | $100-200 / cycle |
| Total per-easter-egg | ~$300-600 |
| Total cluster (3-5 entries) | ~$900-3000 |

Compared to the broader portfolio reviewer envelope, this is well within
the per-app ceiling. **Recommend filing the reviewer-engagement handoff
when 2 conditions are met:**
1. Phase 2 (anthology + photo attach) has fully shipped
2. The Phase 3 cross-cluster cameo work is underway (reviewer round-trip
   wall-time overlaps with Phase 3 dev time, avoiding pipeline stalls)

## Analytics surface

The easter-egg layer adds one categorical analytics event per ADR-016 §
Privacy posture:

```swift
case traditionEasterEggUnlocked(slug: String, conditionSlug: String)
// properties:
//   tradition_slug: the easter-egg entry slug
//   condition: the unlock-condition slug ("deep_listener" / etc.)
```

NO raw culture name in the wire payload (the slug is the categorical
surface); NO unlock-timestamp; NO kid-action breakdown beyond the
condition slug.

## What this plan does NOT cover

- **Specific easter-egg content** — the 3-5 candidate cultures are
  authored AFTER reviewer engagement; this plan locks the surface design,
  not the content
- **Cross-app cameo unlocks** — Phase 3 work; the easter-egg layer is
  contained to the tradition gallery
- **TestFlight-only unlocks** — out of scope; the easter-egg surface
  ships to all builds equally once landed
- **Reviewer-engagement orchestration** — handled via the standard
  `HANDOFF_FROM_APP_<SENSITIVITY_REVIEWER>.md` pattern when the engagement
  is filed; not in this plan's scope

## When to revisit this plan

- After Phase 2 ships completely (the 2 of 7 remaining boxes close)
- When the reviewer-engagement envelope opens (≥ $900 available)
- When Phase 3 cross-cluster cameo work begins (reviewer round-trip
  wall-time overlap)
- If user direction explicitly elevates easter-egg priority

## Cross-references

- `@Docs/FEATURE_PLAN.md` § Phase Delight & Polish — closes the "Easter
  eggs" box as PLANNED
- `@Docs/AUDIT_MICRO_DELIGHT_COVERAGE_2026-06-24.md` — sibling planning
  artifact for the 8-types coverage
- `@.claude/rules/trauma-informed-content.md` — cultural-sensitivity
  gates that govern every tradition entry
- `Docs/ADR-016_DN_S_TRAUMA_GATED_STORY_AXIS_APPROVAL.md` — reviewer
  signoff requirements for trauma-gated cultural content
- `Packages/Libraries/Sources/Models/TraditionEntry.swift` — base schema
  the additive Optional fields extend
- `Packages/Libraries/Sources/Services/Resources/Traditions/traditions.json`
  — base 5 entries the easter-egg pool joins (separately tiered)
- `@.claude/rules/swiftdata.md` § "Pre-App Store: don't create new
  VersionedSchema" — additive-Optional rule the schema follows
