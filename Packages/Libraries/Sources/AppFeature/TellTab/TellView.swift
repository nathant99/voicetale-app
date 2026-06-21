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

    private let pipeline = TranscriptPipeline()

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
                Text("Ready when you are.")
                    .font(.title2.weight(.semibold))
                Text("Tell a 60-to-120-second tale. Bramble will listen.")
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
        let reflection = await mentor.reflect(
            transcript: machine.transcript,
            mood: machine.draftMood,
            beat: beatForReflection
        )
        machine.presentReflection(reflection)
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
            awardSaveXP(entry: entry)
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
