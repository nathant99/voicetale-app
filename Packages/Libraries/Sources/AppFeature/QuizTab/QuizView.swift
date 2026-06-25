import SwiftUI
import SwiftData
import Models
import Services
import SharedUI
import ForgeCelebration
import ForgeMasteryEngine
import ForgePedagogy

/// Phase 1.1 kit walk-through surface. Loads one of the 4 Phase-1
/// question kits (hook / sensory detail / arc / mood) via
/// ``QuestionKitLoader`` and steps the kid through it. Choice-kind
/// items run through ``ForgePedagogy.PedagogySession`` so the per-kit
/// accuracy + scaffolding state is observable for future practice
/// sessions. Kit completion awards XP via ``GamificationService``.
///
/// Per `@Docs/FEATURE_PLAN.md` § Phase 1.1, this is the deferred
/// surface from Phase 1; kit content already shipped in PR #24 via
/// `QuestionKitLoader`.
public struct QuizView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.gamificationService) private var gamification
    @Environment(\.analyticsService) private var analytics
    @Environment(\.celebrationCoordinator) private var celebration
    @Environment(\.sessionTally) private var sessionTally
    /// ForgeMasteryEngine Phase B — `nil` until ``AppRootView.task`` boots
    /// + injects the shared store. When `nil` (e.g., previews +
    /// unbootstrapped tests) `handleChoice` skips the engine call and
    /// preserves the existing ``ForgePedagogy.PedagogySession`` path.
    @Environment(\.kitMasteryStore) private var kitMasteryStore

    @State private var machine = QuizMachine()
    @State private var pedagogy = PedagogySession()
    @State private var loadError: String?
    @State private var didAwardCompletion: Bool = false

    /// Seed used by ``QuestionKitLoader.loadKitForRotation(seed:)`` to
    /// pick which of the 4 kits to surface. Defaults to the current
    /// week-of-year so the kit rotates over time without random churn.
    private let rotationSeed: Int

    /// ForgeMasteryEngine Phase C — when set, the practice surface loads
    /// the specified ``KitID`` rather than the seed-based rotation.
    /// Used by the three-card "Practice with Bramble" surface on
    /// ``ProgressTabView`` once the engine has signal; cold-launch /
    /// new-kid paths still pass `nil` and inherit the rotation.
    private let preselectedKit: KitID?

    public init(
        rotationSeed: Int = Calendar.current.component(.weekOfYear, from: Date()),
        preselectedKit: KitID? = nil
    ) {
        self.rotationSeed = rotationSeed
        self.preselectedKit = preselectedKit
    }

    public var body: some View {
        NavigationStack {
            content
                .voiceTaleNavigationTitle("Practice")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
                .task {
                    loadKitIfNeeded()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch machine.phase {
        case .loading:
            loadingView
        case .question(let index):
            questionView(index: index)
        case .feedback(let index, let wasCorrect):
            feedbackView(index: index, wasCorrect: wasCorrect)
        case .completed:
            completionView
        }
    }

    // MARK: - Loading

    @ViewBuilder
    private var loadingView: some View {
        if let loadError {
            ContentUnavailableView(
                "Couldn't load practice kit",
                systemImage: "exclamationmark.triangle",
                description: Text(loadError)
            )
        } else {
            VStack(spacing: 16) {
                ProgressView()
                Text("Setting up your practice…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    // MARK: - Question

    @ViewBuilder
    private func questionView(index: Int) -> some View {
        if let kit = machine.kit, let question = machine.question(at: index) {
            VStack(alignment: .leading, spacing: 16) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        kitHeader(kit: kit, currentIndex: index)
                        promptCard(question: question)
                        responseSurface(question: question)
                    }
                    .padding()
                }
            }
            .accessibilityElement(children: .contain)
        }
    }

    private func kitHeader(kit: QuestionKit, currentIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(kit.title)
                .font(.headline)
            Text("Question \(currentIndex + 1) of \(kit.questions.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
            ProgressView(
                value: Double(currentIndex),
                total: Double(max(kit.questions.count - 1, 1))
            )
            .tint(.accentColor)
        }
        .accessibilityLabel("Kit \(kit.title), question \(currentIndex + 1) of \(kit.questions.count)")
    }

    private func promptCard(question: KitQuestion) -> some View {
        Text(question.prompt)
            .font(.title3)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityLabel(Text(question.prompt))
    }

    @ViewBuilder
    private func responseSurface(question: KitQuestion) -> some View {
        switch question.kind {
        case .choice:
            choiceSurface(question: question)
        case .reflection, .rewrite:
            reflectionSurface(question: question)
        }
    }

    private func choiceSurface(question: KitQuestion) -> some View {
        VStack(spacing: 8) {
            ForEach(Array((question.options ?? []).enumerated()), id: \.offset) { option in
                Button {
                    handleChoice(questionID: question.id, selectedIndex: option.offset, question: question)
                } label: {
                    HStack {
                        Text(option.element)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("Tap to choose this answer."))
            }
        }
    }

    private func reflectionSurface(question: KitQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Type a few words…", text: $machine.reflectionDraft, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
                .accessibilityHint(Text("Reflect on the prompt above. There's no right answer."))
            Button {
                machine.recordReflection()
            } label: {
                Text("Submit reflection")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint(Text("Save your reflection and see what comes next."))
        }
    }

    // MARK: - Feedback

    @ViewBuilder
    private func feedbackView(index: Int, wasCorrect: Bool?) -> some View {
        if let question = machine.question(at: index) {
            VStack(alignment: .leading, spacing: 16) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        feedbackHeader(question: question, wasCorrect: wasCorrect)
                        if let rationale = question.rationale {
                            rationaleCard(rationale: rationale)
                        }
                        Button {
                            machine.advance()
                        } label: {
                            Text(isLastQuestion(at: index) ? "Wrap up" : "Next question")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
        }
    }

    private func feedbackHeader(question: KitQuestion, wasCorrect: Bool?) -> some View {
        let title: String
        let systemImage: String
        switch wasCorrect {
        case .some(true):
            title = "Nice listening."
            systemImage = "checkmark.seal.fill"
        case .some(false):
            title = "Try this lens next time."
            systemImage = "lightbulb"
        case .none:
            title = "Thanks for telling Bramble."
            systemImage = "sparkles"
        }
        return Label(title, systemImage: systemImage)
            .font(.title3.weight(.semibold))
            .accessibilityLabel(Text(title))
    }

    private func rationaleCard(rationale: String) -> some View {
        Text(rationale)
            .font(.callout)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func isLastQuestion(at index: Int) -> Bool {
        index >= machine.totalQuestions - 1
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Kit complete.")
                .font(.title3.weight(.semibold))
            if let kit = machine.kit {
                Text("You walked through \(kit.title.lowercased()). Bramble noticed.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                dismiss()
            } label: {
                Text("Back to progress")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .task {
            awardCompletionIfNeeded()
        }
    }

    // MARK: - Side effects

    private func loadKitIfNeeded() {
        guard machine.kit == nil else { return }
        do {
            // ForgeMasteryEngine Phase C — when a recommendation-driven
            // kit was passed via `preselectedKit`, prefer it over the
            // week-of-year rotation. Falls back to the rotation when
            // the requested kit's JSON isn't bundled (defensive
            // against a future kit-id-ships-ahead-of-JSON case).
            let kit: QuestionKit
            if let preselectedKit, let resolved = try QuestionKitLoader.loadKit(forKitID: preselectedKit) {
                kit = resolved
            } else {
                kit = try QuestionKitLoader.loadKitForRotation(seed: rotationSeed)
            }
            machine.bootstrap(with: kit)
        } catch {
            loadError = String(describing: error)
        }
    }

    private func handleChoice(questionID: String, selectedIndex: Int, question: KitQuestion) {
        guard let correctIndex = question.correctIndex else { return }
        let wasCorrect = selectedIndex == correctIndex
        // Concept ID per kit-question — keeps ForgePedagogy's mastery
        // tracker grouped by kit + question.id so future rounds can
        // reason about "kit 1 question 2 still wobbly".
        let conceptID = "kit_\(machine.kit?.kit ?? 0)_\(questionID)"
        _ = pedagogy.recordAnswer(conceptId: conceptID, correct: wasCorrect)
        recordKitMasteryAttempt(wasCorrect: wasCorrect)
        machine.recordChoice(questionID: questionID, selectedIndex: selectedIndex)
    }

    /// ForgeMasteryEngine Phase B — record the per-(kid, kit) attempt
    /// outcome through the shared ``KitMasteryStore`` and emit a
    /// categorical analytics event on band crossings. Skipped when the
    /// store is unbootstrapped (previews / unbootstrapped tests) or the
    /// active kit number doesn't resolve to a ``KitID`` (defensive
    /// against a future kit-number-out-of-range condition).
    private func recordKitMasteryAttempt(wasCorrect: Bool) {
        guard let store = kitMasteryStore else { return }
        guard let kitNumber = machine.kit?.kit,
              let kit = KitID(rawValue: kitNumber)
        else { return }
        let elapsed = machine.elapsedSeconds()
        let outcome: AttemptOutcome = wasCorrect
            ? .correctFirstTry(elapsedSeconds: elapsed)
            : .incorrect(elapsedSeconds: elapsed)
        let priorScore = store.state(for: kit).masteryScore
        let next = store.record(outcome, for: kit)
        let nextScore = next.masteryScore
        let fromBand = MasteryBand.band(forScore: priorScore)
        let toBand = MasteryBand.band(forScore: nextScore)
        if fromBand != toBand {
            analytics.track(.kitMasteryAdvanced(
                kit: kitNumber,
                fromBand: fromBand.rawValue,
                toBand: toBand.rawValue
            ))
        }
    }

    private func awardCompletionIfNeeded() {
        guard !didAwardCompletion, let kit = machine.kit else { return }
        didAwardCompletion = true
        let outcome = gamification.awardXP(for: .kitCompleted(kit: kit.kit), in: modelContext)
        if outcome.leveledUp {
            celebration.levelUp(newLevel: outcome.newLevel)
        }
        for badge in outcome.newBadges {
            celebration.badgeEarned(title: badge.title)
            sessionTally.recordBadgeEarned(title: badge.title)
        }
        let accuracy = machine.choiceItemCount == 0 ? -1.0 : machine.choiceAccuracy
        analytics.track(.kitCompleted(kit: kit.kit, accuracy: accuracy))
    }
}
