import SwiftUI

/// A rotating prompt of the day — surfaced on the Tell tab idle surface as
/// a soft nudge. Phase 1 uses a hand-authored prompt pool seeded by the
/// current ordinal day; Phase 2 will rotate from a bundled JSON.
public struct DailyPromptView: View {
    public let prompt: String

    public init(prompt: String = DailyPromptView.todaysPrompt()) {
        self.prompt = prompt
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Prompt of the day")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(prompt)
                .font(.body.weight(.medium))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    /// Returns a prompt selected by the day-of-year — stable per day, rotates
    /// once a midnight passes. 30-entry starter pool per
    /// `@Docs/FEATURE_PLAN.md` § Data Layer.
    public static func todaysPrompt(now: Date = Date(), calendar: Calendar = .current) -> String {
        let day = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        let index = (day - 1) % prompts.count
        return prompts[index]
    }

    public static let prompts: [String] = [
        "Tell me about the most boring 10 seconds of your day — but make it interesting.",
        "Tell me about a small thing that made you laugh this week.",
        "Tell me about a time you noticed something nobody else did.",
        "Tell me about the last time you were scared and how you handled it.",
        "Tell me about a tradition in your house that you wouldn't trade.",
        "Tell me about a stranger who was kind to you.",
        "Tell me about a small lie that didn't matter.",
        "Tell me about something you used to be afraid of.",
        "Tell me about a sound you can't get out of your head.",
        "Tell me about a meal that reminds you of someone.",
        "Tell me about a time you got something right when you didn't think you would.",
        "Tell me about a place you go in your imagination.",
        "Tell me about a 30-second story that ends with a question, not an answer.",
        "Tell me about something your future self should remember about today.",
        "Tell me about a stranger you imagined a whole life for.",
        "Tell me about a smell that takes you somewhere else.",
        "Tell me about a time you were the youngest in the room.",
        "Tell me about a thing you found and what you did with it.",
        "Tell me about a sound that always means morning.",
        "Tell me about a moment when everyone laughed at the same time.",
        "Tell me about a time you were the only one not laughing.",
        "Tell me about a small mistake that turned into a story.",
        "Tell me about a window you remember.",
        "Tell me about a person you only met once.",
        "Tell me about something you forgot until just now.",
        "Tell me about a sentence somebody once said to you that you still carry.",
        "Tell me about a place you'd like to come back to.",
        "Tell me about a time you ate too fast.",
        "Tell me about a path you almost didn't take.",
        "Tell me about a quiet moment that was louder than it should have been.",
    ]
}

#Preview {
    DailyPromptView()
        .padding()
}
