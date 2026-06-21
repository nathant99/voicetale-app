---
status: ACTIVE
date: 2026-06-21
direction: agent → user
intent: optional Xcode-UI step to wire the spark-anvil App Group entitlement so the VoiceTale avatar propagates across portfolio apps (cross-app identity)
freshness-horizon: 60 days
---

# Handoff to User — App Group entitlement for cross-portfolio avatar

Direction: **agent → user**. The avatar editor (`AvatarStudioSheet` shipped in PR #40) works today without any extra setup — it falls back to standard `UserDefaults`, which means the avatar is local-only inside VoiceTale. **If/when you want the avatar to propagate across the portfolio (e.g., same look in AdventureHub / QuillSpell / CuriosityQuest), the App Group entitlement must be wired via Xcode UI.** The agent can't author `.entitlements` files from disk per `@.claude/rules/xcode-agent-safety.md`.

This is **OPTIONAL** — VoiceTale ships fine without it. File this step when the user is ready to take VoiceTale into the cross-portfolio identity stack.

## Step 1 — Add App Group capability in Xcode

1. Open `VoiceTale.xcworkspace` (not the xcodeproj).
2. Select the `VoiceTale` app target → **Signing & Capabilities** tab.
3. Click **+ Capability** → search **App Groups** → double-click to add.
4. Under **App Groups**, click **+** and enter the canonical portfolio suite name:
   ```
   group.com.spark-anvil.shared
   ```
   (Confirm the exact suite name with another portfolio app that already wires it — e.g., CuriosityQuest's `Apps/CuriosityQuest/CuriosityQuest.entitlements`.)
5. Xcode generates `Apps/VoiceTale/VoiceTale/VoiceTale.entitlements` with the new key. Commit this file via `git add Apps/VoiceTale/VoiceTale/VoiceTale.entitlements` — staging Xcode-managed files the user generated is fine; authoring them from disk is what's forbidden.

**Expected result**: the `com.apple.security.application-groups` array under the `VoiceTale` target's entitlements file contains `group.com.spark-anvil.shared`.

## Step 2 — Pass the suite name into AvatarStudioSheet

Once the entitlement is in place, update `ProfileTabView.swift` to pass an explicit `AppGroupStore` with the suite name:

```swift
.sheet(isPresented: $showingAvatarStudio) {
    AvatarStudioSheet(
        appGroupStore: AppGroupStore(suiteName: "group.com.spark-anvil.shared"),
        onDismiss: { showingAvatarStudio = false }
    )
}
```

(The agent can make this Swift edit once you've completed Step 1 — `ProfileTabView.swift` is a Swift file in `Packages/Libraries/Sources/AppFeature/ProfileTab/` and is safe for the agent to write.)

## Step 3 — Verify cross-app propagation

1. Run VoiceTale; change the avatar; tap Save.
2. Open another portfolio app on the same device that's already wired with the same App Group (e.g., CuriosityQuest).
3. Confirm the avatar appears with the new look.

If propagation doesn't fire, the most likely cause is the suite-name mismatch — re-verify Step 1's entry matches the other apps' entitlement exactly.

## Why this step requires the user, not the agent

`*.entitlements` files are owned by Xcode's capabilities editor per `@.claude/rules/xcode-agent-safety.md`. Authoring them from disk:

1. Bypasses the Xcode UI's provisioning-profile re-sign step (causes signing failures)
2. Triggers Xcode's "External Changes" dialog every time the agent edits the file
3. In the worst case, forces a workspace reload that terminates the agent session

The user clicking "+ Capability → App Groups" in the Signing & Capabilities tab is the only safe path. Staging the resulting file is fine.

## What happens if you SKIP this step

`AppGroupStore(suiteName: nil)` falls back to standard `UserDefaults`:

- Avatar is stored locally in VoiceTale only
- No cross-portfolio propagation
- All ForgeAvatar features work normally inside VoiceTale (skin tone, hair, outfit, eyes, mouth, accessories, background, frame)
- Save / cancel / R3 segmented toggle work normally
- No errors, no warnings — the fallback is graceful

You can defer this indefinitely if cross-portfolio propagation isn't a current goal.

## Cross-references

- `Packages/Libraries/Sources/AppFeature/ProfileTab/AvatarStudioSheet.swift` — the host view
- `@.claude/rules/forgekit.md` § Avatar Edit Authority — R3 segmented pattern + AppGroupStore seeding rule
- `@.claude/rules/xcode-agent-safety.md` § "Never write these from disk" — entitlements row
- `Docs/HANDOFF_FROM_LABSMITH_AVATAR_SIMPLIFIED_MIGRATION.md` — note that VoiceTale stays on the legacy composable API (ForgeKit 0.99) — the simplified Contacts-style API in 1.0.0-rc.1 applies on a future pin bump
