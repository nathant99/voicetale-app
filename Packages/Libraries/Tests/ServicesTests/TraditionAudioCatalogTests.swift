import Testing
import Foundation
@testable import Services
import Models

/// SCAFFOLD tests per `@Docs/HANDOFF_FROM_APP_TRADITION_AUDIO_SAMPLES.md`
/// — with ZERO audio CAFs bundled today, every resolver call returns nil.
/// These tests lock the scaffold so the moment labsmith ships the assets,
/// the resolver flips on cleanly without code change.
///
/// Conservative-hide pattern mirrors `TraditionUnlockEvaluator` PR #107.
@Suite("TraditionAudioCatalog scaffold")
struct TraditionAudioCatalogTests {
    // MARK: - resolveBundleURL(forFilename:) — conservative-fallback

    @Test func nilFilenameReturnsNil() {
        #expect(TraditionAudioCatalog.resolveBundleURL(forFilename: nil) == nil)
    }

    @Test func emptyFilenameReturnsNil() {
        #expect(TraditionAudioCatalog.resolveBundleURL(forFilename: "") == nil)
    }

    @Test func whitespaceOnlyFilenameReturnsNil() {
        // Defensive trim — a typo'd JSON like `"audioSampleFilename": "   "`
        // must NOT crash the gallery row OR render a half-broken play button.
        #expect(TraditionAudioCatalog.resolveBundleURL(forFilename: "   ") == nil)
        #expect(TraditionAudioCatalog.resolveBundleURL(forFilename: "\n\t") == nil)
    }

    @Test func unknownFilenameReturnsNil() {
        // Pre-asset-gen state: the filename looks plausible but the file
        // isn't bundled. Resolver returns nil; the gallery row hides the
        // play affordance — kid never sees a broken-when-tapped button.
        #expect(TraditionAudioCatalog.resolveBundleURL(forFilename: "audio/griot.caf") == nil)
        #expect(TraditionAudioCatalog.resolveBundleURL(forFilename: "audio/rakugo.caf") == nil)
        #expect(TraditionAudioCatalog.resolveBundleURL(forFilename: "audio/seanchai.caf") == nil)
    }

    @Test func unknownExtensionReturnsNil() {
        // Future asset waves may ship `.m4a` / `.aac` per audio-pipeline
        // rules. With zero of either bundled today, all return nil.
        #expect(TraditionAudioCatalog.resolveBundleURL(forFilename: "audio/griot.m4a") == nil)
        #expect(TraditionAudioCatalog.resolveBundleURL(forFilename: "audio/griot.aac") == nil)
    }

    @Test func bareFilenameWithoutPathReturnsNil() {
        // Defensive: filenames without a path segment (`griot.caf` vs
        // `audio/griot.caf`) also resolve cleanly — the resolver handles
        // both paths AND bare stems.
        #expect(TraditionAudioCatalog.resolveBundleURL(forFilename: "griot.caf") == nil)
        #expect(TraditionAudioCatalog.resolveBundleURL(forFilename: "griot") == nil)
    }

    // MARK: - Entry overload

    @Test func entryWithoutFilenameReturnsNil() {
        let entry = TraditionEntry(
            slug: "test",
            displayName: "Test",
            region: "Test region",
            summary: "Test summary",
            craftPrimitive: "test primitive",
            culturalCreditNote: "test credit",
            audioSampleFilename: nil
        )
        #expect(TraditionAudioCatalog.resolveBundleURL(for: entry) == nil)
        #expect(TraditionAudioCatalog.hasPlayableSample(for: entry) == false)
    }

    @Test func entryWithMissingFilenameReturnsNil() {
        // Entry advertises a filename but the asset isn't bundled yet.
        // Conservative-hide: gallery row treats as "no sample" rather
        // than rendering a play button that errors on tap.
        let entry = TraditionEntry(
            slug: "test",
            displayName: "Test",
            region: "Test region",
            summary: "Test summary",
            craftPrimitive: "test primitive",
            culturalCreditNote: "test credit",
            audioSampleFilename: "audio/missing.caf"
        )
        #expect(TraditionAudioCatalog.resolveBundleURL(for: entry) == nil)
        #expect(TraditionAudioCatalog.hasPlayableSample(for: entry) == false)
    }

    // MARK: - hasPlayableSample — UI gate

    @Test func hasPlayableSampleIsFalseForEveryShippedEntry() throws {
        // Every entry in the bundled traditions.json today has
        // `audioSampleFilename: null` (labsmith asset gen pending).
        // Lock this so the gallery row's play-affordance gate stays
        // inert until a CAF lands.
        let catalog = try TraditionCatalogLoader.loadBundled()
        for entry in catalog.entries {
            #expect(TraditionAudioCatalog.hasPlayableSample(for: entry) == false,
                    "entry \(entry.slug) unexpectedly has a playable sample")
        }
    }

    // MARK: - Pure-function callable from any actor

    @Test func resolverIsNonisolatedAndPure() {
        // Compile-time guard: calling from a nonisolated context succeeds
        // without an actor hop. If the resolver picked up MainActor
        // isolation accidentally (per the InferIsolatedConformances rule
        // in `.claude/rules/concurrency.md`) this would fail to compile.
        let url1 = TraditionAudioCatalog.resolveBundleURL(forFilename: "audio/griot.caf")
        let url2 = TraditionAudioCatalog.resolveBundleURL(forFilename: "audio/griot.caf")
        #expect(url1 == url2)  // pure — repeat calls return the same result
    }
}
