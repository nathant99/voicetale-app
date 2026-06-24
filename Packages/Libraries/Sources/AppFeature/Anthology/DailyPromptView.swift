import SwiftUI

/// A rotating prompt of the day — surfaced on the Tell tab idle surface as
/// a soft nudge. Phase 1 uses a hand-authored prompt pool seeded by the
/// current ordinal day; Phase 2 will rotate from a bundled JSON.
///
/// Engagement-Foundation phase — ~1 in 5 sessions, the daily prompt
/// rotates into the **rare** pool with a "Rare prompt" badge. Per
/// `@Docs/FEATURE_PLAN.md` § "Variable rewards — ~1 in 5 sessions
/// surface a rare tradition unlock / hidden prompt category."
public struct DailyPromptView: View {
    @Environment(\.analyticsService) private var analytics
    public let prompt: String
    /// `nil` for a standard prompt; non-nil rare-category slug ("hidden_question" /
    /// "tradition_echo" / "wild_card") for a variable-reward surfacing.
    public let rareCategory: String?
    /// Delight & Polish "Agency" micro-delight — the index in
    /// ``DailyPromptView/prompts`` the swap pill rotates THROUGH. View-
    /// local `@State` so the pill is a kid-driven affordance without
    /// touching `@AppStorage`. Initialized to nil = "use today's prompt
    /// from the ordinal-day rotation"; once the kid taps the pill, it
    /// holds the swapped-to index for the rest of the session. Per
    /// `Docs/AUDIT_MICRO_DELIGHT_COVERAGE_2026-06-24.md` § Reds — Agency.
    @State private var swappedIndex: Int?

