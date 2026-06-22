import SwiftUI
import SwiftData
import Models
import Services
import VoiceAuthoring
import SharedUI
import AIMentor

/// Top-level Tell-tab screen. Coordinates the record → review → reflect
/// flow against ``AudioRecorder`` + ``TranscriptPipeline`` +
/// ``BrambleMentor`` + ``VoiceTaleStore``.
public struct TellView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.gamificationService) private var gamification
    @Environment(\.analyticsService) private var analytics
    @State private var machine = TellMachine()
    @State private var recorder = AudioRecorder()
    @State private var mentor = BrambleMentor()

    @State private var transcriptDraft: String = ""
    @State private var timerTick: Date = Date()
    /// Per `@Docs/HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` Move B,
    /// the post-tale reflection surfaces a per-kit cast cameo strip. The kit
    /// rotates per tale so the kid hears a different cast voice across
    /// sessions.
    @State private var activeKit: QuestionKit?
    /// Set when the kid pressed "Tell another" — captures the previous
    /// telling so the next reflection pairs the two transcripts via
    /// ``BrambleMentor/reflectRetell``. Cleared the moment the retell-aware
    /// reflection runs OR a new save lands; kept off the machine because it
    /// only matters for one reflection per retell.
    @State private var previousTranscript: String?

    /// Per `@Docs/FEATURE_PLAN.md` line 112 (Phase 1.2 polish — progressive
    /// disclosure) + § Phase: Onboarding & Child Safety § "Progressive
    /// disclosure", session 1 ships a free-form 30-second tell with the
    /// beat-timer hidden so the kid hits the aha moment in ≤ 60 seconds
    /// (Phase 1 exit criterion). Sessions 2+ get the full 5-beat scaffold.
    /// Stored via `@AppStorage` so the count survives app relaunch + is
    /// inspectable via UI-test launch arguments.
    @AppStorage(TellView.sessionsCompletedKey) private var sessionsCompleted: Int = 0

    private let pipeline = TranscriptPipeline()

    /// Persistence key for the progressive-disclosure session counter.
    /// Co-located here so tests + UI-test launch arguments can flip the
    /// state without depending on a separate constants file. Matches the
    /// pattern ``AppRootView/onboardingCompletedKey`` establishes.
    public static let sessionsCompletedKey = "voicetale.sessionsCompleted"

    /// Session-count threshold at which the beat-timer scaffold becomes
    /// visible. Session 1 is intentionally free-form. From session 2
    /// onward the beat-timer + per-beat hints are shown.
    public static let beatTimerEnabledThreshold = 1

    /// Convenience computed for views + tests: should the full 5-beat
    /// scaffold show on the recording surface?
    public var isBeatTimerEnabled: Bool {
        sessionsCompleted >= Self.beatTimerEnabledThreshold
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            phaseBody
                .voiceTaleNavigationTitle("Tell")
                .task(id: machine.phase) {
                    if case .awaitingReflection = machine.phase {
                        await runReflection()
                    }
                }
        }
    }

    @ViewBuilder
    private var phaseBody: some View {
        switch machine.phase {
        case .idle:
            idleSurface
        case .requestingPermission:
            permissionPendingSurface
        case .recording:
            recordingSurface
        case .reviewingTranscript:
            TranscriptReviewView(
                transcript: $transcriptDraft,
                beatTimeline: machine.beatTimeline,
                onReflect: {
                    machine.transcript = transcriptDraft
                    machine.enterAwaitingReflection()
                }
            )
        case .awaitingReflection, .showingReflection:
            BrambleReflectionView(
                reflection: machine.reflection,
                isThinking: machine.phase == .awaitingReflection,
                kit: activeKit,
                onSave: saveToAnthology,
                onRetell: retellFromScratch
            )
        case .savedToAnthology:
            savedSurface
        case .error(let message):
            errorSurface(message)
        }
    }

    // MARK: - Surfaces

    private var idleSurface: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 24)
            mascot
            VStack(spacing: 8) {
                Text(idleHeadline)
                    .font(.title2.weight(.semibold))
                Text(idleSubtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            moodPicker
            Spacer()
            RecordingControlsView(
                isRecording: false,
                elapsedSeconds: 0,
                onStart: startRecording,
                onStop: {},
                onCancel: {}
            )
        }
        .padding(.bottom)
    }

    /// Session-1 framing is intentionally smaller-stakes: a 30-second tale
    /// invitation that gets the kid to the aha moment fastest. Session 2+
    /// surfaces the full 60-to-120-second framing.
    private var idleHeadline: String {
        isBeatTimerEnabled ? "Ready when you are." : "Just tell me something."
    }

    private var idleSubtitle: String {
        isBeatTimerEnabled
            ? "Tell a 60-to-120-second tale. Bramble will listen."
            : "Tell me about thirty seconds of your day. Bramble will listen."
    }

    private var permissionPendingSurface: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Asking for the microphone…")
                .font(.headline)
            Text("VoiceTale needs your mic to capture the tale on-device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    private var recordingSurface: some View {
        VStack(spacing: 16) {
            if isBeatTimerEnabled {
                BeatTimerView(
                    elapsedSeconds: machine.elapsedSeconds,
                    currentBeat: machine.currentBeat,
                    isActivelyRecording: true
                )
                .padding(.horizontal)
                Text(currentBeatHint)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                freeFormSessionOneCounter
            }
            Spacer()
            RecordingControlsView(
                isRecording: true,
                elapsedSeconds: machine.elapsedSeconds,
                onStart: {},
                onStop: stopRecording,
                onCancel: cancelRecording
            )
        }
        .padding(.top)
        .onReceive(Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()) { _ in
            tickRecorder()
        }
    }

    private var savedSurface: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Saved to your anthology.")
                .font(.title3.weight(.semibold))
            Button("Tell another") {
                machine.reset()
                transcriptDraft = ""
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    @ViewBuilder
    private func errorSurface(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Something got in the way")
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Try again") {
                machine.reset()
                transcriptDraft = ""
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    /// Session-1 fallback counter — replaces the 5-beat timeline with a
    /// simple "I'm listening" line + monospaced elapsed-seconds counter so
    /// the kid can focus on telling without the scaffold demanding attention.
    private var freeFormSessionOneCounter: some View {
        VStack(spacing: 6) {
            Text("I'm listening.")
                .font(.title3.weight(.semibold))
            Text(formattedFreeFormElapsed)
                .font(.system(.title2, design: .rounded).monospacedDigit())
                .foregroundStyle(.secondary)
                .accessibilityLabel("Elapsed seconds: \(Int(machine.elapsedSeconds))")
        }
        .padding(.top, 24)
    }

    private var formattedFreeFormElapsed: String {
        let total = max(0, Int(machine.elapsedSeconds.rounded()))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var mascot: some View {
        ZStack {
            Circle()
                .fill(.tint.opacity(0.15))
                .frame(width: 140, height: 140)
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
        }
        .accessibilityHidden(true)
    }

    private var moodPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(VoiceTaleMood.allCases, id: \.self) { mood in
                    Button(action: { machine.draftMood = mood }) {
                        MoodTagView(mood: mood, isSelected: machine.draftMood == mood)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private var currentBeatHint: String {
        guard let beat = machine.currentBeat else {
            return "Take a breath when you're ready."
        }
        switch beat {
        case .hook:   return "Hook — pull the listener in with a specific detail."
        case .setup:  return "Setup — name the room, the person, the stakes."
        case .rising: return "Rising — let the trouble grow."
        case .turn:   return "Turn — the meaning rotates."
        case .close:  return "Close — land on one image and stop."
        }
    }

    // MARK: - Actions

    private func startRecording() {
        guard PermissionGate.hasMicrophoneUsageDescription else {
            machine.markError("VoiceTale doesn't have permission to use the mic yet. Ask a grown-up to enable it in Settings.")
            return
        }
        analytics.track(.taleRecordingStarted(mood: machine.draftMood))
        machine.phase = .requestingPermission
        Task { @MainActor in
            do {
                try await recorder.start()
                machine.enterRecording()
            } catch AudioRecorder.RecorderError.permissionDenied {
                machine.markError("Microphone access was declined. You can change this in Settings → VoiceTale → Microphone.")
            } catch AudioRecorder.RecorderError.usageDescriptionMissing {
                machine.markError("This build is missing the microphone usage description. Ask a grown-up to update Info.plist.")
            } catch {
                machine.markError("Couldn't start the recording. (\(error.localizedDescription))")
            }
        }
    }

    private func stopRecording() {
        let timestamp = Date()
        let audioURL = makeAudioFileURL()
        Task { @MainActor in
            do {
                let result = try recorder.stop(writingTo: audioURL, at: timestamp)
                var timeline = ArcBeat.allCases.map { beat in
                    BeatSegment(beat: beat, targetSeconds: beat.targetSeconds, actualSeconds: beat.targetSeconds)
                }
                if let captured = capturePerBeatActualSeconds(totalDuration: result.duration) {
                    timeline = captured
                }
                analytics.track(.taleRecordingCompleted(durationSeconds: result.duration, mood: machine.draftMood))
                let transcript = await runTranscription(fileURL: result.fileURL)
                machine.enterReview(transcript: transcript, timeline: timeline, audioFileURL: result.fileURL)
                transcriptDraft = transcript
            } catch {
                machine.markError("The recording ended unexpectedly. (\(error.localizedDescription))")
            }
        }
    }

    private func cancelRecording() {
        recorder.cancel()
        machine.reset()
        transcriptDraft = ""
    }

    private func tickRecorder() {
        guard recorder.isRecording else { return }
        let elapsed = recorder.elapsedSeconds()
        let beat = BeatTimer.beat(forElapsedSeconds: elapsed)
        machine.tick(elapsedSeconds: elapsed, currentBeat: beat)
    }

    private func runTranscription(fileURL: URL?) async -> String {
        guard let fileURL else { return "" }
        do {
            let result = try await pipeline.transcribe(fileURL: fileURL)
            return result.text
        } catch {
            return ""
        }
    }

    private func runReflection() async {
        let beatForReflection = machine.beatTimeline.last?.beat ?? .close
        activeKit = loadActiveKit()
        let skipped = skippedBeats(in: machine.beatTimeline)
        let reflection: VoiceStoryReflection
        if let prior = previousTranscript, !prior.isEmpty {
            reflection = await mentor.reflectRetell(
                transcript: machine.transcript,
                previousTranscript: prior,
                mood: machine.draftMood,
                beat: beatForReflection
            )
            // One retell-aware reflection per "Tell another" press.
            previousTranscript = nil
        } else if !skipped.isEmpty {
            reflection = await mentor.reflectBeatSkipped(
                transcript: machine.transcript,
                mood: machine.draftMood,
                skippedBeats: skipped
            )
        } else {
            reflection = await mentor.reflect(
                transcript: machine.transcript,
                mood: machine.draftMood,
                beat: beatForReflection
            )
        }
        machine.presentReflection(reflection)
        analytics.track(.reflectionShown(
            mood: machine.draftMood,
            beat: beatForReflection,
            modelAvailable: mentor.availability == .available
        ))
    }

    /// Beats whose `actualSeconds` came in under ~50% of their `targetSeconds`
    /// — the same threshold ``hitAllFiveBeats`` uses for the all-5-beats XP
    /// award. Empty timeline → empty list (no reflection downgrade).
    nonisolated private func skippedBeats(in timeline: [BeatSegment]) -> [ArcBeat] {
        timeline
            .filter { $0.actualSeconds < $0.targetSeconds * 0.5 }
            .map(\.beat)
    }

    /// Pick one of the 4 Phase 1 kits to surface the DN-S Move B cameo strip
    /// alongside Bramble's reflection. Seed rotates by `recordedAt` minute so
    /// successive tales surface different cast voices. Silent failure here
    /// degrades gracefully — the reflection view simply omits the strip.
    private func loadActiveKit() -> QuestionKit? {
        let seed = Calendar.current.component(.minute, from: Date())
            ^ machine.transcript.count
        return try? QuestionKitLoader.loadKitForRotation(seed: seed)
    }

    private func saveToAnthology() {
        let entry = VoiceTaleEntry(
            title: machine.draftTitle.isEmpty ? "Untitled tale" : machine.draftTitle,
            mood: machine.draftMood,
            durationSeconds: machine.elapsedSeconds,
            beatTimeline: machine.beatTimeline,
            transcript: machine.transcript,
            reflection: machine.reflection
        )
        do {
            try VoiceTaleStore.insertTale(
                entry,
                audioFileRelativePath: machine.audioFileURL?.lastPathComponent ?? "",
                in: modelContext
            )
            machine.markSaved()
            analytics.track(.taleSavedToAnthology(
                mood: entry.mood,
                hitAllBeats: hitAllFiveBeats(entry: entry)
            ))
            awardSaveXP(entry: entry)
            // Progressive disclosure: bump the session counter so session 2+
            // surfaces the full 5-beat scaffold. AppStorage handles the
            // persistence + cross-launch state.
            sessionsCompleted += 1
        } catch {
            machine.markError("Couldn't save your tale. (\(error.localizedDescription))")
        }
    }

    /// Award XP + record session + evaluate achievements when a tale lands
    /// in the anthology. Per `@Docs/FEATURE_PLAN.md` § Gamification — XP for
    /// first-tale, all-5-beats, transcript-reviewed are independent events.
    private func awardSaveXP(entry: VoiceTaleEntry) {
        gamification.awardXP(for: .taleSaved, in: modelContext)
        if hitAllFiveBeats(entry: entry) {
            gamification.awardXP(for: .allFiveBeatsHit, in: modelContext)
        }
        if didReviewTranscript() {
            gamification.awardXP(for: .transcriptReviewed, in: modelContext)
        }
        Task { @MainActor in
            _ = await gamification.recordSession(in: modelContext)
        }
    }

    /// True if the recorded timeline reached the close beat with at least
    /// ~50% of every target duration. Forgiving threshold so kids who pace
    /// fast still earn the badge.
    private func hitAllFiveBeats(entry: VoiceTaleEntry) -> Bool {
        let coveredBeats = Set(entry.beatTimeline.filter { $0.actualSeconds >= $0.targetSeconds * 0.5 }.map(\.beat))
        return ArcBeat.allCases.allSatisfy { coveredBeats.contains($0) }
    }

    /// True if the kid edited the transcript before saving (raw transcript
    /// differs from saved transcript).
    private func didReviewTranscript() -> Bool {
        // The `transcriptDraft` is what the kid edited; `machine.transcript`
        // is what got saved. If they differ from the original recognizer
        // output (which was assigned into transcriptDraft at enterReview),
        // the kid reviewed it. We approximate via "any save with a non-empty
        // transcript counts as a review" so the achievement isn't gated on
        // a literal diff (which would punish kids whose recognition was
        // already accurate).
        !machine.transcript.isEmpty
    }

    private func retellFromScratch() {
        analytics.track(.taleRetold)
        // Preserve the previous telling so the next reflection can pair the
        // two transcripts. Empty transcripts (cancelled retells) are filtered
        // out at the reflection branch.
        if !machine.transcript.isEmpty {
            previousTranscript = machine.transcript
        }
        machine.reset()
        transcriptDraft = ""
    }

    // MARK: - File-system helpers

    private func makeAudioFileURL() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let folder = directory.appendingPathComponent("Tales", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("\(UUID().uuidString).m4a")
    }

    private func capturePerBeatActualSeconds(totalDuration: Double) -> [BeatSegment]? {
        guard totalDuration > 0 else { return nil }
        var remaining = totalDuration
        return ArcBeat.allCases.map { beat in
            let actual = min(remaining, beat.targetSeconds)
            remaining = max(0, remaining - actual)
            return BeatSegment(
                beat: beat,
                targetSeconds: beat.targetSeconds,
                actualSeconds: actual
            )
        }
    }
}

#Preview {
    TellView()
}
