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
        // accessibilityHint (not .accessibilityLabel) on Buttons preserves
        // the XCUITest matcher `app.buttons["Start telling"]` per
        // `@.claude/rules/swiftlint.md` § `no_accessibility_label_on_buttons`.
        Button(action: onStart) {
            Label("Start telling", systemImage: "mic.circle.fill")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityHint("Begin recording your tale. Microphone permission required. Bramble listens on-device.")
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
        .accessibilityHint("Finish the tale and move to the listen-back review. Elapsed: \(Int(elapsedSeconds)) seconds.")
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
        .accessibilityHint("Discard this take and return to the start. The current recording is not saved.")
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
