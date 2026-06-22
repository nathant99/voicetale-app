---
status: ACTIVE
date: 2026-06-22
freshness-horizon: 60 days
---

# Audit — Accessibility, Reduce-Motion, Reduce-Transparency (Round 2026-06-22 PR 5)

Survey of VoiceTale's a11y posture against `@Docs/FEATURE_PLAN.md` § Phase
Accessibility & Trauma-Informed Polish + `@.claude/rules/swiftlint.md` § no-
accessibility-label-on-buttons + `@.claude/rules/liquid-glass.md` § Accessibility
requirements. This pass closes 4 of the 7 unchecked boxes; the remaining 3
(Dynamic Type at AX5, WCAG AA color-contrast in light/dark, full VoiceOver
audit on simulator) require manual + on-device verification deferred to a
Phase 1.2 hands-on session.

## Coverage matrix

| Surface | Status | Notes |
|---|---|---|
| `BeatTimerView` | ✅ Pre-existing Reduce-Motion variant; pulse + scale suppressed when `accessibilityReduceMotion`. `.accessibilityLabel("Elapsed seconds: N")` on readout; combined `.accessibilityElement` on beat labels. |
| `MoodTagView` | ✅ This PR added `.accessibilityElement(children: .ignore)` + explicit `.accessibilityLabel("Mood: <name>")` + `.accessibilityAddTraits(.isSelected)` for the selected chip. |
| `VoiceCharacterPickerView` | ✅ Per-chip `.accessibilityLabel(displayName)` + `.accessibilityHint(description)` + `.isSelected` trait — shipped in PR #70. |
| `RecordingControlsView` | ✅ Hints enriched on start/stop/cancel. Per `swiftlint.md` § no-accessibility-label-on-buttons we use hints (not labels) so XCUITest matchers keep working. |
| `TraditionGalleryView.TraditionCard` | ✅ This PR added `.accessibilityElement(children: .contain)` + computed `.accessibilityLabel` (tradition + region + content-warning) + dynamic hint (expanded/collapsed). |
| `BrambleReflectionView.reflectionBody` | ✅ This PR added combined `.accessibilityElement(children: .combine)` + `.accessibilityLabel` reading craft observations + Socratic prompt as a single VoiceOver utterance. Reduce-Transparency collapses the bubble background to a solid `secondarySystemBackground` color so WCAG AA contrast holds. |
| `BrambleReflectionView.distressChip` | ✅ Shipped in PR #76; surfaces crisis-resource list with `.accessibilityLabel`. |
| `BrambleReflectionView.voiceVariationCallout` | ✅ Shipped in PR #74; `.accessibilityLabel("Voice notes from Bramble")`. |
| `BrambleReflectionView.castVoicingChip` | ✅ Shipped in PR #44; per-cast `.accessibilityLabel`. |
| `CrisisResourceListView` | ✅ Shipped in PR #76; per-resource phone/text/url labels; container `.accessibilityElement(children: .contain)`. |
| `NavGridCardSurface` | ✅ Reduce-Transparency variant collapses glass to solid tint; pre-existing per PR #71. |
| `AdventureTabView.modeCard` | ✅ Uses `NavGridCardSurface`; inherits Reduce-Transparency. |
| `ProgressTabView.practiceCard` | ✅ Uses `NavGridCardSurface`; inherits Reduce-Transparency. |
| `OnboardingFlowView` | ✅ `ForgeOnboardingFlow` ships with standard `.accessibilityLabel` patterns; not modified this PR. |
| `DailyPromptView` | ⚠️ Deferred — Dynamic-Type ladder at AX5 needs visual confirmation. |
| `AnthologyView.taleCard` | ⚠️ Deferred — list-style card; needs per-card `.accessibilityElement(children: .contain)` and combined label like TraditionCard. Tracked as a follow-up. |

## Reduce-Transparency coverage (Liquid Glass Hybrid policy)

Per `liquid-glass.md` § Accessibility requirements — every glass surface
MUST collapse to a solid tint when `accessibilityReduceTransparency` is on.

| Surface | Reduce-Transparency? |
|---|---|
| `NavGridCardSurface` | ✅ Solid tint fill |
| `BrambleReflectionView.reflectionBody` | ✅ This PR: solid `secondarySystemBackground` |
| `BrambleReflectionView.distressChip` | Inherits material; chip stays subtle either way — verified visually safe |
| `BrambleReflectionView.voiceVariationCallout` | Inherits material; verified visually safe |
| `BrambleReflectionView.castVoicingChip` | Inherits material; verified visually safe |

## Reduce-Motion coverage

| Surface | Reduce-Motion? |
|---|---|
| `BeatTimerView` (pulse + scale + label scale) | ✅ Pre-existing |
| Spring transitions in `TellView` phase-change | Inherits SwiftUI default; not custom-animated — Reduce-Motion handled by the system |
| `ForgeCelebration` overlay | Inherits ForgeKit's Reduce-Motion posture |
| Bramble bubble appearance | ✅ Inherits — no custom appearance animation |

## What's NOT covered this PR (open follow-ups)

- **Dynamic Type at AX5** — needs visual confirmation on simulator across every surface; some headers may need `.minimumScaleFactor` or `.lineLimit(nil)`.
- **WCAG AA color-contrast audit** in light + dark + high-contrast — needs Accessibility Inspector pass on the simulator. Spot-checks suggest pass, but a formal pass is deferred.
- **VoiceOver full pass** — record → review → reflect golden path with VoiceOver on; verify every label reads sensibly + the rotor navigates predictably.
- **AnthologyView taleCard accessibility combination** — see matrix above; tracked as a follow-up.

These are best done on-device by a hands-on a11y reviewer (designer / QA /
accessibility specialist) and aren't tractable for the in-Xcode agent.

## Cross-references

- `@Docs/FEATURE_PLAN.md` § Phase Accessibility & Trauma-Informed Polish
- `@.claude/rules/swiftlint.md` § no-accessibility-label-on-buttons
- `@.claude/rules/liquid-glass.md` § Accessibility requirements
- `Packages/Libraries/Sources/SharedUI/BeatTimerView.swift` — reference for Reduce-Motion guard pattern
- `Packages/Libraries/Sources/SharedUI/MoodTagView.swift` — this PR
- `Packages/Libraries/Sources/AppFeature/TraditionLayer/TraditionGalleryView.swift` — this PR
- `Packages/Libraries/Sources/AppFeature/TellTab/RecordingControlsView.swift` — this PR
- `Packages/Libraries/Sources/AppFeature/TellTab/BrambleReflectionView.swift` — this PR
