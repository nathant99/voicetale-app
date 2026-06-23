import SwiftUI
import Models
import SharedUI

/// Engagement-Foundation session-closer recap. Surfaces as a sheet at the
/// end of a session — the kid sees what they did this sitting (tales told,
/// badges earned) + a one-line preview of what tomorrow's session can
/// reach for.
///
/// Per `@Docs/FEATURE_PLAN.md` § Engagement Foundation → "Session
/// targeting: 10-15 minute sessions with gentle ending summary" + § Parent
/// Integration → "Session closer: end-of-session summary with achievements
/// + preview of next session content".
///
/// Voice register: Bramble's grandmother register (per the cast voice
/// card). Never celebrates "zero tales told" as a failure — the recap
/// honors the sitting whether or not a tale landed.
public struct SessionCloserView: View {
    public struct Recap: Sendable, Equatable {
        public let talesSavedThisSession: Int
        public let badgesEarnedThisSession: [String]
        public let currentStreakDays: Int
        public let nextSessionInvite: String

        public init(
            talesSavedThisSession: Int,
            badgesEarnedThisSession: [String],
            currentStreakDays: Int,
            nextSessionInvite: String
        ) {
            self.talesSavedThisSession = talesSavedThisSession
            self.badgesEarnedThisSession = badgesEarnedThisSession
            self.currentStreakDays = currentStreakDays
            self.nextSessionInvite = nextSessionInvite
        }
    }

    public let recap: Recap
    public let onDismiss: () -> Void

    public init(recap: Recap, onDismiss: @escaping () -> Void) {
        self.recap = recap
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            taleSummary
            if recap.badgesEarnedThisSession.isEmpty == false {
                badgesSection
            }
            streakLine
            Divider()
            nextSessionLine
            Spacer()
            doneButton
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 28)
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("A good sitting")
                .font(.title.weight(.semibold))
            Text(SessionCloserView.openingLine(for: recap.talesSavedThisSession))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var taleSummary: some View {
        HStack(spacing: 12) {
            Image(systemName: "books.vertical.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(SessionCloserView.taleCountPhrase(recap.talesSavedThisSession))
                    .font(.headline)
                Text("Every tale stays here for you.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(SessionCloserView.taleCountPhrase(recap.talesSavedThisSession)). Every tale stays here for you."
        )
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("New craft markers")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(recap.badgesEarnedThisSession, id: \.self) { title in
                Label(title, systemImage: "rosette")
                    .font(.callout)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            Text("New craft markers earned this sitting: \(recap.badgesEarnedThisSession.joined(separator: ", "))")
        )
    }

    private var streakLine: some View {
        let phrase = SessionCloserView.streakPhrase(days: recap.currentStreakDays)
        return HStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(phrase)
                .font(.callout)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(phrase))
    }

    private var nextSessionLine: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Next sitting")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(recap.nextSessionInvite)
                .font(.callout)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Next sitting: \(recap.nextSessionInvite)"))
    }

    private var doneButton: some View {
        Button(action: onDismiss) {
            Text("All right, see you next time")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityHint(Text("Close the session summary."))
    }

    // MARK: - Copy helpers (pure functions; testable)

    /// Opening line tuned to whether the kid told a tale this sitting. No
    /// scolding for zero — the silent sitting is honored.
    public static func openingLine(for talesSaved: Int) -> String {
        switch talesSaved {
        case ..<1:
            return "You came back today. That counts too."
        case 1:
            return "One tale told. The room is still warm from it."
        case 2...3:
            return "A handful of tales. Bramble heard each one."
        default:
            return "A whole armful of tales. The room is full."
        }
    }

    public static func taleCountPhrase(_ count: Int) -> String {
        switch count {
        case ..<1:  return "No tales saved this sitting"
        case 1:     return "One tale saved this sitting"
        default:    return "\(count) tales saved this sitting"
        }
    }

    public static func streakPhrase(days: Int) -> String {
        switch days {
        case ..<1:  return "Today is a fresh start."
        case 1:     return "One day in a row. A streak begins."
        case 2:     return "Two days running. Bramble's noticed."
        case 3...6: return "\(days) days in a row. The shape is holding."
        default:    return "\(days) days in a row. A real streak now."
        }
    }
}