    public init(
        prompt: String = DailyPromptView.todaysPrompt(),
        rareCategory: String? = nil
    ) {
        self.prompt = prompt
        self.rareCategory = rareCategory
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Prompt of the day")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if rareCategory != nil {
                    Label("Rare", systemImage: "sparkles")
                        .labelStyle(.titleAndIcon)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Color.accentColor.opacity(0.18))
                        )
                        .foregroundStyle(Color.accentColor)
                        .accessibilityLabel(Text("Rare prompt"))
                }
            }
            Text(displayPrompt)
                .font(.body.weight(.medium))
            // Agency surface — swap pill suppressed on rare prompts so
            // the kid can't skip past the discovery moment.
            if rareCategory == nil {
                swapPill
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .onAppear {
            analytics.track(.dailyPromptViewed)
            if let category = rareCategory {
                analytics.track(.rarePromptSurfaced(category: category))
            }
        }
    }

    /// The prompt the body actually renders: swapped-to value (if the
    /// kid tapped the pill) OR the prop passed in by the caller.
    private var displayPrompt: String {
        if let swappedIndex {
            return DailyPromptView.prompts[swappedIndex]
        }
        return prompt
    }

    /// The "Try a different one" pill — Agency micro-delight surface.
    /// Anti-shame framing: the copy explicitly normalizes the swap
    /// ("These prompts are all yours to pick from") via the
    /// accessibility hint. Pill copy itself stays terse so the surface
    /// doesn't lecture.
    @ViewBuilder
    private var swapPill: some View {
        HStack(spacing: 8) {
            Button {
                let nextIndex = DailyPromptView.nextSwapIndex(
                    currentIndex: currentPromptIndex,
                    poolSize: DailyPromptView.prompts.count
                )
                swappedIndex = nextIndex
                analytics.track(.promptSwapped(toIndex: nextIndex))
            } label: {
                Label("Try a different one", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderless)
            .background(.thinMaterial, in: Capsule())
            .accessibilityHint(Text("These prompts are all yours to pick from."))
            Spacer()
        }
        .padding(.top, 2)
    }

    /// Index in the standard prompt pool currently being displayed.
    /// Used as the seed for the swap rotation so consecutive swaps
    /// surface different entries.
    private var currentPromptIndex: Int {
        if let swappedIndex {
            return swappedIndex
        }
        return DailyPromptView.todaysPromptIndex()
    }

    /// Returns a prompt selected by the day-of-year — stable per day, rotates
    /// once a midnight passes. 30-entry starter pool per
    /// `@Docs/FEATURE_PLAN.md` § Data Layer.
    public static func todaysPrompt(now: Date = Date(), calendar: Calendar = .current) -> String {
        return prompts[todaysPromptIndex(now: now, calendar: calendar)]
    }

    /// Returns the index in ``prompts`` corresponding to today's prompt.
    /// Used by the swap-pill rotation as the seed so consecutive swaps
    /// step through the pool deterministically. Public + `nonisolated`
    /// so unit tests can pin the index without spinning up the view.
    nonisolated public static func todaysPromptIndex(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let day = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        return (day - 1) % prompts.count
    }

    /// Delight & Polish "Agency" micro-delight — pure-function next-
    /// index resolver for the "Try a different one" pill. Walks the
    /// pool by 7 entries per tap so the kid steps through varied
    /// prompts instead of seeing adjacent entries (which would feel
    /// monotonous). Wraps around at the pool boundary; never returns
    /// the input `currentIndex` (the swap MUST change the prompt).
    /// Pure + `nonisolated` so unit tests can lock the rotation.
    nonisolated public static func nextSwapIndex(currentIndex: Int, poolSize: Int) -> Int {
        guard poolSize > 1 else { return currentIndex }
        let step = 7  // co-prime-ish stride against 30 — distributes nicely
        var next = (currentIndex + step) % poolSize
        if next == currentIndex {
            next = (next + 1) % poolSize
        }
        return next
    }

    /// Variable-reward selection. Returns a rare prompt + category slug
    /// every Nth session (`rareFrequency`, default 5) per the engagement-
    /// foundation rule. Otherwise returns the regular daily prompt with
    /// `rareCategory == nil`. Deterministic in `sessionCount` so tests can
    /// pin the surfacing cadence.
    public static func resolved(
        sessionCount: Int,
        now: Date = Date(),
        calendar: Calendar = .current,
        rareFrequency: Int = 5
    ) -> (prompt: String, rareCategory: String?) {
        // 1-indexed cadence: sessions 1-4 → standard, session 5 → rare,
        // sessions 6-9 → standard, session 10 → rare, etc.
        guard sessionCount > 0, rareFrequency > 0 else {
            return (todaysPrompt(now: now, calendar: calendar), nil)
        }
        let isRare = sessionCount % rareFrequency == 0
        if !isRare {
            return (todaysPrompt(now: now, calendar: calendar), nil)
        }
        // Rotate through the rare pool by session count so consecutive
        // rare sessions don't repeat the same prompt.
        let rareIndex = (sessionCount / rareFrequency - 1) % rarePrompts.count
        let rare = rarePrompts[rareIndex]
        return (rare.text, rare.category)
    }

    /// Rare-prompt pool surfaced ~1 in 5 sessions. Each entry pairs a
    /// kid-readable prompt with a category slug emitted in the
    /// `rare_prompt_surfaced` analytics event.
    public static let rarePrompts: [(text: String, category: String)] = [
        (
            "Bramble's friends each leave one line tonight. Tell me a tale that uses ALL FOUR of their voices.",
            "cast_ensemble"
        ),
        (
            "Hidden question: what is the SECOND-most boring moment of your day, and what makes it secretly interesting?",
            "hidden_question"
        ),
        (
            "Tradition echo: tell a tale the way a griot would — name your listener at the start and at the end.",
            "tradition_echo"
        ),
        (
            "Wild card: pick a single household object and tell its tale, not yours.",
            "wild_card"
        ),
        (
            "Time-travel telling: tell me a tale that happened yesterday — but tell it as if from twenty years from now.",
            "time_travel"
        ),
        (
            "Voice passport: pick one of Bramble's friends and tell a tale entirely in their voice, then take a single breath and finish in your own.",
            "voice_passport"
        ),
        (
            "Mood echo: tell me a tale in the mood you've told most often — and let the ending tip into the OPPOSITE mood for the last beat.",
            "mood_echo"
        ),
        (
            "Family tradition: ask someone in your house tonight for a story they remember from when they were your age. Bring it back tomorrow.",
            "family_tradition"
        ),
    ]

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
