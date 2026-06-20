import SwiftUI
import SwiftData
import Models
import Services
import SharedUI

/// Anthology gallery — every told tale the kid has saved, optionally filtered
/// by mood. Renders from value-type caches per
/// `@.claude/rules/swiftdata.md` § "Zero @Query in Views".
public struct AnthologyView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var tales: [VoiceTaleEntry] = []
    @State private var moods: [AnthologyMoodData] = []
    @State private var moodFilter: VoiceTaleMood?

    public init() {}

    public var body: some View {
        NavigationStack {
            content
                .voiceTaleNavigationTitle("Anthology")
                .onAppear(perform: reload)
        }
    }

    @ViewBuilder
    private var content: some View {
        if tales.isEmpty {
            ContentUnavailableView(
                "No tales yet",
                systemImage: "books.vertical",
                description: Text("Every tale you save lands here. Tag a mood from the Tell tab.")
            )
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    moodFilterRow
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTales) { tale in
                            taleCard(tale)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
    }

    private var moodFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: { moodFilter = nil }) {
                    Label("All", systemImage: "tray.full")
                        .font(.callout)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(moodFilter == nil ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                ForEach(VoiceTaleMood.allCases, id: \.self) { mood in
                    Button(action: { moodFilter = mood }) {
                        MoodTagView(mood: mood, isSelected: moodFilter == mood)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private func taleCard(_ tale: VoiceTaleEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tale.title)
                    .font(.headline)
                Spacer()
                MoodTagView(mood: tale.mood)
            }
            Text(tale.recordedAt, format: .relative(presentation: .named))
                .font(.caption)
                .foregroundStyle(.secondary)
            if !tale.transcript.isEmpty {
                Text(tale.transcript)
                    .font(.callout)
                    .lineLimit(3)
                    .foregroundStyle(.primary)
            }
            if let reflection = tale.reflection, let first = reflection.craftObservations.first {
                Text("\u{201C}\(first)\u{201D}")
                    .font(.footnote.italic())
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Label("\(Int(tale.durationSeconds))s", systemImage: "clock")
                Label("\(tale.beatTimeline.filter(\.isWithinTolerance).count)/\(tale.beatTimeline.count) beats", systemImage: "circle.dotted")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var filteredTales: [VoiceTaleEntry] {
        guard let moodFilter else { return tales }
        return tales.filter { $0.mood == moodFilter }
    }

    private func reload() {
        tales = VoiceTaleStore.fetchTales(in: modelContext)
        moods = VoiceTaleStore.fetchAnthologyMoods(in: modelContext)
    }
}
