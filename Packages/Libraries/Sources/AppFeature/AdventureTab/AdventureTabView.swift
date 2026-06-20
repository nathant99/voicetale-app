import SwiftUI
import Models
import SharedUI

/// Phase 1 Adventure tab — surfaces the Word Workshop zone as placeholder
/// mode-card stubs until the Level 2 `VoiceTaleHubContribution` overlay
/// lands per `@Docs/TECHNICAL_DESIGN.md` § Adventure Mode.
public struct AdventureTabView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    ForEach(modes, id: \.title) { mode in
                        modeCard(mode)
                    }
                }
                .padding()
            }
            .voiceTaleNavigationTitle("Word Workshop")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Word Workshop")
                .font(.title2.weight(.semibold))
            Text("Sharpen one piece of told-tale craft at a time. Modes unlock as you tell more.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private func modeCard(_ mode: ModeCard) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(mode.color.opacity(0.18))
                    .frame(width: 56, height: 56)
                Image(systemName: mode.systemImage)
                    .font(.system(size: 24))
                    .foregroundStyle(mode.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(mode.title)
                        .font(.headline)
                    if mode.isLocked {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                Text(mode.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if mode.isLocked {
                    Text(mode.unlockHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .opacity(mode.isLocked ? 0.6 : 1)
        .accessibilityHint(mode.isLocked ? "Locked: \(mode.unlockHint)" : "Open this Word Workshop mode")
    }

    private var modes: [ModeCard] {
        [
            ModeCard(
                title: "Hook Builder",
                subtitle: "Tell 30-second openers; Lean's body shows whether the hook pulled.",
                systemImage: "leaf.circle.fill",
                color: .orange,
                isLocked: false,
                unlockHint: ""
            ),
            ModeCard(
                title: "Pacing Walk",
                subtitle: "Tell your story to Slow's walking — pacing matches.",
                systemImage: "tortoise.fill",
                color: .green,
                isLocked: true,
                unlockHint: "Unlocks after 3 saved tales."
            ),
            ModeCard(
                title: "Turn Drill",
                subtitle: "Set up beats 1-3 so beat 4 rotates the meaning. Pivot watches.",
                systemImage: "arrow.triangle.2.circlepath",
                color: .teal,
                isLocked: true,
                unlockHint: "Unlocks after 5 saved tales."
            ),
            ModeCard(
                title: "Callback Refrain",
                subtitle: "A phrase at the open, the same phrase at the close. Refrain keeps score.",
                systemImage: "repeat",
                color: .pink,
                isLocked: true,
                unlockHint: "Unlocks after 7 saved tales."
            ),
        ]
    }

    private struct ModeCard {
        let title: String
        let subtitle: String
        let systemImage: String
        let color: Color
        let isLocked: Bool
        let unlockHint: String
    }
}

#Preview {
    AdventureTabView()
}
