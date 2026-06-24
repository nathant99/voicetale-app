---
status: SHIPPED
date: 2026-06-24
round: 2026-06-24 same-day TENTH (PR-D)
freshness-horizon: 90 days
---

# Liquid Glass audit — VoiceTale surfaces

Per `@.claude/rules/liquid-glass.md` § Portfolio Hybrid Liquid Glass policy
(R158 #590 generalization). 4-category decision matrix; per-surface posture;
audit grep evidence.

## Phase 1 — TabBar chrome (auto-glass)

**Result: PASS — no overrides found.**

```bash
grep -rEn "toolbarBackground|toolbarColorScheme|UITabBar\.appearance" \
  Packages/Libraries/Sources/
# → 0 functional matches; only a comment in AppRootView.swift:45 that
#   documents the canonical absence.
```

The `AppRootView.tabSurface` `TabView(selection:)` body renders 4 plain
`Tab(...) { ... }` slots with no `toolbarBackground` / `toolbarColorScheme`
/ `UITabBar.appearance` overrides. iOS 26 SDK auto-applies Liquid Glass
to TabBar + NavigationBar + Sheets + Popovers + Menus + Alerts +
Toggles + Sliders + Pickers automatically. No code change needed.

## Phase 2 — Nav-grid cards (category C glass)

**Result: PASS — every nav-grid card already wired through `NavGridCardSurface`.**

| Surface | File | Modifier | Status |
|---|---|---|---|
| AdventureTab mode cards | `AppFeature/AdventureTab/AdventureTabView.swift:120` | `.modifier(NavGridCardSurface(tint:reduceTransparency:))` | ✅ Phase 2 done |
| ProgressTab practice rows | `AppFeature/ProgressTab/ProgressTabView.swift` (via `navGridCardSurface` extension) | `navGridCardSurface(tint:reduceTransparency:)` | ✅ Phase 2 done |

Both consumers pass the system `accessibilityReduceTransparency`
environment value through to the modifier, which collapses to a solid
tint when on (per the WCAG-AA + `prefers-reduced-transparency` rule).

## Phase 3 — Interactive controls (category B)

**Result: PASS — no override-blocking patterns; system controls already
auto-glass via iOS 26 SDK.**

Mood-filter chips, collection chips, prompt swap pill, voice-character
picker chips: all use `Capsule().fill(...)` solid backgrounds intentionally
— these are SMALL controls (28-40pt) where the cost of GPU compositing
(`backdrop-filter` blur + paste) is high and the visual win is marginal.
The policy explicitly allows category B controls to use solid fills when
the surface is small + frequent + high-touch. Cards (larger) still use
glass via Phase 2.

Action buttons (`ForgePrimaryButton`, `RecordingControlsView`'s record /
save / retry buttons): all use ForgeUI's default `.buttonStyle(...)`
which respects the system tint + auto-Liquid-Glass for iOS 26.

## Phase 4 — Content-display cards (category D — KEEP SOLID)

**Result: PASS — content cards use `.thinMaterial` (HIG-canonical material),
NOT `.glassEffect()` (refraction).**

| Surface | File | Treatment |
|---|---|---|
| Bramble reflection bubble | `AppFeature/TellTab/BrambleReflectionView.swift` | `.thinMaterial` + `accessibilityReduceTransparency` solid fallback |
| Surprise / Mastery / Voice-variation strips | `AppFeature/TellTab/BrambleReflectionView.swift` | `.thinMaterial` (matched register) |
| Anthology row cards | `AppFeature/Anthology/AnthologyView.swift` | `.thinMaterial` |
| Published-tale certificate card | `AppFeature/Anthology/PublishedTaleCertificateSheet.swift` | `.thinMaterial` (PR #109) |
| Anthology cover swatches | `AppFeature/Anthology/AnthologyCoverView.swift` | Mood-keyed gradient (solid color paths; no glass) |
| Daily prompt card | `AppFeature/Anthology/DailyPromptView.swift` | `.thinMaterial` |
| TraditionGalleryView cards | `AppFeature/TraditionLayer/TraditionGalleryView.swift` | `.thinMaterial` |
| Tradition discovery callout | `AppFeature/TraditionLayer/TraditionGalleryView.swift:127` | `.thinMaterial` |
| QuizView question card | `AppFeature/QuizTab/QuizView.swift` | `.thinMaterial` |
| TaleTrialView prompt card | `AppFeature/AdventureTab/TaleTrialView.swift` | `.thinMaterial` |
| WelcomeBack last-tale recap | `AppFeature/WelcomeBack/WelcomeBackView.swift` | `.thinMaterial` |
| TranscriptReviewView beat rows | `AppFeature/TellTab/TranscriptReviewView.swift` | `.thinMaterial` |
| CompanionPack cards | `AppFeature/CompanionPack/CompanionPackView.swift` | `.thinMaterial` |
| Cast cameo strip | `SharedUI/CastCameoStripView.swift` | `.thinMaterial` |

13 distinct content-card surfaces all use `.thinMaterial`. Per the
policy: `.thinMaterial` is the canonical HIG translucent material — NOT
`.glassEffect()` which adds refraction + tinted blur. Content cards
keeping `.thinMaterial` is the right posture (refraction would violate
HIG content-layer rule).

## Phase 5 — Imagery (category E)

**Result: N/A.**

Cast portraits / mascot illustrations / topic illustrations / backdrops
are imagery, not surfaces. No glass treatment is appropriate or applied.

## Accessibility postures

- `accessibilityReduceTransparency` — observed by **5 files**
  (`NavGridCardSurface`, `BrambleReflectionView`, `AdventureTabView`,
  `ProgressTabView`, `AnthologyCoverView`). Each collapses translucent
  surfaces to a solid tint when system Reduce-Transparency is on.
- `accessibilityReduceMotion` — observed where animated transitions
  exist (`BeatTimerView`, `CelebrationOverlay` per ForgeCelebration's
  built-in handling, `AnthologyCoverView` for reduce-motion-aware
  layouts).
- WCAG AA contrast — content text always lives on solid surfaces
  inside the `.thinMaterial` card; no body text directly on
  `.glassEffect`.

## Audit grep evidence (steady-state)

```bash
# Phase 1 — chrome auto-glass not blocked: zero functional hits
grep -rEn "toolbarBackground|toolbarColorScheme|UITabBar\.appearance" \
  Packages/Libraries/Sources/

# Phase 2 — nav-grid cards use the canonical modifier
grep -rEn "navGridCardSurface|NavGridCardSurface\(" \
  Packages/Libraries/Sources/
# → AdventureTabView + ProgressTabView consume the SharedUI modifier

# Phase 4 — content cards use .thinMaterial, NOT .glassEffect
grep -rEn "\.glassEffect\(" Packages/Libraries/Sources/
# → 1 hit: SharedUI/NavGridCardSurface.swift (the modifier itself; Category C only)
```

## Why no zero-risk fix was filed in this PR

VoiceTale shipped the canonical posture across all 4 phases in earlier
rounds:

- PR #71 (Phase 4 Reduce-Transparency variants) established the
  `accessibilityReduceTransparency` + solid-fallback pattern across
  content cards
- PR #82 / #86 / #87 wired the `NavGridCardSurface` modifier to the
  AdventureTab + ProgressTab nav-grid surfaces
- PR #88 / #93 / #94 / #98 / #99 / #100 / #105 / #109 preserved
  `.thinMaterial` (NOT `.glassEffect`) on every new content-card
  surface added through Phase Delight & Polish
- AppRootView from day one omitted `toolbarBackground` overrides on
  the root TabView

The TENTH-round audit confirms the posture is steady. **No code change
required — the audit doc itself is the durable artifact**, available for
future rounds to cite when adding new surfaces.

## Forward-looking notes for new surfaces

When adding a new surface in a future round:

1. Is it a **navigation affordance** (drill into deeper content via tap)?
   → category C → use `.navGridCardSurface(tint:reduceTransparency:)`
2. Is it a **small interactive control** (chip / pill / button under 40pt)?
   → category B → solid fill (Capsule) is fine; system controls
     auto-Liquid-Glass on iOS 26
3. Is it a **content-display card** (kid READS / VIEWS it)?
   → category D → `.thinMaterial` + `RoundedRectangle(cornerRadius: 12-16)`
4. Is it **chrome** (TabBar / NavigationBar / Sheet / Popover)?
   → category A → don't add `toolbarBackground` / `toolbarColorScheme`
     overrides; iOS 26 SDK auto-applies Liquid Glass

When adding `@Environment(\.accessibilityReduceTransparency)`-observing
code, mirror the `NavGridCardSurface` body pattern — solid tint branch
+ glass branch + identical `RoundedRectangle(cornerRadius:)` shape so
the layout stays stable across the toggle.

## Cross-references

- `@.claude/rules/liquid-glass.md` § Portfolio Hybrid Liquid Glass policy
- `@Docs/AUDIT_ACCESSIBILITY_2026-06-22.md` — sister a11y posture audit
- `Packages/Libraries/Sources/SharedUI/NavGridCardSurface.swift` —
  canonical category-C modifier
- `Packages/Libraries/Sources/AppFeature/AppRootView.swift:43-45` —
  documented "no toolbarBackground overrides" comment
