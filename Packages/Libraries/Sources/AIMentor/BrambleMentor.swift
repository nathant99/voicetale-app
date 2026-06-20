import Foundation
import Models

@Observable
public final class BrambleMentor {
    public enum Availability: Sendable, Equatable {
        case available
        case unavailableDeviceNotEligible
        case unavailableAppleIntelligenceNotEnabled
        case unavailableModelNotReady
        case unknown
    }

    public private(set) var availability: Availability = .unknown

    public init() {}

    public func staticFallback(for mood: VoiceTaleMood, beat: ArcBeat) -> VoiceStoryReflection {
        let observation: String
        let prompt: String
        switch (mood, beat) {
        case (.funny, .hook):
            observation = "Your opening landed like a small joke I wanted to hear the rest of."
            prompt = "What was the moment in the day that made you want to start there?"
        case (.scary, .turn):
            observation = "You held the turn long enough for me to feel the cold air change."
            prompt = "What did you notice when you slowed down right before it?"
        case (.tender, .close):
            observation = "The last line stayed in the room after you stopped."
            prompt = "Did you mean it to land that way, or did it surprise you too?"
        case (.wild, .rising):
            observation = "The rising section ran fast — I felt the world spilling outward."
            prompt = "What would happen if you let one image hang for a full breath?"
        default:
            observation = "I heard you choose your pace on the \(beat.displayLabel.lowercased())."
            prompt = "Was that the listener you were telling it to?"
        }
        return VoiceStoryReflection(craftObservations: [observation], socraticPrompt: prompt)
    }
}
