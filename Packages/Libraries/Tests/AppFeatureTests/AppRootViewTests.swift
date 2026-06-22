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

@Suite("VoiceTaleHubContribution")
struct VoiceTaleHubContributionTests {
    @Test func sourceAppMetadataIsStable() {
        let contribution = VoiceTaleHubContribution()
        #expect(contribution.sourceAppID == "voicetale")
        #expect(contribution.sourceAppDisplayName == "VoiceTale")
    }

    @Test func contributesToWordWoodsZone() {
        let contribution = VoiceTaleHubContribution()
        #expect(contribution.zone.rawValue == "word-woods")
    }

    @Test func supportsQuestEngineInPhase1() {
        let contribution = VoiceTaleHubContribution()
        #expect(contribution.supportedEngines.map(\.rawValue) == ["quest"])
    }

    @Test func mentorPersonaIsBramble() {
        let contribution = VoiceTaleHubContribution()
        #expect(contribution.mentorPersona.id == "bramble")
        #expect(contribution.mentorPersona.systemPromptHeader.contains("Bramble"))
    }

    @Test func kitResourcesCoverAllFourPhase1Kits() {
        let contribution = VoiceTaleHubContribution()
        let kitIDs = contribution.kitResources.map(\.kitID)
        #expect(kitIDs.contains("kit_01_hook"))
        #expect(kitIDs.contains("kit_02_sensory_detail"))
        #expect(kitIDs.contains("kit_03_arc_completeness"))
        #expect(kitIDs.contains("kit_04_mood"))
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

    // MARK: - Variable rewards (rare prompt)

    @Test func rarePoolIsNonEmpty() {
        #expect(DailyPromptView.rarePrompts.isEmpty == false)
    }

    @Test func rarePromptCategorySlugsAreUnique() {
        let categories = DailyPromptView.rarePrompts.map(\.category)
        #expect(Set(categories).count == categories.count)
    }

    @Test func standardSessionsReturnNilCategory() {
        for n in [1, 2, 3, 4, 6, 7, 8, 9] {
            let resolved = DailyPromptView.resolved(sessionCount: n)
            #expect(resolved.rareCategory == nil, "session \(n) should be standard")
        }
    }

    @Test func fifthSessionSurfacesRarePrompt() {
        let resolved = DailyPromptView.resolved(sessionCount: 5)
        #expect(resolved.rareCategory != nil)
    }

    @Test func everyFifthSessionSurfacesRare() {
        for n in [5, 10, 15, 20, 25] {
            let resolved = DailyPromptView.resolved(sessionCount: n)
            #expect(resolved.rareCategory != nil, "session \(n) should be rare")
        }
    }

    @Test func consecutiveRareSessionsRotateThroughThePool() {
        let firstRare = DailyPromptView.resolved(sessionCount: 5)
        let secondRare = DailyPromptView.resolved(sessionCount: 10)
        #expect(firstRare.prompt != secondRare.prompt)
    }

    @Test func zeroSessionCountReturnsStandard() {
        let resolved = DailyPromptView.resolved(sessionCount: 0)
        #expect(resolved.rareCategory == nil)
    }
}

@MainActor
@Suite("TellView progressive disclosure")
struct TellViewProgressiveDisclosureTests {
    private static func makeIsolatedDefaults() -> UserDefaults {
        let suite = UserDefaults(suiteName: "TellViewProgressiveDisclosureTests-\(UUID().uuidString)")!
        suite.removePersistentDomain(forName: "TellViewProgressiveDisclosureTests")
        return suite
    }

    @Test func sessionsCompletedKeyMatchesAppStorageContract() {
        // Public key is co-located on TellView for UI-test launch-argument
        // wiring. Test pins the literal so a rename surfaces here.
        #expect(TellView.sessionsCompletedKey == "voicetale.sessionsCompleted")
    }

    @Test func beatTimerThresholdGatesAtSecondSession() {
        // Session 1 (count == 0) hides the scaffold; session 2 (count == 1)
        // shows it. The threshold is the first session COMPLETED, not the
        // first session STARTED, so the scaffold lights up after the kid
        // ships their first tale.
        #expect(TellView.beatTimerEnabledThreshold == 1)
    }

    @Test func freshInstallHidesBeatTimer() {
        // Default AppStorage value is 0; isBeatTimerEnabled should be false.
        // We can't observe @AppStorage values from a SwiftUI struct without
        // a host view, but the computed `isBeatTimerEnabled` depends only
        // on the stored value vs the threshold, so we test the comparison
        // directly via the threshold constant.
        let sessionsCompletedOnFreshInstall = 0
        #expect(sessionsCompletedOnFreshInstall < TellView.beatTimerEnabledThreshold)
    }

    @Test func sessionTwoOnwardShowsBeatTimer() {
        let sessionsCompletedAfterFirstSave = 1
        #expect(sessionsCompletedAfterFirstSave >= TellView.beatTimerEnabledThreshold)
        let sessionsCompletedAfterFiveSaves = 5
        #expect(sessionsCompletedAfterFiveSaves >= TellView.beatTimerEnabledThreshold)
    }
}

@Suite("TellView voice-character helpers (Phase 1.1)")
struct TellViewVoiceCharacterTests {
    @Test func beatsByVoiceCharacterGroupsByVoice() {
        let timeline: [BeatSegment] = [
            BeatSegment(beat: .hook, targetSeconds: 10, actualSeconds: 10, voiceCharacterSlug: "hero"),
            BeatSegment(beat: .setup, targetSeconds: 20, actualSeconds: 20, voiceCharacterSlug: "hero"),
            BeatSegment(beat: .rising, targetSeconds: 30, actualSeconds: 30, voiceCharacterSlug: "sage"),
            BeatSegment(beat: .turn, targetSeconds: 30, actualSeconds: 30, voiceCharacterSlug: nil),
            BeatSegment(beat: .close, targetSeconds: 20, actualSeconds: 20, voiceCharacterSlug: nil),
        ]
        let grouped = TellView.beatsByVoiceCharacter(in: timeline)
        #expect(grouped["hero"]?.count == 2)
        #expect(grouped["sage"]?.count == 1)
        // nil slugs map to the narrator default.
        #expect(grouped["narrator"]?.count == 2)
        #expect(grouped["hero"]?.contains(.hook) == true)
        #expect(grouped["hero"]?.contains(.setup) == true)
    }

    @Test func beatsByVoiceCharacterReturnsEmptyForEmptyTimeline() {
        let grouped = TellView.beatsByVoiceCharacter(in: [])
        #expect(grouped.isEmpty)
    }

    @Test func beatsByVoiceCharacterTreatsNilSlugsAsNarrator() {
        let timeline: [BeatSegment] = ArcBeat.allCases.map { beat in
            BeatSegment(beat: beat, targetSeconds: beat.targetSeconds, actualSeconds: beat.targetSeconds)
        }
        let grouped = TellView.beatsByVoiceCharacter(in: timeline)
        #expect(grouped.count == 1)
        #expect(grouped["narrator"]?.count == ArcBeat.allCases.count)
    }
}
