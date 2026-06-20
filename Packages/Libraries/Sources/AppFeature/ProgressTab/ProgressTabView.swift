import SwiftUI
import SwiftData
import Models
import Services
import SharedUI
import ForgeGamification

/// Phase 1 Progress tab — surfaces XP / level / streak / counted tales /
/// per-mood breakdown. Reads value-type caches from ``VoiceTaleStore`` per
/// `@.claude/rules/swiftdata.md`.
public struct ProgressTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var progress: PlayerProgressData = PlayerProgressData()
    @State private var moods: [AnthologyMoodData] = []
    @State private var totalTales: Int = 0

    private let xpEngine = XPEngine(config: GamificationConfig())

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    xpCard
                    streakCard
                    moodBreakdown
                }
                .padding()
            }
            .voiceTaleNavigationTitle("Progress")
            .onAppear(perform: reload)
        }
    }

    private var xpCard: some View {
        let level = xpEngine.level(for: progress.xpTotal)
        let progressFraction = xpEngine.xpProgress(currentXP: progress.xpTotal)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.tint)
                Text("Level \(level)")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text("\(progress.xpTotal) XP")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progressFraction)
                .tint(.accentColor)
            Text("Every tale you tell earns Bramble's attention.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var streakCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Label("\(progress.currentStreakDays)-day streak", systemImage: "flame.fill")
                    .font(.headline)
                Text(progress.currentStreakDays == 0
                     ? "Start a streak by telling one tale today."
                     : "Longest so far: \(progress.maxStreakDays) days.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack {
                Image(systemName: "books.vertical.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text("\(totalTales) tales")
                    .font(.headline)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var moodBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Anthology by mood")
                .font(.headline)
            if moods.isEmpty {
                Text("Tag your first tale to start the breakdown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(moods) { entry in
                    HStack {
                        Text(entry.displayLabel)
                        Spacer()
                        Text("\(entry.taleCount)")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func reload() {
        progress = VoiceTaleStore.progressSnapshot(in: modelContext)
        moods = VoiceTaleStore.fetchAnthologyMoods(in: modelContext)
        totalTales = moods.reduce(0) { $0 + $1.taleCount }
    }
}
