---
status: PRESERVED FROM PRIOR CLAUDE.md
preserved-date: 2026-06-08
preserved-from: CLAUDE.md (v1, 18-section template)
preserved-to-v2: CLAUDE.md (v2, 5-section template) per Docs/RESEARCH_CLAUDE_MD_BEST_PRACTICES_2026-06-08
---

# VoiceTale — preserved app-specific notes (from prior CLAUDE.md)

This file holds content preserved from the pre-2026-06-08 CLAUDE.md (the 18-section v1 template). Per the CLAUDE.md best-practices research, the v2 template delegates portfolio-wide content to `@.claude/rules/` (auto-loaded) and per-app design content to per-app `Docs/*.md` files referenced via `@import`. This file holds the latter pending per-section review + relocation to the right destination.

## Things That Will Bite You (current learnings)

- **`Bundle.module.url(forResource:withExtension:subdirectory:)` is flaky for SPM `.process("Resources")` bundles in test targets** (Xcode 26 / Swift 6.2). The API returns `nil` even when the file is at the expected bundle path. All Phase 1 loaders (`QuestionKitLoader`, `CompanionPackLoader`, `TraditionCatalogLoader`) route through `Services/ResourceLookup.swift` which retries via flat lookup + direct path under `resourceURL`. New loaders that need bundled resources MUST go through `ResourceLookup` — do not call `Bundle.module.url(...subdirectory:)` directly. Discovered 2026-06-21 when the Phase 1 test plan finally exercised the loaders for the first time (4 loaders × subdirectory: returned nil; flat + direct-path fallback recovered them).

## Accessibility audit notes (Phase 1, in-flight)

> Captured 2026-06-22 alongside the UI test scaffolds. The full a11y audit lives in Phase 1.2; this list is the per-surface inventory the audit will walk against. Cross-references `@.claude/rules/swiftui.md` § A11y conventions + `@.claude/rules/testing.md` § UI Tests + `@.claude/rules/liquid-glass.md` § Reduce-Transparency.

### Per-surface a11y inventory

| Surface | A11y label sources | Open items |
|---|---|---|
| `TellView` idle | "Ready when you are." (title) + "Tell a 60-to-120-second tale. Bramble will listen." (subtitle); mood picker via `MoodTagView` per-mood label; mascot is `.accessibilityHidden(true)` | Confirm VoiceOver reads idle headline first; verify session-1 free-form copy "Just tell me something." passes Dynamic Type XXL |
| `TellView` recording | `BeatTimerView` exposes `Elapsed seconds: N` + "Current beat: X" labels; per-beat hint is plain text; free-form session-1 counter exposes "Elapsed seconds: N" | Verify the spring nudge animation respects Reduce-Motion (covered by `accessibilityReduceMotion` check in `BeatTimerView`) |
| `BeatTimerView` | `Elapsed seconds: N` + "Current beat: X" combined accessibility element on labels | Add per-beat target-seconds disclosure for VoiceOver kids ("Current beat: Rising, target 30 seconds") |
| `TranscriptReviewView` | TextEditor inherits VoiceOver; per-beat chunk headings labeled | Confirm beat-chunk navigation works under VoiceOver swipe gesture |
| `BrambleReflectionView` | Bramble icon hidden; observation + Socratic prompt are body Text (read by VoiceOver in document order) | Confirm "thinking" state announces a "Bramble is listening" hint to VoiceOver |
| `AnthologyView` | Per-tale row labels include title + mood + duration | Add tap-target verification — rows must be ≥ 44pt tall |
| `TraditionGalleryView` | Per-card displayName + region + craftPrimitive; content-warning is a labeled `.exclamationmark.shield.fill` icon | Confirm cultural-credit text passes contrast against the `.thinMaterial` card background in both light + dark mode |
| `DailyPromptView` | Prompt text is body text; "Refresh" / "Tell now" buttons have explicit labels | Confirm prompt is announced when day rolls over (already deterministic per `DailyPromptView.todaysPrompt(now:)`) |
| `AdventureTabView` | Mode-card title + subtitle + unlock-hint label; locked rows use `.accessibilityHint("Locked: <hint>")` | Confirm the lock state is also exposed via VoiceOver trait, not just visual lock icon |
| `ProfileTabView` / `AvatarStudioSheet` | Inherits from `ForgeAvatar.AvatarStudioView` accessibility | Confirm the R3 segmented `.lite`/`.full` picker exposes "Lite preset" / "Full preset" labels |
| `SettingsView` | Privacy posture text + crisis-resource list labels | Confirm 988 / Childhelp / Crisis Text Line phone numbers are tap-to-call accessible |
| `OnboardingFlowView` | Inherits from `ForgeUI.ForgeOnboardingFlow` accessibility | Confirm parent handoff page 2 surfaces the parent callout to VoiceOver |

