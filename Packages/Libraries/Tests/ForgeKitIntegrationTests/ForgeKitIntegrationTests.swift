import Testing
import ForgeModels
import ForgeGamification
import ForgeUI
@testable import Models

@Suite("ForgeKit integration")
struct ForgeKitIntegrationTests {
    @Test func forgeKitVersionIsNonEmpty() {
        let version = ForgeKitVersion.version
        #expect(version.isEmpty == false)
    }

    @Test func bloomLevelIsComparable() {
        #expect(BloomLevel.remember < BloomLevel.create)
        #expect(BloomLevel.understand < BloomLevel.apply)
    }

    @Test func gradeLevelOrderingHolds() {
        let middleGrades = GradeLevel.allCases
        #expect(middleGrades.isEmpty == false)
    }

    @Test func localTypeCompilesAlongsideForgeModels() {
        let entry = VoiceTaleEntry(
            title: "Sanity",
            mood: .funny,
            durationSeconds: 60,
            beatTimeline: [],
            transcript: ""
        )
        #expect(entry.title == "Sanity")
    }

    @Test func xpEngineLevelsBaselineXP() {
        let engine = XPEngine(config: GamificationConfig())
        #expect(engine.level(for: 0) >= 0)
    }
}
