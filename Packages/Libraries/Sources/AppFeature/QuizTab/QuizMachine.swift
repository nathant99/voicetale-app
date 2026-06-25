import Foundation
import Models

/// State machine for ``QuizView``. Walks the kid through a kit's 4
/// questions in order, captures their per-question response, and tracks
/// the running accuracy on `.choice`-kind questions for the
/// `ForgePedagogy.PedagogySession`. Per `@.claude/rules/state-machines.md`
/// § `*Machine` Structs, this is a top-level value type with a `reset()`
/// that re-assigns `self`.
nonisolated public struct QuizMachine: Sendable, Equatable {

    /// Where the kid is in the kit walkthrough.
    public enum Phase: Sendable, Equatable {
        case loading
        case question(index: Int)
        case feedback(index: Int, wasCorrect: Bool?)
        case completed
    }

    public var phase: Phase = .loading
    public var kit: QuestionKit?
    public var reflectionDraft: String = ""

    /// Per-question outcomes for `.choice` items. Reflection / rewrite
    /// items count toward kit completion (XP) but never against accuracy.
    public private(set) var choiceOutcomes: [String: Bool] = [:]

    /// ForgeMasteryEngine Phase B — wall-clock timestamp set when the
    /// machine enters a `.question` phase. Consumed by
    /// ``QuizView/handleChoice`` to compute `elapsedSeconds` for the
    /// `AttemptOutcome.correctFirstTry / .incorrect` cases. `nil` outside
    /// a question phase or before `bootstrap`. Per
    /// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase B + the
    /// state-machines.md "pure value-type mutation, no closures" rule.
    public private(set) var questionStartedAt: Date?

    public init() {}

    /// Total number of questions in the loaded kit, or 0 when nothing
    /// has loaded yet.
    public var totalQuestions: Int { kit?.questions.count ?? 0 }

    /// Index → question convenience.
    public func question(at index: Int) -> KitQuestion? {
        guard let kit, kit.questions.indices.contains(index) else { return nil }
        return kit.questions[index]
    }

    /// Accuracy fraction across the `.choice` items recorded so far.
    /// Returns 0 when no choice items have been answered (the analytics
    /// event categorizes that bucket as `no_choice_items`).
    public var choiceAccuracy: Double {
        guard !choiceOutcomes.isEmpty else { return 0 }
        let correct = choiceOutcomes.values.filter { $0 }.count
        return Double(correct) / Double(choiceOutcomes.count)
    }

    /// Total choice items the kit shipped — drives the analytics
    /// "no_choice_items" bucket vs an unanswered run.
    public var choiceItemCount: Int {
        kit?.questions.filter { $0.kind == .choice }.count ?? 0
    }

    // MARK: - Transitions

    public mutating func bootstrap(with kit: QuestionKit, now: Date = .now) {
        self.kit = kit
        self.phase = .question(index: 0)
        self.choiceOutcomes = [:]
        self.reflectionDraft = ""
        self.questionStartedAt = now
    }

    /// Record a `.choice` answer + transition to feedback.
    public mutating func recordChoice(questionID: String, selectedIndex: Int) {
        guard
            case .question(let index) = phase,
            let question = self.question(at: index),
            question.kind == .choice,
            let correctIndex = question.correctIndex
        else { return }
        let wasCorrect = selectedIndex == correctIndex
        choiceOutcomes[questionID] = wasCorrect
        phase = .feedback(index: index, wasCorrect: wasCorrect)
        // The question timer freezes when we land on feedback; the
        // `elapsedSeconds(now:)` accessor captures the wall-clock delta
        // for whatever consumer (e.g., ``QuizView/handleChoice``) calls
        // it on the same tick.
    }

    /// Record a `.reflection` / `.rewrite` submission. No correctness
    /// signal — these advance straight to feedback so the kid can see
    /// the rationale (if any) before moving on.
    public mutating func recordReflection() {
        guard case .question(let index) = phase else { return }
        phase = .feedback(index: index, wasCorrect: nil)
        reflectionDraft = ""
    }

    /// Advance from a feedback step to either the next question or the
    /// completion phase. Stamps `questionStartedAt` on the new question
    /// so the next ForgeMasteryEngine attempt records a fresh elapsed
    /// window per item.
    public mutating func advance(now: Date = .now) {
        guard case .feedback(let index, _) = phase else { return }
        let next = index + 1
        if next >= totalQuestions {
            phase = .completed
            questionStartedAt = nil
        } else {
            phase = .question(index: next)
            questionStartedAt = now
        }
    }

    /// Wall-clock elapsed seconds for the question currently in flight
    /// (or that just landed on feedback). Returns 0 when no question
    /// has been entered. Floor-clamped at 0.1 so a near-instant tap
    /// never reads as 0 in the FSRS engine (which treats 0 as "no
    /// timing data"). Pure-function — capture via the consumer's local
    /// `Date()` for determinism in tests.
    public func elapsedSeconds(now: Date = .now) -> Double {
        guard let start = questionStartedAt else { return 0 }
        let delta = now.timeIntervalSince(start)
        return max(0.1, delta)
    }

    public mutating func reset() {
        self = QuizMachine()
    }
}
