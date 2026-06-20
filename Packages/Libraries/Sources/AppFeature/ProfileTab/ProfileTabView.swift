import SwiftUI
import Models
import SharedUI

/// Phase 1 Profile tab — surfaces a soft avatar placeholder + entry points
/// to traditions / settings. Avatar editor wiring lands once the ForgeAvatar
/// 1.0-rc.1 `AvatarStudioView` Contacts-style migration handoff is wired per
/// `@Docs/HANDOFF_FROM_LABSMITH_AVATAR_SIMPLIFIED_MIGRATION.md`.
public struct ProfileTabView: View {
    @State private var showingTraditions: Bool = false
    @State private var showingSettings: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    avatarSection
                }
                Section("Storytelling lineage") {
                    Button {
                        showingTraditions = true
                    } label: {
                        Label("Honor the traditions", systemImage: "scroll.fill")
                    }
                }
                Section("Grown-up corner") {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Parent + privacy settings", systemImage: "person.crop.circle.badge.checkmark")
                    }
                }
            }
            .voiceTaleNavigationTitle("Profile")
            .sheet(isPresented: $showingTraditions) {
                TraditionGalleryView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var avatarSection: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.18))
                    .frame(width: 64, height: 64)
                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Storyteller")
                    .font(.headline)
                Text("Your avatar lives across the Forge family of apps.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Avatar settings open in a future build.")
    }
}

#Preview {
    ProfileTabView()
}
