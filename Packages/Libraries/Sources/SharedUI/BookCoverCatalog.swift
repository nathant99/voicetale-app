import Foundation

/// Resolves bundled VoiceTale book-cover WebP assets shipped by the hub
/// per `Docs/HANDOFF_FROM_HUB_BOOK_COVERS.md`. Two tiers ship:
///
/// - **Standard** (Blubook register; ages 9-12) — `cover_book_standard.webp`
/// - **Advanced** (Folio register; ages 11-14) — `cover_book_advanced.webp`
///
/// Both live under `Sources/SharedUI/Resources/CustomArt/voicetale/` so they
/// ship inside the SharedUI SPM bundle (the canonical app-source-of-truth);
/// the repo-root `Resources/CustomArt/voicetale/` copy is the hub-distribution
/// staging path and is duplicated here so apps consume via `Bundle.module`.
///
/// PDF book content itself lives on the website at
/// `spark-and-anvil.com/books/voicetale-book.pdf` (Standard) and
/// `spark-and-anvil.com/books/advanced/voicetale-book.pdf` (Advanced) — apps
/// surface the covers as a teaser / discovery card; readers tap through to
/// the website to read or download the PDF. Not bundled in-app yet (PDF size
/// + audience-tier choice are intentionally deferred per the hub handoff).
public enum BookCoverCatalog {
    nonisolated public enum Tier: String, CaseIterable, Sendable, Identifiable {
        case standard
        case advanced

        public var id: String { rawValue }

        public var fileName: String {
            switch self {
            case .standard: return "cover_book_standard"
            case .advanced: return "cover_book_advanced"
            }
        }

        public var displayTitle: String {
            switch self {
            case .standard: return "VoiceTale — Standard Edition"
            case .advanced: return "VoiceTale — Advanced Edition"
            }
        }

        public var audienceLabel: String {
            switch self {
            case .standard: return "Ages 9–12 · Blubook register"
            case .advanced: return "Ages 11–14 · Folio register"
            }
        }

        public var description: String {
            switch self {
            case .standard:
                return "The four oral-craft friends — Lean, Slow, Pivot, Refrain — gather around the fire. Magic-Tree-House cadence."
            case .advanced:
                return "Same four friends, longer chapters. Wonder / Hatchet / Holes register. Same characters; deeper sentences."
            }
        }

        public var websitePath: String {
            switch self {
            case .standard: return "/books/voicetale-book.pdf"
            case .advanced: return "/books/advanced/voicetale-book.pdf"
            }
        }
    }

    /// Resolves the WebP URL from the SharedUI SPM bundle. Returns `nil` if
    /// the asset is missing (e.g., the hub sync hasn't run since cover gen).
    public static func coverURL(tier: Tier) -> URL? {
        Bundle.module.url(
            forResource: tier.fileName,
            withExtension: "webp",
            subdirectory: "CustomArt/voicetale"
        ) ?? Bundle.module.url(forResource: tier.fileName, withExtension: "webp")
    }

    /// Convenience for UI code — returns `(tier, url)` pairs in canonical
    /// surface order (Standard first; Advanced second). Tiers whose WebP is
    /// missing from the bundle are silently skipped so the surface gracefully
    /// degrades.
    public static func availableCovers() -> [(tier: Tier, url: URL)] {
        Tier.allCases.compactMap { tier in
            guard let url = coverURL(tier: tier) else { return nil }
            return (tier, url)
        }
    }
}
