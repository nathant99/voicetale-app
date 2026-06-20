import Foundation

/// Per-app companion pack manifest. The PDFs are bundled at gen time by
/// labsmith (queue #332) and surfaced via ``CompanionPackView`` per
/// `Docs/HANDOFF_FROM_LABSMITH_COMPANION_PACK.md`.
nonisolated public struct CompanionPackManifest: Codable, Sendable, Hashable {
    public let app: String
    public let format: String
    public let source: String
    public let spec: String
    public let pdfs: [String]
    public let count: Int
    public let loadingHint: String

    public init(
        app: String,
        format: String,
        source: String,
        spec: String,
        pdfs: [String],
        count: Int,
        loadingHint: String
    ) {
        self.app = app
        self.format = format
        self.source = source
        self.spec = spec
        self.pdfs = pdfs
        self.count = count
        self.loadingHint = loadingHint
    }

    private enum CodingKeys: String, CodingKey {
        case app, format, source, spec, pdfs, count
        case loadingHint = "loading_hint"
    }
}

/// One entry inside the rendered companion-pack UI. The mapping from raw
/// PDF filename → display title + icon lives here so future surfaces (Settings,
/// Profile, web) stay consistent.
nonisolated public struct CompanionPackPDF: Sendable, Hashable, Identifiable {
    public var id: String { fileName }
    public let fileName: String
    public let title: String
    public let summary: String
    public let systemImage: String

    public init(fileName: String, title: String, summary: String, systemImage: String) {
        self.fileName = fileName
        self.title = title
        self.summary = summary
        self.systemImage = systemImage
    }

    public static let knownEntries: [String: CompanionPackPDF] = [
        "coloring.pdf": CompanionPackPDF(
            fileName: "coloring.pdf",
            title: "Coloring Sheets",
            summary: "Print and color the cast.",
            systemImage: "paintpalette.fill"
        ),
        "puzzle_sampler.pdf": CompanionPackPDF(
            fileName: "puzzle_sampler.pdf",
            title: "Puzzle Sampler",
            summary: "Print and solve six puzzles with a pencil.",
            systemImage: "puzzlepiece.fill"
        ),
        "cast_poster.pdf": CompanionPackPDF(
            fileName: "cast_poster.pdf",
            title: "Cast Poster",
            summary: "Meet the cast — print and hang on the wall.",
            systemImage: "person.3.fill"
        ),
        "parent_letter.pdf": CompanionPackPDF(
            fileName: "parent_letter.pdf",
            title: "Parent Letter",
            summary: "A note about what your child is learning.",
            systemImage: "envelope.fill"
        ),
    ]
}
