import SwiftUI
import SwiftData
import Models
import Services
import SharedUI
import ForgeCelebration

/// Tradition gallery — 5 short kid-readable explainers of oral-storytelling
/// lineages. Per `@.claude/rules/trauma-informed-content.md` §
/// Cultural-sensitivity gates, every entry surfaces an explicit
/// cultural-credit note + optional content warning. The Indigenous-oral-
/// histories card defaults to its content warning expanded.
public struct TraditionGalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.gamificationService) private var gamification
    @Environment(\.analyticsService) private var analytics
    @Environment(\.celebrationCoordinator) private var celebration
    @Environment(\.sessionTally) private var sessionTally
    @State private var catalog: TraditionCatalog?
    @State private var loadError: String?
    /// Delight & Polish "Discovery" micro-delight — count of traditions
    /// the kid has not yet expanded. Drives the discovery callout above
    /// the gallery list. Recomputed on appear + after each `onExplore`
    /// tap (since expanding a tradition turns it from "unexplored" →
    /// "explored").
    @State private var unexploredCount: Int = 0

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
                    if let calloutCopy = Self.discoveryCalloutCopy(unexploredCount: unexploredCount) {
                        traditionDiscoveryCallout(calloutCopy)
                    }
                    ForEach(catalog.entries) { entry in
                        TraditionCard(entry: entry, onExplore: {
                            VoiceTaleStore.recordTraditionExplored(slug: entry.slug, in: modelContext)
                            let outcome = gamification.awardXP(
                                for: .traditionExplored(slug: entry.slug),
                                in: modelContext
                            )
                            if outcome.leveledUp {
                                celebration.levelUp(newLevel: outcome.newLevel)
                            }
                            for badge in outcome.newBadges {
                                celebration.badgeEarned(title: badge.title)
                                sessionTally.recordBadgeEarned(title: badge.title)
                            }
                            analytics.track(.traditionExplored(slug: entry.slug))
                            // Surprise micro-delight tradition-echo signal —
                            // record the tradition's craft-register slugs so
                            // ``TellView.deriveSurpriseMomentIfAny()`` can fire
                            // ``SurpriseMoment.traditionEchoSameSession`` when
                            // the kid tells a tale in a matching mood within
                            // the same sitting. Per PR-B 2026-06-24 NINTH-round.
                            sessionTally.recordTraditionExpanded(slug: entry.slug)
                            // Discovery callout updates as the kid expands
                            // traditions — pull the next iteration of
                            // unexplored count from the persistence layer.
                            recomputeUnexploredCount()
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

    /// Delight & Polish "Discovery" micro-delight — surfaces a Bramble-
    /// register callout above the tradition list inviting the kid to
    /// pull a tradition card closer when they're ready. Per
    /// `@Docs/AUDIT_MICRO_DELIGHT_COVERAGE_2026-06-24.md` § Yellow —
    /// Discovery expansion.
    @ViewBuilder
    private func traditionDiscoveryCallout(_ copy: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(.tint)
            Text(copy)
                .font(.callout)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Discovery hint: \(copy)"))
    }

    /// Pure-function copy resolver for the discovery callout. Returns
    /// `nil` when the kid has explored every tradition (no callout
    /// needed) — the copy never names the count, never frames remaining
    /// traditions as deficient.
    ///
    /// Public + `nonisolated` so unit tests can exercise the resolver
    /// without spinning up the SwiftUI host.
    nonisolated public static func discoveryCalloutCopy(unexploredCount: Int) -> String? {
        guard unexploredCount > 0 else { return nil }
        if unexploredCount == 1 {
            return "One tradition is waiting — pull it closer when you're ready."
        }
        return "More traditions are waiting — pull one closer when you're ready."
    }

    private func load() {
        guard catalog == nil else { return }
        do {
            catalog = try TraditionCatalogLoader.loadBundled()
            recomputeUnexploredCount()
        } catch {
            loadError = "\(error)"
        }
    }

    /// Reads the catalog + the explored-tradition persistence layer to
    /// compute how many catalog entries have NOT yet been expanded.
    /// Idempotent and cheap — called on appear + after each `onExplore`
    /// tap so the discovery callout fades correctly as the kid pulls
    /// traditions closer one by one.
    private func recomputeUnexploredCount() {
        guard let catalog else { return }
        let explored = Set(
            VoiceTaleStore.fetchTraditionExploration(in: modelContext)
                .compactMap { $0.firstExploredAt != nil ? $0.slug : nil }
        )
        unexploredCount = catalog.entries.reduce(into: 0) { count, entry in
            if !explored.contains(entry.slug) {
                count += 1
            }
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text(accessibilityHint))
    }

    /// VoiceOver label combining tradition name + region + cultural-credit
    /// register so the kid can scan the gallery without expanding every card.
    private var accessibilityLabel: String {
        var label = "\(entry.displayName), from \(entry.region)"
        if let warning = entry.contentWarning, showContentWarning {
            label += ". Content note: \(warning)"
        }
        return label
    }

    private var accessibilityHint: String {
        isExpanded
            ? "Tap Show less to collapse the explainer."
            : "Tap Read more to expand the explainer and read the cultural-credit note."
    }
}
