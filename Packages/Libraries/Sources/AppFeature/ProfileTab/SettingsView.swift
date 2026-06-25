import SwiftUI
import Models
import Services
import SharedUI
import VoiceAuthoring

/// Grown-up settings — privacy posture, crisis-resource list, on-device-only
/// affordance. Surfaces the crisis resources from the tradition catalog per
/// `@.claude/rules/trauma-informed-content.md` § "Refer up".
public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var crisisResources: [CrisisResource] = []
    /// DN-S Move D step 3 — experimental cast-voicing toggle. AppStorage is
    /// the source of truth so `TellView` and `SettingsView` observe the same
    /// key without an actor-bridging environment value. Default off per the
    /// DN-S portfolio rollout (TestFlight opt-in only).
    @AppStorage(TellView.castVoicingLiveEnabledKey) private var castVoicingLiveEnabled: Bool = false
    /// ForgeReflection Phase C — grown-up-overridable retention horizon.
    /// `AppRootView.task` reads the same key + clamps to the policy's
    /// allowed set (90 / 180 / 365) so a corrupt write degrades safely.
    /// Per `@.claude/rules/age-assurance.md` § "2026 FTC COPPA Rule
    /// Amendments" (defined retention period requirement).
    @AppStorage(AppRootView.reflectionRetentionDaysKey) private var reflectionRetentionDays: Int = ReflectionRetentionPolicy.defaultRetentionDays

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                privacySection
                permissionsSection
                reflectionRetentionSection
                siriShortcutsSection
                experimentalSection
                crisisSection
                aboutSection
            }
            .voiceTaleNavigationTitle("Settings", large: false)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear(perform: loadCrisisResources)
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("On-device only")
                        .font(.body.weight(.semibold))
                    Text("Audio, transcripts, and reflections stay on this device. VoiceTale does not upload tales to any server.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "lock.shield")
            }
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Intelligence is on-device")
                        .font(.body.weight(.semibold))
                    Text("Bramble runs against the system's on-device Foundation Models when available. When it's not, you'll still get hand-authored fallback feedback.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "cpu.fill")
            }
        }
    }

    private var permissionsSection: some View {
        Section("Permissions") {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Microphone")
                        .font(.body.weight(.semibold))
                    Text(PermissionGate.hasMicrophoneUsageDescription
                         ? "VoiceTale uses the microphone to record your child's tale."
                         : "VoiceTale will be able to record once a grown-up enables the microphone in Settings → VoiceTale.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "mic.fill")
            }
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Speech recognition")
                        .font(.body.weight(.semibold))
                    Text(PermissionGate.hasSpeechRecognitionUsageDescription
                         ? "Used on-device to make the recorded tale searchable."
                         : "Without speech recognition, transcripts will be empty — your child can still record and reflect.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "text.bubble")
            }
        }
    }

    /// Lists the four canonical Siri phrases declared in
    /// `Apps/VoiceTale/VoiceTale/Intents/VoiceTaleShortcuts.swift` so a
    /// grown-up can teach the kid what to say. Phrases come from
    /// ``VoiceTaleIntentRouter.shortcutPhrases`` — the same
    /// portfolio-canonical builder the runtime registers — so this
    /// surface stays in lockstep with what Siri actually accepts.
    /// Per `Docs/HANDOFF_TO_USER_APP_INTENTS_REGISTRATION.md` Step 4 —
    /// the in-app hint surface lowers the discovery barrier without
    /// changing the runtime registration.
    private var siriShortcutsSection: some View {
        let phrases = VoiceTaleIntentRouter.shortcutPhrases
        return Section {
            siriPhraseRow(
                phrase: phrases.tellATale,
                systemImage: "mic.circle.fill",
                detail: "Jumps to the Tell tab so they can start a new tale."
            )
            siriPhraseRow(
                phrase: phrases.showMyTales,
                systemImage: "books.vertical.fill",
                detail: "Opens the anthology of saved tales."
            )
            siriPhraseRow(
                phrase: phrases.showMyProgress,
                systemImage: "chart.bar.fill",
                detail: "Lands on Progress so they can see XP and streak."
            )
            siriPhraseRow(
                phrase: phrases.showTraditionGallery,
                systemImage: "globe",
                detail: "Opens the tradition gallery — griot, seanchaí, rakugo, slam, and more."
            )
        } header: {
            Text("Try saying to Siri")
        } footer: {
            Text("Siri & Shortcuts works once a grown-up enables it for VoiceTale in Settings → Siri & Search. Recordings and reflections still stay on-device.")
                .font(.caption2)
        }
    }

    private func siriPhraseRow(phrase: String, systemImage: String, detail: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text("\u{201C}\(phrase)\u{201D}")
                    .font(.body.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
        }
        .accessibilityLabel(Text("Try saying \u{201C}\(phrase)\u{201D}"))
        .accessibilityHint(Text(detail))
    }

    /// ForgeReflection Phase C — kid-readable grown-up control for the
    /// retention horizon. The three picks (90 / 180 / 365 days) match
    /// the policy's `allowedRetentionDays`. The kid-readable labels
    /// ("around 3 months" / "around half a year" / "around a year")
    /// avoid raw day-count framing that reads as adult-corporate-policy
    /// register.
    private var reflectionRetentionSection: some View {
        Section {
            Picker(
                selection: $reflectionRetentionDays,
                content: {
                    Text("Around 3 months").tag(90)
                    Text("Around half a year").tag(180)
                    Text("Around a year").tag(365)
                },
                label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("How long reflections stick around")
                            .font(.body.weight(.semibold))
                        Text("VoiceTale removes older reflections automatically. You can choose how long they hang on for.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            )
            .pickerStyle(.menu)
            .accessibilityHint("Choose how long reflections persist before VoiceTale removes them.")
        } header: {
            Text("Reflections")
        } footer: {
            Text("Reflections never leave the device. This setting only controls how long they stay on it.")
                .font(.caption2)
        }
    }

    private var experimentalSection: some View {
        Section {
            Toggle(isOn: $castVoicingLiveEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hear from Bramble's friends")
                        .font(.body.weight(.semibold))
                    Text("After a reflection, surface a single in-character line from one of the cast — Lean, Slow, Pivot, or Refrain. Routes through on-device Apple Intelligence; nothing leaves the device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityHint("When on, each saved tale's reflection includes a single short line from one of Bramble's four oral-craft friends.")
        } header: {
            Text("Experimental")
        } footer: {
            Text("Default off. Bramble's reflection itself is unchanged either way.")
                .font(.caption2)
        }
    }

    private var crisisSection: some View {
        Section {
            CrisisResourceListView(resources: crisisResources)
        } header: {
            Text("If a tale brings something up")
        } footer: {
            Text("If your child's tale surfaces a real-life crisis, please pause the session and connect them with a trusted adult. These resources are available in the United States.")
                .font(.caption2)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            VStack(alignment: .leading, spacing: 6) {
                Text("VoiceTale")
                    .font(.headline)
                Text("Voice-first oral storytelling workshop for tweens. Spark & Anvil, 501(c)(3) pending.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func loadCrisisResources() {
        guard crisisResources.isEmpty else { return }
        let catalog = try? TraditionCatalogLoader.loadBundled()
        crisisResources = catalog?.crisisResources?.us ?? []
    }
}

#Preview {
    SettingsView()
}
