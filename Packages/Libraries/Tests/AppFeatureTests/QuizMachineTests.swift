import Testing
import Foundation
@testable import AppFeature
import Models

@Suite("QuizMachine")
struct QuizMachineTests {
    private func sampleKit() -> QuestionKit {
        QuestionKit(
            kit: 1,
            title: "The Hook",
            primitive: "hook / leanability",
            anchorCharacterSlug: "lean",
            summary: "test",
            questions: [
                KitQuestion(id: "k1q1", kind: .reflection, prompt: "Reflect 1"),
                KitQuestion(
                    id: "k1q2",
                    kind: .choice,
                    prompt: "Pick one",
                    options: ["a", "b", "c"],
                    correctIndex: 1,
                    rationale: "Because b."
                ),
                KitQuestion(id: "k1q3", kind: .rewrite, prompt: "Rewrite this"),
            ],
            castCameos: []
        )
    }

    @Test func bootstrapMovesToFirstQuestion() {
        var machine = QuizMachine()
        machine.bootstrap(with: sampleKit())
        #expect(machine.phase == .question(index: 0))
        #expect(machine.totalQuestions == 3)
    }

    @Test func recordReflectionAdvancesToFeedback() {
        var machine = QuizMachine()
        machine.bootstrap(with: sampleKit())
        machine.recordReflection()
        #expect(machine.phase == .feedback(index: 0, wasCorrect: nil))
    }

    @Test func recordChoiceCorrectMarksWasCorrectTrue() {
        var machine = QuizMachine()
        machine.bootstrap(with: sampleKit())
        // First skip the reflection to land on the choice question
        machine.recordReflection()
        machine.advance()
        machine.recordChoice(questionID: "k1q2", selectedIndex: 1)
        #expect(machine.phase == .feedback(index: 1, wasCorrect: true))
        #expect(machine.choiceOutcomes["k1q2"] == true)
        #expect(machine.choiceAccuracy == 1.0)
    }

    @Test func recordChoiceIncorrectMarksWasCorrectFalse() {
        var machine = QuizMachine()
        machine.bootstrap(with: sampleKit())
        machine.recordReflection()
        machine.advance()
        machine.recordChoice(questionID: "k1q2", selectedIndex: 0)
        #expect(machine.phase == .feedback(index: 1, wasCorrect: false))
        #expect(machine.choiceOutcomes["k1q2"] == false)
        #expect(machine.choiceAccuracy == 0.0)
    }

    @Test func advanceFromLastFeedbackCompletes() {
        var machine = QuizMachine()
        machine.bootstrap(with: sampleKit())
        machine.recordReflection()                      // q0 -> feedback
        machine.advance()                               // -> q1
        machine.recordChoice(questionID: "k1q2", selectedIndex: 1)  // -> feedback
        machine.advance()                               // -> q2
        machine.recordReflection()                      // -> feedback
        machine.advance()                               // -> completed
        #expect(machine.phase == .completed)
    }

    @Test func resetClearsAllState() {
        var machine = QuizMachine()
        machine.bootstrap(with: sampleKit())
        machine.recordReflection()
        machine.advance()
        machine.recordChoice(questionID: "k1q2", selectedIndex: 1)
        machine.reset()
        #expect(machine.phase == .loading)
        #expect(machine.kit == nil)
        #expect(machine.choiceOutcomes.isEmpty)
    }

    @Test func choiceItemCountReportsKitChoiceQuestions() {
        var machine = QuizMachine()
        machine.bootstrap(with: sampleKit())
        #expect(machine.choiceItemCount == 1)
    }
}
