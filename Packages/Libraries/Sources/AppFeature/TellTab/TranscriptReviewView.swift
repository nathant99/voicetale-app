import SwiftUI
import Models

/// Per-beat transcript review surface. The kid edits each chunk before
/// Bramble reflects on the tale — the transcript pipeline is on-device but
/// imperfect, and the review step keeps the kid in control of what gets
/// "remembered".
public struct TranscriptReviewView: View {
    @Binding public var transcript: String
    public let beatTimeline: [BeatSegment]
    public let onReflect: () -> Void

    public init(
        transcript: Binding<String>,
        beatTimeline: [BeatSegment],
        onReflect: @escaping () -> Void
    ) {
        self._transcript = transcript
        self.beatTimeline = beatTimeline
        self.onReflect = onReflect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    transcriptEditor
                    timelineSummary
                }
                .padding(.horizontal)
            }
            reflectButton
        }
        .padding(.top)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Listen back, then edit")
                .font(.title3.weight(.semibold))
            Text("On-device transcription is a starting point. Fix anything you want before Bramble listens back with you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private var transcriptEditor: some View {
        TextEditor(text: $transcript)
            .frame(minHeight: 200)
            .padding(8)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.2))
            )
            .accessibilityHint("Edit your tale's transcript. The audio file itself is unchanged.")
    }

    @ViewBuilder
    private var timelineSummary: some View {
        if !beatTimeline.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Beat timing")
                    .font(.headline)
                ForEach(beatTimeline, id: \.beat) { segment in
                    HStack {
                        Text(segment.beat.displayLabel)
                            .frame(width: 80, alignment: .leading)
                        Text("target \(Int(segment.targetSeconds))s")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Label(
                            "\(String(format: "%.1f", segment.actualSeconds))s",
                            systemImage: segment.isWithinTolerance ? "checkmark.circle" : "exclamationmark.triangle"
                        )
                        .font(.caption)
                        .foregroundStyle(segment.isWithinTolerance ? Color.green : Color.orange)
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(.top, 8)
        }
    }

    private var reflectButton: some View {
        Button(action: onReflect) {
            Label("Listen with Bramble", systemImage: "ear.and.waveform")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .accessibilityHint("Ask Bramble to reflect on what they heard.")
    }
}
