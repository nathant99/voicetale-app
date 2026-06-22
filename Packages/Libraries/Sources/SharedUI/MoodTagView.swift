import SwiftUI
import Models

/// Lightweight chip surface for a ``VoiceTaleMood``. Used both as an active
/// picker and as a display badge in the anthology gallery.
public struct MoodTagView: View {
    public let mood: VoiceTaleMood
    public let isSelected: Bool

    public init(mood: VoiceTaleMood, isSelected: Bool = false) {
        self.mood = mood
        self.isSelected = isSelected
    }

    public var body: some View {
        Label {
            Text(mood.displayLabel)
        } icon: {
            Image(systemName: symbol)
        }
        .font(.callout)
        .fontWeight(isSelected ? .semibold : .regular)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(tint.opacity(isSelected ? 0.25 : 0.12))
        )
        .overlay(
            Capsule().stroke(tint.opacity(isSelected ? 0.6 : 0.2), lineWidth: 1)
        )
        .foregroundStyle(tint)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Mood: \(mood.displayLabel)"))
        .accessibilityHint(isSelected ? "Currently selected" : "Tap to choose this mood")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var symbol: String {
        switch mood {
        case .funny:  return "face.smiling"
        case .scary:  return "moon.stars.fill"
        case .tender: return "heart.fill"
        case .wild:   return "tornado"
        }
    }

    private var tint: Color {
        switch mood {
        case .funny:  return .yellow
        case .scary:  return .purple
        case .tender: return .pink
        case .wild:   return .orange
        }
    }
}

#Preview {
    HStack {
        ForEach(VoiceTaleMood.allCases, id: \.self) { mood in
            MoodTagView(mood: mood, isSelected: mood == .tender)
        }
    }
    .padding()
}
