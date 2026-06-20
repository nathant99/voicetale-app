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

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                privacySection
                permissionsSection
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

    private var crisisSection: some View {
        Section {
            ForEach(crisisResources) { resource in
                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.name)
                        .font(.body.weight(.semibold))
                    if let phone = resource.phone {
                        Label(phone, systemImage: "phone.fill")
                            .font(.caption)
                    }
                    if let text = resource.text {
                        Label(text, systemImage: "message.fill")
                            .font(.caption)
                    }
                    if let url = resource.url {
                        Label(url, systemImage: "globe")
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }
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
