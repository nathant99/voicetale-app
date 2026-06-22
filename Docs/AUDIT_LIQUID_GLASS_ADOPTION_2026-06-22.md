---
status: ACTIVE
date: 2026-06-22
freshness-horizon: 30 days
---

# Audit — Liquid Glass adoption per Portfolio Hybrid policy

Audit run during round 2026-06-22 (post-#70) closing PR C of the round.
Surveys VoiceTale's surface against `@.claude/rules/liquid-glass.md`
§ Portfolio Hybrid Liquid Glass policy and records the per-surface
disposition.

## Phase 1 — TabBar override audit

Grep:

```bash
grep -rEn 'toolbarBackground|toolbarColorScheme|UITabBar\.appearance|tabViewStyle' \
  Packages/Libraries/Sources/
```

**Result**: 1 match — a doc comment in `AppRootView.swift` line 40
("Liquid Glass adoption is automatic — no `toolbarBackground`
overrides per `@.claude/rules/liquid-glass.md`"). No live code
overrides. ✅ PASS.

## Phase 2 — Nav-grid card adoption (category C)

| Surface | Disposition | Notes |
|---|---|---|
| `AdventureTabView.modeCard` | **Converted** to interactive tinted glass via new `NavGridCardSurface(tint: mode.color, reduceTransparency: …)`. Per-mode color (orange / green / teal / pink) carried into the tint. | Nav-grid affordance — drills into Word Workshop mode. |
| `ProgressTabView.practiceCard` | **Converted** to interactive tinted glass via `NavGridCardSurface(tint: .accentColor, reduceTransparency: …)`. | Nav-grid affordance — drills into QuizView. |

Both call sites honor `@Environment(\.accessibilityReduceTransparency)`;
when the system setting is on, the surface collapses to a solid tint
fill with the same corner radius so WCAG AA contrast holds.

## Phase 3 — Interactive controls (category B)

| Surface | Disposition | Notes |
|---|---|---|
| `TellView.RecordingControlsView` start/stop/cancel buttons | **Solid (no change)** — these are primary CTAs; per policy "Primary CTAs (`btn-primary`) stay solid — trust + max contrast". |
| `TellView.MoodTagView` mood chips | **Solid (no change)** — these are content-display tags, not nav. |
| `AnthologyView.exportRow ShareLink` | **Solid (no change)** — `.borderedProminent` button style; primary action. |
| `AnthologyView.playbackRow Listen-back` button | **Solid (no change)** — `.bordered` button style; not a category-C nav surface. |

Decision: Phase 3 interactive controls audit completes with zero
conversions. The existing `.borderedProminent` / `.bordered` /
`buttonStyle(.plain)` choices already match the policy's CTA stance.

## Phase 4 — Content-display cards (category D — DO NOT touch)

| Surface | Disposition | Rationale |
|---|---|---|
| `AnthologyView.taleCard` | KEEP SOLID | Content-display card — shows transcript + reflection + duration; kid reads from it. |
| `TraditionGalleryView.TraditionCard` | KEEP SOLID | Content-display card — explicit cultural credit, content warning, summary. Glass would dilute the cultural-credit register. |
| `ProgressTabView.xpCard` / `streakCard` / `listeningTimeCard` / `moodBreakdown` / `badgeShelf` | KEEP SOLID | Stat / progress / list cards — content-display per policy table. |
| `DailyPromptView` prompt card | KEEP SOLID (existing) | Joke/quote/prompt content card. |
| `BrambleReflectionView` Bramble bubble | KEEP SOLID (existing) | Mentor reflection — content card. |
| `ProfileTabView` rows | List-driven; iOS 26 auto-applies Liquid Glass to the `List` chrome. No manual override. |

## Phase 5 — Imagery (category E)

No glass on `BookCoverCatalog` / mascot illustrations / cast portraits.
✅ PASS.

## Companion: new shared utility

`Packages/Libraries/Sources/SharedUI/NavGridCardSurface.swift` ships a
`ViewModifier` + a `View.navGridCardSurface(tint:reduceTransparency:cornerRadius:)`
convenience so future nav-grid card surfaces wire through a single
seam. 4 `NavGridCardSurfaceTests` lock the default corner radius +
reduce-transparency carry-through + extension composition.

## Cross-references

- `@.claude/rules/liquid-glass.md` § Portfolio Hybrid Liquid Glass
  policy — canonical rule
- `Packages/Libraries/Sources/SharedUI/NavGridCardSurface.swift` —
  shared modifier
- `Packages/Libraries/Sources/AppFeature/AdventureTab/AdventureTabView.swift` —
  Adventure mode-card adoption
- `Packages/Libraries/Sources/AppFeature/ProgressTab/ProgressTabView.swift` —
  practice-card adoption
