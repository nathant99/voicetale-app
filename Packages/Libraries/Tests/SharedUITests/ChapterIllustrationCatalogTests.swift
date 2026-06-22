import Testing
@testable import SharedUI
import Foundation

@Suite("ChapterIllustrationCatalog")
struct ChapterIllustrationCatalogTests {
    @Test func chapterExposesStableIdentifier() {
        #expect(ChapterIllustrationCatalog.Chapter.lean.id == "lean")
        #expect(ChapterIllustrationCatalog.Chapter.pivot.id == "pivot")
        #expect(ChapterIllustrationCatalog.Chapter.refrain.id == "refrain")
        #expect(ChapterIllustrationCatalog.Chapter.slow.id == "slow")
    }

    @Test func chapterCraftPrimitiveSurfacesRegister() {
        // Each chapter's craft-primitive sentence must surface the
        // distinguishing word from the Voicetale DN cast spec — Lean = HOOK,
        // Pivot = TURN, Refrain = CALLBACK, Slow = PACING. This guards
        // against drift if the strings are edited.
        let lean = ChapterIllustrationCatalog.Chapter.lean.craftPrimitive.lowercased()
        #expect(lean.contains("hook") || lean.contains("tip forward"))

        let pivot = ChapterIllustrationCatalog.Chapter.pivot.craftPrimitive.lowercased()
        #expect(pivot.contains("rotates") || pivot.contains("turn"))

        let refrain = ChapterIllustrationCatalog.Chapter.refrain.craftPrimitive.lowercased()
        #expect(refrain.contains("phrase") || refrain.contains("callback") || refrain.contains("same words"))

        let slow = ChapterIllustrationCatalog.Chapter.slow.craftPrimitive.lowercased()
        #expect(slow.contains("pacing") || slow.contains("tempo"))
    }

    @Test func fileNameFollowsChapterVariantConvention() {
        #expect(
            ChapterIllustrationCatalog.fileName(chapter: .lean, variant: .opener) == "chapter_lean_opener"
        )
        #expect(
            ChapterIllustrationCatalog.fileName(chapter: .refrain, variant: .spot) == "chapter_refrain_spot"
        )
    }

    @Test func illustrationURLResolvesAllEightVariants() throws {
        for chapter in ChapterIllustrationCatalog.Chapter.allCases {
            for variant in ChapterIllustrationCatalog.Variant.allCases {
                let url = try #require(
                    ChapterIllustrationCatalog.illustrationURL(chapter: chapter, variant: variant),
                    "Missing chapter WebP for \(chapter.rawValue)/\(variant.rawValue) — verify Resources/Illustrations/chapters/chapter_\(chapter.rawValue)_\(variant.rawValue).webp landed in the SharedUI bundle"
                )
                #expect(FileManager.default.fileExists(atPath: url.path))
                #expect(
                    url.lastPathComponent == "chapter_\(chapter.rawValue)_\(variant.rawValue).webp"
                )
            }
        }
    }

    @Test func availableIllustrationsListsAllEightInCanonicalOrder() throws {
        let illustrations = ChapterIllustrationCatalog.availableIllustrations()
        #expect(illustrations.count == 8)
        // Canonical order: chapter × variant. Lean opener / Lean spot /
        // Pivot opener / Pivot spot / ... per allCases interleaving.
        #expect(illustrations[0].chapter == .lean && illustrations[0].variant == .opener)
        #expect(illustrations[1].chapter == .lean && illustrations[1].variant == .spot)
        #expect(illustrations[2].chapter == .pivot && illustrations[2].variant == .opener)
        #expect(illustrations[3].chapter == .pivot && illustrations[3].variant == .spot)
        #expect(illustrations[6].chapter == .slow && illustrations[6].variant == .opener)
        #expect(illustrations[7].chapter == .slow && illustrations[7].variant == .spot)
    }
}
