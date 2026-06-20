import Testing
import Foundation
@testable import AppFeature
import Models

@Suite("AppRootView scaffold")
struct AppRootViewTests {
    @Test func appTabCasesCoverFourTabs() {
        #expect(AppRootView.AppTab.allCases.count == 4)
    }

    @Test func appTabTitlesAreNonEmpty() {
        for tab in AppRootView.AppTab.allCases {
            #expect(tab.title.isEmpty == false)
            #expect(tab.systemImage.isEmpty == false)
        }
    }
}

@Suite("TellMachine")
struct TellMachineTests {
    @Test func resetReturnsToIdle() {
        var machine = TellMachine()
        machine.enterRecording()
        machine.tick(elapsedSeconds: 10, currentBeat: .setup)
        machine.reset()
        #expect(machine.phase == .idle)
        #expect(machine.elapsedSeconds == 0)
        #expect(machine.transcript.isEmpty)
    }

    @Test func enterRecordingStartsAtHook() {
        var machine = TellMachine()
        machine.enterRecording()
        #expect(machine.phase == .recording)
        #expect(machine.currentBeat == .hook)
    }

    @Test func tickAdvancesBeat() {
        var machine = TellMachine()
        machine.enterRecording()
        machine.tick(elapsedSeconds: 25, currentBeat: .setup)
        #expect(machine.elapsedSeconds == 25)
        #expect(machine.currentBeat == .setup)
    }

    @Test func enterReviewStoresTranscriptAndTimeline() {
        var machine = TellMachine()
        let timeline = [BeatSegment(beat: .hook, targetSeconds: 10, actualSeconds: 10)]
        machine.enterReview(transcript: "hello", timeline: timeline, audioFileURL: URL(fileURLWithPath: "/tmp/x.m4a"))
        #expect(machine.phase == .reviewingTranscript)
        #expect(machine.transcript == "hello")
        #expect(machine.beatTimeline.count == 1)
        #expect(machine.audioFileURL?.lastPathComponent == "x.m4a")
    }

    @Test func presentReflectionMovesToShowingReflection() {
        var machine = TellMachine()
        machine.enterAwaitingReflection()
        let reflection = VoiceStoryReflection(craftObservations: ["heard"], socraticPrompt: "What?")
        machine.presentReflection(reflection)
        #expect(machine.phase == .showingReflection)
        #expect(machine.reflection?.socraticPrompt == "What?")
    }

    @Test func errorPhaseCarriesMessage() {
        var machine = TellMachine()
        machine.markError("oops")
        if case let .error(message) = machine.phase {
            #expect(message == "oops")
        } else {
            Issue.record("Expected .error phase")
        }
    }
}

@Suite("DailyPromptView")
struct DailyPromptTests {
    @Test func promptPoolHasThirtyEntries() {
        #expect(DailyPromptView.prompts.count == 30)
    }

    @Test func todaysPromptIsDeterministicPerDay() {
        let day1 = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let day2 = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 1, day: 2))!
        let first = DailyPromptView.todaysPrompt(now: day1)
        let second = DailyPromptView.todaysPrompt(now: day1)
        let nextDay = DailyPromptView.todaysPrompt(now: day2)
        #expect(first == second)
        #expect(first != nextDay)
    }
}
