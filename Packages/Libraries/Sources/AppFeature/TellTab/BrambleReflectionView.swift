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
    public let onSave: () -> Void
    public let onRetell: () -> Void

    public init(
        reflection: VoiceStoryReflection?,
        isThinking: Bool,
        kit: QuestionKit? = nil,
        onSave: @escaping () -> Void,
        onRetell: @escaping () -> Void
    ) {
        self.reflection = reflection
        self.isThinking = isThinking
        self.kit = kit
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
            Image(systemName: "leaf.circle.fill")
                .resizable()
                .frame(width: 44, height: 44)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Bramble")
                    .font(.headline)
                Text("Listening coach")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
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
