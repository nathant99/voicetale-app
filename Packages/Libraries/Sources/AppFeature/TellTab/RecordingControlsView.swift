import SwiftUI
import Models

/// Three-button record-flow controls. `onStart` kicks the audio engine;
/// `onStop` finalises into review; `onCancel` discards the in-progress take.
public struct RecordingControlsView: View {
    public let isRecording: Bool
    public let elapsedSeconds: Double
    public let onStart: () -> Void
    public let onStop: () -> Void
    public let onCancel: () -> Void

    public init(
        isRecording: Bool,
        elapsedSeconds: Double,
        onStart: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.isRecording = isRecording
        self.elapsedSeconds = elapsedSeconds
        self.onStart = onStart
        self.onStop = onStop
        self.onCancel = onCancel
    }

    public var body: some View {
        HStack(spacing: 16) {
            if isRecording {
                cancelButton
                stopButton
            } else {
                startButton
            }
        }
        .padding()
    }

    private var startButton: some View {
        Button(action: onStart) {
            Label("Start telling", systemImage: "mic.circle.fill")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityHint("Begin recording your tale. Microphone permission required.")
    }

    private var stopButton: some View {
        Button(action: onStop) {
            Label("Done", systemImage: "checkmark.circle.fill")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .controlSize(.large)
        .accessibilityHint("Finish the tale and listen back.")
    }

    private var cancelButton: some View {
        Button(role: .destructive, action: onCancel) {
            Label("Cancel", systemImage: "xmark.circle")
                .font(.title3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .accessibilityHint("Discard this take and return to the start.")
    }
}

#Preview("Idle") {
    RecordingControlsView(
        isRecording: false,
        elapsedSeconds: 0,
        onStart: {},
        onStop: {},
        onCancel: {}
    )
    .padding()
}

#Preview("Recording") {
    RecordingControlsView(
        isRecording: true,
        elapsedSeconds: 45,
        onStart: {},
        onStop: {},
        onCancel: {}
    )
    .padding()
}
