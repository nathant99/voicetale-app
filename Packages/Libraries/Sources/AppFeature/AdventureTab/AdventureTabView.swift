import SwiftUI
import SwiftData
import Models
import Services
import SharedUI
import ForgeProgression
import ForgeAdventure
import ForgeModels

/// Phase 1 Adventure tab — surfaces the Word Workshop zone as 4 mode-cards
/// driven by a ``ForgeProgressionManager`` so the unlock thresholds match
/// `@Docs/FEATURE_PLAN.md` § Adventure Mode (3 / 5 / 7 saved tales).
///
/// The cards are kept hand-authored at Phase 1 because the Level-2
/// ``VoiceTaleHubContribution`` Quest-engine surface is the canonical entry
/// point (registered on the shared ``HubContributionRegistry`` at app launch
/// via ``AppRootView``); future Phase 1.1 / 2 work will surface mode-cards
/// directly from the contribution's `kitResources`.
public struct AdventureTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var talesSavedCount: Int = 0

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    let manager = VoiceTaleProgressionGate.makeManager(
                        talesSavedCount: talesSavedCount
                    )
                    ForEach(modes, id: \.gateID) { mode in
                        modeCard(mode, manager: manager)
                    }
                }
                .padding()
            }
            .voiceTaleNavigationTitle("Word Workshop")
            .onAppear(perform: refreshTalesCount)
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

    private func modeCard(_ mode: ModeCard, manager: ForgeProgressionManager) -> some View {
        let isUnlocked = manager.isUnlocked(mode.gateID)
        let unlockHint = manager.unlockHint(for: mode.gateID) ?? ""
        return HStack(alignment: .top, spacing: 14) {
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
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                Text(mode.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !isUnlocked {
                    Text(unlockHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .opacity(isUnlocked ? 1 : 0.6)
        .accessibilityHint(isUnlocked ? "Open this Word Workshop mode" : "Locked: \(unlockHint)")
    }

    private func refreshTalesCount() {
        talesSavedCount = VoiceTaleStore.fetchTales(in: modelContext).count
    }

    private var modes: [ModeCard] {
        [
            ModeCard(
                gateID: VoiceTaleProgressionGate.hookBuilderID,
                title: "Hook Builder",
                subtitle: "Tell 30-second openers; Lean's body shows whether the hook pulled.",
                systemImage: "leaf.circle.fill",
                color: .orange
            ),
            ModeCard(
                gateID: VoiceTaleProgressionGate.pacingWalkID,
                title: "Pacing Walk",
                subtitle: "Tell your story to Slow's walking — pacing matches.",
                systemImage: "tortoise.fill",
                color: .green
            ),
            ModeCard(
                gateID: VoiceTaleProgressionGate.turnDrillID,
                title: "Turn Drill",
                subtitle: "Set up beats 1-3 so beat 4 rotates the meaning. Pivot watches.",
                systemImage: "arrow.triangle.2.circlepath",
                color: .teal
            ),
            ModeCard(
                gateID: VoiceTaleProgressionGate.callbackRefrainID,
                title: "Callback Refrain",
                subtitle: "A phrase at the open, the same phrase at the close. Refrain keeps score.",
                systemImage: "repeat",
                color: .pink
            ),
        ]
    }

    private struct ModeCard {
        let gateID: String
        let title: String
        let subtitle: String
        let systemImage: String
        let color: Color
    }
}

#Preview {
    AdventureTabView()
}
