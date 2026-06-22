import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Resolves bundled VoiceTale DN-S chapter illustration WebP assets shipped by
/// labsmith Round 496 per `Docs/HANDOFF_FROM_LABSMITH_CHAPTER_ILLUSTRATIONS_WAVE.md`
/// + ADR-017. Eight illustrations ship — 4 chapters × 2 variants:
///
/// - **Opener** (Gemini 3 Pro; ~$0.134 each) — full-page chapter splash; sized
///   for the chapter's hero card / detail-sheet header
/// - **Spot** (Gemini 3.1 Flash; reference-conditioned on the opener;
///   ~$0.045 each) — smaller in-line illustration; sized for chapter-list
///   thumbnails or mid-chapter beats
///
/// All eight live under `Sources/SharedUI/Resources/Illustrations/chapters/`
/// so they ship inside the SharedUI SPM bundle. The repo-root
/// `Resources/Illustrations/chapters/` copy is the hub-distribution staging
/// path and is kept in sync with this bundle copy.
///
/// Per the canonical Pattern B / DN-S register (writing-craft cluster), the
/// 4 chapters surface the 4 cast members each embodying one oral-craft
/// primitive: Lean (HOOK / leanability) / Pivot (TURN) / Refrain (CALLBACK) /
/// Slow (PACING). Filename slugs match the chapter MD filenames at
/// `Docs/dn-s/chapters/<char>.md` per R-CAST-PORTRAIT-SLUG.
public enum ChapterIllustrationCatalog {
    nonisolated public enum Chapter: String, CaseIterable, Sendable, Identifiable {
        case lean
        case pivot
        case refrain
        case slow

        public var id: String { rawValue }

        public var displayName: String {
            switch self {
            case .lean:    return "Lean"
            case .pivot:   return "Pivot"
            case .refrain: return "Refrain"
            case .slow:    return "Slow"
            }
        }

        /// One-line craft primitive — the WHY of the chapter. Kid-readable,
        /// not jargon. Surfaces as the chapter-card subtitle.
        public var craftPrimitive: String {
            switch self {
            case .lean:
                return "Hooks that make the listener tip forward at second five."
            case .pivot:
                return "The moment a story's meaning rotates."
            case .refrain:
                return "Saying a phrase once at the open and again at the close — same words, different weight."
            case .slow:
                return "Pacing — the body's tempo for a told tale."
            }
        }
    }

    nonisolated public enum Variant: String, CaseIterable, Sendable, Identifiable {
        case opener
        case spot

        public var id: String { rawValue }
    }

    /// File basename in the bundle (without extension). Per `chapter_<slug>_<variant>.webp`
    /// — the gen-pipeline filename convention.
    public static func fileName(chapter: Chapter, variant: Variant) -> String {
        "chapter_\(chapter.rawValue)_\(variant.rawValue)"
    }

    /// Resolves the WebP URL from the SharedUI SPM bundle. Returns `nil` if
    /// the asset is missing (e.g., the hub sync hasn't run since chapter gen).
    public static func illustrationURL(chapter: Chapter, variant: Variant) -> URL? {
        let basename = fileName(chapter: chapter, variant: variant)
        return Bundle.module.url(
            forResource: basename,
            withExtension: "webp",
            subdirectory: "Illustrations/chapters"
        ) ?? Bundle.module.url(forResource: basename, withExtension: "webp")
    }

    /// Returns all `(chapter, variant, url)` triples present in the bundle in
    /// canonical (chapter × variant) order. Missing files are silently skipped
    /// so the surface gracefully degrades.
    public static func availableIllustrations() -> [(chapter: Chapter, variant: Variant, url: URL)] {
        var result: [(Chapter, Variant, URL)] = []
        for chapter in Chapter.allCases {
            for variant in Variant.allCases {
                if let url = illustrationURL(chapter: chapter, variant: variant) {
                    result.append((chapter, variant, url))
                }
            }
        }
        return result
    }
}

/// Renders a chapter illustration WebP from the SharedUI bundle. Falls back to
/// an SF-Symbol book icon when the WebP is missing. Sized for the chapter card
/// (opener variant, ~120pt+) by default; pass smaller `cornerRadius` + height
/// via `frame(width:height:)` from the caller for thumbnail surfaces.
public struct ChapterIllustrationView: View {
    public let chapter: ChapterIllustrationCatalog.Chapter
    public let variant: ChapterIllustrationCatalog.Variant
    public let cornerRadius: CGFloat

    public init(
        chapter: ChapterIllustrationCatalog.Chapter,
        variant: ChapterIllustrationCatalog.Variant = .opener,
        cornerRadius: CGFloat = 12
    ) {
        self.chapter = chapter
        self.variant = variant
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        Group {
            #if canImport(UIKit)
            if let url = ChapterIllustrationCatalog.illustrationURL(chapter: chapter, variant: variant),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                fallback
            }
            #elseif canImport(AppKit)
            if let url = ChapterIllustrationCatalog.illustrationURL(chapter: chapter, variant: variant),
               let image = NSImage(contentsOfFile: url.path) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                fallback
            }
            #else
            fallback
            #endif
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .accessibilityLabel("\(chapter.displayName) — chapter illustration")
    }

    private var fallback: some View {
        ZStack {
            Color(.secondarySystemBackground)
            Image(systemName: "book.closed.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
        }
    }
}
