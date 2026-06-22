import Testing
@testable import SharedUI
import Foundation

@Suite("BookCoverCatalog")
struct BookCoverCatalogTests {
    @Test func tierExposesStableIdentifier() {
        #expect(BookCoverCatalog.Tier.standard.id == "standard")
        #expect(BookCoverCatalog.Tier.advanced.id == "advanced")
    }

    @Test func tierMetadataIsKidAndParentReadable() {
        for tier in BookCoverCatalog.Tier.allCases {
            #expect(!tier.displayTitle.isEmpty)
            #expect(!tier.audienceLabel.isEmpty)
            #expect(!tier.description.isEmpty)
            // Tier description should reference register or one of the 4 cast
            // friends so the parent reads context, not boilerplate.
            let lower = tier.description.lowercased()
            let mentionsCast = lower.contains("lean") || lower.contains("slow")
                || lower.contains("pivot") || lower.contains("refrain")
                || lower.contains("register") || lower.contains("magic-tree-house")
                || lower.contains("wonder") || lower.contains("hatchet") || lower.contains("holes")
            #expect(mentionsCast, "Tier \(tier) description must reference cast/register: \(tier.description)")
        }
    }

    @Test func tierWebsitePathsAreDistinct() {
        #expect(BookCoverCatalog.Tier.standard.websitePath != BookCoverCatalog.Tier.advanced.websitePath)
        #expect(BookCoverCatalog.Tier.standard.websitePath.hasSuffix(".pdf"))
        #expect(BookCoverCatalog.Tier.advanced.websitePath.hasSuffix(".pdf"))
    }

    @Test func coverURLResolvesBothTiers() throws {
        // Both WebPs were copied into SharedUI/Resources/CustomArt/voicetale/
        // by the PR-2 surfacing step; the bundle must surface both via
        // BookCoverCatalog.coverURL(tier:).
        let standard = try #require(BookCoverCatalog.coverURL(tier: .standard))
        #expect(FileManager.default.fileExists(atPath: standard.path))
        #expect(standard.lastPathComponent == "cover_book_standard.webp")

        let advanced = try #require(BookCoverCatalog.coverURL(tier: .advanced))
        #expect(FileManager.default.fileExists(atPath: advanced.path))
        #expect(advanced.lastPathComponent == "cover_book_advanced.webp")
    }

    @Test func availableCoversListsBothInCanonicalOrder() throws {
        let covers = BookCoverCatalog.availableCovers()
        #expect(covers.count == 2)
        #expect(covers[0].tier == .standard)
        #expect(covers[1].tier == .advanced)
    }
}
