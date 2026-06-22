import SwiftUI
import Models
import SharedUI

/// Per-beat transcript review surface. The kid edits each chunk before
/// Bramble reflects on the tale — the transcript pipeline is on-device but
/// imperfect, and the review step keeps the kid in control of what gets
/// "remembered".
///
/// Phase 1.1: per-beat voice-character picker lives here. The kid taps a
/// preset chip per beat row; ``BeatSegment.voiceCharacterSlug`` is stored
/// so the attribution survives the save → reflect → save loop. The
/// optional ``onPreview`` callback fires when the kid wants to audition
/// the picked preset; the host view (`TellView`) wires the preview to
/// ``VoiceCharacterPlayback``.
public struct TranscriptReviewView: View {
    @Binding public var transcript: String
    @Binding public var beatTimeline: [BeatSegment]
    public let onReflect: () -> Void
    public let onPreview: ((BeatSegment) -> Void)?
    public let onPreviewStop: (() -> Void)?
    public let activePreviewBeat: ArcBeat?

    public init(
        transcript: Binding<String>,
        beatTimeline: Binding<[BeatSegment]>,
        onReflect: @escaping () -> Void,
        onPreview: ((BeatSegment) -> Void)? = nil,
        onPreviewStop: (() -> Void)? = nil,
        activePreviewBeat: ArcBeat? = nil
    ) {
        self._transcript = transcript
        self._beatTimeline = beatTimeline
        self.onReflect = onReflect
        self.onPreview = onPreview
        self.onPreviewStop = onPreviewStop
        self.activePreviewBeat = activePreviewBeat
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
            VStack(alignment: .leading, spacing: 12) {
                Text("Beat timing & voice")
                    .font(.headline)
                ForEach(Array(beatTimeline.enumerated()), id: \.element.beat) { index, segment in
                    beatRow(index: index, segment: segment)
                }
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func beatRow(index: Int, segment: BeatSegment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(segment.beat.displayLabel)
                    .font(.subheadline.weight(.semibold))
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
            HStack(spacing: 8) {
                Text("Voice")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .leading)
                VoiceCharacterPickerView(
                    selection: bindingForSlug(at: index)
                )
                if let onPreview {
                    Button {
                        if activePreviewBeat == segment.beat, let onPreviewStop {
                            onPreviewStop()
                        } else {
                            onPreview(segment)
                        }
                    } label: {
                        Image(systemName: activePreviewBeat == segment.beat ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(activePreviewBeat == segment.beat ? Text("Stop voice preview") : Text("Preview voice"))
                    .accessibilityHint(Text("Hear the tale through the picked voice character."))
                }
            }
        }
        .padding(.vertical, 4)
    }

    /// Bridge between ``BeatSegment.voiceCharacterSlug`` and the
    /// ``VoiceCharacterPickerView`` `Binding<VoiceCharacterPreset>`. The
    /// picker always selects a non-optional preset; "narrator" maps to
    /// slug = nil so unchanged beats stay unattributed in storage.
    private func bindingForSlug(at index: Int) -> Binding<VoiceCharacterPreset> {
        Binding(
            get: {
                guard beatTimeline.indices.contains(index) else { return .narrator }
                return beatTimeline[index].voiceCharacterPreset
            },
            set: { newValue in
                guard beatTimeline.indices.contains(index) else { return }
                let slug: String? = (newValue == .narrator) ? nil : newValue.rawValue
                beatTimeline[index] = beatTimeline[index].withVoiceCharacter(slug)
            }
        )
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
