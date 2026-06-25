import SwiftUI
import Models
import SharedUI
import ForgeModels
import ForgeUI

/// Presents Bramble's listening-coach reflection — one to two craft
/// observations + one open-ended Socratic prompt. Designed to be the
/// terminal screen of the record → review → reflect flow; callers wire
/// ``onSave`` / ``onRetell`` for the next-step affordances.
///
/// Phase 1 DN-S Move B per
/// `@Docs/HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md`: when callers pass
/// a non-nil ``kit``, the view appends a cast-cameo strip surfacing the kit's
/// four `CastCameo` lines beneath the Socratic prompt.
public struct BrambleReflectionView: View {
    public let reflection: VoiceStoryReflection?
    public let isThinking: Bool
    public let kit: QuestionKit?
    /// Optional live cast-voicing line surfaced beneath Bramble's reflection.
    /// When non-nil, renders a small "Hear from <name>" chip with the line so
    /// the kid hears one cast voice react in-character. Per DN-S Move D
    /// step 3 (HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md). Gated upstream
    /// by `@AppStorage("voicetale.castVoicing.live")` so the surface only
    /// appears when the experimental toggle is on.
    public let castVoicingLine: String?
    public let castVoicingDisplayName: String?
    /// Slug of the cast member being voiced (e.g. `"lean"` / `"pivot"` /
    /// `"refrain"` / `"slow"`). When this resolves to a known
    /// ``CastPortraitCatalog/Slug``, the cast-voicing chip surfaces the
    /// bundled WebP portrait instead of the SF-Symbol fallback. `nil` leaves
    /// the chip in the fallback state (still rendered, just with the icon).
    public let castVoicingSlug: String?
    /// Phase 1.1 voice-variation reflection. Non-nil when the tale spans
    /// ≥ 2 distinct non-narrator voice characters; renders below Bramble's
    /// main reflection in a styled "Voice notes" callout.
    public let voiceVariation: VoiceStoryReflection?
    /// Trauma-informed distress chip. When non-nil, the view surfaces the
    /// crisis-resource list below Bramble's bubble so the kid + a grown-up
    /// have a "refer up" affordance in the moment. Set by ``TellView`` from
    /// ``BrambleMentor.lastDistressAxis``. Per `@.claude/rules/trauma-informed-content.md`
    /// § "refer up" + ADR-016.
    public let crisisResources: [CrisisResource]
    /// Delight & Polish "Mastery moments" — when non-nil, surfaces a
    /// quiet recognition strip below Bramble's bubble (anti-clobber:
    /// distress chip still wins; voice-variation callout still wins;
    /// mastery is the lowest-priority strip per
    /// ``MasteryMoment`` § "priority discipline"). Per
    /// `@Docs/FEATURE_PLAN.md` § Delight & Polish.
    public let masteryMoment: MasteryMoment?
    /// Delight & Polish "Surprise" micro-delight — when non-nil,
    /// surfaces a lighter recognition strip below Bramble's bubble.
    /// Anti-clobber: distress chip suppresses the strip entirely;
    /// ``MasteryMoment`` suppresses the surprise (mastery is the
    /// deeper, rarer signal). The surprise strip sits BELOW the
    /// voice-variation callout but ABOVE the cast-voicing chip. Per
    /// `@Docs/AUDIT_MICRO_DELIGHT_COVERAGE_2026-06-24.md`.
    public let surpriseMoment: SurpriseMoment?
    /// ForgeReflection Phase B — optional kit number plumbed through to
    /// ``VoiceTaleReflectionConfigCatalog/forSocraticPrompt(_:kitNumber:)``
    /// so per-kit retention policy can diverge later. `nil` from the
    /// Phase 1 Tell-flow (no kit context); set by ``TellView`` to
    /// `activeKit?.kit` when a kit cameo is surfaced.
    public let reflectionKitNumber: Int?
    public let onSave: () -> Void
    public let onRetell: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    /// ForgeReflection Phase B — `nil` until ``AppRootView.task`` boots
    /// + injects the shared store via environment. When `nil` (e.g.,
    /// previews + unbootstrapped tests) the "Answer Bramble" affordance
    /// stays hidden, preserving the listening-back register.
    @Environment(\.voiceTaleReflectionStore) private var reflectionStore
    @Environment(\.analyticsService) private var analytics
    /// Drives `.reflectionPrompt(...)` presentation. Reset on dismiss
    /// by the ForgeUI modifier; reset on retell/save by ``TellView`` via
    /// the existing `onRetell` / `onSave` callbacks (no extra plumbing
    /// needed — the sheet's `isPresented` binding lives view-local).
    @State private var isAnsweringBramble: Bool = false

