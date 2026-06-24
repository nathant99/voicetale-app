---
status: ACTIVE-STEP-4-ONLY
date: 2026-06-23
last-updated: 2026-06-24 (Step 3 Swift wire-up SHIPPED via PR-B of the TENTH-round)
direction: agent → user
intent: Xcode-UI steps to register a concrete `AppIntent` + `AppShortcutsProvider` so the ForgeIntents foundation from PR #89 turns on Siri / Spotlight / Shortcuts entry points for VoiceTale
freshness-horizon: 60 days
---

# Handoff to User — AppIntent + AppShortcutsProvider registration

Direction: **agent → user**. PR #89 shipped the typed plumbing (`VoiceTaleIntentDestination` + `VoiceTaleIntentRouter` + canonical Siri phrases). The next step — registering a real `AppIntent` so Siri / Spotlight / Shortcuts can route into the app — needs Xcode-UI work the agent cannot do from disk per `@.claude/rules/xcode-agent-safety.md` § "Never write these from disk".

This handoff captures the GUI-only steps. After the user reports back, the next CC session ships a follow-on PR that lands the `AppIntent` Swift code under `Apps/VoiceTale/VoiceTale/` (synchronized folder — safe to author per `@CLAUDE.md` § "Always safe to write") + the `AppShortcutsProvider` struct that wires the canonical phrases from `VoiceTaleShortcutPhrases` into the system.

## What's already in place (no Xcode work needed for this part)

- `Packages/Libraries/Sources/AppFeature/Intents/VoiceTaleIntentDestination.swift` — typed destination enum (4 cases: `tell` / `anthology` / `progress` / `tradition`)
- `Packages/Libraries/Sources/AppFeature/Intents/VoiceTaleIntentRouter.swift` — pure `tab(for:)` mapper + `VoiceTaleShortcutPhrases.build()` factory backed by `ForgeIntents.ForgeShortcutPhraseBuilder`
- `Tests/AppFeatureTests/VoiceTaleIntentRouterTests.swift` + `VoiceTaleIntentDestinationTests.swift` lock the API

## Step 1 — Confirm the deployment target supports App Intents

App Intents framework ships in iOS 16+, but `@AppIntent` macro + `AppShortcutsProvider` require iOS 26 SDK + Xcode 26. VoiceTale already targets iOS 26, so this is structural.

1. Open `VoiceTale.xcworkspace` (never `Apps/VoiceTale/VoiceTale.xcodeproj` directly per `@.claude/rules/xcode-agent-safety.md` § "Always open .xcworkspace").
2. Select the `VoiceTale` project → `VoiceTale` target → **General** tab.
3. Confirm **Minimum Deployments → iOS** is set to **26.0** or higher. (If the Apple Declared Age Range step from `HANDOFF_TO_USER_APPLE_DECLARED_AGE_RANGE.md` has been completed, this will read 26.2 — also fine.)

**Expected result**: the project's `IPHONEOS_DEPLOYMENT_TARGET` build setting reads `26.0` or higher in both `Debug` and `Release` configs. No action needed if already set.

## Step 2 — Add the `INIntentsSupported` array to Info.plist (optional but recommended)

This step is OPTIONAL for `AppShortcutsProvider`-only adoption — Apple's modern App Intents API doesn't require `INIntentsSupported` for shortcut phrases to surface to Siri. However, it's strongly recommended because:

- It makes the intent discoverable to the Shortcuts app's "Add Action" menu without requiring user-driven shortcut creation
- It surfaces the intent in Siri's "What can I ask?" picker
- It's still the canonical place for Apple's App Store review to verify the declared intents

1. Still in **Target → VoiceTale**, select the **Info** tab.
2. Under **Custom iOS Target Properties**, click the `+` to add a new key.
3. Add key: **`NSUserActivityTypes`** (Array type if not present)
   - Add string: `com.sparkanvil.voicetale.RecordNewTaleIntent`
4. Add key: **`INIntentsSupported`** (Array of Strings)
   - Add string: `RecordNewTaleIntent`
   - Add string: `OpenAnthologyIntent`
   - Add string: `ShowProgressIntent`
   - Add string: `OpenTraditionGalleryIntent`

These keys are stored in the build settings as `INFOPLIST_KEY_*` if Xcode's "Generate Info.plist File" is enabled (it is for VoiceTale).

**Expected result**: the project's build settings contain `INFOPLIST_KEY_INIntentsSupported = "RecordNewTaleIntent OpenAnthologyIntent ShowProgressIntent OpenTraditionGalleryIntent"`. Staging the resulting `project.pbxproj` diff is fine.

