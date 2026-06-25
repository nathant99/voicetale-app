import Testing
import Foundation
import SwiftData
import ForgeMasteryEngine
@testable import AppFeature
import Models
import Services

/// ForgeMasteryEngine Phase B coverage per
/// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase B. Exercises the
/// QuizMachine elapsed-seconds wiring + the `MasteryBand` quartile
/// helper + the analytics event shape, plus an integration round-trip
/// through the Phase A `KitMasteryStore`.
@MainActor
@Suite("KitMasteryQuizWiring")
struct KitMasteryQuizWiringTests {
    // MARK: - QuizMachine.elapsedSeconds wiring

    @Test func bootstrapStampsQuestionStartedAt() {
        var machine = QuizMachine()
        let now = Date()
        let kit = QuestionKit(
            kit: 1,
            title: "Hook",
            primitive: "hook craft",
            anchorCharacterSlug: "lean",
            summary: "Hook practice",
            questions: [
                KitQuestion(
                    id: "q1",
                    kind: .choice,
                    prompt: "Pick one",
                    options: ["A", "B"],
                    correctIndex: 0
                )
            ],
            castCameos: []
        )
        machine.bootstrap(with: kit, now: now)
        #expect(machine.questionStartedAt == now)
        // Elapsed-seconds at the bootstrap tick clamps at the 0.1
        // floor — no question registers as exactly 0 to the FSRS
        // engine (which would treat 0 as "no timing data").
        #expect(machine.elapsedSeconds(now: now) == 0.1)
    }

    @Test func elapsedSecondsClampsToFloor() {
        var machine = QuizMachine()
        let kit = QuestionKit(
            kit: 1,
            title: "Hook",
            primitive: "hook craft",
            anchorCharacterSlug: "lean",
            summary: "Hook practice",
            questions: [
                KitQuestion(
                    id: "q1",
                    kind: .choice,
                    prompt: "Pick one",
                    options: ["A", "B"],
                    correctIndex: 0
                )
            ],
            castCameos: []
        )
        let start = Date()
        machine.bootstrap(with: kit, now: start)
        // 5 seconds later — the elapsed delta should report ~5s.
        let later = start.addingTimeInterval(5.3)
        let elapsed = machine.elapsedSeconds(now: later)
        #expect(abs(elapsed - 5.3) < 0.001)
    }

    @Test func advanceStampsNewQuestionStartTime() {
        var machine = QuizMachine()
        let kit = QuestionKit(
            kit: 1,
            title: "Hook",
            primitive: "hook craft",
            anchorCharacterSlug: "lean",
            summary: "Hook practice",
            questions: [
                KitQuestion(
                    id: "q1",
                    kind: .choice,
                    prompt: "Pick one",
                    options: ["A", "B"],
                    correctIndex: 0
                ),
                KitQuestion(
                    id: "q2",
                    kind: .choice,
                    prompt: "Pick another",
                    options: ["C", "D"],
                    correctIndex: 1
                )
            ],
            castCameos: []
        )
        let start = Date()
        machine.bootstrap(with: kit, now: start)
        machine.recordChoice(questionID: "q1", selectedIndex: 0)
        // Advance ~2s later — the new question's timer starts from
        // there, not from the prior question's start time.
        let advanceAt = start.addingTimeInterval(2.0)
        machine.advance(now: advanceAt)
        #expect(machine.questionStartedAt == advanceAt)
    }

    @Test func resetClearsQuestionStartedAt() {
        var machine = QuizMachine()
        let kit = QuestionKit(
            kit: 1,
            title: "Hook",
            primitive: "hook craft",
            anchorCharacterSlug: "lean",
            summary: "Hook practice",
            questions: [
                KitQuestion(
                    id: "q1",
                    kind: .choice,
                    prompt: "Pick one",
                    options: ["A", "B"],
                    correctIndex: 0
                )
            ],
            castCameos: []
        )
        machine.bootstrap(with: kit)
        #expect(machine.questionStartedAt != nil)
        machine.reset()
        #expect(machine.questionStartedAt == nil)
        // No question entered yet — elapsedSeconds returns 0.
        #expect(machine.elapsedSeconds(now: Date()) == 0)
    }

    // MARK: - MasteryBand quartile helper

    @Test func masteryBandQuartileBoundaries() {
        #expect(MasteryBand.band(forScore: 0.0) == .emerging)
        #expect(MasteryBand.band(forScore: 0.24) == .emerging)
        #expect(MasteryBand.band(forScore: 0.25) == .developing)
        #expect(MasteryBand.band(forScore: 0.49) == .developing)
        #expect(MasteryBand.band(forScore: 0.50) == .meeting)
        #expect(MasteryBand.band(forScore: 0.74) == .meeting)
        #expect(MasteryBand.band(forScore: 0.75) == .deepening)
        #expect(MasteryBand.band(forScore: 1.00) == .deepening)
    }