    public init(
        reflection: VoiceStoryReflection?,
        isThinking: Bool,
        kit: QuestionKit? = nil,
        castVoicingLine: String? = nil,
        castVoicingDisplayName: String? = nil,
        castVoicingSlug: String? = nil,
        voiceVariation: VoiceStoryReflection? = nil,
        crisisResources: [CrisisResource] = [],
        masteryMoment: MasteryMoment? = nil,
        surpriseMoment: SurpriseMoment? = nil,
        reflectionKitNumber: Int? = nil,
        onSave: @escaping () -> Void,
        onRetell: @escaping () -> Void
    ) {
        self.reflection = reflection
        self.isThinking = isThinking
        self.kit = kit
        self.castVoicingLine = castVoicingLine
        self.castVoicingDisplayName = castVoicingDisplayName
        self.castVoicingSlug = castVoicingSlug
        self.voiceVariation = voiceVariation
        self.crisisResources = crisisResources
        self.masteryMoment = masteryMoment
        self.surpriseMoment = surpriseMoment
        self.reflectionKitNumber = reflectionKitNumber
        self.onSave = onSave
        self.onRetell = onRetell
    }

    /// True when the "Answer Bramble" surface should render. Per
    /// `@Docs/PLAN_FORGEREFLECTION_LIFT.md` § Phase B: surfaces ONLY when
    /// the reflection carries a non-empty Socratic prompt AND a store is
    /// wired AND the listening-back register isn't being held by a
    /// distress hold-space (anti-clobber per ``distressChip``).
    public var canAnswerBramble: Bool {
        guard reflectionStore != nil else { return false }
        guard crisisResources.isEmpty else { return false }
        guard let prompt = reflection?.socraticPrompt else { return false }
        return !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            mascotHeader
            if isThinking {
                thinkingState
            } else if let reflection {
                reflectionBody(reflection)
                if !crisisResources.isEmpty {
                    distressChip
                }
                if let voiceVariation {
                    voiceVariationCallout(voiceVariation)
                }
                if let masteryMoment, crisisResources.isEmpty {
                    masteryMomentStrip(masteryMoment)
                }
                // Surprise strip — suppressed under distress AND under
                // mastery (mastery wins per priority discipline).
                if let surpriseMoment, crisisResources.isEmpty, masteryMoment == nil {
                    surpriseMomentStrip(surpriseMoment)
                }
                if let line = castVoicingLine, !line.isEmpty {
                    castVoicingChip(
                        line: line,
                        name: castVoicingDisplayName,
                        portraitSlug: CastPortraitCatalog.Slug(slug: castVoicingSlug)
                    )
                }
                if let kit {
                    CastCameoStripView(
                        cameos: kit.castCameos,
                        anchorSlug: kit.anchorCharacterSlug,
                        kitTitle: kit.title
                    )
                }
            } else {
                ContentUnavailableView(
                    "No reflection yet",
                    systemImage: "ear",
                    description: Text("Bramble is here as soon as you finish the tale.")
                )
            }
            Spacer(minLength: 16)
            actionRow
        }
        .padding()
        .reflectionPrompt(
            answerBrambleConfig,
            isPresented: $isAnsweringBramble,
            onComplete: handleBrambleAnswer
        )
    }

    /// ForgeReflection Phase B — config consumed by the `.reflectionPrompt`
    /// modifier. The Socratic prompt routes through
    /// ``VoiceTaleReflectionConfigCatalog/forSocraticPrompt(_:kitNumber:)``;
    /// the catalog enforces the trauma-informed `.skip` precondition + the
    /// V1 omission of `.drawing`. Falls back to a neutral placeholder when
    /// no prompt is present so the precondition (1-2 questions) holds even
    /// during the in-between render frame where the kid taps the button
    /// before `reflection` re-sets.
    private var answerBrambleConfig: ReflectionPromptConfig {
        let prompt = reflection?.socraticPrompt?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return VoiceTaleReflectionConfigCatalog.forSocraticPrompt(
            prompt,
            kitNumber: reflectionKitNumber
        )
    }

    /// Persists the entry via the store + emits a categorical analytics
    /// event. Modality raw value travels (`text` / `voice` / `drawing` /
    /// `emoji` / `skip`); the text payload NEVER travels. `.skip`
    /// entries DO persist so the parent dashboard can show the kid
    /// engaged-then-skipped path, but they carry no `textValue` (the
    /// `.skip` factory enforces this) — anti-shame discipline per
    /// `@.claude/rules/trauma-informed-content.md` § "off-ramp".
    private func handleBrambleAnswer(_ entry: ReflectionEntry) async {
        guard let reflectionStore else { return }
        do {
            try await reflectionStore.save(entry)
        } catch {
            // Per `@.claude/rules/debug-logging.md` § "Replace silent
            // try? with logged catches" — when a categorized DebugLog
            // surface lands in AppFeature, route the failure through
            // it. Phase B preserves the parent's existing degrade-quiet
            // contract; the entry is dropped but the kid sees no error.
        }
        analytics.track(.brambleAnswered(modality: entry.modality.rawValue))
    }

    private var mascotHeader: some View {
        HStack(spacing: 12) {
            MascotPoseView(pose: currentMascotPose, dimension: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("Bramble")
                    .font(.headline)
                Text("Listening coach")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Maps the reflection-view state to a Bramble pose so the mascot's
    /// posture matches what's happening in the flow. `thinking` while
    /// awaiting the reflection; `praising` once a reflection has landed
    /// (Bramble's "I heard something good" register); `encouraging` for the
    /// empty / pre-reflection idle path.
    private var currentMascotPose: MascotPoseCatalog.Pose {
        if isThinking { return .thinking }
        if reflection != nil { return .praising }
        return .encouraging
    }

    @ViewBuilder
    private var thinkingState: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Bramble is listening back…")
                .font(.body.italic())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func reflectionBody(_ reflection: VoiceStoryReflection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(reflection.craftObservations.enumerated()), id: \.offset) { _, observation in
                Text("\u{201C}\(observation)\u{201D}")
                    .font(.title3)
                    .lineSpacing(4)
            }
            if let prompt = reflection.socraticPrompt, !prompt.isEmpty {
                Divider().padding(.vertical, 6)
                VStack(alignment: .leading, spacing: 6) {
                    Text("And — Bramble asks:")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(prompt)
                        .font(.title3.weight(.medium))
                }
            }
        }
        .padding(16)
        .background(bubbleBackground, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(reflectionAccessibilityLabel(reflection)))
    }

    /// Reflection bubble background — material by default; collapses to a
    /// solid secondarySystemBackground when Reduce-Transparency is on so
    /// the WCAG AA contrast holds against the bubble's body text.
    private var bubbleBackground: AnyShapeStyle {
        if reduceTransparency {
            return AnyShapeStyle(Color(uiColor: .secondarySystemBackground))
        }
        return AnyShapeStyle(Material.thin)
    }

    /// Combined VoiceOver label for the reflection bubble — reads the
    /// craft observations + Socratic prompt as a single semantic unit so
    /// VoiceOver users hear the reflection as one thought rather than
    /// per-line fragments.
    private func reflectionAccessibilityLabel(_ reflection: VoiceStoryReflection) -> String {
        var parts: [String] = ["Bramble's reflection."]
        parts.append(contentsOf: reflection.craftObservations)
        if let prompt = reflection.socraticPrompt, !prompt.isEmpty {
            parts.append("Bramble asks: \(prompt)")
        }
        return parts.joined(separator: " ")
    }

    /// Trauma-informed distress chip. Surfaces the crisis-resource list
    /// alongside Bramble's hold-space reflection so the kid + a grown-up
    /// have an immediate refer-up affordance. Per
    /// `@.claude/rules/trauma-informed-content.md` § "refer up" + ADR-016.
    @ViewBuilder
    private var distressChip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "heart.text.square")
                    .foregroundStyle(.tint)
                Text("If this is real, here's where to go")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            CrisisResourceListView(resources: crisisResources)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityLabel(Text("Crisis resources from Bramble"))
    }

    /// Phase 1.1 voice-variation callout. Sits between Bramble's main
    /// reflection and the cast-voicing chip; styled as a quieter sub-card
    /// so it reads as a secondary note rather than a competing reflection.
    @ViewBuilder
    private func voiceVariationCallout(_ reflection: VoiceStoryReflection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.and.person.filled")
                    .foregroundStyle(.tint)
                Text("Voice notes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(reflection.craftObservations.enumerated()), id: \.offset) { _, observation in
                Text(observation)
                    .font(.body)
                    .lineSpacing(3)
            }
            if let prompt = reflection.socraticPrompt, !prompt.isEmpty {
                Text(prompt)
                    .font(.body.italic())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityLabel(Text("Voice notes from Bramble"))
    }

    /// Delight & Polish "Mastery moments" strip. Sits below the voice-
    /// variation callout (when present) and below the distress chip
    /// (which suppresses the strip entirely — distress recognition is
    /// not the moment for craft-mastery celebration). Anti-clobber per
    /// ``MasteryMoment`` § "priority discipline".
    @ViewBuilder
    private func masteryMomentStrip(_ moment: MasteryMoment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: moment.systemImage)
                    .foregroundStyle(.tint)
                Text(moment.headline)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(moment.body)
                .font(.body)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Mastery moment: \(moment.headline) \(moment.body)"))
    }

    /// Delight & Polish "Surprise" micro-delight strip. Mirrors the
    /// ``masteryMomentStrip`` layout but uses a lighter recognition
    /// register. Per `@Docs/AUDIT_MICRO_DELIGHT_COVERAGE_2026-06-24.md`.
    @ViewBuilder
    private func surpriseMomentStrip(_ moment: SurpriseMoment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: moment.systemImage)
                    .foregroundStyle(.tint)
                Text(moment.headline)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(moment.body)
                .font(.body)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Surprise moment: \(moment.headline) \(moment.body)"))
    }

    @ViewBuilder
    private func castVoicingChip(
        line: String,
        name: String?,
        portraitSlug: CastPortraitCatalog.Slug?
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                if let portraitSlug {
                    CastPortraitView(slug: portraitSlug, dimension: 32)
                } else {
                    Image(systemName: "person.wave.2.fill")
                        .foregroundStyle(.tint)
                        .frame(width: 32, height: 32)
                }
                Text(name.map { "Hear from \($0)" } ?? "Hear from one of Bramble's friends")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text("\u{201C}\(line)\u{201D}")
                .font(.body.italic())
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityLabel(name.map { "\($0) says: \(line)" } ?? "Cast member says: \(line)")
    }

    private var actionRow: some View {
        VStack(spacing: 12) {
            if canAnswerBramble {
                answerBrambleButton
            }
            HStack(spacing: 12) {
                Button(action: onRetell) {
                    Label("Tell again", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Discard this take and re-record the tale.")

                Button(action: onSave) {
                    Label("Add to my anthology", systemImage: "bookmark.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Save this tale + transcript to your anthology.")
            }
        }
    }

    /// ForgeReflection Phase B — "Answer Bramble" affordance. Tap presents
    /// the ForgeUI reflection sheet (text / voice / emoji / skip). Wired
    /// only when ``canAnswerBramble`` (non-empty Socratic prompt + store
    /// bootstrapped + no distress hold-space). Per
    /// `@Docs/PLAN_FORGEREFLECTION_LIFT.md` § Phase B + the
    /// listening-back register's "additive, never substitutive" rule.
    private var answerBrambleButton: some View {
        Button {
            isAnsweringBramble = true
        } label: {
            Label("Answer Bramble", systemImage: "bubble.left.and.text.bubble.right.fill")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .accessibilityHint("Type, record, or emoji your answer to Bramble's question. You can skip.")
    }
}

#Preview("Thinking") {
    BrambleReflectionView(
        reflection: nil,
        isThinking: true,
        onSave: {},
        onRetell: {}
    )
}

#Preview("With reflection") {
    BrambleReflectionView(
        reflection: VoiceStoryReflection(
            craftObservations: ["You held the turn long enough for me to feel the cold air change."],
            socraticPrompt: "What did you notice when you slowed down right before it?"
        ),
        isThinking: false,
        onSave: {},
        onRetell: {}
    )
}
