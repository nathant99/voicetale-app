---
status: ACTIVE
date: 2026-06-23
direction: agent → user
intent: optional Xcode-UI step to wire the iOS 26.2+ Declared Age Range API for COPPA "actual knowledge" gating before TestFlight
freshness-horizon: 60 days
---

# Handoff to User — Apple Declared Age Range API (iOS 26.2+)

Direction: **agent → user**. VoiceTale ships fine today without this step; the app does not collect PII, does not run third-party analytics, and stores all child data on-device, so the existing posture is COPPA-compliant by structure. **However**, when VoiceTale ships to TestFlight (and especially the App Store), wiring the **Declared Age Range API** is the canonical way to enforce age-aware behavior at the Apple-platform layer. This handoff captures the Xcode-UI steps the agent cannot take from disk per `@.claude/rules/xcode-agent-safety.md` § "Never write these from disk".

This step is **OPTIONAL for Phase 1** (no PII flows; structural compliance holds). It becomes **load-bearing before TestFlight** if any of the following ship:

- A feature that asks for parental consent (Significant Change API trigger)
- Any push notification path
- App Store metadata that declares an age rating (13+ / 16+ / 18+ per 2026 FTC update)

## Background — why the API matters

Per `@.claude/rules/age-assurance.md`:

> `Declared Age Range` returns age categories via Family Sharing: **Under 13** (child), **13–15** (teen), **16–17** (older teen), **Over 18** (adult). Actual birthdate never shared.
>
> **CRITICAL**: Receiving "under 13" creates **COPPA actual knowledge** — all consent flows and record-keeping requirements immediately apply.

VoiceTale targets ages **8–13**, so the kid-bucket is the dominant cohort. Receiving "under 13" through this API is the moment iOS hands us the COPPA-actual-knowledge flag; we must then route that user through the parental-consent path, suppress any third-party SDK (we have none — but the structural guarantee matters), and ensure data retention follows the 2026 FTC limits (already structurally enforced because all data is on-device + revocable from Settings).

## Step 1 — Set the minimum deployment target to iOS 26.2

The Declared Age Range API ships in **iOS 26.2** (not 26.0). VoiceTale's current minimum may be lower.

1. Open `VoiceTale.xcworkspace` (NOT `Apps/VoiceTale/VoiceTale.xcodeproj` directly per `@.claude/rules/xcode-agent-safety.md` § "Always open .xcworkspace").
2. Select the `VoiceTale` project → `VoiceTale` target → **General** tab.
3. Under **Minimum Deployments**, confirm **iOS** is set to **26.2** or higher.
4. If lower, set it to **26.2**. The xcodeproj will update with the new `IPHONEOS_DEPLOYMENT_TARGET = 26.2` build setting in both `Debug` and `Release` configs.

**Expected result**: the project's `IPHONEOS_DEPLOYMENT_TARGET` build setting reads `26.2` in both build configs. Staging the resulting `.pbxproj` diff is fine.

Also update `Packages/Libraries/Package.swift` `platforms` clause to `.iOS(.v26_2)` once Apple ships the Swift API and the toolchain accepts that platform spec. Until then, the package can stay on `.iOS(.v26)` because Xcode resolves availability against the app target.

## Step 2 — Add the Declared Age Range capability / entitlement

The Declared Age Range API requires an Apple-provided entitlement. As of iOS 26.2, the canonical capability surface in Xcode is:

