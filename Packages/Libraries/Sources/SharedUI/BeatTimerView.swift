import SwiftUI
import Models

/// Visual 5-beat timeline with elapsed-seconds indicator + per-beat progress.
/// Reads from `Models.ArcBeat` for canonical durations; never assumes a
/// specific timeline length so it scales as the spec evolves.
public struct BeatTimerView: View {
    public let elapsedSeconds: Double
    public let currentBeat: ArcBeat?
    public let isActivelyRecording: Bool

    public init(
        elapsedSeconds: Double,
        currentBeat: ArcBeat? = nil,
        isActivelyRecording: Bool = false
    ) {
        self.elapsedSeconds = elapsedSeconds
        self.currentBeat = currentBeat
        self.isActivelyRecording = isActivelyRecording
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var body: some View {
        VStack(spacing: 12) {
            elapsedReadout
            timeline
            beatLabels
        }
        .padding(.vertical, 8)
    }

    private var elapsedReadout: some View {
        Text(formattedElapsed)
            .font(.system(.title, design: .rounded).monospacedDigit())
            .fontWeight(.semibold)
            .accessibilityLabel("Elapsed seconds: \(Int(elapsedSeconds))")
    }

    private var timeline: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                ForEach(Array(ArcBeat.allCases.enumerated()), id: \.element) { index, beat in
                    let offset = beatStartFraction(for: index)
                    let width = beat.targetSeconds / Self.totalSeconds
                    Capsule()
                        .fill(color(for: beat).opacity(currentBeat == beat ? 0.85 : 0.35))
                        .frame(width: proxy.size.width * width)
                        .offset(x: proxy.size.width * offset)
                }
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(4, proxy.size.width * elapsedFraction))
                    .animation(reduceMotion ? nil : .linear(duration: 0.1), value: elapsedFraction)
            }
        }
        .frame(height: 14)
        .clipShape(Capsule())
    }

    private var beatLabels: some View {
        HStack(spacing: 0) {
            ForEach(ArcBeat.allCases, id: \.self) { beat in
                Text(beat.displayLabel)
                    .font(.caption2)
                    .fontWeight(currentBeat == beat ? .semibold : .regular)
                    .foregroundStyle(currentBeat == beat ? Color.primary : .secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(beatLabelsAccessibilityLabel)
    }

    private var beatLabelsAccessibilityLabel: String {
        if let currentBeat {
            return "Current beat: \(currentBeat.displayLabel)"
        }
        return "Five beats: hook, setup, rising, turn, close."
    }

    private var formattedElapsed: String {
        let total = max(0, Int(elapsedSeconds.rounded()))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var elapsedFraction: Double {
        guard Self.totalSeconds > 0 else { return 0 }
        return min(1, max(0, elapsedSeconds / Self.totalSeconds))
    }

    private static let totalSeconds: Double = ArcBeat.allCases.reduce(0) { $0 + $1.targetSeconds }

    private func beatStartFraction(for index: Int) -> Double {
        let total = Self.totalSeconds
        guard total > 0, index > 0 else { return 0 }
        let running = ArcBeat.allCases.prefix(index).reduce(0) { $0 + $1.targetSeconds }
        return running / total
    }

    private func color(for beat: ArcBeat) -> Color {
        switch beat {
        case .hook:   return .orange
        case .setup:  return .yellow
        case .rising: return .green
        case .turn:   return .teal
        case .close:  return .blue
        }
    }
}

#Preview("Idle") {
    BeatTimerView(elapsedSeconds: 0)
        .padding()
}

#Preview("Mid-rising") {
    BeatTimerView(elapsedSeconds: 45, currentBeat: .rising, isActivelyRecording: true)
        .padding()
}
