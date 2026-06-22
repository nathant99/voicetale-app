import SwiftUI
import Models
import SharedUI

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
    public let onSave: () -> Void
    public let onRetell: () -> Void

    public init(
        reflection: VoiceStoryReflection?,
        isThinking: Bool,
        kit: QuestionKit? = nil,
        castVoicingLine: String? = nil,
        castVoicingDisplayName: String? = nil,
        castVoicingSlug: String? = nil,
        onSave: @escaping () -> Void,
        onRetell: @escaping () -> Void
    ) {
        self.reflection = reflection
        self.isThinking = isThinking
        self.kit = kit
        self.castVoicingLine = castVoicingLine
        self.castVoicingDisplayName = castVoicingDisplayName
        self.castVoicingSlug = castVoicingSlug
        self.onSave = onSave
        self.onRetell = onRetell
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            mascotHeader
            if isThinking {
                thinkingState
            } else if let reflection {
                reflectionBody(reflection)
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
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