1. Select the `VoiceTale` app target → **Signing & Capabilities** tab.
2. Click **+ Capability** → search **"Family Controls"** OR **"Declared Age Range"** (the exact label depends on the SDK version; in iOS 26.2 betas it surfaces as **Declared Age Range**; in iOS 26.0/26.1 it surfaces under **Family Controls**). Double-click to add.
3. Xcode generates `Apps/VoiceTale/VoiceTale/VoiceTale.entitlements` with the new key (if it didn't exist) OR adds the new key to the existing entitlements file.

The key Xcode writes is one of:

```xml
<key>com.apple.developer.family-controls</key>
<true/>
```

OR (newer SDKs):

```xml
<key>com.apple.developer.declared-age-range</key>
<true/>
```

4. Commit the entitlements file via `git add Apps/VoiceTale/VoiceTale/VoiceTale.entitlements` — staging Xcode-managed files you generated through the UI is allowed per `@.claude/rules/xcode-agent-safety.md` § "Instead — file a handoff doc". What's forbidden is authoring the bytes from disk.

**Expected result**: the entitlements file's plist contains the Declared Age Range (or Family Controls) entitlement key set to `true`. Provisioning profile re-sign happens automatically on next build.

## Step 3 — Add `NSAgeRangeUsageDescription` (or equivalent) to Info.plist

Per the standing iOS rule on privacy-gated frameworks (see `@.claude/rules/warnings.md` § "Privacy-Gated Frameworks"), accessing the Declared Age Range API without a usage-description string hard-crashes the process. Add the description via the Xcode GUI:

1. Select the `VoiceTale` target → **Info** tab.
2. Click the **+** under **Custom iOS Target Properties**.
3. Add a new key. As of iOS 26.2 the key is **NSAgeRangeUsageDescription** (kid-readable name: **"Privacy - Age Range Usage Description"**).
4. Set the value to (kid-readable copy):

   ```
   VoiceTale uses your age range from Family Sharing to make sure tradition layers and reflection prompts are right for you. We never see your birthdate.
   ```

5. Build (Cmd-B). The xcodeproj will write the key into the build settings as `INFOPLIST_KEY_NSAgeRangeUsageDescription` in both `Debug` and `Release` configs (Xcode's modern Info.plist generation pattern — keys live in the xcodeproj, not a free-standing `Info.plist` per the existing VoiceTale Phase 1 pattern, see `Apps/VoiceTale/VoiceTale.xcodeproj/project.pbxproj` for `INFOPLIST_KEY_NSMicrophoneUsageDescription` + `INFOPLIST_KEY_NSSpeechRecognitionUsageDescription` precedent).

**Expected result**: the build setting `INFOPLIST_KEY_NSAgeRangeUsageDescription` is set in both `Debug` and `Release` configs of the `VoiceTale` target. Staging the resulting `.pbxproj` diff is fine.

## Step 4 — Wire the Swift call site

After Steps 1–3 are done, the agent CAN author the Swift call site — it's a Swift file under `Packages/Libraries/Sources/AppFeature/`. The canonical pattern (based on iOS 26.2 documentation snapshot; verify via `DocumentationSearch` before writing the final form):

```swift
import DeclaredAgeRange   // module name TBD per iOS 26.2 SDK shipping name
import os.log

@MainActor
@Observable
final class AgeAssuranceService {
    enum AgeBucket: Sendable {
        case under13
        case teen13to15
        case olderTeen16to17
        case adult18plus
        case undeclared
    }

    private(set) var bucket: AgeBucket = .undeclared
    private(set) var coppaActualKnowledge: Bool = false

    func refresh() async {
        // Gate access per the privacy-description check pattern documented in
        // `@.claude/rules/warnings.md` § Privacy-Gated Frameworks.
        guard hasUsageDescription else { return }
        do {
            let rangeRequest = AgeRangeRequest()
            let response = try await rangeRequest.values
            bucket = mapToBucket(response)
            // Receiving "under 13" creates COPPA actual knowledge per
            // `@.claude/rules/age-assurance.md`.
            coppaActualKnowledge = (bucket == .under13)
        } catch {
            os_log("AgeAssurance refresh failed: %@", "\(error)")
        }
    }

    private var hasUsageDescription: Bool {
        guard let str = Bundle.main.object(forInfoDictionaryKey: "NSAgeRangeUsageDescription") as? String else {
            return false
        }
        return !str.isEmpty
    }

    private func mapToBucket(_ response: Any) -> AgeBucket {
        // Implementation TBD per iOS 26.2 final SDK signature.
        return .undeclared
    }
}
```

The agent will author this as a separate PR after Steps 1–3 are confirmed in Xcode. Until then the call site can't compile because the entitlement isn't wired.

## Step 5 — Verify

1. Build + run on a device with Family Sharing configured (an iCloud-signed-in iPhone is sufficient — Family Sharing isn't strictly required for the API to return `.undeclared`).
2. On first launch, confirm the system surfaces the age-range permission prompt (kid-readable copy from Step 3).
3. On a child-account device, confirm `coppaActualKnowledge` flips to `true` after `refresh()`.

If the permission prompt doesn't surface, the most likely cause is Step 3 (missing usage description) — verify the build setting persisted.

## Why these steps require the user, not the agent

Per `@.claude/rules/xcode-agent-safety.md` § "Never write these from disk":

| File class | Why it's owned by Xcode |
|---|---|
| `*.xcodeproj/project.pbxproj` | Workspace-defining XML; direct edits trigger External Changes dialog and can corrupt |
| `*.entitlements` | Owned by Xcode's capabilities editor; provisioning re-sign step must run |
| `*/Info.plist` / `INFOPLIST_KEY_*` in `.pbxproj` | Owned by Xcode's target editor; build-setting-mediated Info.plist generation requires the GUI |

Editing any of these from disk:

1. Bypasses the Xcode UI's provisioning-profile re-sign step (causes signing failures)
2. Triggers Xcode's "External Changes" dialog every time the agent edits the file
3. In the worst case, forces a workspace reload that terminates the agent session mid-task

The user clicking through Signing & Capabilities + Info tabs is the only safe path. Staging the resulting files via `git add <specific-path>` is fine.

## What happens if you SKIP this step

VoiceTale ships fine without the Declared Age Range API as long as:

- No PII is collected (✅ true today)
- No third-party analytics SDK is added (✅ true today)
- App Store age rating remains at 9+ or 4+ (i.e., NOT the new 13+ / 16+ / 18+ buckets that triggered the 2026 FTC update — see `@.claude/rules/age-assurance.md` § Age Rating Updates)
- No push notification flow is wired (✅ true today)

If any of those four become FALSE in Phase 2 / Phase 3 / Phase 4, this handoff becomes blocking. File a follow-up handoff (or unblock this one) at that time.

## Cross-references

- `@.claude/rules/age-assurance.md` — full Declared Age Range API context + 2026 FTC COPPA Rule amendments
- `@.claude/rules/xcode-agent-safety.md` § "Never write these from disk" — entitlements + Info.plist rows
- `@.claude/rules/warnings.md` § "Privacy-Gated Frameworks" — Info.plist usage description pattern
- `Docs/HANDOFF_TO_USER_XCODE_WORKSPACE_INTEGRATION.md` (status: CLOSED) — precedent for the same handoff-doc-for-Xcode-UI pattern
- `Apps/VoiceTale/VoiceTale.xcodeproj/project.pbxproj` — existing `INFOPLIST_KEY_NSMicrophoneUsageDescription` + `INFOPLIST_KEY_NSSpeechRecognitionUsageDescription` precedent (Step 3 follows the same pattern)
- `Docs/FEATURE_PLAN.md` § Onboarding — "Apple Declared Age Range API (iOS 26+)" line
