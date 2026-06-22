---
status: CLOSED
date: 2026-06-22
freshness-horizon: 30 days
audit-scope: VoiceTaleAnalyticsEvent vocabulary coverage
---

# Audit — Analytics Event Emission Coverage (2026-06-22)

Per `.claude/rules/portfolio.md` § "Asset Consumer Audit" precedent: **declared ≠ wired**. This audit walks every case of `VoiceTaleAnalyticsEvent` and verifies it has a real emission site in code. Gaps surface as "declared but never emitted" — the analytics equivalent of shipped-but-dark assets.

## Method

```bash
# 1. Enumerate cases from the analytics vocab:
Packages/Libraries/Sources/AppFeature/Analytics/AnalyticsService.swift
# 2. Grep emission sites:
grep -rEn 'analytics\.track\(' Packages/Libraries/Sources/
# 3. Pair each case with at least one emission site.
```

## Coverage table

| Event case | Emission site(s) | Status |
|---|---|---|
| `sessionStarted` | `AppRootView.swift:86` (`.task` on root) | ✅ wired |
| `taleRecordingStarted(mood:)` | `TellView.swift:328` (start record action) | ✅ wired |
| `taleRecordingCompleted(durationSeconds:mood:)` | `TellView.swift:356` (stop record success path) | ✅ wired |
| `taleSavedToAnthology(mood:hitAllBeats:)` | `TellView.swift:494` (after `VoiceTaleStore.insertTale`) | ✅ wired |
| `taleRetold` | `TellView.swift:563` (`retellFromScratch`) | ✅ wired |
| `reflectionShown(mood:beat:modelAvailable:)` | `TellView.swift:424` (after reflection completes) | ✅ wired |
| `traditionExplored(slug:)` | `TraditionGalleryView.swift:50` (card explore action) | ✅ wired |
| `dailyPromptViewed` | `DailyPromptView.swift:26` (`.onAppear`) | ✅ wired |
| `avatarSheetOpened` | `ProfileTabView.swift:60` (avatar section button) | ✅ wired (this PR) |
| `voiceRecordingShared(mood:durationSeconds:)` | `AnthologyView.swift:196` (ShareLink tap gesture) | ✅ wired |
| `kitCompleted(kit:accuracy:)` | `QuizView.swift:303` (kit walk-through completion) | ✅ wired |

## Gaps closed in this PR

1. **`avatarSheetOpened`** — declared in `AnalyticsService.swift:19` since the Phase-1 analytics vocab landed, but no emission site existed. This PR wires it to the avatar section button in `ProfileTabView.swift:60` so the event actually fires when the kid taps to open the avatar studio.

## What this audit does NOT enforce

- **Per-emission-site test coverage**: each emission site is a one-line `analytics.track(...)` call; the test value of asserting "this view calls .track" beyond unit-testing the event vocabulary (covered by `AnalyticsServiceTests`) is low. UI tests cover the user-action paths end-to-end.
- **PII regression detection**: the vocab's `properties` dictionary keys are tested for categorical-only shape via the existing `AnalyticsServiceTests`. A separate exhaustiveness test added in this PR enforces (a) unique non-empty event names + (b) snake_case naming.
- **External-emission verification**: the engine is on-device only (no third-party SDK per `Docs/TECHNICAL_DESIGN.md` § Analytics). No outbound network call to verify; just on-device store accumulation.

## Future regressions

When adding a new case to `VoiceTaleAnalyticsEvent`:

1. Add the case + name + properties shape to `AnalyticsService.swift`
2. Add a representative entry to the `representativeEvents` array in `AnalyticsServiceTests.everyDeclaredEventHasAUniqueNonEmptyName`
3. Wire at least one emission site in the appropriate view
4. Update this audit table

If step 3 lags (declared-but-dark), the next refresh of this audit doc surfaces it.

## Cross-references

- `Packages/Libraries/Sources/AppFeature/Analytics/AnalyticsService.swift` — event vocabulary + engine wrapper
- `Packages/Libraries/Tests/AppFeatureTests/AnalyticsServiceTests.swift` — event property + uniqueness tests
- `Docs/TECHNICAL_DESIGN.md` § Analytics — COPPA-safe, on-device-only policy
- `.claude/rules/portfolio.md` § Asset Consumer Audit — precedent for the "declared ≠ wired" check pattern