### Dynamic Type checkpoints (test each surface at)

- Smallest: `xsmall`
- Default: `large`
- Largest: `accessibility5` (XXXL accessibility)

### Color-contrast checkpoints (WCAG AA, 4.5:1 minimum)

- Hero teal `#1B7B8C` against light + dark backgrounds
- Mood-tag pill colors against `MoodTagView` background
- Beat-block colors (orange / yellow / green / teal / blue) against `.quaternary` rail
- `.thinMaterial` card backgrounds against text in both modes
- Disabled/locked Adventure mode-card states (60% opacity must still pass on the per-mode color)

### Reduce-Motion variants

- `BeatTimerView` spring nudge — already gated via `@Environment(\.accessibilityReduceMotion)` (PR `feature/beat-boundary-nudge-animations`)
- Bramble reflection appear animations — pending audit
- Adventure mode-card unlock transitions — pending audit

### Reduce-Transparency variants

- All `.thinMaterial` cards (TraditionCard, AdventureCard, RecordingControls) — fall back to solid `Color(uiColor: .secondarySystemBackground)` when `accessibilityReduceTransparency` is enabled, per `@.claude/rules/liquid-glass.md` § Accessibility requirements

### Mic-recording status

- Per `@.claude/rules/concurrency.md` § "[`Voice input, audio capture]" and FEATURE_PLAN.md a11y audit row (line 123), the mic-recording status MUST be spoken when entering the recording surface. Current `RecordingControlsView` shows visual state only — add `.accessibilityAddTraits(.startsMediaSession)` + an `accessibilityAnnouncement` post on transition to `.recording`. Captured here as a follow-up.

### What this list does NOT cover

- VoiceOver rotor configuration for the per-beat hint cycling (deferred; rotor is power-user a11y, not Phase 1 ship-blocker)
- Bramble TTS narration of the reflection (intentional — Bramble is text-only per the trauma-informed posture; reading aloud is a Phase 2+ accessibility option)
- Tradition-layer audio samples (pending labsmith handoff per `HANDOFF_FROM_APP_TRADITION_AUDIO_SAMPLES.md`)

**Recommended next steps for this file**:

1. Identify which sections of the preserved content are genuinely app-specific (architecture / domain patterns / app-specific gotchas / app-specific limitations) and KEEP them here OR migrate them to topic-specific docs:
   - Architecture → `Docs/TECHNICAL_DESIGN.md`
   - Domain patterns → `Docs/DOMAIN_PATTERNS.md`
   - Parent / educator integration → `Docs/PARENT_EDUCATOR_INTEGRATION.md`
   - Onboarding design → `Docs/ONBOARDING_DESIGN.md`
   - Engagement / retention → `Docs/ENGAGEMENT_RETENTION.md`
2. Identify which sections duplicate portfolio-wide rules (concurrency / SwiftData / SwiftUI / testing / Workflow / COPPA) and DELETE them (the rules in `@.claude/rules/` already auto-load).
3. Once review is complete, update `CLAUDE.md`'s `App-Specific Conventions` section with 3-8 bullets summarizing the actual app-specific differentiators.

---

## Preserved content (verbatim from prior CLAUDE.md)

# VoiceTale

Voice-first oral storytelling workshop for tweens — 60-120 second told tales across a 5-beat arc (hook/setup/rising/turn/close), with on-device transcript-side AI reflection and a tradition layer that honors oral-storytelling lineages without appropriation.

**Status**: Pre-implementation scaffold. See @Docs/README.md for the labsmith concept doc + Phase 1 entry point. **Full Tier 2 doc set is pending**: TECHNICAL_DESIGN.md, FEATURE_PLAN.md, CONTENT_STYLE_GUIDE.md, TESTING_STRATEGY.md, PERFORMANCE_BUDGET.md, KIDSAFE_PREPARATION.md, DOCUMENT_CATALOG.md (per `labsmith/Docs/PORTFOLIO_PATTERNS.md` Documentation Maturity Tier 2). Labsmith authors these in a future wave; this repo is bootstrap-only.

