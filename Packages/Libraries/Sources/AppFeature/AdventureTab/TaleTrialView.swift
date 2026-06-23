import SwiftUI
import SwiftData
import Models
import Services

/// Phase 2 Tale Trial mode surface. Surfaces a random fast-fire prompt + a
/// reshuffle affordance + a "Tell this one" CTA that:
/// 1. Bumps the persistent `taleTrialPlays` counter on
///    ``PersistentPlayerProgress``
/// 2. Emits ``VoiceTaleAnalyticsEvent.taleTrialStarted``
/// 3. Dismisses the sheet so the kid lands back on the Adventure tab and
///    can navigate to the Tell tab to record (or — if the call site
///    chooses — re-presents the existing tell surface; the wiring is
///    intentionally loose so the kid can record now OR later)
///
/// The view stays scaffolding-free per `@Docs/FEATURE_PLAN.md` § Phase 2
/// "Tale Trial (random prompt + 60s tell + Bramble blind judging)".
/// Beat-timer + question-kit overlays are explicitly NOT present.
struct TaleTrialView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.analyticsService) private var analytics
    @State private var machine: TaleTrialMachine

    init(initialMachine: TaleTrialMachine = TaleTrialView.makeInitialMachine()) {
        _machine = State(initialValue: initialMachine)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    introBlock
                    promptCard
                    actions
                    if machine.playsThisSession > 0 {
                        cadenceBadge
                    }
                }
                .padding(24)
            }
            .navigationTitle("Tale Trial")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .accessibilityHint("Close Tale Trial without playing this round.")
                }
            }
        }
    }

    private var introBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("60 seconds. No scaffolding.")
                .font(.title3.weight(.semibold))
            Text("Bramble's listening fresh — no beat timer, no five-beat shape. Just the tale you can find in this prompt.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your prompt")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(machine.currentPrompt.text)
                .font(.title3)
                .foregroundStyle(.primary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Tale Trial prompt: \(machine.currentPrompt.text)"))
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button(action: handleTellThisOne) {
                Label("Tell this one", systemImage: "mic.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("Confirm this prompt as your trial, then head to the Tell tab to record.")

            Button(action: handleReshuffle) {
                Label("Reshuffle", systemImage: "shuffle")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .accessibilityHint("Get a different trial prompt.")
        }
    }

    private var cadenceBadge: some View {
        let count = machine.playsThisSession
        let phrase = count == 1
            ? "1 trial this session — Bramble's listening."
            : "\(count) trials this session — Bramble's listening close."
        return Text(phrase)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityLabel(phrase)
    }

    private func handleTellThisOne() {
        let prompt = machine.recordPlay()
        VoiceTaleStore.bumpTaleTrialPlays(in: modelContext)
        analytics.track(.taleTrialStarted(promptSlug: prompt.slug))
        dismiss()
    }

    private func handleReshuffle() {
        machine.reshuffle()
    }

    /// Build an initial machine seeded with a day-stable prompt so a kid
    /// who opens the sheet twice in a row gets the same prompt by default
    /// (with reshuffle available). The seed is the day-of-year so the
    /// rotation feels natural across the week.
    static func makeInitialMachine(now: Date = Date()) -> TaleTrialMachine {
        let calendar = Calendar(identifier: .gregorian)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 0
        return TaleTrialMachine(currentPrompt: TaleTrialMachine.seededPrompt(daySeed: dayOfYear))
    }
}
