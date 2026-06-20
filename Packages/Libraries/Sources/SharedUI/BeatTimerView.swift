import SwiftUI
import Models

public struct BeatTimerView: View {
    public let elapsedSeconds: Double
    public let beatTimeline: [BeatSegment]

    public init(elapsedSeconds: Double, beatTimeline: [BeatSegment] = []) {
        self.elapsedSeconds = elapsedSeconds
        self.beatTimeline = beatTimeline
    }

    public var body: some View {
        VStack(spacing: 8) {
            Text("Beat timer")
                .font(.headline)
            Text("\(String(format: "%.1f", elapsedSeconds))s")
                .font(.system(.title, design: .rounded).monospacedDigit())
                .accessibilityLabel("Elapsed seconds")
        }
        .padding()
    }
}
