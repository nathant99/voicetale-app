import Testing
@testable import SharedUI
import Foundation

@Suite("MascotPoseCatalog")
struct MascotPoseCatalogTests {
    @Test func poseExposesStableIdentifier() {
        #expect(MascotPoseCatalog.Pose.thinking.id == "thinking")
        #expect(MascotPoseCatalog.Pose.working.id == "working")
        #expect(MascotPoseCatalog.Pose.demonstrating.id == "demonstrating")
        #expect(MascotPoseCatalog.Pose.encouraging.id == "encouraging")
        #expect(MascotPoseCatalog.Pose.praising.id == "praising")
    }

    @Test func poseFileNameFollowsBrambleConvention() {
        // Per `.claude/rules/forgekit.md` § "Cast asset filename convention",
        // mascot files use `<mascot>_<pose>.webp` — the catalog must spell that
        // out so future renames are localized to this one method.
        for pose in MascotPoseCatalog.Pose.allCases {
            #expect(pose.fileName == "bramble_\(pose.rawValue)")
            #expect(!pose.fileName.contains(" "))
            #expect(pose.fileName == pose.fileName.lowercased())
        }
    }

    @Test func accessibilityDescriptionIsKidReadable() {
        for pose in MascotPoseCatalog.Pose.allCases {
            #expect(!pose.accessibilityDescription.isEmpty)
            // Kid-readable register — every description should mention Bramble
            // by name so screen-reader users hear who's on screen, not just
            // "Image."
            #expect(pose.accessibilityDescription.contains("Bramble"))
        }
    }

    @Test func poseURLResolvesAllFivePoses() throws {
        for pose in MascotPoseCatalog.Pose.allCases {
            let url = try #require(
                MascotPoseCatalog.poseURL(for: pose),
                "Missing mascot WebP for pose \(pose.rawValue) — verify Resources/Illustrations/mascots/bramble_\(pose.rawValue).webp landed in the SharedUI bundle"
            )
            #expect(FileManager.default.fileExists(atPath: url.path))
            #expect(url.lastPathComponent == "bramble_\(pose.rawValue).webp")
        }
    }

    @Test func availablePosesListsAllFiveInCanonicalOrder() throws {
        let poses = MascotPoseCatalog.availablePoses()
        #expect(poses.count == 5)
        #expect(poses[0].pose == .thinking)
        #expect(poses[1].pose == .working)
        #expect(poses[2].pose == .demonstrating)
        #expect(poses[3].pose == .encouraging)
        #expect(poses[4].pose == .praising)
    }
}
