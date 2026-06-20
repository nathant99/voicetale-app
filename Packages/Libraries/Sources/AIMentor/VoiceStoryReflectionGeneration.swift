import Foundation
import FoundationModels

/// `@Generable` shape Bramble produces from the transcript. Property order
/// is load-bearing per `@.claude/rules/foundationmodels.md` § "Property order
/// matters": observations come first because they prime the Socratic prompt.
@Generable
public struct VoiceStoryReflectionGeneration: Sendable {
    @Guide(description: "One or two short observations about the craft. NEVER grades. NEVER comments on accent, fluency, or articulation. Each observation reflects ONE concrete moment the listener heard the teller do — sensory detail, pacing, a specific image, the shape of the arc — not a judgment of overall quality.")
    public let craftObservations: [String]

    @Guide(description: "A single open-ended follow-up question that invites the teller deeper into their own choice. The question MUST start with 'What' or 'How' or 'When' (never 'Why'); MUST be answerable by the teller without further guidance; MUST NOT be a leading question.")
    public let socraticPrompt: String?

    public init(craftObservations: [String], socraticPrompt: String?) {
        self.craftObservations = craftObservations
        self.socraticPrompt = socraticPrompt
    }
}
