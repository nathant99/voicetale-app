import SwiftUI
import Models
import Services
import SharedUI

/// Engagement-Foundation welcome-back overlay. Surfaces as a sheet when
/// ``LapsedReturnDetector.shouldSurfaceWelcomeBack(lastActive:)`` returns
/// `true` on launch. Per `@Docs/FEATURE_PLAN.md` § "Return loop —
/// Welcome-back flow for 3+ day lapsed users: warm greeting + best-tale
/// recap."
///
/// Visual register: Bramble's grandmother-listener voice. NEVER shames the
/// gap, NEVER guilts the kid into telling. Names what's there + invites
/// them back without an obligation. Per
/// `@.claude/rules/trauma-informed-content.md` § "validate, then inform" —
/// the lapse is named, not interpreted.
public struct WelcomeBackView: View {
    public let daysLapsed: Int
    public let lastTale: VoiceTaleEntry?
    public let onTellAnother: () -> Void
    public let onJustLooking: () -> Void

    public init(
        daysLapsed: Int,
        lastTale: VoiceTaleEntry?,
        onTellAnother: @escaping () -> Void,
        onJustLooking: @escaping () -> Void
    ) {
        self.daysLapsed = daysLapsed
        self.lastTale = lastTale
        self.onTellAnother = onTellAnother
        self.onJustLooking = onJustLooking
    }

    public var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 16)
            mascot
            VStack(spacing: 8) {
                Text("Bramble's been listening.")
                    .font(.title2.weight(.semibold))
                Text(greetingSubtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            if let lastTale {
                lastTaleCard(lastTale)
            }
            Spacer()
            actionRow
        }
        .padding()
    }

    private var mascot: some View {
        ZStack {
            Circle()
                .fill(.tint.opacity(0.15))
                .frame(width: 120, height: 120)
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
        }
        .accessibilityHidden(true)
    }

    private var greetingSubtitle: String {
        let daysWord = daysLapsed == 1 ? "day" : "days"
        return "It's been \(daysLapsed) \(daysWord). I held a spot by the fire for you."
    }

    @ViewBuilder
    private func lastTaleCard(_ tale: VoiceTaleEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last tale you told")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(tale.title.isEmpty ? "Untitled tale" : tale.title)
                .font(.headline)
            HStack(spacing: 8) {
                MoodTagView(mood: tale.mood)
                Text("\(Int(tale.durationSeconds))s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !tale.transcript.isEmpty {
                Text(tale.transcript.prefix(120) + (tale.transcript.count > 120 ? "…" : ""))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Last tale you told: \(tale.title.isEmpty ? "Untitled tale" : tale.title), mood \(tale.mood.displayLabel)"))
    }

    private var actionRow: some View {
        VStack(spacing: 10) {
            Button(action: onTellAnother) {
                Label("Tell me one more", systemImage: "mic.circle.fill")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint("Open the Tell tab and start a new recording.")

            Button(action: onJustLooking) {
                Text("Just looking around")
                    .font(.callout)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityHint("Dismiss this welcome screen without recording.")
        }
    }
}

#Preview {
    WelcomeBackView(
        daysLapsed: 5,
        lastTale: VoiceTaleEntry(
            title: "The pancake heist",
            mood: .funny,
            durationSeconds: 67,
            beatTimeline: [],
            transcript: "And then the dragon flew over the kitchen and Mom laughed",
            reflection: nil
        ),
        onTellAnother: {},
        onJustLooking: {}
    )
}
