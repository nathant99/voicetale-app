import SwiftUI
import SwiftData
import Models
import Services
import VoiceAuthoring
import SharedUI
import AIMentor
import ForgeCelebration

/// Top-level Tell-tab screen. Coordinates the record → review → reflect
/// flow against ``AudioRecorder`` + ``TranscriptPipeline`` +
/// ``BrambleMentor`` + ``VoiceTaleStore``.
public struct TellView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.gamificationService) private var gamification
    @Environment(\.analyticsService) private var analytics
    @Environment(\.celebrationCoordinator) private var celebration
    @Environment(\.sessionTally) private var sessionTally
    @State private var machine = TellMachine()
    @State private var recorder = AudioRecorder()
    @State private var mentor = BrambleMentor()
    /// Phase 1.1 voice-character preview. Drives a single
    /// ``AVAudioEngine``+``AVAudioUnitTimePitch`` graph so the kid can
    /// audition picked presets per beat row in the TranscriptReviewView.
    @State private var voicePlayback = VoiceCharacterPlayback()
    /// Beat whose voice preset is currently auditioning, or `nil` when no
    /// preview is in flight. Plumbed to ``TranscriptReviewView`` so the
    /// row's play/stop affordance can flip without observing the engine
    /// state directly.
    @State private var activePreviewBeat: ArcBeat?

    @State private var transcriptDraft: String = ""
    @State private var timerTick: Date = Date()
    /// Per `@Docs/HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` Move B,
    /// the post-tale reflection surfaces a per-kit cast cameo strip. The kit
    /// rotates per tale so the kid hears a different cast voice across
    /// sessions.
    @State private var activeKit: QuestionKit?
    /// DN-S Move D step 3 live wire-up — a single per-tale cast-voiced line
    /// surfaces below Bramble's reflection when the experimental toggle is on.
    /// Cleared on retell/save/cancel so each tale gets a fresh voicing pass.
    @State private var castVoicing = CastVoicingService(isLiveVoicingEnabled: false)
    @State private var castVoicingLine: String?
    @State private var castVoicingDisplayName: String?
    /// Raw slug of the cast member surfaced in the voicing chip (e.g. `"lean"`).
    /// Plumbed to ``BrambleReflectionView`` so the chip can render the bundled
    /// `CastPortraitCatalog` WebP portrait. `nil` while no voicing line is
    /// active OR when the slug doesn't resolve.
    @State private var castVoicingSlug: String?
    /// Phase 1.1 voice-variation reflection — populated by ``runReflection``
    /// when the tale spans ≥ 2 distinct non-narrator voice characters.
    /// Cleared on retell / cancel / save so each tale gets a fresh
    /// voice-variation pass.
    @State private var voiceVariationReflection: VoiceStoryReflection?
    /// Trauma-informed crisis-resource list. Populated when
    /// ``BrambleMentor.lastDistressAxis`` is non-nil — the chip surfaces
    /// below Bramble's bubble alongside the hold-space reflection.
    /// Cleared on retell / cancel / save. Per
    /// `@.claude/rules/trauma-informed-content.md` § "refer up" + ADR-016.
    @State private var distressCrisisResources: [CrisisResource] = []
    /// Experimental feature flag. `@AppStorage` is the source of truth so the
    /// SettingsView toggle and the TellView reading both observe the same key
    /// without an actor-bridging environment value. Default false per the DN-S
    /// portfolio rollout (TestFlight opt-in only).
    @AppStorage(TellView.castVoicingLiveEnabledKey) private var castVoicingLiveEnabled: Bool = false
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

    /// Persistence key for the DN-S cast-voicing experimental toggle.
    /// Surfaced as a Toggle in ``SettingsView``; default false.
    public static let castVoicingLiveEnabledKey = "voicetale.castVoicing.live"

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
                .task {
                    recalibrateBrambleTier()
                }
        }
    }

    /// Phase 2 DDA — fold the kid's saved-tale count into Bramble's
    /// reflection tier on every Tell-tab appearance. Pure-function tier
    /// resolution; setTier no-ops when the tier hasn't changed (per
    /// ``BrambleMentor/setTier(_:)``). The instruction-body swap is
    /// invisible to the kid — only Bramble's voice shifts (gentler for
    /// new tellers, deeper for veteran ones).
    private func recalibrateBrambleTier() {
        let count = VoiceTaleStore.fetchTales(in: modelContext).count
        let tier = DifficultyController.tier(forTalesCount: count)
        let bramblePromptTier = BramblePromptBuilder.DifficultyTier(rawValue: tier.rawValue) ?? .standard
        mentor.setTier(bramblePromptTier)
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
                beatTimeline: $machine.beatTimeline,
                onReflect: {
                    machine.transcript = transcriptDraft
                    stopVoicePreview()
                    machine.enterAwaitingReflection()
                },
                onPreview: previewVoiceCharacter(for:),
                onPreviewStop: stopVoicePreview,
                activePreviewBeat: activePreviewBeat
            )
        case .awaitingReflection, .showingReflection:
            BrambleReflectionView(
                reflection: machine.reflection,
                isThinking: machine.phase == .awaitingReflection,
                kit: activeKit,
                castVoicingLine: castVoicingLine,
                castVoicingDisplayName: castVoicingDisplayName,
                castVoicingSlug: castVoicingSlug,
                voiceVariation: voiceVariationReflection,
                crisisResources: distressCrisisResources,
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
        HapticsBridge.fireRecordStart()
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
        stopVoicePreview()
        machine.reset()
        transcriptDraft = ""
        clearCastVoicing()
    }

    /// Audition the current voice-character pick for the given beat by
    /// playing the entire recorded tale through the preset's pitch + rate
    /// shift. Scope per `@Docs/FEATURE_PLAN.md` § Phase 1.1: whole-tale
    /// single-preset preview; per-beat chunked playback ships in Phase 1.2.
    /// Silently no-ops when the audio file URL isn't known yet (e.g.,
    /// stale state right after `stopRecording`).
    private func previewVoiceCharacter(for segment: BeatSegment) {
        guard let url = machine.audioFileURL else { return }
        let preset = segment.voiceCharacterPreset
        voicePlayback.preview(fileURL: url, preset: preset)
        activePreviewBeat = segment.beat
    }

    private func stopVoicePreview() {
        guard activePreviewBeat != nil else {
            voicePlayback.stop()
            return
        }
        voicePlayback.stop()
        activePreviewBeat = nil
    }

    private func clearCastVoicing() {
        castVoicingLine = nil
        castVoicingDisplayName = nil
        castVoicingSlug = nil
        voiceVariationReflection = nil
        distressCrisisResources = []
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
        // Trauma-informed gate: if Bramble's mentor surfaced a distress
        // axis on this reflection, populate the crisis-resource list so
        // BrambleReflectionView renders the refer-up chip alongside.
        // Voice-variation + cast voicing are SUPPRESSED when distress is
        // present — the hold-space register comes first, and surfacing
        // a "voice notes" sub-card on top of a hold-space reflection
        // would feel jarring.
        if mentor.lastDistressAxis != nil {
            distressCrisisResources = loadCrisisResources()
            voiceVariationReflection = nil
            clearCastVoicing()
        } else {
            distressCrisisResources = []
        }
        analytics.track(.reflectionShown(
            mood: machine.draftMood,
            beat: beatForReflection,
            modelAvailable: mentor.availability == .available
        ))
        guard mentor.lastDistressAxis == nil else { return }
        await runVoiceVariationReflectionIfNeeded()
        await runCastVoicingIfEnabled()
    }

    /// Load the crisis-resource list from the tradition catalog so the
    /// trauma-informed chip surfaces the canonical resource set (988 /
    /// Crisis Text Line / Childhelp / Trevor Project). Falls back to an
    /// empty list if the catalog is unavailable — the chip simply doesn't
    /// render.
    private func loadCrisisResources() -> [CrisisResource] {
        let catalog = try? TraditionCatalogLoader.loadBundled()
        return catalog?.crisisResources?.us ?? []
    }

    /// Phase 1.1 voice-variation reflection — runs after the main reflection
    /// when the saved beat timeline spans ≥ 2 distinct non-narrator voice
    /// characters. The reflection notices what the shift did for the
    /// listener; never grades the kid's own voice. Skipped silently when
    /// the timeline is single-voice OR the fallback yields nil.
    private func runVoiceVariationReflectionIfNeeded() async {
        let beatsByVoice = Self.beatsByVoiceCharacter(in: machine.beatTimeline)
        let nonNarrator = beatsByVoice.filter { slug, _ in
            slug != VoiceCharacterPreset.narrator.rawValue
        }
        guard nonNarrator.keys.count >= 2 else {
            voiceVariationReflection = nil
            return
        }
        let reflection = await mentor.reflectVoiceVariation(
            transcript: machine.transcript,
            mood: machine.draftMood,
            beatsByVoice: beatsByVoice
        )
        voiceVariationReflection = reflection
    }

    /// Build `[slug: [beats]]` from a beat timeline. Beats without a slug
    /// map to `.narrator`. Public on the type so unit tests can pin the
    /// helper without bridging through ``TellView``.
    nonisolated static func beatsByVoiceCharacter(in timeline: [BeatSegment]) -> [String: [ArcBeat]] {
        var result: [String: [ArcBeat]] = [:]
        for segment in timeline {
            let slug = segment.voiceCharacterSlug ?? VoiceCharacterPreset.narrator.rawValue
            result[slug, default: []].append(segment.beat)
        }
        return result
    }

    /// DN-S Move D step 3 — fetch a single in-character cast utterance and
    /// surface it on ``BrambleReflectionView``. Skipped (clears any prior
    /// line) when the experimental toggle is off OR the reflection has no
    /// observations to riff on. Failures fall through silently — the chip
    /// just doesn't appear.
    private func runCastVoicingIfEnabled() async {
        guard castVoicingLiveEnabled,
              let observation = machine.reflection?.craftObservations.first,
              !observation.isEmpty else {
            clearCastVoicing()
            return
        }
        await castVoicing.setLiveVoicingEnabled(true)
        let slug = CastVoicingService.slugForMood(machine.draftMood)
        let kitNumber = activeKit?.kit ?? 1
        let line = await castVoicing.respond(
            as: slug,
            trigger: .scaffold,
            kitNumber: kitNumber,
            topic: observation
        )
        guard !line.isEmpty, line != "…" else { return }
        castVoicingLine = line
        castVoicingDisplayName = slug.displayName
        castVoicingSlug = slug.rawValue
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
            stopVoicePreview()
            HapticsBridge.fireTaleSaved()
            sessionTally.recordTaleSaved()
            analytics.track(.taleSavedToAnthology(
                mood: entry.mood,
                hitAllBeats: hitAllFiveBeats(entry: entry)
            ))
            awardSaveXP(entry: entry)
            // Progressive disclosure: bump the session counter so session 2+
            // surfaces the full 5-beat scaffold. AppStorage handles the
            // persistence + cross-launch state.
            sessionsCompleted += 1
            clearCastVoicing()
        } catch {
            machine.markError("Couldn't save your tale. (\(error.localizedDescription))")
        }
    }

    /// Award XP + record session + evaluate achievements when a tale lands
    /// in the anthology. Per `@Docs/FEATURE_PLAN.md` § Gamification — XP for
    /// first-tale, all-5-beats, transcript-reviewed are independent events.
    private func awardSaveXP(entry: VoiceTaleEntry) {
        let saveOutcome = gamification.awardXP(for: .taleSaved, in: modelContext)
        fireCelebrationsIfAny(outcome: saveOutcome)
        if hitAllFiveBeats(entry: entry) {
            let beatsOutcome = gamification.awardXP(for: .allFiveBeatsHit, in: modelContext)
            fireCelebrationsIfAny(outcome: beatsOutcome)
        }
        if didReviewTranscript() {
            let reviewOutcome = gamification.awardXP(for: .transcriptReviewed, in: modelContext)
            fireCelebrationsIfAny(outcome: reviewOutcome)
        }
        Task { @MainActor in
            _ = await gamification.recordSession(in: modelContext)
        }
    }

    /// Fire a level-up + per-badge celebration when the XP award crossed
    /// either threshold. Level-up takes precedence (the coordinator collapses
    /// lower-tier events while a higher-tier one is active per
    /// ``CelebrationCoordinator.celebrate(_:message:emoji:slug:)``).
    private func fireCelebrationsIfAny(outcome: XPAwardOutcome) {
        if outcome.leveledUp {
            celebration.levelUp(newLevel: outcome.newLevel)
            HapticsBridge.fireLevelUp()
        }
        for badge in outcome.newBadges {
            celebration.badgeEarned(title: badge.title)
            sessionTally.recordBadgeEarned(title: badge.title)
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
        stopVoicePreview()
        machine.reset()
        transcriptDraft = ""
        clearCastVoicing()
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
