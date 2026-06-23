---
status: ACTIVE
date: 2026-06-23
direction: agent → user
intent: Xcode-UI steps to add NSCameraUsageDescription + NSPhotoLibraryUsageDescription so Phase 2's photo-attach feature can land
freshness-horizon: 60 days
---

# Handoff to User — Photo attach usage descriptions

Direction: **agent → user**. The Phase 2 "photo attach per tale" feature is one of the last two unshipped boxes in Phase 2 per `@Docs/FEATURE_PLAN.md` § Phase 2. The implementation is straightforward — additive `Models/TalePhotoAttachment` value type + parental-gate before camera permission + `TellView` attach affordance + `AnthologyView` display — BUT it cannot land until the Info.plist has the usage-description keys. Per `@.claude/rules/xcode-agent-safety.md` § "Never write these from disk" + `@.claude/rules/warnings.md` § "Privacy-Gated Frameworks", iOS hard-crashes the process the moment the gated API is invoked without the matching usage description.

This handoff captures the Info.plist GUI steps. After the user reports back, the next CC session lands the photo-attach Swift implementation.

## Background — why both keys are needed

VoiceTale's photo-attach surface has TWO entry points per `@Docs/FEATURE_PLAN.md`:

1. **Take a photo** — kid uses the device camera to capture a fresh photo to attach to a tale. Requires `NSCameraUsageDescription`.
2. **Pick from library** — kid picks an existing photo from the on-device library. Requires `NSPhotoLibraryUsageDescription` (read-only access via PhotoKit `PHPickerViewController`).

Per `@.claude/rules/warnings.md`:

> iOS hard-crashes the process with `"This app has crashed because it attempted to access privacy-sensitive data without a usage description"` the moment a privacy-gated API is invoked without the corresponding `Info.plist` key. The crash is not a Swift exception and cannot be caught.

`PHPickerViewController` (the modern iOS 14+ photo picker) does NOT actually require `NSPhotoLibraryUsageDescription` because Apple sandboxes the picker into a separate process — the user picks, the system hands back the selected URL, and the app never sees the rest of the library. **However**, defensive practice is to add the key anyway because:

- App Store review expects it when the binary links PhotoKit
- Future iOS versions may tighten the gate without warning
- Crash-protection is cheap (one Info.plist key)

VoiceTale's posture is **kid-readable copy** — never marketing-speak. The strings below match the Bramble grandmother register the rest of the app uses (per `@.claude/rules/distributed-narrative.md` § "Pattern B").

## Step 1 — Open the workspace

1. Open `VoiceTale.xcworkspace` (NOT `Apps/VoiceTale/VoiceTale.xcodeproj` directly per `@.claude/rules/xcode-agent-safety.md` § "Always open .xcworkspace").
2. Select the `VoiceTale` project → `VoiceTale` target → **Info** tab.

## Step 2 — Add `NSCameraUsageDescription`

1. Under **Custom iOS Target Properties**, click the `+` button to add a new row.
2. Key: `Privacy - Camera Usage Description` (Xcode displays the kid-readable label; the raw key is `NSCameraUsageDescription`).
3. Value (kid-readable copy — match this exactly):

   ```
   VoiceTale uses the camera so you can take a photo to remember a tale by. Photos stay on this device.
   ```

   The two-sentence pattern (purpose + on-device promise) matches the existing `NSMicrophoneUsageDescription` register.

**Expected result**: the project's build settings contain `INFOPLIST_KEY_NSCameraUsageDescription = "VoiceTale uses the camera so you can take a photo to remember a tale by. Photos stay on this device."` (Xcode promotes the Info-tab entry to a build setting when "Generate Info.plist File" is enabled, which it is for VoiceTale).

## Step 3 — Add `NSPhotoLibraryUsageDescription`

1. Same Info tab, click `+` again.
2. Key: `Privacy - Photo Library Usage Description` (raw key: `NSPhotoLibraryUsageDescription`).
3. Value (match exactly):

   ```
   VoiceTale uses the photo library so you can pick a photo to remember a tale by. Photos stay on this device.
   ```

**Expected result**: the project's build settings contain `INFOPLIST_KEY_NSPhotoLibraryUsageDescription = "VoiceTale uses the photo library so you can pick a photo to remember a tale by. Photos stay on this device."`.

## Step 4 — Confirm the diff in `project.pbxproj`

After the Info-tab edits, Xcode rewrites `Apps/VoiceTale/VoiceTale.xcodeproj/project.pbxproj`. Per `@.claude/rules/xcode-agent-safety.md` § "Staging and committing Xcode-managed files (after the user generates them via Xcode) is OK; authoring the bytes from disk is not", the user can stage + commit the resulting diff.

1. `git diff Apps/VoiceTale/VoiceTale.xcodeproj/project.pbxproj` — the diff should contain exactly 4 added lines (2 keys × 2 build configs `Debug` + `Release`).
2. `git add Apps/VoiceTale/VoiceTale.xcodeproj/project.pbxproj`
3. `git commit -m "feat(VoiceTale): add NSCameraUsageDescription + NSPhotoLibraryUsageDescription for Phase 2 photo attach"`

The next CC session pulls this commit + lands the photo-attach Swift implementation. No follow-up Info.plist work is needed from the user.

## Why this step requires the user, not the agent

Per `@.claude/rules/xcode-agent-safety.md` § "Never write these from disk":

- `*/Info.plist` (app-target) is owned by Xcode's target editor — the agent cannot author it from disk
- The `INFOPLIST_KEY_*` build settings live in `project.pbxproj` which is also Xcode-owned

The agent CAN author all the photo-attach Swift code — `Models/TalePhotoAttachment` value type + `Services/PhotoAttachStore` SwiftData mutator + `AppFeature/PhotoAttach/PhotoAttachGateView` parental-gate + `TellView` + `AnthologyView` integration — because that all lives under SPM sources or the synchronized-folder app target. The boundary is the Info.plist + project file.

## What this handoff does NOT cover

- The photo-attach Swift implementation — lands in the follow-on PR after this handoff closes
- Photo storage strategy — on-device only, no iCloud sync (already a structural guarantee per VoiceTale's COPPA posture)
- Parental gate UI — uses the existing `ParentalGate` pattern from the COPPA onboarding flow
- AI-analysis prohibition — already encoded as a structural promise; the photo data never crosses the Bramble session boundary

## Cross-references

- `@.claude/rules/xcode-agent-safety.md` — the non-negotiable Info.plist ban
- `@.claude/rules/warnings.md` § Privacy-Gated Frameworks — the privacy-description-or-crash rule
- `@.claude/rules/age-assurance.md` § "Parental gates" — the COPPA-compliant gate the implementation will use
- `@Docs/HANDOFF_TO_USER_APPLE_DECLARED_AGE_RANGE.md` — sibling Info.plist handoff (Apple Declared Age Range API)
- `@Docs/HANDOFF_TO_USER_APP_INTENTS_REGISTRATION.md` — sibling Info.plist handoff (AppIntents + AppShortcutsProvider)
- `@Docs/FEATURE_PLAN.md` § Phase 2 — the "optional photo attach per tale" + "photo-privacy guard rails" boxes this handoff unblocks
- `@Docs/SESSION_HANDOFF_2026-06-23_LATE_EVENING.md` § "Recommended next-session priorities" #4 — the photo-attach priority this handoff captures