## Step 3 — (No new Step) — `AppShortcutsProvider` is registered via Swift — **✅ SHIPPED 2026-06-24 PR-B of TENTH round**

The `AppShortcutsProvider` registration happens in code. It does NOT require additional Info.plist entries beyond the optional Step 2. The `@main` shell discovers the provider automatically because the App Intents runtime scans the binary for any struct conforming to `AppShortcutsProvider`.

Step 3 SHIPPED — Swift wire-up landed under `Apps/VoiceTale/VoiceTale/Intents/`:

1. ✅ `Apps/VoiceTale/VoiceTale/Intents/RecordNewTaleIntent.swift`
2. ✅ `Apps/VoiceTale/VoiceTale/Intents/OpenAnthologyIntent.swift`
3. ✅ `Apps/VoiceTale/VoiceTale/Intents/ShowProgressIntent.swift`
4. ✅ `Apps/VoiceTale/VoiceTale/Intents/OpenTraditionGalleryIntent.swift`
5. ✅ `Apps/VoiceTale/VoiceTale/Intents/VoiceTaleShortcuts.swift` declaring `struct VoiceTaleShortcuts: AppShortcutsProvider`
6. ✅ `Packages/Libraries/Sources/AppFeature/Intents/IntentTabCoordinator.swift` — `@Observable @MainActor` singleton; intent `perform()` posts via `IntentTabCoordinator.shared.request(destination:)`; `AppRootView` observes via `.onChange(of: IntentTabCoordinator.shared.requestedTab)` and applies + clears
7. ✅ Categorical analytics: `VoiceTaleAnalyticsEvent.intentDestinationRequested(destination:)` fires on apply (destination raw value only — no PII; never the prompt text, never the user-facing copy)
8. ✅ Onboarding guard: requests fire ONLY after the kid has cleared onboarding (`hasCompletedOnboarding == true`); unboarded-kid requests are silently dropped so the COPPA / mic-permission gates are never skipped
9. ✅ 8 `IntentTabCoordinatorTests` + 4 `IntentDestinationRequestedAnalyticsTests` lock the bridge surface + analytics property bag

## Step 4 — Verify in Settings → Siri & Search

Once Steps 1–3 are complete (after the next CC session lands the Swift):

1. Build + run on the iPhone 17 simulator
2. **Settings → VoiceTale → Siri & Search** should list the 4 shortcut phrases
3. **Settings → Siri & Search → Suggestions from VoiceTale** should be ON by default
4. Open **Shortcuts.app** → tap `+` → search "VoiceTale" → the 4 intents should appear under **Actions**

**Expected result**: Siri responds to "Hey Siri, tell a tale" by opening VoiceTale to the Tell tab (the canonical mapping in `VoiceTaleIntentRouter.tab(for: .tell)`).

## Why this step requires the user, not the agent

Per `@.claude/rules/xcode-agent-safety.md` § "Never write these from disk":

- `*/Info.plist` (app-target) is owned by Xcode's target editor — the agent cannot author it from disk
- The `INFOPLIST_KEY_*` build settings live in `project.pbxproj` which is also Xcode-owned

The agent CAN author the Swift sources under `Apps/VoiceTale/VoiceTale/Intents/` because that's a synchronized folder — files dropped there are auto-discovered by Xcode. The boundary is the Info.plist + project file, not the Swift code.

## What this handoff does NOT cover

- The `AppIntent` Swift implementations themselves — those land in the follow-on PR after this handoff closes
- Siri voice recording / Voice ID configuration — that's user-side, no app code needed
- App Store metadata for declared App Intents — that's Phase 4 (App Store submission)

## Cross-references

- `@.claude/rules/xcode-agent-safety.md` — the non-negotiable Info.plist ban
- `Packages/Libraries/Sources/AppFeature/Intents/VoiceTaleIntentRouter.swift` — the typed plumbing this handoff unblocks
- `@Docs/HANDOFF_TO_USER_APPLE_DECLARED_AGE_RANGE.md` — sibling Info.plist handoff (Apple Declared Age Range API)
- `@Docs/HANDOFF_TO_USER_XCODE_WORKSPACE_INTEGRATION.md` — original workspace integration handoff (closed 2026-06-21)
- `@Docs/SESSION_HANDOFF_2026-06-23_LATE_EVENING.md` § "Recommended next-session priorities" #1 — the ForgeIntents follow-on this handoff captures
- `@.claude/rules/forgekit.md` § ForgeIntents module — `ForgeShortcutPhraseBuilder` API + cross-portfolio conventions
