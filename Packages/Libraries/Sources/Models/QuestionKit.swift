import Foundation

/// One Phase-1 question kit (kits 01-04). Loaded from
/// `Sources/Services/Resources/QuestionKits/kit_NN_*.json` via
/// `Bundle.module`. Per `@Docs/IMPLEMENTATION_HANDOFF.md` § 6 ("Phase 1: 4
/// inline scaffolds — hook / sensory detail / arc / mood").
nonisolated public struct QuestionKit: Codable, Sendable, Hashable, Identifiable {
    public var id: Int { kit }
    public let kit: Int
    public let title: String
    public let primitive: String
    public let anchorCharacterSlug: String
    public let summary: String
    public let questions: [KitQuestion]
    public let castCameos: [CastCameo]

    public init(
        kit: Int,
        title: String,
        primitive: String,
        anchorCharacterSlug: String,
        summary: String,
        questions: [KitQuestion],
        castCameos: [CastCameo]
    ) {
        self.kit = kit
        self.title = title
        self.primitive = primitive
        self.anchorCharacterSlug = anchorCharacterSlug
        self.summary = summary
        self.questions = questions
        self.castCameos = castCameos
    }
}

/// A single prompt inside a kit. The kit supports several kinds (reflection /
/// choice / rewrite) — the shape is unified so the view can switch on
/// ``kind`` without conditional decoding.
nonisolated public struct KitQuestion: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let kind: Kind
    public let prompt: String
    public let options: [String]?
    public let correctIndex: Int?
    public let rationale: String?

    public init(
        id: String,
        kind: Kind,
        prompt: String,
        options: [String]? = nil,
        correctIndex: Int? = nil,
        rationale: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.prompt = prompt
        self.options = options
        self.correctIndex = correctIndex
        self.rationale = rationale
    }

    public enum Kind: String, Codable, Sendable, Hashable {
        case reflection
        case choice
        case rewrite
    }
}

/// One cast member's kit-anchored cameo line. Per
/// `@Docs/HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` Move B (DN-S Integration).
nonisolated public struct CastCameo: Codable, Sendable, Hashable, Identifiable {
    public var id: String { slug }
    public let slug: String
    public let line: String

    public init(slug: String, line: String) {
        self.slug = slug
        self.line = line
    }
}
