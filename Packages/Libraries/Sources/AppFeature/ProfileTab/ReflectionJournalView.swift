import SwiftUI
import Foundation
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
    /// TWENTIETH-round polish gate — the yearly digest section reads
    /// the same `voicetale.reflection.retention_days` key the
    /// ``SettingsView`` picker writes (Phase C polish). The yearly row
    /// renders only when this resolves to `365` — at 90 / 180, the
    /// "past year" window would exceed the actual retention horizon
    /// and mislead the grown-up. Anti-shame discipline: the digest
    /// must never report a band that the system can't actually back.
    @AppStorage(AppRootView.reflectionRetentionDaysKey) private var reflectionRetentionDays: Int = ReflectionRetentionPolicy.defaultRetentionDays

    public init() {}

    public var body: some View {
        List {
            opt_inSection
            weeklyDigestSection
            monthlyDigestSection
            quarterlyDigestSection
            yearlyDigestSection
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

    /// "This week" engagement digest. Renders only when the grown-up
    /// has opted in (kid-private posture is the default) AND the kid
    /// has actually engaged with Bramble in the last 7 days. The digest
    /// reuses ``Models/ReflectionRetentionPolicy.removedCountBucket(_:)``
    /// for bucketed counts so the wire shape mirrors the sibling
    /// ``parentReflectionJournalOpened(visibleCount:)`` /
    /// ``reflectionsPurged(removed:)`` analytics events. Raw counts
    /// NEVER appear on the row — only the bucket label + (when present)
    /// per-modality bucket labels.
    @ViewBuilder
    private var weeklyDigestSection: some View {
        if parentJournalVisible, let store {
            let digest = store.weeklyEngagement()
            if !digest.isEmpty {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(digestHeadline(digest.totalBucket)) this week")
                                .font(.body.weight(.semibold))
                            if !digest.perModalityBucket.isEmpty {
                                Text(perModalitySummary(digest))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Bramble heard from your child a few times — keep encouraging the curiosity.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } icon: {
                        Image(systemName: "calendar.badge.clock")
                    }
                } header: {
                    Text("This week")
                }
            }
        }
    }

    /// "This month" engagement digest — EIGHTEENTH-round polish sibling
    /// of ``weeklyDigestSection``. Same gating, same wire-shape, same
    /// anti-PII discipline; the only differences are the 30-day window
    /// (via ``VoiceTaleReflectionStore/monthlyEngagement(now:)``) and the
    /// "this month" suffix on the headline.
    ///
    /// The digest renders only when the grown-up has opted in AND the
    /// kid has actually engaged with Bramble in the last 30 days. An
    /// empty-month edge case bypasses the section so the grown-up
    /// doesn't see a "Reflections this month" row that quietly reports
    /// zero engagement.
    ///
    /// Visual register matches the weekly digest deliberately — both
    /// rows use ``Label`` + a calendar-themed SF symbol; only the
    /// month-specific symbol (`calendar`) differs from the week's
    /// `calendar.badge.clock` so the eye can scan-distinguish the
    /// windows at a glance.
    @ViewBuilder
    private var monthlyDigestSection: some View {
        if parentJournalVisible, let store {
            let digest = store.monthlyEngagement()
            if !digest.isEmpty {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(digestHeadline(digest.totalBucket)) this month")
                                .font(.body.weight(.semibold))
                            if !digest.perModalityBucket.isEmpty {
                                Text(perModalitySummary(digest))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Bramble heard from your child a few times this month — keep encouraging the curiosity.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } icon: {
                        Image(systemName: "calendar")
                    }
                } header: {
                    Text("This month")
                }
            }
        }
    }

    /// "Past 90 days" engagement digest — NINETEENTH-round polish
    /// sibling extending the weekly + monthly digests to a quarterly
    /// window. Same gating, same wire-shape, same anti-PII discipline;
    /// the only differences are the 90-day window (via
    /// ``VoiceTaleReflectionStore/quarterlyEngagement(now:)``) and the
    /// "past 90 days" suffix on the headline.
    ///
    /// The digest renders only when the grown-up has opted in AND the
    /// kid has actually engaged with Bramble in the last 90 days. An
    /// empty-quarter edge case bypasses the section so the grown-up
    /// doesn't see a "Reflections past 90 days" row that quietly
    /// reports zero engagement.
    ///
    /// Visual register matches the weekly + monthly digests
    /// deliberately — all three rows use ``Label`` + a calendar-themed
    /// SF symbol; only the quarter-specific symbol
    /// (`calendar.badge.checkmark`) differs from the week's
    /// `calendar.badge.clock` + the month's `calendar` so the eye can
    /// scan-distinguish all three windows at a glance.
    @ViewBuilder
    private var quarterlyDigestSection: some View {
        if parentJournalVisible, let store {
            let digest = store.quarterlyEngagement()
            if !digest.isEmpty {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(digestHeadline(digest.totalBucket)) past 90 days")
                                .font(.body.weight(.semibold))
                            if !digest.perModalityBucket.isEmpty {
                                Text(perModalitySummary(digest))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Bramble heard from your child a few times this quarter — keep encouraging the curiosity.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } icon: {
                        Image(systemName: "calendar.badge.checkmark")
                    }
                } header: {
                    Text("Past 90 days")
                }
            }
        }
    }

    /// "Past year" engagement digest — TWENTIETH-round polish sibling
    /// extending the weekly + monthly + quarterly digests to a 365-day
    /// window. Same anti-PII discipline; same window-neutral factory
    /// reuse; but **with an extra gate**: the section renders only when
    /// the grown-up has chosen the 365-day retention horizon in
    /// ``SettingsView``. At 90 / 180 the yearly window would exceed
    /// the actual data horizon and mislead the grown-up — anti-shame
    /// discipline says the digest never reports a band the system
    /// can't back.
    ///
    /// Three combined gates must pass before rendering:
    /// 1. ``parentJournalVisible`` opt-in (kid-private posture default)
    /// 2. ``reflectionRetentionDays == 365`` (retention-horizon match)
    /// 3. Non-empty 365-day window (the kid actually engaged)
    ///
    /// Visual register matches the prior siblings deliberately —
    /// ``Label`` + calendar-themed SF symbol; the year-specific symbol
    /// (`calendar.badge.exclamationmark`) distinguishes it from the
    /// week's `calendar.badge.clock`, the month's `calendar`, and the
    /// quarter's `calendar.badge.checkmark` so the eye can
    /// scan-distinguish all four windows at a glance.
    @ViewBuilder
    private var yearlyDigestSection: some View {
        if parentJournalVisible,
           reflectionRetentionDays == 365,
           let store {
            let digest = store.yearlyEngagement()
            if !digest.isEmpty {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(digestHeadline(digest.totalBucket)) past year")
                                .font(.body.weight(.semibold))
                            if !digest.perModalityBucket.isEmpty {
                                Text(perModalitySummary(digest))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Bramble heard from your child a few times this year — keep encouraging the curiosity.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } icon: {
                        Image(systemName: "calendar.badge.exclamationmark")
                    }
                } header: {
                    Text("Past year")
                }
            }
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

    /// Kid-readable headline derived from the bucketed total count.
    /// Never speaks raw counts — only the cohort-safe bucket band.
    /// Window-neutral — both the weekly and monthly digest sections
    /// route through this helper so the bucket-to-phrase mapping stays
    /// in a single seam.
    private func digestHeadline(_ totalBucket: String) -> String {
        switch totalBucket {
        case "one_to_three":  return "A few reflections"
        case "four_to_ten":   return "Several reflections"
        case "eleven_plus":   return "Lots of reflections"
        default:              return "Reflections"
        }
    }

    /// Renders the per-modality bucket map as a short comma-joined
    /// phrase: "typed: a few, voice: several". Drops `.skip` from the
    /// summary because surfacing "engaged then private" counts in a
    /// week digest would invite the grown-up to second-guess the
    /// kid's privacy choice — the per-entry list already surfaces
    /// engagement-then-private signals at the row level.
    private func perModalitySummary(_ digest: ReflectionWeeklyEngagement) -> String {
        let order: [ReflectionResponseModality] = [.text, .voice, .drawing, .emoji]
        let phrases = order.compactMap { modality -> String? in
            guard let bucket = digest.perModalityBucket[modality] else { return nil }
            return "\(modalityShortLabel(modality)): \(bucketShortLabel(bucket))"
        }
        return phrases.joined(separator: " · ")
    }

    private func modalityShortLabel(_ modality: ReflectionResponseModality) -> String {
        switch modality {
        case .text:    return "typed"
        case .voice:   return "voice"
        case .drawing: return "drawing"
        case .emoji:   return "emoji"
        case .skip:    return "private"
        }
    }

    private func bucketShortLabel(_ bucket: String) -> String {
        switch bucket {
        case "one_to_three": return "a few"
        case "four_to_ten":  return "several"
        case "eleven_plus":  return "lots"
        default:             return "none"
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
