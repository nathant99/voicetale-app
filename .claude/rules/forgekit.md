# ForgeKit Integration

Shared SPM framework at `../forgekit/`. Apps import only the modules they need.

## Versioning

ForgeKit uses **semantic versioning** with annotated git tags (current: **1.0.0-rc.3** shipped 2026-06-17). **`forgekit/Docs/CHANGELOG.md` is authoritative** — labsmith rule/CLAUDE.md text drifts; verify CHANGELOG before quoting a specific version.

**1.0.0-rc.1 — `ForgeAvatar` BREAKING simplification** per labsmith ADR-022 (2026-06-02). The 108-WebP composable accessory pipeline + `AvatarAssetCatalog` actor + `AvatarStudioView.Presentation` (.lite/.full) enum + `AvatarLayer` enum + `AvatarSpriteNode` are REMOVED. New Apple Contacts-style API: `AvatarConfig` (in ForgeModels — `tintIndex: Int` + `glyph: AvatarGlyph`), `AvatarGlyph` enum (.initial / .symbol / .emoji), `AvatarRenderer` (pure SwiftUI), `AvatarStudioView` (single-presentation; takes `appGroupStore:` + `displayName: String?` + `onSaved:` + `onCancelled:`), `AvatarThemedGlyphProvider` protocol + `ForgeAvatarRegistry` for per-app overrides without forking. Migration for portfolio apps: drop the `catalog:` parameter on `AvatarStudioView` callers; drop the segmented `.lite`/`.full` picker; the editor is now single-shape. **VoiceTale migration reference impl**: `Packages/Libraries/Sources/AppFeature/ProfileTab/AvatarStudioSheet.swift` (round 2026-06-24 TWELFTH; PR #124).

**1.0.0-rc.2 — `ForgeMasteryEngine` new client module** (depends on ForgeModels + ForgeGamification). All public types are `nonisolated struct` / `nonisolated enum` — pure value types. `MasteryGraph<Topic>` (cycle/duplicate/unknown-prereq detection at init; stable topological order via lexicographic DFS), `TopicMasteryState` (FSRS-6 + attemptCount + rolling recentOutcomes; `masteryScore = 60% retrievability + 40% recent accuracy`; `isRacingAhead` / `isStuck` heuristics), `AttemptOutcome` enum, `NextProblemPicker<Topic, ProblemID>` (extend / consolidate / stretch per Vygotsky-ZPD), `MasteryUpdater`. Closes Phase A of the VoiceTale ForgeMasteryEngine integration per `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` (PR #124, ELEVENTH-round TWELFTH same-day round 2026-06-24). **Phase B SHIPPED PR #128 (2026-06-25 THIRTEENTH round)**: `QuizMachine` gains `questionStartedAt: Date?` + `elapsedSeconds(now:)` (pure value-type per state-machines.md); `QuizView.handleChoice` routes outcomes through `MasteryUpdater.recordAttempt(...)` via env-injected `KitMasteryStore` (`Packages/Libraries/Sources/AppFeature/QuizTab/QuizView.swift:recordKitMasteryAttempt`); new `MasteryBand` 4-quartile helper (`Packages/Libraries/Sources/AppFeature/Adaptive/MasteryBand.swift`) buckets `[0,1]` scores into `emerging / developing / meeting / deepening`; new categorical `kitMasteryAdvanced(kit:fromBand:toBand:)` analytics event fires ONLY on band crossings — raw `masteryScore` doubles NEVER travel (anti-fingerprinting + COPPA-2026 anti-PII discipline). Bootstrap pattern: `AppRootView.task` fetches `PersistentPlayerProgress` via `VoiceTaleStore.fetchOrCreateProgress(in:)` + calls `kitMasteryStore.bootstrap(progress:)` once per cold launch. **Phase C SHIPPED PR #132 (2026-06-25 FOURTEENTH round)**: new `Services/Adaptive/KitMasteryRecommender` (`nonisolated struct`) wraps `NextProblemPicker<KitID, KitID>` (problem IDs = the KitIDs themselves; one "problem" per kit) and projects each engine `Recommendation` into a typed `KitMasteryRecommendation(kit: KitID, kind: KitMasteryCopyCatalog.Kind, brambleCopy: String)`; new `Models/KitMasteryCopyCatalog` is the SINGLE seam where Bramble speaks about mastery state — 27 vetted second-person warm-curiosity lines (3 kinds × 9 kits) with an enforced anti-shame token blocklist (no `hard`/`easy`/`wrong`/`stuck`/`behind`/`master`/`score`/`level up`); `QuestionKitLoader` gains `loadKit(forKitID:)` + recommendation-first `loadKitForRotation(seed:recommendation:)` (falls back to week-of-year when `nil`); `QuizView` gains `preselectedKit: KitID?`; `ProgressTabView`'s `practiceCard` becomes `practiceSurface` — engine signal → three-card extend / consolidate / stretch stack with non-judgmental SF Symbols (`leaf.fill` / `arrow.clockwise.circle.fill` / `sparkles`; trophy / star / rosette / medal explicitly blocked); empty state → legacy single-card surface preserved. Anti-shame token blocklist unit-test-enforced via `KitMasteryRecommenderTests.copyCatalogAvoidsShameTokens`. **Phase D SHIPPED PR #136 (2026-06-25 FIFTEENTH round)**: mastery-driven "deeper challenge" affordance surfaces on each unlocked Adventure mode-card when the kid's mastery on the dominant kit crosses the edge-of-competence threshold (`≥ 0.80` per the engine's Vygotsky-ZPD floor). New `Models/ModeMasteryMapping` is the canonical mode-card → KitID table (Hook Builder → `.hookCraft`, Pacing Walk → `.pacingRhythm`, Turn Drill → `.surprisePivot`, Callback Refrain → `.closingGrace`); Tale Trial is intentionally unmapped (a mastery hint on a blind-judged surface would defeat the rubric). New `Services/Adaptive/DeeperChallengeAffordance` is a pure value-type service: `shouldSurface(masteryScore:)` (nil-safe; cold-launch kid renders unadorned mode-card) + `brambleCopy(for:)` (delegates to `KitMasteryCopyCatalog.line(for: .stretch, kit:)` — single seam preserves anti-shame token blocklist enforcement) + `symbolName` (sparkles — matches the Practice-with-Bramble stretch card; trophy / star / medal / rosette explicitly blocked at the unit-test layer). `AdventureTabView` reads the env-injected `KitMasteryStore` and renders the affordance pill below the subtitle on each unlocked + mapped mode-card. New categorical `deeperChallengeAvailable(mode:)` analytics event travels the mode raw value only (`hook_builder` / `pacing_walk` / `turn_drill` / `callback_refrain`); the mapped kit, the mastery score, and the Bramble copy NEVER travel (anti-fingerprinting per COPPA-2026 anti-PII). One-fire-per-mode-per-appearance via a `@State Set` so scroll-induced re-renders don't flood the wire. **Phase D SECOND-HALF SHIPPED PR #139 (2026-06-25 SIXTEENTH round)**: the Bramble-register shift on reflection — closing the consumer-wiring lifecycle for ForgeMasteryEngine end-to-end (PR #124 → #128 → #132 → #136 → #139). The catalog gains a fourth `Kind` case (`.deeperChallengeOpener`) with 9 vetted past-tense Bramble-voice lines ("Bramble noticed you [verbed] this time") — the SAME anti-shame token blocklist + Bramble-prefix anchor + sparkles symbol as the existing 3 kinds; the symbol reuse is intentional for visual continuity between affordance pill (PR #136) → reflection opener (PR #139). Threading: new `Models/TaleRecordingContext` value type (pure `nonisolated struct` carrying optional `deeperChallengeKit: KitID?`) + new `Services/Adaptive/RecordingContextCoordinator` (`@MainActor @Observable` process-singleton mirroring `IntentTabCoordinator` — one-shot consume + clear semantics) carry the Adventure-card pill-tap signal into `TellMachine.recordingContext` → `TellView.runReflection` → `BrambleMentor.reflect(..., deeperChallengeOpener:)`. `BramblePromptBuilder.reflectionPrompt(..., deeperChallengeOpener:)` injects a "prepend verbatim" directive into the LM prompt body; `BrambleMentor.applyDeeperChallengeOpener(_:opener:)` (public static helper mirroring `applyFavoriteMoodCallback`) belt-and-braces prepends the opener to the first craft observation (idempotent against already-prefixed observations — the LM may obey the prompt OR may not). New categorical `deeperChallengeTaleStarted(mode:)` analytics event fires on pill-tap (distinct from the existing `.deeperChallengeAvailable(mode:)` which fires on pill-surface) — mode raw value travels; the dominant kit + mastery score + Bramble register-shift opener NEVER travel (anti-fingerprinting + COPPA-2026 anti-PII discipline replays the affordance-half wire shape). Suppression: distress paths bypass the opener entirely (the hold-space register comes first); retell + beat-skipped paths bypass too (those surfaces are themselves register shifts; layering the opener would muddy the register). The pill-tap routes via `IntentTabCoordinator.shared.request(destination: .tell)` so the existing intent-routing surface handles the cross-tab transition cleanly. Round-stats: **38 new tests across 5 suites** (`TaleRecordingContextTests` / `KitMasteryCopyCatalogDeeperChallengeOpenerTests` / `RecordingContextCoordinatorTests` / `BrambleDeeperChallengeOpenerTests` + sibling `BramblePromptBuilderDeeperChallengeOpenerTests` / `AnalyticsServiceTests` additions) + 48 regression tests stable; `KitMasteryRecommenderTests.catalogIsComplete` auto-extends to 4 kinds × 9 kits = 36 entries; `copyCatalogAvoidsShameTokens` auto-covers all 36 entries including the 9 new opener lines. **Phase D second-half closure completes the full Phase A → B → C → D-affordance-half → D-second-half consumer-wiring lifecycle for ForgeMasteryEngine across a six-round chain — the first complete CLOSURE of a ForgeKit module's consumer-wiring lifecycle in the auto-cycle chain.** **Phase D parity polish SHIPPED PR #145 (2026-06-26 EIGHTEENTH round)**: Adventure-card practice-with-Bramble extend/consolidate badge — kid-facing parity polish bringing the broader `KitMasteryRecommender` surface (previously visible only on `ProgressTabView`'s `practiceSurface` three-card stack per PR #132) onto each unlocked Adventure mode-card as a small in-context badge. New pure value-type service `Services/Adaptive/PracticeWithBrambleBadge` (`nonisolated enum`; mirrors `DeeperChallengeAffordance` shape) delegates to the existing recommender — NO new threshold logic; the engine's bands stay canonical. `badge(for:masteryStates:recommender:)` returns the first `(extend | consolidate)` recommendation matching the requested kit; returns `nil` for `.stretch` (deferred to `DeeperChallengeAffordance` — no double-render). `AdventureTabView.practiceBadgeView(badge:tint:)` is a small-register Label below the existing deeper-challenge pill slot — NOT a `Button` (informational; the Progress tab's three-card surface owns the tap-to-act path). Symbol comes from `KitMasteryCopyCatalog.Kind.symbolName` (`leaf.fill` for extend; `arrow.clockwise.circle.fill` for consolidate). New categorical analytics event `practiceWithBrambleAvailable(mode:kind:)` mirrors `deeperChallengeAvailable(mode:)` wire shape — mode raw value + kind raw value (`extend` / `consolidate`) travel; the dominant kit + mastery score + Bramble copy NEVER travel (anti-fingerprinting per COPPA-2026 anti-PII). One-fire-per-(mode, kind)-per-appearance via a new `@State Set` keyed by `"<mode>|<kind>"`. 11 new tests (8 in `PracticeWithBrambleBadgeTests` — Tale Trial unmapped invariant / no double-render with stretch pill / mid-band kit surfaces extend or consolidate / catalog single-seam / exhaustive anti-shame blocklist over `(.extend, .consolidate) × KitID` / symbol register lock-down / cold-launch nil / no cross-kit leak + 3 in `AnalyticsServiceTests`); 0 regressions; 29/29 ServicesTests covered + 26/26 AnalyticsServiceTests pass. The parity polish closes the recommended-next-session priority #1 from the SEVENTEENTH-round handoff and demonstrates that the within-round multi-PR Default scales cleanly through cross-module post-closure parity polish (the round ships a parity-polish-only PR alongside the parallel ForgeReflection parity polish at PR #146 — monthly engagement digest sibling — within a single auto-cycle round). **Phase D parity polish tap-to-act SHIPPED PR #151 (2026-06-26 NINETEENTH round)**: scope-reversal follow-on to PR #145 — the badge that landed informational (NOT a `Button`) in the EIGHTEENTH round is promoted to a tap-affordance. `AdventureTabView.practiceBadgeView(badge:tint:gateID:)` becomes a `Button`; tap fires the new categorical analytics event `practiceWithBrambleStartedFromAdventure(mode:kind:)` AND presents `QuizView(preselectedKit: badge.kit)` via a new `.sheet` (mirrors `ProgressTabView.recommendationCard(_:)` from Phase C). New `@State pendingPracticeKit: KitID?` + `@State isPracticePresented: Bool` mirror `ProgressTabView`'s sheet-presentation pattern. New analytics event mirrors the wire shape of `practiceWithBrambleAvailable(mode:kind:)` — mode + kind raw values travel; the dominant kit + mastery score + Bramble copy NEVER travel (anti-fingerprinting per COPPA-2026 anti-PII). The distinct event name lets cohort analysis separate "badge lit" from "badge acted on" — same separation pattern as the `.deeperChallengeAvailable` ↔ `.deeperChallengeTaleStarted` split from Phase D second-half. Anti-shame invariants preserved unchanged: Tale Trial NEVER lights (unmapped per `ModeMasteryMapping`); `.stretch` defers to `DeeperChallengeAffordance` (no double-render); catalog single-seam discipline preserved; copy still flows through `KitMasteryCopyCatalog.line(for:kit:)`. 4 new tests in `AnalyticsServiceTests`; 0 regressions; 30/30 AnalyticsServiceTests + 8/8 PracticeWithBrambleBadgeTests pass. The tap-to-act PR is the FIRST round in the auto-cycle chain to demonstrate a scope-reversal follow-on (explicitly reversing the EIGHTEENTH-round's "NOT a Button" deliberate scope choice with rationale documented in the new PR's body).

**1.0.0-rc.3 — patch-only** ship-prep hygiene + Linux platform stub closure.

**0.99.1 — patch-only** test rewrite (`ForgeAIGeneratorTests` → `ForgeAIContentCachePublicAPITests`).

**0.99.0 — `ReflectionPromptModifier` + `ReflectionPromptStorage` shipped** (ForgeUI + ForgePersistence; closes Move R2 — journal hooks / structured reflection prompts for ~22 Reflect-pillar apps). VoiceTale Phase A integration shipped PR #123 (2026-06-24 TWELFTH-round): `VoiceTaleReflectionConfigCatalog.forSocraticPrompt(_:kitNumber:)` + `@MainActor @Observable VoiceTaleReflectionStore` wrapping the storage actor, mirroring the zero-`@Query` cache pattern. `ReflectionEntryRecord` registered in `VoiceTaleSchemaV1.models`. **Phase B SHIPPED PR #127 (2026-06-25 THIRTEENTH round)**: `BrambleReflectionView` gains an "Answer Bramble" action-row button surfaced ONLY when `canAnswerBramble` (non-empty Socratic prompt + store bootstrapped + no distress hold-space). Tap presents the canonical `ForgeUI.reflectionPrompt(...)` sheet via `VoiceTaleReflectionConfigCatalog.forSocraticPrompt(_:kitNumber:)`; `onComplete` persists via `VoiceTaleReflectionStore.save(_:)` + emits a categorical `brambleAnswered(modality:)` analytics event (modality raw value only — text payload NEVER travels). `.skip` off-ramp persists for the parent-dashboard "engaged-then-skipped" surface but carries no text payload (anti-shame discipline per ADR-016). `AppRootView.task` bootstraps the store once + injects via new `@Entry voiceTaleReflectionStore` env value. `TellView` passes `reflectionKitNumber: activeKit?.kit` so the catalog can emit per-kit-scoped config ids (`bramble.socratic.<kit>` vs `bramble.socratic.freeform`). **Phase C SHIPPED PR #131 (2026-06-25 FOURTEENTH round)**: weekly retention purge cadence wired into `AppRootView.task` per FTC 2026 COPPA Rule Amendment's defined-retention-period requirement. New pure-function `Models/ReflectionRetentionPolicy` (`shouldPurge` / `cutoff` / `clampedRetentionDays` / `removedCountBucket`) is unit-testable without a SwiftData host. Two new `@AppStorage` keys: `voicetale.reflection.purge.last_run` (last-run timestamp) + `voicetale.reflection.retention_days` (90 / 180 / 365; default 180). `SettingsView` gains a "How long reflections stick around" 3-pick `Picker` under a new "Reflections" section. New categorical `reflectionsPurged(removed:)` analytics event — bucketed via `ReflectionRetentionPolicy.removedCountBucket`; raw delete counts NEVER travel (anti-fingerprinting). Corrupt `@AppStorage` writes degrade to the 180-day default rather than skipping the purge (anti-defeat invariant). 12 ModelsTests lock cadence / cutoff / clamp / bucket invariants. **Phase D SHIPPED PR #135 (2026-06-25 FIFTEENTH round)**: parent-dashboard opt-in read-back surface. New `AppFeature/ProfileTab/ReflectionJournalView` hosts the explicit opt-in toggle via new `@AppStorage("voicetale.reflection.parent_journal_visible")` key (default OFF — kid-private posture is the canonical state per COPPA-2026 opt-in default). When ON, lists modality + responded-at + (optional) kit number per row — the kid-typed `textValue` payload NEVER appears, even after opt-in (anti-PII discipline). `.skip` rows render the engagement-then-private signal. `VoiceTaleReflectionStore.parentVisibleEntries(promptVisibility:)` is a pure value-type pass-through over the cached snapshot — preserves the zero-`@Query` discipline. `SettingsView` gains a `NavigationLink` under the existing "Reflections" section. New categorical `parentReflectionJournalOpened(visibleCount:)` analytics event reuses `ReflectionRetentionPolicy.removedCountBucket` for wire-shape lockstep with `reflectionsPurged(removed:)`; raw counts NEVER travel. 10 new AppFeatureTests lock the opt-in default posture, per-promptID filter partition, `.skip`-row visibility without text payload, analytics-event bucketing, raw-count anti-leak invariant, and the `@AppStorage` key shape. **Phase D second-half polish SHIPPED PR #142 (2026-06-25 SEVENTEENTH round)**: parent-dashboard "This week" engagement digest row in `ReflectionJournalView`. New pure value-type `Models/ReflectionWeeklyEngagement` (`totalBucket: String` + `perModalityBucket: [ReflectionResponseModality: String]` — `.zero` per-modality buckets are dropped so the view never renders "0 voice / 0 drawing / 0 emoji" rows; counts bucketed via the existing `ReflectionRetentionPolicy.removedCountBucket(_:)` so the wire shape stays in lockstep with the sibling `parentReflectionJournalOpened(visibleCount:)` / `reflectionsPurged(removed:)` events). New `VoiceTaleReflectionStore.weeklyEntries(now:)` + `weeklyEngagement(now:)` pure pass-through over the cached snapshot — 7-day boundary semantics mirror `ReflectionRetentionPolicy.cutoff` (`>=` cutoff includes boundary entry; strictly older entries dropped). View renders the digest ONLY when the grown-up has opted in AND the kid has engaged in the last 7 days — empty-week edge case bypasses the section. `.skip` modality is intentionally dropped from the per-modality short-phrase (a grown-up second-guessing the kid's privacy choice is the anti-shame failure mode; the per-entry list's "Engaged then chose privacy" row already surfaces engagement-then-private signals at the row level). Anti-PII discipline: raw counts NEVER travel — only bucketed labels appear on the row. NO new `@AppStorage` keys + NO new analytics events. 13 new tests across 2 suites (`ReflectionWeeklyEngagementTests` (8) + `VoiceTaleReflectionStoreTests` weekly-engagement additions (5)) + 33 regression tests stable; the polish closes the recommended-next-session priority #1 from the SIXTEENTH-round handoff and demonstrates that the within-round multi-PR Default scales cleanly through post-closure consumer-polish (the round ships polish-only consumer-wiring follow-on for an ALREADY-CLOSED ForgeKit module integration lifecycle). **Phase D second-half polish SIBLING SHIPPED PR #146 (2026-06-26 EIGHTEENTH round)**: parent-dashboard monthly engagement digest sibling — natural 30-day extension of PR #142's weekly digest. New `VoiceTaleReflectionStore.monthlyEntries(now:)` + `monthlyEngagement(now:)` pure pass-through over the cached snapshot — 30-day boundary semantics identical to weekly (`>= cutoff` inclusive; strictly older dropped). Reuses the existing `ReflectionWeeklyEngagement.make(from:)` factory at the monthly window (the value type's name is window-neutral). `ReflectionJournalView.monthlyDigestSection` renders directly below `weeklyDigestSection` — same gating (opt-in + non-empty window); empty-month edge case bypasses the section. Renamed view helper from `weeklyDigestHeadline` to window-neutral `digestHeadline` (single seam for the bucket-to-phrase mapping; both windows share it). Visual register: same `Label` + calendar-themed SF symbol; uses `calendar` (vs week's `calendar.badge.clock`) so the eye can scan-distinguish the windows. NO new analytics events. NO new `@AppStorage` keys. Anti-PII invariants preserved verbatim (raw counts NEVER travel; `.skip` modality dropped from per-modality phrase; `.zero` per-modality buckets dropped). 6 new tests in `VoiceTaleReflectionStoreTests` (`monthlyEngagementOnEmptyStoreIsEmpty` / `…IncludesOnlyEntriesInWindow` / `…IncludesBoundaryEntry` / `…ExcludesEntryStrictlyOlderThanBoundary` / `…DropsZeroModalityBuckets` / `monthlyDigestReusesFactoryShape`); 27/27 total tests pass; 0 regressions. The polish-sibling closes the recommended-next-session priority #2 from the SEVENTEENTH-round handoff and demonstrates that the within-round multi-PR Default scales cleanly through cross-module post-closure parity polish (the round ships a parity-polish-only PR alongside the parallel ForgeMasteryEngine parity polish at PR #145 — Adventure-card extend/consolidate badge — within a single auto-cycle round). **Phase D second-half polish QUARTERLY SIBLING SHIPPED PR #150 (2026-06-26 NINETEENTH round)**: parent-dashboard "Past 90 days" engagement digest — natural 90-day extension of PR #146's monthly digest. New `VoiceTaleReflectionStore.quarterlyEntries(now:)` + `quarterlyEngagement(now:)` pure pass-through over the cached snapshot — 90-day boundary semantics identical to weekly + monthly (`>= cutoff` inclusive; strictly older dropped). Reuses the existing `ReflectionWeeklyEngagement.make(from:)` factory at the 90-day window — locks the load-bearing window-neutral value-type convention from the EIGHTEENTH round (the type's name reflects the FIRST consumer; future window-extension variants reuse the factory at their respective windows without renaming). `ReflectionJournalView.quarterlyDigestSection` renders directly below `monthlyDigestSection` — same opt-in gating; empty-quarter edge case bypasses the section. Visual register: `calendar.badge.checkmark` distinguishes the quarterly row from the week's `calendar.badge.clock` + month's `calendar` so all three windows can be scan-distinguished. NO new analytics events. NO new `@AppStorage` keys. Anti-PII invariants preserved verbatim from PR #142 + PR #146 (raw counts NEVER travel; `.skip` modality dropped from per-modality phrase; `.zero` per-modality buckets dropped). 6 new tests in `VoiceTaleReflectionStoreTests` mirroring the monthly pattern at the 90-day boundary; 0 regressions; 25/25 VoiceTaleReflectionStoreTests pass.

**0.98.0 — `CastEncounter` primitive shipped** (`ForgePersistence`; SwiftData `@Model` + `CastEncounterStore` actor; closes DN-D12 longitudinal cast progression for ~37 high-priority adopters).

**0.97.0 — `CastDialog` primitive shipped** (`ForgeAI`; FoundationModels-backed cast voice with reviewer-signoff gating + ForgeServerSafety moderation pipeline; closes DN-D3 for ~26 non-trauma + ~25-30 trauma-adjacent apps).

**0.96.0 — `ForgeServerLeaderboard` module shipped** (NEW 11th server module; zero-dep `LeaderboardStore` protocol + `InMemoryLeaderboardStore` reference impl; PostgresLeaderboardStore deferred to forgesync Phase 6; closes Move T8 async leaderboard for ~31 apps).

**0.95.0 — `HubContributionConfig.togetherMode` field shipped** + `TogetherMode.Archetype` enum (5 cases: passAndPlay / cooperativePair / bystanderRoleplay / classroomLive / asyncLeaderboard; closes Move T10 for 4 aggregator + ~30 source apps).

**0.94.0 — `ForgeClassroom` module shipped** (LiveKit-Cloud-backed v1 live classroom). 0.86→0.94 added 7 new client modules: `ForgeAvatar` / `ForgeBranding` / `ForgeClassroom` / `ForgeColoringMode` / `ForgeManagedConfiguration` / `ForgeMiniGames` / `ForgePuzzles` + 1 new server module: `ForgeClassroomServer`. Module count post-0.99: **58 total** (45 client + 11 server + 2 shared).

**0.89.0 — `DyadicPair` API shipped** (unblocks MindForge / SafetyForge / CardForge / GrammarForge pass-and-play retrofits; lives in `ForgePassAndPlay`).

**0.86.0 — DIR/FEDC API gap closure** — 7 new affect-aware types in `ForgeDevelopmental` + `ForgeModels`: `EmotionSnapshot`, `AffectCalibrator`, `CoRegulationEngine`, `SensoryRamp`, `FEDCDemonstrationRecord`, `UserFEDCProfile`, `FEDCPromptContext` + `StreakManager.recordSession(emotionSnapshot:...)` overload + new `StreakResult.heldUnderDistress` case. Apps switching exhaustive `StreakResult` switches must add `.heldUnderDistress` arm OR `@unknown default` — `ExtendedStreakManager` forwards as `.sameDay` so apps using the wrapper are unaffected.

**0.85.0** added Linux platform support via `#if canImport(CoreGraphics)` guard in `AvatarLayer`.

- **Runtime check**: `ForgeKitVersion.version` / `.major` / `.minor` / `.patch` in ForgeModels
- **CHANGELOG**: `forgekit/Docs/CHANGELOG.md` — Keep a Changelog format
- **Release checklist**: Update `ForgeKitVersion.swift` → update `CHANGELOG.md` → commit → `git tag -a X.Y.Z -m "message"` → `git push origin main --tags`

## Source Layout (0.57.0 soft-split)

```
forgekit/Sources/
├── Client/   45 modules — UI, gameplay, persistence, on-device AI, accessibility, avatars, classroom, reflection
├── Server/   11 modules — Hummingbird 2 actors, middleware, matchmaking, email, classroom, leaderboard
└── Shared/    2 modules — ForgeModels, ForgeServerDTOs (consumed by both)
```

Public API and product names are unchanged — apps still write `.product(name: "ForgeIllustrations", package: "forgekit")` and `import ForgeIllustrations`. The split is internal-only. When reading ForgeKit source, find files with `find /Volumes/Data/Projects/GitHub/forgekit/Sources -ipath "*<ModuleName>*" -name "*.swift"`.

## Remote GitHub Dependency (Default)

`Libraries/Package.swift` uses `.package(url: "https://github.com/nathant99/forgekit.git", from: "0.99.0")` — pin to minimum version, allows multiple app workspaces open simultaneously. After a ForgeKit release, `File > Packages > Update to Latest Package Versions` in each consuming workspace.

**Migration from `branch: "main"`**: Replace `branch: "main"` with `from: "0.99.0"` in `Libraries/Package.swift`. This pins to the current release and auto-resolves compatible updates (up to 1.0.0).

### Local Development Fallback

Temporarily switch to `.package(path: "../../forgekit")` for active ForgeKit development — enables edit-build-test without pushing. **Only one workspace can claim a local path dependency** — close other workspaces using ForgeKit locally. Switch back to the remote URL with `from:` when done.

## Module Catalog (50 modules — 39 client + 9 server + 2 shared)

For the authoritative list, run `ls ../forgekit/Sources/{Client,Server,Shared}`. The catalog below names every module and gives a one-line purpose; full APIs are documented in each module's `Tests/` and inline `///` doc-comments.

### Shared (2) — `Sources/Shared/<Module>/`

| Module | Purpose |
|---|---|
| `ForgeModels` | Foundational domain types: `StudentProfile`, `AchievementDefinition`, `BloomLevel`, `GradeLevel`, `ProgressRecord`, `ContentItem`, `CurriculumStandard`, `ForgeKitVersion` |
| `ForgeServerDTOs` | Typed JSON payloads on the wire — clients decode these, servers emit them. Reclassified to Shared in 0.57.0 |

### Client (38) — `Sources/Client/<Module>/`

| Module | Depends On | Purpose |
|---|---|---|
| `ForgeUI` | ForgeModels | SwiftUI components: buttons, progress bars, HUD, feedback modifiers, onboarding, theming |
| `ForgeAccessibility` | ForgeUI | COPPA compliance (parental consent with 12-month expiry), session timer, haptics, ADHD mode |
| `ForgeAdventure` | ForgeModels | Adventure mode framework: 13 game mode engines, map progression, mode availability, multiplayer config. **Hub subdirectory (0.79.0)**: `HubContribution`, `HubContributionRegistry` (actor), `HubContributionConfig` (Codable snake_case + Int `BloomLevel`), `HubGenericChallengeView`, `HubMentorOrchestrator` (+ `HubMentorSession` protocol + `NoOpHubMentorSession`), value types (`ZoneID`, `HubPresentation`, `MentorPersona`, `AudioVoiceProfile`, `HubKitResource`, `EngineCopy`, `HubChallengeResult`, `HubQuestion`/`HubQuestionKit`, `HubChallengeContext`), `Color(hex:)` extension |
| `ForgeAI` | ForgeModels | FoundationModels helpers: session management, availability gating |
| `ForgeAnalytics` | ForgeModels | Analytics events, session tracking, engagement metrics |
| `ForgeAvatar` (0.82.0) | ForgeModels (0.83.0+) | Composable avatar system. `AvatarConfig` + `AvatarLayer` live in `ForgeModels` since 0.83.0 (single source of truth, no WebP-asset drag on ForgeSync). Other public types: `AvatarAssetCatalog` (actor, multi-bundle resolution), `AvatarRenderer` (SwiftUI, renderer-masking clips layers to `anchorRect`), `AvatarSpriteNode` (SKNode w/ lazy visual setup). Bundles 128 WebP assets (6.8 MB): 20 anchors + 40 layers + 68 cosmetics. Toca-Boca-style chunky-cartoon aesthetic per `labsmith/Docs/DESIGN_AVATAR_AESTHETIC.md`. **Edit authority**: see Avatar Edit Authority section below |
| `ForgeAudio` | ForgeModels | Audio playback, SFX management |
| `ForgeCelebration` | ForgeModels, ForgeIllustrations | Celebration *orchestration* (`CelebrationCoordinator`, `CelebrationOverlayModifier`); separate from `ForgeIllustrations.CelebrationCatalog` which owns the assets |
| `ForgeContent` | ForgeModels, ForgeNetworking | Content loading, question kit parsing |
| `ForgeDevelopmental` | ForgeModels | DIR/FEDC developmental scaffolding — 16 levels, capacity-based support |
| `ForgeEmotionAware` | ForgeModels | Emotion-aware adaptive features |
| `ForgeEvents` | ForgeModels | Seasonal event lifecycle, 41 built-in holidays, celebration packs |
| `ForgeExperiments` | ForgeModels | On-device A/B testing, COPPA-compliant experimentation |
| `ForgeGameCenter` | ForgeModels | GameCenter integration: leaderboards, achievements, turn-based matchmaking |
| `ForgeGameEngine` | ForgeModels | SpriteKit helpers: scene management, node extensions |
| `ForgeGamification` | ForgeModels, ForgePersistence | XP, streaks, achievements, economy, spaced repetition |
| `ForgeIllustrations` | ForgeModels | Illustration registry/loader/resolver, prebuilt SwiftUI views, `CelebrationCatalog` (8 Lottie celebrations), on-device generation bridge |
| `ForgeIntents` | ForgeModels | App Intents framework integration for Siri / Shortcuts |
| `ForgeKnowledgeGraph` | ForgeModels | Knowledge-graph traversal for adaptive content suggestion |
| `ForgeLiveActivities` | ForgeModels | Dynamic Island + Lock Screen Live Activity support |
| `ForgeMasteryEngine` (SHIPPED 1.0.0-rc.2 per ADR-026) | ForgeModels, ForgeKnowledgeGraph, ForgeGamification | Adaptive mastery practice spine: `MasteryGraph<Topic>` DAG (with cycle / duplicate / unknown-prereq detection at init; stable `topologicalOrder` via lexicographic DFS) + `TopicMasteryState` (FSRS-6 + attemptCount + rolling `recentOutcomes` window; derived `masteryScore` = 60% FSRS retrievability + 40% recent accuracy; `isRacingAhead` / `isStuck` convenience flags) + `NextProblemPicker.recommendations` (extend / consolidate / stretch with `SelectionRationale`) + `MasteryUpdater`. Pure value-type API; all `nonisolated`. Edge-of-competence heuristic (Vygotsky ZPD; target difficulty in [mastery + 0.10, 0.20] band). First consumer: AlcumusForge. Spec: `forgekit/Docs/HANDOFF_FROM_LABSMITH_FORGEMASTERYENGINE.md`. SHIPPED: `forgekit/Docs/HANDOFF_FROM_FORGEKIT_FORGEMASTERYENGINE_SHIPPED.md` |
| `ForgeLocalization` | — | String catalog management, pluralization, brand guard, date formatting |
| `ForgeMath` | ForgeModels | Math utilities, expression evaluation, number formatting |
| `ForgeMultipeerKit` | ForgeModels | MultipeerConnectivity wrapper (distinct from ForgeMultiplayer) |
| `ForgeMultiplayer` | ForgeModels | Multiplayer session management, turn-based and real-time modes |
| `ForgeNavigation` | ForgeModels, ForgeUI | Navigation patterns, tab/sidebar coordination |
| `ForgeNetworking` | ForgeModels | Network layer, API client |
| `ForgePartyGames` | ForgeModels | Local-multiplayer mini-game engines: ForbiddenWords, ForeheadReveal, HotPotato, RapidRecall |
| `ForgePassAndPlay` | ForgeModels | Pass-and-play state machine + 4-stage privacy curtain |
| `ForgePedagogy` | ForgeModels | Pedagogical strategies, bloom-level targeting, hint scaffolding. **PolyaScaffold SHIPPED 1.0.0-rc.2 per ADR-026** (`Sources/Client/ForgePedagogy/Polya/`): `PolyaScaffold` protocol + `PolyaPhase` 4-case enum (understand / plan / execute / lookBack with `Understanding` / `StrategyPlan` / `ExecutionState` / `Reflection` associated structs) + `StrategyTag` enum (14 canonical + `.custom`) + `PolyaMachine` state-machine + 3 `Configuration` presets (.default / .strict / .permissive). Load-bearing `hintsAllowedBeforePlan: 0` default = articulate-before-hint enforcement. First consumers: MathCircle + NumberSense. Spec: `forgekit/Docs/HANDOFF_FROM_LABSMITH_POLYASCAFFOLD.md`. SHIPPED: `forgekit/Docs/HANDOFF_FROM_FORGEKIT_POLYASCAFFOLD_SHIPPED.md` |
| `ForgePersistence` | ForgeModels | SwiftData helpers: container configuration, migration utilities |
| `ForgeProgression` | ForgeModels | Session-based content gating, calendar-aware session counting, debug bypass |
| `ForgeReporting` | ForgeModels | Progress reports, standards-mapped analytics dashboards |
| `ForgeSensory` | ForgeModels | Multi-modal feedback coordination (visual + audio + haptic) |
| `ForgeSettings` | ForgeModels | Settings / preferences storage |
| `ForgeSocial` | ForgeModels | Social features (leaderboards, friend codes — COPPA-bound) |
| `ForgeSpotlight` | ForgeModels | Spotlight search integration via `ForgeSpotlightIndexer` actor |
| `ForgeStateMachine` | ForgeModels | Generic finite state machine helpers |
| `ForgeSync` | ForgeModels | Cross-app progression sync, XP tracking, streak tracking, achievements |
| `ForgeWidgets` | ForgeModels | Home-screen widget support (WidgetKit) |

### Server (9) — `Sources/Server/<Module>/`

For Hummingbird 2 microservices (`CuriosityQuestServer`, `forgesync`, etc.). See `Docs/TEMPLATE_IMPLEMENTATION_HANDOFF_SERVER.md` (in any server-bearing app repo) for verified APIs. See `@Docs/GUIDE_FORGESERVER_ADOPTION.md` for the thin-wrapper adoption playbook.

| Module | Purpose |
|---|---|
| `ForgeServerActors` | `HTTPRateLimiter`, `WebSocketRateLimiter`, `HistoryStore`, `VerificationCodeStore` (0.58.0 `issue(_:for:)` overload), `PeriodicCleanupService`, `RoomCodeAlphabet`, `RoomManager`, `MessageWriter`, **`ConnectionRegistry<Writer>` (0.60.0)**, **`SingleFlightJobQueue<Key,Value>` (0.63.0)**, **`RoomRegistry<Room: ForgeRoom>` (0.68.0)** |
| `ForgeServerMatchmaking` | Skill-based queue, match formation |
| `ForgeServerMiddleware` | `APIKeyValidator` (nonisolated struct), `CORSPolicy`, `HeaderTokenValidator`, **`SecurityHeaders` (0.60.1)** |
| `ForgeServerMultiplayer` | Anti-cheat heuristics, elimination brackets, server-authoritative content |
| `ForgeServerRealTime` | `CountdownService`, game-state anchor primitives |
| `ForgeServerSafety` | `InputSafetyService` (`nonisolated struct` since 0.59.1), `OutputModerationService`, `CrisisResource.description` (0.59.0), **`SSEStreamModerator` + `SyntheticSSEResponseBuilder` (0.61.0)**, `SafetyConfig` output-side fields (0.66.0) |
| `ForgeServerTracking` | `APIUsageTracker` + `CallRecord` grouped summary (0.66.0), `EventStore<Event>` + `.remove(where:)/.remove(for:where:)` (0.66.0), **`APIQuotaTracker` (0.62.0)** |
| `ForgeServerWebSocket` | `BroadcastService` fan-out (+ stored-encoder init in 0.74.0), `GameMessageProtocol` envelope, **`FloorController<Speaker>` (0.64.0; `.pause()/.resume()` in 0.66.0)**, **`MessageRelay` static helpers (0.68.0)** |
| **`ForgeServerEmail` (0.65.0)** | `EmailMessage` / `EmailSender` protocol / `InMemoryEmailSender` / `VerificationEmailBuilder`. Vendor-agnostic — apps ship concrete Mailgun/SES/etc. adapters |

## ForgeUI Quick Reference

### Theming

Implement `ForgeTheme` protocol and inject via `.environment(\.forgeTheme, MyTheme())`:

```swift
protocol ForgeTheme: Sendable {
    var primaryColor: Color { get }
    var accentColor: Color { get }
    var backgroundColor: Color { get }
    var fontFamily: String? { get }
    var cornerRadius: CGFloat { get }
}
```

### Components

| Component | Init Parameters | Notes |
|---|---|---|
| `ForgePrimaryButton` | `title: String`, `isLoading: Bool = false`, `action: () -> Void` | Liquid Glass material, auto-disables when loading |
| `ForgeXPBar` | `currentXP: Int`, `xpForNextLevel: Int`, `level: Int` | Gradient fill, numeric text transitions |
| `ForgeProgressBar` | `value: Double`, `total: Double`, `label: String? = nil`, `showPercentage: Bool = true` | Generic progress, capsule shape |
| `ForgeScoreHUD` | `score: Int`, `totalQuestions: Int`, `streak: Int? = nil`, `currency: Int? = nil` | Composable game HUD overlay |
| `ForgeCurrencyHUD` | `amount: Int`, `label: String = ""` | Coin display with glass capsule |
| `ForgeStreakBadge` | `streak: Int`, `isActive: Bool` | Flame icon, pulse at milestones (5/10/25/50/100) |
| `ForgeTimerRing` | `remaining: TimeInterval`, `total: TimeInterval`, `warningThreshold: TimeInterval = 60` | Color shifts orange→red |
| `ForgeEmptyState` | `systemImage: String`, `title: String`, `description: String`, `action: (() -> Void)? = nil`, `actionTitle: String? = nil` | Wraps `ContentUnavailableView` |
| `ForgeCard` | `@ViewBuilder content: () -> Content` | Material card with theme corner radius |
| `ForgeOnboardingFlow` | `pages: [Page]`, `onComplete: () -> Void` | Multi-step with skip, parent handoff support |
| `ForgeAchievementPopup` | `badge: BadgeDisplayData`, `onDismiss: () -> Void` | Auto-dismisses after 3s, spring animation |

### View Modifiers

| Modifier | Parameter | Notes |
|---|---|---|
| `.correctFeedback(isActive:)` | `isActive: Bool` | Green flash + bounce. **NOT `trigger:`** |
| `.incorrectFeedback(isActive:)` | `isActive: Bool` | Red flash + shake |
| `.hudOverlay(alignment:content:)` | `alignment: Alignment`, `@ViewBuilder content` | Safe area-aware HUD positioning |

## ForgeGamification Quick Reference

### XPEngine

Pure value type — replaces custom level threshold arrays:

```swift
let engine = XPEngine(config: GamificationConfig())
engine.level(for: totalXP)         // Int
engine.xpRequired(forLevel: 5)    // Int (total XP needed)
engine.xpProgress(currentXP: xp)  // Double (0.0–1.0 within current level)
```

XP curves: `.standard` (level = sqrt(xp/100)), `.accelerated` (sqrt(xp/50)), `.custom((Int) -> Int)`.

### StreakManager

Actor — pure in-memory state, callers handle persistence:

```swift
let manager = StreakManager(currentStreak: 0, availableFreezes: 2)
let result = await manager.recordSession()  // StreakResult enum
```

Returns `.continued(streak:)`, `.frozenAndContinued(streak:freezesRemaining:)`, `.reset(previousStreak:)`, or `.sameDay(streak:)`.

### AchievementEngine

```swift
let engine = AchievementEngine()
let newBadges = engine.evaluate(definitions: defs, earnedIDs: earned) { def in
    // App-specific criteria check
}
```

### EconomyEngine

```swift
let engine = EconomyEngine(pricingCurve: ExponentialPricingCurve())
let newBalance = try engine.earn(amount: 50, currentBalance: balance)
let newBalance = try engine.spend(amount: 30, currentBalance: balance)
let (balance, upgrade) = try engine.purchaseUpgrade(upgrade: state, currentBalance: balance)
```

### SpacedRepetitionEngine (FSRS-6)

```swift
let srs = SpacedRepetitionEngine(desiredRetention: 0.9)
let newState = srs.reviewItem(state: fsrsState, quality: 4)  // quality 1-5
let isDue = srs.isItemDue(state)
let nextDate = srs.nextReviewDate(for: state)
```

### GamificationConfig

Central config passed to engines:

```swift
GamificationConfig(
    sessionTargetMinutes: 10...15,
    streakFreezeCount: 2,
    desiredRetention: 0.9,
    xpCurve: .standard,
    achievementDefinitions: [...]
)
```

## ForgeModels Quick Reference

| Type | Properties | Notes |
|---|---|---|
| `StudentProfile` | `id`, `displayName`, `gradeLevel`, `avatarAssetName?`, `createdAt` | Value type, not SwiftData — apps bridge to `@Model` |
| `AchievementDefinition` | `id`, `title`, `description`, `iconAssetName`, `xpValue`, `standard?` | Used by `AchievementEngine.evaluate()` |
| `BloomLevel` | `.remember` through `.create` | `Comparable` by cognitive complexity |
| `GradeLevel` | Grade band enum | Controls DDA difficulty |
| `BadgeDisplayData` | `id`, `title`, `iconAssetName`, `earnedAt` | UI display struct from `AchievementEngine.displayData()` |
| `FSRSState` | `stability`, `difficulty`, `lastReview`, `repetitions` | Spaced repetition memory state |

## Avatar Edit Authority (ForgeAvatar + ForgeSync, 0.85.0+)

Locked-in portfolio policy — see `labsmith/Docs/DECISION_AVATAR_EDIT_AUTHORITY.md` for full rationale (**R3** revision: universal full editor + hub-as-cross-portfolio-manager). `AvatarStudioView` **shipped in ForgeKit 0.85.0** (2026-05-17).

- **Any app MAY write `ForgeID.avatar`** via `appGroupStore.setAvatar(_:editedAt:)` — but apps using `ForgeAvatar.AvatarStudioView` don't call `setAvatar` directly; the view does it for them on Save. Last-write-wins on `avatarEditedAt`. If you must call `setAvatar` directly (hand-rolled paths are disallowed but the LWW rule still applies), pass `editedAt: .now`. The single-arg overload clears the timestamp; never use it
- **Render the editor via `ForgeAvatar.AvatarStudioView`, not hand-rolled UI.** Public `Presentation` enum:
  - **`.lite`** — default entry point in source apps. Skin tone + hair / outfit / eyes tint pickers
  - **`.full`** — adds background, frame, and accessories pickers. **Every app MAY offer both** (R3). Three adoption patterns observed in production (per `Docs/AUDIT_AVATAR_STUDIO_ADOPTION_RANKS_5_20_2026-05-28.md`):
    - **`.lite`-only** — recommended for Play-PRIMARY apps (curiosityquest reference impl: `Packages/Libraries/Sources/SharedUI/Onboarding/ForgeAvatarStudioShell.swift`). Profile/Settings entry; "More customization" affordance can re-present `.full` if added later
    - **`.full`-only** — recommended for Create-PRIMARY + Together-PRIMARY apps where accessory picker is part of identity loop (cubesensei reference impl: `Packages/Libraries/Sources/CubeUI/Tabs/ProfileTabView.swift:201`). Single tap → `.full` directly
    - **`.lite`+`.full` segmented toggle** — best-in-class R3 "both surfaces" pattern; lets player switch in-view without dismiss/reopen (**creaturecare reference impl**: `Libraries/Sources/AppFeature/AvatarStudioSheet.swift:62-68` — segmented picker with `@State presentation: AvatarStudioView.Presentation`; **quillspell reference impl** verified R141 #572: `Packages/Libraries/Sources/AppFeature/AvatarStudioSheet.swift` — same pattern, themed "Word Wizard" + 8 app-bundle accessories via `AvatarAssetCatalog(appBundles:)` + `.id(presentation)` for clean rebuild on toggle). Use this pattern when both presentations are equally relevant to the app's UX
- **AdventureHub differentiates by being the cross-portfolio identity manager**, NOT by exclusive access to `.full`. M7 wrapper features (multi-look save slots + badge-driven cosmetic unlock grid) live on top of `AvatarStudioView(.full)` and remain hub-exclusive. The editor itself is universal
- **Re-read `currentForgeID()?.avatar` when opening the editor** — not just at app launch. Player may have edited in another app since last open. `AvatarStudioView` does this automatically via `baselineEditedAt:` — pass it from your latest snapshot
- **Concurrent-edit conflict alerts are built into `AvatarStudioView`** — it observes `AppGroupStoreNotification.forgeIDUpdated` while open and surfaces a two-CTA alert (Discard & reload | Save and overwrite). Apps don't wire this themselves
- **Local cosmetics still OK for things outside the avatar** — apps MAY add in-app-only personalization (mascot tint, username color, app-only sticker pack, HUD palette) stored in their own SwiftData — three rules: (1) in-app only / no `AppGroupStore` writes, (2) no portfolio propagation, (3) no `AvatarLayer` overlap (no hair / face / outfit / eyes / mouth / accessories / background / frame)
- **Naming**: keep local cosmetics out of the `Avatar*` namespace — use `AppMascot…`, `AppNamePlate…`, `AppHUDPalette…`. Reserve `Avatar*` for the canonical types in `ForgeModels` + `ForgeAvatar`
- **No hand-rolled avatar editors** — don't build a per-app skin/hair/outfit picker that bypasses `AvatarStudioView`. Fragments the portfolio look and doubles maintenance

### Portfolio-canonical 8-accessory convention (R147 #578 + R150 #581 upgrade to portfolio-canonical)

PRIMARY-cluster apps consistently ship **8 themed accessories** with a uniform `lowercase_underscore` naming convention. **Upgraded from "recommendation outside Play" to portfolio-canonical at R150 #581** after corroboration across 5 of 6 audited apps spanning 3 clusters:

| App | Cluster | Theme | Status |
|---|---|---|---|
| QuillSpell | Play | Word Wizard | ✅ |
| GrammarForge | Play | Grammar | ✅ (`comma_charm` / `editing_pen` / `editor_satchel` / `grammar_book` / `parts_of_speech_pin` / `punctuation_pendant` / `scholar_cap_red` / `syntax_scarf`) |
| ReadQuest | Play | Reading | ✅ (`bookmark_charm` / `comprehension_pendant` / `library_satchel` / `narrative_scarf` / `open_book` / `page_marker_pin` / `reading_glasses` / `story_beanie_blue`) |
| BeatForge | Create | Music/beat | ✅ R148 corroboration (`band_jacket_red` / `beat_pin_quarternote` / `boombox_charm` / `drumstick_pair` / `headphones_red` / `snapback_hat_blue` / `tambourine_hand` / `vinyl_pin`) |
| BridgeForge | Science/STEM | Civil engineering | ✅ R150 corroboration (`blueprint_roll_civil` / `blueprint_satchel_steel` / `civil_engineer_vest` / `drafting_set` / `engineer_beanie_steel` / `engineer_hardhat_blue` / `load_pin` / `truss_pendant`) |
| FossilForge | Science/STEM | (paleontology) | ❌ — pack not generated yet |

**Convention rules** (portfolio-canonical):
- **Bundle location**: `Libraries/Sources/SharedUI/Resources/AvatarShared/accessories/` (flat-bundle for `AvatarAssetCatalog(appBundles:)` resolution)
- **File format**: `.webp` at 256×256 with alpha
- **Naming**: `lowercase_underscore.webp`; no app-prefix (the bundle scope provides per-app uniqueness)
- **Pack size**: 8 per app for visual variety + balanced picker layout in `.full` mode (8 fits cleanly in 2×4 or 4×2 grid)
- **Theme cohesion**: all 8 should reflect the app's curricular surface area (writing-craft / engineering / etc.) so picker selections feel like identity-curation, not random cosmetics
- **Cost ceiling**: ~$0.36 generation cost per app via standard accessory pipeline (per `portfolio.md` § Asset generation ownership)

**Why 8 not other counts**: empirical convergent count across 5 independent apps spanning 3 clusters. Provides visual balance (2×4 / 4×2 grids), enough variety for personalization, small enough to fit in ~$0.36 generation cost ceiling.

**Adoption pattern for new PRIMARY-cluster apps**: when scaffolding, plan for 8 themed accessories from day one. Generate via standard accessory pipeline. Wire through `AvatarStudioSheet.swift` per per-cluster recommendation (Play: R3 both-surfaces / Create: `.full`-direct / Science/STEM: `.full`-direct or R3 if identity-cosmetics-heavy). Reference template impl: `quillspell-app/Packages/Libraries/Sources/AppFeature/AvatarStudioSheet.swift`.

**Exceptions to portfolio-canonical**: apps where accessory cosmetics don't fit the surface (e.g., reflective-pillar apps where identity-customization would dilute the journaling register; trauma-gated apps where avatar cosmetics could undermine off-ramps). Each exception documented per-app via TECHNICAL_DESIGN.md.

## Server `/version` endpoint (R151 #582; lifted from CuriosityQuest 2026-05-29)

Every portfolio server MUST expose a `GET /api/v1/version` endpoint behind the existing `X-API-Key` middleware. Codified after CQ TTS cascade (PRs #130 → #138) where build-identity ambiguity ("is PR #132 actually deployed?") blocked diagnosis for hours across 6+ debug cycles.

### Pattern

| Endpoint | Auth | Body | Why |
|---|---|---|---|
| `GET /health` | none | `{"server":"ok",...}` | Load-balancer probe — public, minimal, fast |
| `GET /api/v1/version` | `X-API-Key` | `{version, versionFull, branch, builtAt}` | Deploy verification — clients have the key, no public exposure |

### Security guardrail (CVE-2026-29787)

**Public `/health` MUST NOT contain build/system info** (commit SHA, OS version, language version, hardware specs, etc.). CVE-2026-29787 (mcp-memory-service, filed 2026) was for exactly this anti-pattern — leaking OS/runtime/hardware specs via unauthenticated health endpoint. **Authenticated `/version` is the right place** for build metadata; behind the existing API-key middleware, exposure is limited to clients that already authenticate.

### Implementation recipe

1. **Committed placeholder file** `Sources/BuildInfo.swift`:

```swift
public enum BuildInfo {
    public static let gitSHA: String = "dev-local"
    public static let gitSHAFull: String = "dev-local"
    public static let builtAt: String = "dev-local"
    public static let gitBranch: String = "dev-local"
}
```

2. **Dockerfile** overwrites the file with real metadata before `swift build`:

```dockerfile
ARG RAILWAY_GIT_COMMIT_SHA=""
ARG RAILWAY_GIT_BRANCH=""
RUN BUILD_SHA="${RAILWAY_GIT_COMMIT_SHA:-dev-local}" && \
    BUILD_SHA_SHORT=$(echo "${BUILD_SHA}" | cut -c1-7) && \
    BUILD_BRANCH="${RAILWAY_GIT_BRANCH:-dev-local}" && \
    BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ") && \
    cat > Sources/BuildInfo.swift <<EOF
import Foundation
public enum BuildInfo {
    public static let gitSHA: String = "${BUILD_SHA_SHORT}"
    public static let gitSHAFull: String = "${BUILD_SHA}"
    public static let builtAt: String = "${BUILD_TIMESTAMP}"
    public static let gitBranch: String = "${BUILD_BRANCH}"
}
EOF
```

3. **Route registration** inside the existing API-key-protected group:

```swift
apiGroup.get("version") { _, _ -> [String: String] in
    return [
        "version": BuildInfo.gitSHA,
        "versionFull": BuildInfo.gitSHAFull,
        "branch": BuildInfo.gitBranch,
        "builtAt": BuildInfo.builtAt
    ]
}
```

### Platform-specific env var names

The Dockerfile recipe assumes Railway. Other platforms expose the SHA under different env var names:

| Platform | Env var |
|---|---|
| Railway | `RAILWAY_GIT_COMMIT_SHA` + `RAILWAY_GIT_BRANCH` |
| Render | `RENDER_GIT_COMMIT` |
| Fly.io | `FLY_GIT_COMMIT` (or `--build-arg` from CI) |
| GitHub Actions | `GITHUB_SHA` |
| Generic Docker | `--build-arg GIT_SHA=$(git rev-parse HEAD)` |

### Reference impl

CuriosityQuestServer (CQ PR #135):
- `Server/CuriosityQuestServer/Sources/BuildInfo.swift` — committed placeholder
- `Server/CuriosityQuestServer/Dockerfile` — Railway recipe
- `Server/CuriosityQuestServer/Sources/Application+build.swift` — route registration

### Cross-references

- `labsmith/Docs/RESEARCH_SERVER_VERSION_ENDPOINT_2026-05-29.md` — sources + security analysis + methodology lesson
- `labsmith/.claude/rules/audio-pipeline.md` — companion rule from the same CQ cascade

## Cast asset filename convention (DN methodology)

For apps with a DN cast bundled via `ForgeIllustrations`, cast assets MUST use a **flat-bundle filename convention** with a `cast_` prefix:

```
Packages/Libraries/Sources/AppFeature/Resources/Illustrations/
├── cast_<character_slug>_<pose>.webp
├── cast_etyma_demonstrating.webp
├── cast_lexa_thinking.webp
```

**Why**:
- `ForgeIllustrations.IllustrationRegistry` resolves via `Bundle.module` flat lookup; subdirectory paths fail silently
- The `cast_` prefix disambiguates cast members from existing mascot files (`<mascot_name>_<pose>.webp`)
- Per-character poses share the prefix so registry filtering can group by character (`registry.assets(prefix: "cast_etyma_")`)

Codified per QuillSpell `HANDOFF_FROM_APP_CAST_FILENAME_CONVENTION.md` (Round 93 #479-A42, 2026-05-27). Applies to all DN-cast retrofit apps.

## Common Gotchas

- **`AvatarStudioView` requires `getOrCreateForgeID` seeding** (R489 2026-06-02; lifted from CQ `HANDOFF_FROM_APP_LIFT_AVATAR_STORE_FORGEID_SEED.md`) — `AppGroupStore.setAvatar(_:editedAt:)` throws `AppGroupStoreError.forgeIDMissing` (surfaces as cryptic `ForgeSync.AppGroupStoreError error 0`) if no identity has been seeded. `AvatarStudioView` internally calls `setAvatar` on user Save — apps that adopt the editor MUST seed the identity BEFORE the editor opens, via:

  ```swift
  // Inside your AvatarStudioView host (e.g., ForgeAvatarStudioShell.body):
  AvatarStudioView(initialConfig: ..., catalog: ..., presentation: ..., appGroupStore: store, onSaved: ..., onCancelled: ...)
      .task {
          // CRITICAL: AvatarStudioView internally calls appGroupStore.setAvatar(_:editedAt:)
          // which throws .forgeIDMissing (= "error 0") unless a ForgeID has already
          // been created. Seed before the user can interact with Save.
          let id = await appGroupStore.getOrCreateForgeID(displayName: profile.name)
          DebugLog.lifecycle("ForgeAvatarStudioShell.task — seeded ForgeID: \(id.id.uuidString)")
      }
  ```

  **Why this hits non-ForgeSync apps the hardest**: apps that don't use ForgeSync for XP / streaks / achievements never trigger ForgeID seeding through other code paths (CQ has its own SwiftData-backed `StudentProfile` so this gotcha bit on first AvatarStudioView adoption). `.task` is the canonical SwiftUI hook — runs on view appear, async-friendly, completes before the user can tap Save.

  **`AppGroupStoreError` is single-case** (`forgeIDMissing`) — `case 0 = forgeIDMissing`. The numeric surface in SwiftUI's error toast is the rawValue; if you see `ForgeSync.AppGroupStoreError error 0` anywhere, it's this gotcha. Reference impl: `curiosityquest-app/Packages/Libraries/Sources/SharedUI/Onboarding/ForgeAvatarStudioShell.swift`.

- **`ForgeUI.CorrectFeedbackModifier`**: parameter is `isActive:`, **NOT** `trigger:`
- **All ForgeKit types are `public`** — app code imports them directly
- **`ForgeModels` types are value types** — not `@Model`. Apps create their own SwiftData models and convert to/from ForgeModels types
- **`StreakManager` is an actor** — all access is `async`
- **`XPEngine`/`EconomyEngine`/`AchievementEngine` are pure structs** — no internal state, callers manage persistence
- **Theme injection is required** — components use `@Environment(\.forgeTheme)`. Inject a custom theme at the app root or `DefaultForgeTheme` applies
- **`nonisolated` required on Sendable value types** — `InferIsolatedConformances` causes protocol conformances on value types to inherit MainActor isolation. All ForgeKit Sendable structs/enums are marked `nonisolated`. Exception: `@MainActor` SpriteKit types (`ForgeFeedback`, `ForgeCelebration`, `ForgeNodeFactory`) must NOT be `nonisolated`
- **`ForgeProgressionManager` debug bypass** — use `debugUnlockAllGates()` / `debugRestoreGateEvaluation()` for testing; constructor parameter for permanent bypass
- **ForgeKit path from `Libraries/Package.swift`** — use `../../forgekit` (two levels up), not `../forgekit`. Package.swift is inside `Libraries/`, one level deeper than the app repo root
- **Type name collisions** — qualify fully when both app modules and ForgeKit define the same type name (e.g., `Models.Expression` vs `Foundation.Expression`, `AppFeature.AppPhase` vs `ForgeNavigation.AppPhase`)
- **`@retroactive` not needed within same package** — conformances to ForgeKit protocols from targets in the same `Libraries` package are NOT retroactive. `@retroactive` in this case is a compile error
- **Fix isolation in ForgeKit, not in app code** — if a ForgeKit value type causes "call to main actor-isolated initializer in nonisolated context", mark it `nonisolated struct` IN the ForgeKit repo. Don't work around it in app code
<!-- END LABSMITH-SYNCED CONTENT -->