**Wave**: Wave 5 (writing-craft cluster) per `labsmith/Docs/PLAN_WRITING_CRAFT_CLUSTER.md` or related cluster plan.

**Hero color**: `#1B7B8C`
**Mascot**: Bramble (chunky-cartoon flat-vector, shipped at `Resources/Illustrations/mascots/bramble_encouraging.webp`).

## Tech Stack (portfolio standard)

- **Language**: Swift 6 (strict concurrency)
- **UI**: SwiftUI (menus, HUD, overlays)
- **Rendering**: SwiftUI + SpriteKit + SpriteView (gameplay surfaces). SceneKit prohibited (deprecated WWDC25)
- **AI Mentor**: FoundationModels (on-device, `@Generable` types)
- **Persistence**: SwiftData (`@Model`, `@Relationship`)
- **Minimum Target**: iOS 26
- **IDE**: Xcode 26
- **Testing**: Swift Testing framework (`@Test`, `#expect`)
- **No Combine**: Async/await only
- **Linting**: SwiftLint SUSPENDED (crashes on Xcode 26). Config retained in `.swiftlint.yml`; rules enforced manually
- **Architecture**: App shell + local Swift Package (all code in `Libraries/Package.swift`)
- **Concurrency**: MainActor default, approachable concurrency enabled

## Commands

```bash
# Build (iOS Simulator) — once Xcode project is created in Phase 1
xcodebuild -workspace VoiceTale.xcworkspace -scheme VoiceTale -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Cross-Repo

- **Concept doc** (labsmith): `labsmith/Docs/VoiceTale/README.md`
- **ForgeKit** (shared SPM): `../forgekit/`
- **AdventureHub HubContribution**: `labsmith/Resources/HubContributions/voicetale.json`
- **Portfolio patterns**: `../labsmith/Docs/PORTFOLIO_PATTERNS.md`
- **Portfolio rules**: `.claude/rules/` (synced from labsmith)

## Reference Documents

| Document | Status | Purpose |
|---|---|---|
| @Docs/README.md | ✓ scaffolded | Index + labsmith concept-doc pointer |
| @Docs/IMPLEMENTATION_HANDOFF.md | ✓ scaffolded | Phase 1 entry point + scope (placeholder) |
| Docs/TECHNICAL_DESIGN.md | pending | Architecture + data models |
| Docs/FEATURE_PLAN.md | pending | Phased delivery roadmap |
| Docs/CONTENT_STYLE_GUIDE.md | pending | AI mentor voice + tone |
| Docs/TESTING_STRATEGY.md | pending | Swift Testing patterns |
| Docs/PERFORMANCE_BUDGET.md | pending | Launch / memory / FPS targets |
| Docs/KIDSAFE_PREPARATION.md | pending | COPPA + parental gate |
| Docs/DOCUMENT_CATALOG.md | pending | Self-referential doc index |

## Known Limitations

- **No Xcode project yet** — bootstrap only. Phase 1 implementation session creates the project per `labsmith/Docs/PORTFOLIO_PATTERNS.md` § Implementation Prep Checklist
- **No Question Kits yet** — labsmith authors `Resources/Questions/voicetale/kit_NN_*.json` in a future wave
- **No additional mascot poses** — only `encouraging` ships; remaining 4 (demonstrating, praising, thinking, working) generate in a future wave (~$1.08 cost ceiling per app)

## Workflow

This is a docs-only scaffold today. When the implementing CC session opens this repo:

1. Read `Docs/IMPLEMENTATION_HANDOFF.md` first
2. Read the labsmith concept doc at `labsmith/Docs/VoiceTale/README.md` for full vision
3. Follow the Implementation Prep Checklist in `labsmith/Docs/PORTFOLIO_PATTERNS.md` (Steps 3-7: create Xcode project, SPM package, stub files, build, begin Phase 1)
4. Author the pending Tier 2 docs as you go (or request labsmith to author them via a `Docs/HANDOFF_FROM_APP_TIER2_DOCS.md` request)