    @Test func masteryBandClampsOutOfRange() {
        // Defensive — the engine guarantees [0, 1] but downstream
        // consumers may drift. Both ends clamp to the nearest band.
        #expect(MasteryBand.band(forScore: -0.5) == .emerging)
        #expect(MasteryBand.band(forScore: 1.5) == .deepening)
    }

    @Test func masteryBandHasAllFourCases() {
        // Locks the 4-band wire surface — if a future change adds a
        // 5th case, this test trips so the analytics + UI consumers
        // get reviewed for the change.
        #expect(MasteryBand.allCases.count == 4)
    }

    // MARK: - kitMasteryAdvanced analytics event shape

    @Test func kitMasteryAdvancedEventShape() {
        let event = VoiceTaleAnalyticsEvent.kitMasteryAdvanced(
            kit: 3,
            fromBand: MasteryBand.emerging.rawValue,
            toBand: MasteryBand.developing.rawValue
        )
        #expect(event.name == "kit_mastery_advanced")
        let props = event.properties
        #expect(props.count == 3)
        #expect(props["kit"] == "3")
        #expect(props["from_band"] == "emerging")
        #expect(props["to_band"] == "developing")
    }

    @Test func kitMasteryAdvancedNeverCarriesRawScoreKey() {
        // Defensive — the event surface MUST NOT have a key matching
        // any common score-payload name. Locks the band-only
        // anti-fingerprinting discipline.
        let forbiddenKeys: Set<String> = [
            "score", "mastery_score", "from_score", "to_score",
            "retrievability", "accuracy", "fsrs", "elapsed",
        ]
        let event = VoiceTaleAnalyticsEvent.kitMasteryAdvanced(
            kit: 1,
            fromBand: "emerging",
            toBand: "developing"
        )
        let keys = Set(event.properties.keys)
        #expect(keys.intersection(forbiddenKeys).isEmpty)
    }

    // MARK: - KitMasteryStore round-trip via Phase B path

    @Test func kitMasteryStoreRecordsCorrectAttempt() async throws {
        let container = try VoiceTalePersistence.makeInMemoryContainer()
        let context = ModelContext(container)
        let progress = VoiceTaleStore.fetchOrCreateProgress(in: context)
        let store = KitMasteryStore()
        store.bootstrap(progress: progress)

        let initialState = store.state(for: .hookCraft)
        #expect(initialState.attemptCount == 0)
        #expect(initialState.masteryScore == 0)

        let next = store.record(.correctFirstTry(elapsedSeconds: 4.0), for: .hookCraft)
        #expect(next.attemptCount == 1)
        // First correct attempt advances accuracy substantially.
        // Exact value depends on FSRS state but must be > 0.
        #expect(next.masteryScore > 0)
        // Cached snapshot updated immediately.
        #expect(store.state(for: .hookCraft).attemptCount == 1)
    }

    @Test func kitMasteryStoreRecordsIncorrectAttempt() async throws {
        let container = try VoiceTalePersistence.makeInMemoryContainer()
        let context = ModelContext(container)
        let progress = VoiceTaleStore.fetchOrCreateProgress(in: context)
        let store = KitMasteryStore()
        store.bootstrap(progress: progress)

        let next = store.record(.incorrect(elapsedSeconds: 15.0), for: .sensoryDetail)
        #expect(next.attemptCount == 1)
        // The recent-window includes the incorrect attempt — the
        // recent-accuracy half of the masteryScore floors at 0 for
        // a single incorrect attempt.
        #expect(next.recentOutcomes.count == 1)
        if case .incorrect = next.recentOutcomes.first {
            // matched
        } else {
            Issue.record("Expected `.incorrect` outcome in recentOutcomes; got \(String(describing: next.recentOutcomes.first))")
        }
    }

    @Test func kitMasteryStorePersistsSnapshotAcrossBootstraps() async throws {
        // The Phase A scaffold proved the round-trip survives a fresh
        // store bootstrap against the same progress row. Phase B
        // re-verifies the path is still honored after the QuizView
        // wiring lands (no regression on the Optional `Data?` field).
        let container = try VoiceTalePersistence.makeInMemoryContainer()
        let context = ModelContext(container)
        let progress = VoiceTaleStore.fetchOrCreateProgress(in: context)
        let first = KitMasteryStore()
        first.bootstrap(progress: progress)
        _ = first.record(.correctFirstTry(elapsedSeconds: 3.0), for: .mood)

        // Re-fetch the row (simulating a fresh app launch reading the
        // same SwiftData store) + bootstrap a fresh store.
        let progressAgain = VoiceTaleStore.fetchOrCreateProgress(in: context)
        let second = KitMasteryStore()
        second.bootstrap(progress: progressAgain)
        let restored = second.state(for: .mood)
        #expect(restored.attemptCount == 1)
    }
}
