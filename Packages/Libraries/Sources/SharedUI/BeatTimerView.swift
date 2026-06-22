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

    /// Tracks whether the active beat just changed so the nudge pulse can
    /// briefly highlight the new beat without preventing subsequent renders
    /// from settling back to the resting style. Per
    /// `@Docs/TECHNICAL_DESIGN.md` § Full-App UI/UX Patterns — "gentle nudge
    /// animations (no abrupt cuts)" at beat boundaries.
    @State private var nudgeBeat: ArcBeat?
    @State private var lastObservedBeat: ArcBeat?

    public var body: some View {
        VStack(spacing: 12) {
            elapsedReadout
            timeline
            beatLabels
        }
        .padding(.vertical, 8)
        .onChange(of: currentBeat) { _, newValue in
            handleBeatBoundary(newBeat: newValue)
        }
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
                        .fill(color(for: beat).opacity(beatFillOpacity(for: beat)))
                        .frame(width: proxy.size.width * width)
                        .offset(x: proxy.size.width * offset)
                        .scaleEffect(
                            y: beatScale(for: beat),
                            anchor: .center
                        )
                        .animation(
                            reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.55),
                            value: nudgeBeat
                        )
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

    /// Opacity for the beat-block fill. Active beat fades in; the brief
    /// boundary nudge briefly brightens it. Reduce-Motion mode keeps the
    /// active beat at full opacity — same visual signal, no pulse.
    private func beatFillOpacity(for beat: ArcBeat) -> Double {
        guard currentBeat == beat else { return 0.35 }
        if reduceMotion { return 0.85 }
        return nudgeBeat == beat ? 1.0 : 0.85
    }

    /// Vertical scale for the beat-block during the nudge window. 1.0 when
    /// no nudge active or Reduce-Motion enabled. Only the newly-entered beat
    /// scales — sibling blocks stay still.
    private func beatScale(for beat: ArcBeat) -> CGFloat {
        guard !reduceMotion else { return 1.0 }
        return nudgeBeat == beat ? 1.3 : 1.0
    }

    /// Fires the beat-boundary nudge when ``currentBeat`` transitions to a
    /// non-nil value that differs from the previously observed beat. Holds
    /// the nudge briefly, then releases — the spring animation handles the
    /// fade-back to resting. Idempotent: rapid same-beat ticks are no-ops.
    private func handleBeatBoundary(newBeat: ArcBeat?) {
        guard let newBeat else {
            lastObservedBeat = nil
            nudgeBeat = nil
            return
        }
        guard newBeat != lastObservedBeat else { return }
        lastObservedBeat = newBeat
        guard !reduceMotion else { return }
        nudgeBeat = newBeat
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            if nudgeBeat == newBeat {
                nudgeBeat = nil
            }
        }
    }

    private var beatLabels: some View {
        HStack(spacing: 0) {
            ForEach(ArcBeat.allCases, id: \.self) { beat in
                Text(beat.displayLabel)
                    .font(.caption2)
                    .fontWeight(currentBeat == beat ? .semibold : .regular)
                    .foregroundStyle(currentBeat == beat ? Color.primary : .secondary)
                    .scaleEffect(labelScale(for: beat))
                    .frame(maxWidth: .infinity)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.55),
                        value: nudgeBeat
                    )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(beatLabelsAccessibilityLabel)
    }

    /// Brief 1.18× pulse on the newly-entered beat label. Reduce-Motion keeps
    /// every label at 1.0 — the foregroundStyle + fontWeight already convey
    /// "active beat" without animation.
    private func labelScale(for beat: ArcBeat) -> CGFloat {
        guard !reduceMotion else { return 1.0 }
        return nudgeBeat == beat ? 1.18 : 1.0
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
