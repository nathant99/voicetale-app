import SwiftUI
import Models
import SharedUI

/// Phase 1 Profile tab — surfaces the ForgeAvatar editor (R3 segmented
/// `.lite`+`.full` toggle per writing-craft cluster pattern in
/// `@.claude/rules/forgekit.md` § Avatar Edit Authority) + entry points to
/// traditions / settings / companion pack.
public struct ProfileTabView: View {
    @State private var showingTraditions: Bool = false
    @State private var showingSettings: Bool = false
    @State private var showingCompanionPack: Bool = false
    @State private var showingAvatarStudio: Bool = false

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
                    Button {
                        showingCompanionPack = true
                    } label: {
                        Label("Print + share companion pack", systemImage: "printer.fill")
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
            .sheet(isPresented: $showingCompanionPack) {
                CompanionPackView()
            }
            .sheet(isPresented: $showingAvatarStudio) {
                AvatarStudioSheet(onDismiss: { showingAvatarStudio = false })
            }
        }
    }

    private var avatarSection: some View {
        Button {
            showingAvatarStudio = true
        } label: {
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
                        .foregroundStyle(.primary)
                    Text("Tap to change your look.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Open the avatar editor — simple or all-options view.")
    }
}

#Preview {
    ProfileTabView()
}
