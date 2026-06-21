import SwiftUI
import SwiftData
import Models
import Services
import SharedUI

/// Tradition gallery — 5 short kid-readable explainers of oral-storytelling
/// lineages. Per `@.claude/rules/trauma-informed-content.md` §
/// Cultural-sensitivity gates, every entry surfaces an explicit
/// cultural-credit note + optional content warning. The Indigenous-oral-
/// histories card defaults to its content warning expanded.
public struct TraditionGalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.gamificationService) private var gamification
    @State private var catalog: TraditionCatalog?
    @State private var loadError: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            content
                .voiceTaleNavigationTitle("Traditions")
                .onAppear(perform: load)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let catalog {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    catalogIntro
                    ForEach(catalog.entries) { entry in
                        TraditionCard(entry: entry, onExplore: {
                            VoiceTaleStore.recordTraditionExplored(slug: entry.slug, in: modelContext)
                            gamification.awardXP(
                                for: .traditionExplored(slug: entry.slug),
                                in: modelContext
                            )
                        })
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        } else if let loadError {
            ContentUnavailableView(
                "Couldn't load traditions",
                systemImage: "exclamationmark.triangle",
                description: Text(loadError)
            )
        } else {
            ProgressView().padding()
        }
    }

    private var catalogIntro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Honor the storytellers before us")
                .font(.title3.weight(.semibold))
            Text("Five oral-storytelling traditions, credited to the communities they belong to. You can listen, learn, and leave knowing where the craft of telling came from.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private func load() {
        guard catalog == nil else { return }
        do {
            catalog = try TraditionCatalogLoader.loadBundled()
        } catch {
            loadError = "\(error)"
        }
    }
}

private struct TraditionCard: View {
    let entry: TraditionEntry
    let onExplore: () -> Void

    @State private var isExpanded: Bool = false
    @State private var showContentWarning: Bool

    init(entry: TraditionEntry, onExplore: @escaping () -> Void) {
        self.entry = entry
        self.onExplore = onExplore
        // Default-expand the content warning on the Indigenous entry so the
        // kid sees it before tapping in.
        self._showContentWarning = State(initialValue: entry.contentWarning != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.displayName)
                    .font(.headline)
                Spacer()
                Text(entry.region)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 180)
            }
            if let warning = entry.contentWarning, showContentWarning {
                Label(warning, systemImage: "exclamationmark.shield.fill")
                    .font(.footnote)
                    .padding(10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.primary)
            }
            if isExpanded {
                Text(entry.summary)
                    .font(.body)
                Text("Craft primitive — \(entry.craftPrimitive)")
                    .font(.callout.italic())
                    .foregroundStyle(.secondary)
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cultural credit")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(entry.culturalCreditNote)
                        .font(.footnote)
                }
            } else {
                Text(entry.summary)
                    .font(.body)
                    .lineLimit(3)
            }
            HStack {
                Button(isExpanded ? "Show less" : "Read more") {
                    isExpanded.toggle()
                    if isExpanded { onExplore() }
                }
                .buttonStyle(.bordered)
                Spacer()
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
