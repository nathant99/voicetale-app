import SwiftUI
import ForgeModels
import Models

/// ForgeReflection Phase D — grown-up-facing reflection journal surface
/// pushed from ``SettingsView`` under the "Reflections" section. Per
/// `@Docs/PLAN_FORGEREFLECTION_LIFT.md` § Phase D.
///
/// Adopts the canonical "opt-in default" posture per
/// `@.claude/rules/age-assurance.md` § "2026 FTC COPPA Rule Amendments":
///
/// - The kid's reflections stay **kid-private by default** — every
///   `ReflectionPromptConfig` ships at `parentVisible: false` in V1.
/// - The Phase D opt-in surface is the
///   ``parentJournalVisibleKey`` `@AppStorage` toggle hosted on this
///   view. When **OFF (default)**, the surface renders an
///   anti-shame empty state explaining the privacy posture. When the
///   grown-up flips it **ON**, the cached snapshot from
///   ``VoiceTaleReflectionStore`` is filtered through a constant
///   `(_) -> Bool` closure that surfaces every cached entry.
///
/// **What never travels on a row**: the raw `textValue` payload. Even
/// once the grown-up has explicitly opted in, the journal renders
/// modality + responded-at + (when present) kit number — never the
/// kid-typed text. The trauma-informed off-ramp (`.skip` entries)
/// renders as a count signal ("engaged with this prompt, kept it
/// private") so the grown-up sees engagement without the kid's words.
///
/// The categorical ``parentReflectionJournalOpened(visibleCount:)``
/// analytics event fires once per appearance with a bucketed visible-
/// entry count (zero / one_to_three / four_to_ten / eleven_plus). Raw
/// counts NEVER travel; the bucketing reuses
/// ``ReflectionRetentionPolicy.removedCountBucket(_:)`` so the wire
/// shape stays in lockstep with the sibling
/// ``reflectionsPurged(removed:)`` event.
public struct ReflectionJournalView: View {
    /// Persistence key for the grown-up opt-in toggle. Co-located here
    /// so tests + the SettingsView host agree on the canonical shape.
    /// `nonisolated` so the key can be read from background contexts
    /// (analytics buckets, etc.).
    public nonisolated static let parentJournalVisibleKey = "voicetale.reflection.parent_journal_visible"

    @Environment(\.voiceTaleReflectionStore) private var store
    @Environment(\.analyticsService) private var analytics
    @Environment(\.dismiss) private var dismiss
    @AppStorage(ReflectionJournalView.parentJournalVisibleKey) private var parentJournalVisible: Bool = false

    public init() {}

    public var body: some View {
        List {
            opt_inSection
            entriesSection
            privacyFooter
        }
        .voiceTaleNavigationTitle("Reflection journal", large: false)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear(perform: emitOpenedEvent)
    }

    private var opt_inSection: some View {
        Section {
            Toggle(isOn: $parentJournalVisible) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Show kid's reflections")
                        .font(.body.weight(.semibold))
                    Text("Off by default. When on, you'll see when and how your child answered Bramble's questions — but never the words they typed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityHint("When on, this surface lists how and when your child answered Bramble's questions. Their typed words are never shown either way.")
        } header: {
            Text("Privacy")
        }
    }

    @ViewBuilder
    private var entriesSection: some View {
        if parentJournalVisible {
            let entries = visibleEntries
            Section {
                if entries.isEmpty {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nothing yet")
                                .font(.body.weight(.semibold))
                            Text("Your child hasn't answered Bramble's questions on this device. Reflections will show up here as they happen.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "leaf")
                    }
                } else {
                    ForEach(entries) { entry in
                        journalRow(entry)
                    }
                }
            } header: {
                Text("Recent reflections")
            }
        } else {
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kid-private right now")
                            .font(.body.weight(.semibold))
                        Text("Bramble keeps the listening private by default. Flip the toggle above when you'd like a window in.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "lock.shield")
                }
            } header: {
                Text("Recent reflections")
            }
        }
    }

    private var privacyFooter: some View {
        Section {
            Text("Reflections live on this device only. VoiceTale never uploads them, and your child's typed words never appear on this surface even when the toggle is on.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func journalRow(_ entry: ReflectionEntry) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(modalityHeadline(entry.modality))
                    .font(.body.weight(.semibold))
                if let kit = entry.kitNumber {
                    Text("Kit \(kit) · \(relativeTimestamp(entry.respondedAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(relativeTimestamp(entry.respondedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: modalitySymbol(entry.modality))
        }
    }

    /// Pulls the cached snapshot through the parent-visibility filter.
    /// The closure is a constant `{ _ in true }` while the toggle is on
    /// (per the V1 opt-in posture); future iterations could thread a
    /// per-promptID picker through here.
    private var visibleEntries: [ReflectionEntry] {
        guard let store, parentJournalVisible else { return [] }
        return store.parentVisibleEntries(promptVisibility: { _ in true })
    }

    private func emitOpenedEvent() {
        let count = visibleEntries.count
        analytics.track(.parentReflectionJournalOpened(visibleCount: count))
    }

    /// Kid-readable headline for each row. Never speaks the kid's
    /// typed words — only the modality + (for `.skip`) the engagement
    /// signal.
    private func modalityHeadline(_ modality: ReflectionResponseModality) -> String {
        switch modality {
        case .text:    return "Answered Bramble (typed)"
        case .voice:   return "Answered Bramble (voice)"
        case .drawing: return "Answered Bramble (drawing)"
        case .emoji:   return "Answered Bramble (emoji)"
        case .skip:    return "Engaged then chose privacy"
        }
    }

    private func modalitySymbol(_ modality: ReflectionResponseModality) -> String {
        switch modality {
        case .text:    return "text.bubble.fill"
        case .voice:   return "waveform.circle.fill"
        case .drawing: return "scribble.variable"
        case .emoji:   return "face.smiling.inverse"
        case .skip:    return "lock.fill"
        }
    }

    private func relativeTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}

#Preview {
    NavigationStack {
        ReflectionJournalView()
    }
}
