---
status: ACTIVE
date: 2026-06-19
direction: agent → user
intent: ask the user to perform the Xcode-UI steps the agent cannot do safely (workspace add-package, target framework link, scheme test-plan add, Info.plist usage descriptions)
freshness-horizon: 30 days
---

# Handoff to User — Xcode workspace integration (Phase 0 close-out)

Direction: **agent → user**. The Phase 0 ForgeKit bootstrap PR landed `Packages/Libraries/Package.swift` + 6 SPM targets + tests + stub Swift files + documentation. The remaining steps require Xcode UI — the agent cannot write `.xcworkspace` / `.pbxproj` / `.xcscheme` / `Info.plist` from disk (would corrupt the workspace or terminate the agent session per `@.claude/rules/xcode-agent-safety.md`).

Please do the following 4 steps in Xcode. Each is reversible.

## Step 1 — Add `Packages/Libraries` as a local SPM package in the workspace

1. Open `VoiceTale.xcworkspace` (not `Apps/VoiceTale/VoiceTale.xcodeproj`).
2. `File > Add Package Dependencies...`
3. Bottom-left of the sheet, click **`Add Local...`**
4. Navigate to `Packages/Libraries/` (the directory containing `Package.swift`) and click **Add Package**.
5. In the products sheet, leave defaults and click **Add Package**.
6. Xcode resolves the package — first time takes ~30–60s (it fetches `forgekit` from GitHub).

**Expected result**: the workspace navigator shows `Libraries` as a new package alongside `VoiceTale.xcodeproj`. ForgeKit modules resolve under the package.

If Xcode shows the package as a plain folder (icon mismatch), see `.claude/rules/spm-architecture.md` § Gotchas — typically resolved by deleting `Packages/Libraries/.swiftpm/` + DerivedData and re-adding.

## Step 2 — Link `AppFeature` (and any other libraries) into the `VoiceTale` app target

1. In the workspace navigator, click the `VoiceTale` project (top of `Apps/VoiceTale/VoiceTale.xcodeproj`).
2. Select the `VoiceTale` target.
3. **General** tab → **Frameworks, Libraries, and Embedded Content** → **+** button.
4. In the sheet, scroll to the `Libraries` package's products and pick **AppFeature** (the only one the app shell needs to import).
5. Click **Add**.

**Expected result**: `import AppFeature` resolves in `Apps/VoiceTale/VoiceTale/VoiceTaleApp.swift`.

Once linked, update `VoiceTaleApp.swift` so the app shell shows the placeholder tabs (small edit; you can do this once linked):

```swift
import SwiftUI
import AppFeature

@main
struct VoiceTaleApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
```

(You can ask me to author that edit once you've completed Step 2 — `VoiceTaleApp.swift` is a synchronized-folder file so it's safe for the agent to write once `AppFeature` resolves.)

## Step 3 — Add SPM test targets to the scheme test plan

The `VoiceTale.xctestplan` at repo root is the canonical test plan. Per `.claude/rules/spm-architecture.md` § "`.xctestplan` files — tracking is canonical; hand-editing is forbidden", the only safe way to add test targets is through Xcode's GUI.

1. `Product > Scheme > Edit Scheme...`
2. Left sidebar → **Test**.
3. **Test Plans** tab → click on `VoiceTale.xctestplan` to open it (or use **Set Active Test Plan** if needed).
4. In the test-plan editor that opens, **+** under "Test Targets" → add the following one at a time:
   - `ModelsTests`
   - `ServicesTests`
   - `VoiceAuthoringTests`
   - `SharedUITests`
   - `AIMentorTests`
   - `AppFeatureTests`
   - `ForgeKitIntegrationTests`
5. Save (`Cmd+S`).

**Expected result**: Test navigator now lists the 7 SPM test targets alongside `VoiceTaleTests` and `VoiceTaleUITests`. `Cmd+U` runs them all.

## Step 4 — Add microphone + speech recognition usage descriptions (Phase 1 prerequisite)

Phase 1 will hard-crash on first record without these per `.claude/rules/warnings.md` § Privacy-Gated Frameworks. Add them now so the agent's defensive gates have a key to check against:

1. Select the `VoiceTale` target → **Info** tab.
2. Under **Custom iOS Target Properties**, add:
   - Key: `Privacy - Microphone Usage Description` (`NSMicrophoneUsageDescription`)
     - Value: `VoiceTale needs the microphone so you can tell your story aloud. Tales stay on your device.`
   - Key: `Privacy - Speech Recognition Usage Description` (`NSSpeechRecognitionUsageDescription`)
     - Value: `VoiceTale turns your tale into text on-device so Bramble can listen back with you. Nothing leaves your device.`
3. Save (`Cmd+S`).

**Expected result**: when Phase 1 record code lands, iOS prompts for permission with these kid-readable strings.

## After all 4 steps

1. Verify clean build (`Cmd+B`) — should succeed with zero warnings.
2. Verify tests (`Cmd+U`) — all 7 SPM test targets + the 2 app test targets should pass.
3. Confirm in our chat and I'll author the small `VoiceTaleApp.swift` edit (Step 2) + close out Phase 0 with the labsmith handoff (`HANDOFF_FROM_APP_FORGEKIT_INTEGRATION_COMPLETE.md`).

If anything fails, paste the error and I'll diagnose against `.claude/rules/spm-architecture.md` § Gotchas + `.claude/rules/forgekit.md` § Common Gotchas.

## Why these steps require the user, not the agent

| File the step touches | Why the agent cannot write it |
|---|---|
| `VoiceTale.xcworkspace/contents.xcworkspacedata` (Step 1) | Workspace membership XML — direct edit forces workspace reload, terminates agent session |
| `Apps/VoiceTale/VoiceTale.xcodeproj/project.pbxproj` (Step 2) | Workspace-defining XML — direct edit triggers External Changes dialog; can corrupt the file |
| `Apps/VoiceTale/VoiceTale.xcodeproj/xcshareddata/xcschemes/VoiceTale.xcscheme` + `VoiceTale.xctestplan` (Step 3) | Scheme JSON + test plan JSON — Xcode caches in memory + overwrites disk on save; hand-editing corrupts both |
| `Info.plist` (Step 4) | Owned by Xcode's target editor — direct edit triggers External Changes dialog |

Codified in `@.claude/rules/xcode-agent-safety.md` + `@CLAUDE.md` § Xcode File Safety.

## Cross-references

- `Docs/HANDOFF_FROM_LABSMITH_FORGEKIT_BOOTSTRAP.md` — the bootstrap playbook this handoff completes
- `Docs/IMPLEMENTATION_HANDOFF.md` § 7 — per-target ForgeKit wiring matrix
- `Docs/TECHNICAL_DESIGN.md` § SPM Module Architecture — the 6-target shape
- `.claude/rules/xcode-agent-safety.md` — full rule + recovery steps
- `.claude/rules/spm-architecture.md` § Gotchas — failure-mode catalog
