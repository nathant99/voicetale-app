---
status: PLAN — pre-trigger
date: 2026-06-24
direction: agent → next-session
intent: capture the SwiftData V2 migration plan that converts to a handoff the moment App Store ship date is on the calendar
freshness-horizon: 60 days
---

# Plan — SwiftData V2 migration prep

Direction: **CC session → next CC session that picks up the App Store ship prep**. This is a PLAN, not a handoff. The plan converts to a real `Docs/HANDOFF_TO_USER_SWIFTDATA_V2_MIGRATION.md` (Xcode-UI-gated portions if any) and a real Swift PR when **either** trigger fires:

1. **The App Store ship date is committed** (any session-spanning calendar date)
2. **The first dev-device install is required to retain across schema field renames** (currently no field has been renamed; if one does, that's the trigger)

Until then, this doc captures the audit + the V2 design + the migration-stage authoring plan so the next session can execute without re-deriving.

## Why this matters

VoiceTale currently runs against `VoiceTaleSchemaV1` per `@Packages/Libraries/Sources/Models/VoiceTaleSchema.swift`. Per `@.claude/rules/swiftdata.md` § "Pre-App Store: don't create new VersionedSchema for unreleased models," every additive Optional field shipped across Phases 1.1 / 2 / Onboarding / Delight & Polish landed directly on V1 with a default value — no `MigrationStage` was authored because nothing has shipped to the App Store yet.

The pre-App-Store rule terminates **the moment the binary ships**. After that, every additive field requires a proper `VersionedSchema` + `SchemaMigrationPlan` stage to defend kid data. This plan captures the audit + the V2 design so the cleanup is a known shape, not a derivation under deadline pressure.

## Audit — additive Optional fields accumulated on V1

The following fields were ADDED to existing `@Model` classes via the pre-App-Store additive rule. Each landed directly on V1 with either an Optional + nil default or a non-Optional + concrete default. Every one of these is back-compat-free under the rule TODAY but requires a V1 → V2 migration stage AFTER App Store ship.

### `PersistentVoiceTaleEntry`

The encoded-metadata blob (`encodedMetadata: Data`) decodes a `VoiceTaleEntry` value type. Additive Optional fields landed on the value-type side via `decodeIfPresent` per `@.claude/rules/swiftdata.md` § "Additive Optional fields on Codable value types stored in SwiftData JSON-blobs":

| Field | Type | Default | Shipped in | Comment |
|---|---|---|---|---|
| `BeatSegment.voiceCharacterSlug` | `String?` | nil | PR #73 (Phase 1.1) | Per-beat voice attribution |
| `VoiceTaleEntry.reflection` | `VoiceStoryReflection?` | nil | Phase 1 base | (Already Optional from day one; not migration-relevant) |

Migration stage: NONE needed at the SwiftData layer — the SwiftData class doesn't change; only the `Data` blob's decoder evolves. The Codable layer's `decodeIfPresent` already handles legacy JSON.

### `PersistentPlayerProgress`

| Field | Type | Default | Shipped in | Comment |
|---|---|---|---|---|
| `completedKitIDsRaw` | `[Int]` | `[]` | PR #75 | Phase 1.1 per-kit completion tracking |
| `lastActiveDate` | `Date?` | nil | PR #78 | Lapsed-return detection |
| `installDate` | `Date?` | nil | PR #83 | Retention metrics anchor |
| `d1HitAt` / `d7HitAt` / `d30HitAt` | `Date?` | nil | PR #83 | D1/D7/D30 retention markers |
| `taleTrialPlays` | `Int` | 0 | PR (2026-06-23) | Phase 2 Tale Trial mode counter |
| `firstFiveBeatTaleAt` | `Date?` | nil | PR #86 | First inaugural-arc marker (celebration system) |

Migration stage for V2: lightweight (additive, all with defaults). No data-loss risk; the `@Model` class gains the fields verbatim from V1 + defaults survive the upgrade.

### `PersistentMoodCollection`

| Field | Type | Default | Shipped in | Comment |
|---|---|---|---|---|
| `id` | `UUID` | `UUID()` | Phase 2 base | Identity from day one |
| `name` | `String` | `""` | Phase 2 base | Per-collection display name |
| `moodRaw` | `String?` | nil | Phase 2 base | Mood filter; Optional from day one |
| `taleIDsRaw` | `[UUID]` | `[]` | Phase 2 base | Collection membership |
| `createdAt` | `Date` | `Date()` | Phase 2 base | Creation timestamp |

NEW model — shipped as part of V1 expansion. No migration needed AT V2 because the model lands in V1 today; V2 migration only handles cross-version field deltas, not new-since-day-one models.

### `PersistentTraditionEntry`

| Field | Type | Default | Shipped in | Comment |
|---|---|---|---|---|
| `slug` | `String` | `""` | V1 base | Tradition identity |
| `firstExploredAt` | `Date?` | nil | V1 base | First-expansion timestamp |
| `lastListenedAt` | `Date?` | nil | V1 base | Most-recent listen timestamp |
| `listenCount` | `Int` | 0 | V1 base | Per-tradition revisit counter |

NEW additive Optional from PR-A this round (NINTH-round, 2026-06-24):

| Field | Type | Default | Comment |
|---|---|---|---|
| `TraditionEntry.tier` | `TraditionTier?` | nil | Easter-eggs Phase A scaffold; lives on the Codable value-type catalog JSON, NOT on the persistent class |
| `TraditionEntry.unlockCondition` | `String?` | nil | Same — catalog JSON only |
| `TraditionEntry.reviewerSignoff` | `ReviewerSignoff?` | nil | Same |

These three fields are on `TraditionEntry` (value type, JSON-blob in `traditions.json`) not on `PersistentTraditionEntry` (the SwiftData record). They don't trigger a V2 migration — the JSON-blob decoder handles legacy keys via `decodeIfPresent`.

### `PersistentAchievement`

| Field | Type | Default | Shipped in | Comment |
|---|---|---|---|---|
| `id` | `String` (unique) | `""` | V1 base | Catalog ID |
| `earnedAt` | `Date` | `Date()` | V1 base | Award timestamp |

No migration delta — model has been stable since V1 ship.

### `PersistentAnthologyMood`

| Field | Type | Default | Shipped in | Comment |
|---|---|---|---|---|
| `mood` | `String` | `""` | V1 base | Mood identity |
| `customLabel` | `String?` | nil | V1 base | Optional override |
| `taleCount` | `Int` | 0 | V1 base | Aggregated counter |
| `lastTaleAt` | `Date?` | nil | V1 base | Most-recent tale timestamp |

No migration delta.

## V2 schema design

When the V2 trigger fires, ship:

### Step 1 — Author `VoiceTaleSchemaV2`

```swift
// Packages/Libraries/Sources/Models/VoiceTaleSchema.swift

public enum VoiceTaleSchemaV2: VersionedSchema {
    public static let versionIdentifier = Schema.Version(2, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [
            PersistentVoiceTaleEntry.self,
            PersistentTraditionEntry.self,
            PersistentPlayerProgress.self,
            PersistentAnthologyMood.self,
            PersistentAchievement.self,
            PersistentMoodCollection.self,
        ]
    }
}

public typealias CurrentSchema = VoiceTaleSchemaV2
```

### Step 2 — Extend the `SchemaMigrationPlan`

```swift
public enum VoiceTaleMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [VoiceTaleSchemaV1.self, VoiceTaleSchemaV2.self]
    }

    public static var stages: [MigrationStage] {
        [.lightweight(fromVersion: VoiceTaleSchemaV1.self, toVersion: VoiceTaleSchemaV2.self)]
    }
}
```

### Step 3 — Move `@Model` class definitions to use `V2` typealias

Per `@.claude/rules/swiftdata.md` § "typealias for current models," every reference to a `@Model` class in app code goes through the `CurrentSchema` typealias chain. After V2 ships:

```swift
// app code refers to CurrentSchema.PersistentPlayerProgress.self
// and the typealias resolves to V2 transparently
```

In practice: the `@Model` class definitions stay in their current files (`Models/PersistentPlayerProgress.swift` etc.) and remain `public final class` — the version-namespaced typealiases live in `VoiceTaleSchema.swift` for callers that need version-explicit references.

### Step 4 — Verify the lightweight migration covers every additive field

Per the audit above, every additive field landed with either:

- An Optional + nil default (decodes from V1 with nil)
- A non-Optional + concrete default (decodes from V1 with the default)

SwiftData's lightweight migration handles both shapes automatically. No `willMigrate` / `didMigrate` blocks needed. The migration completes in milliseconds even on devices with hundreds of saved tales.

## Risk profile

| Risk | Likelihood | Mitigation |
|---|---|---|
| Migration triggers a fresh-install cascade (model classes appear unchanged but SwiftData sees a schema version bump) | Medium | The version bump alone is enough to trigger the migration stage; lightweight stages should not re-create the store. Test on a dev device with V1 data before ship. |
| Existing devices already have `lastActiveDate` etc. as nil → V2 reads them fine; no risk | Low | The fields landed pre-1.0, so production has not yet seen them on the App Store. |
| A future field rename (e.g. `taleTrialPlays` → `trialAttempts`) requires a custom migration stage | Medium | Adopt `@Attribute(originalName:)` for renames per `@.claude/rules/swiftdata.md` § "Lightweight (automatic)". Custom stages reserved for type changes / data transforms. |
| `iOS 26.1` array attribute Transformable storage bug (per `@.claude/rules/swiftdata.md` § 24) | Low | `completedKitIDsRaw: [Int]` + `taleIDsRaw: [UUID]` are the array-bearing fields. Test V1 → V2 migration on iOS 26.1 + iOS 26.2+ before ship. |

## Test plan when V2 ships

Per `@.claude/rules/swiftdata.md` § "Test every version path":

1. Generate a V1 `ModelContainer` at a temp URL with representative data (1 player progress + 5 tales + 5 traditions + 3 collections + 8 achievements + 4 anthology moods).
2. Open the same URL with V2; verify the container loads without throwing.
3. Verify every additive field is readable + matches its V1 nil/default state.
4. Run a save + re-open to verify the WAL is in sync.
5. Test on production-like data volumes (≥ 1000 tales) — per `@.claude/rules/swiftdata.md` § 29.

## When this plan converts to a handoff

The conversion is a follow-on PR titled `feat(Models): SwiftData V2 schema + lightweight migration stage`. The PR ships:

- `VoiceTaleSchemaV2` declaration
- Migration plan extension with `.lightweight` stage
- `typealias CurrentSchema = VoiceTaleSchemaV2`
- A new test file `VoiceTaleSchemaMigrationTests.swift` covering the V1 → V2 path
- Updated `CLAUDE.md` § "Things That Will Bite You" lifting the pre-App-Store rule for V2-onward fields

No Xcode-UI handoff is currently required (the entire change lives in Swift source). If iOS 26 introduces a new build-setting-level migration toggle that we'd need to enable, a separate handoff doc will be filed at that time.

## Cross-references

- `@.claude/rules/swiftdata.md` — schema versioning rules (§ 9–24)
- `@Packages/Libraries/Sources/Models/VoiceTaleSchema.swift` — current `VoiceTaleSchemaV1` + stub `VoiceTaleMigrationPlan`
- `@Docs/FEATURE_PLAN.md` § Phase 4 — Classroom + App Store + Final Polish (the trigger phase)
- `@Docs/IMPLEMENTATION_HANDOFF.md` — labsmith-shipped implementation context
- `@Docs/TECHNICAL_DESIGN.md` § Persistence — architecture context for the schema
