import Testing
import Foundation
@testable import AppFeature
import Models

@Suite("TaleTrialMachine")
struct TaleTrialMachineTests {
    @Test func initialStateUsesFirstCatalogPrompt() {
        let machine = TaleTrialMachine()
        #expect(machine.currentPrompt.slug == TaleTrialPromptCatalog.phase2.first?.slug)
        #expect(machine.playsThisSession == 0)
        #expect(machine.lastShuffledSlug == nil)
    }

    @Test func reshuffleNeverReturnsSameSlug() {
        // Run many shuffles against a seeded RNG; every transition's
        // resulting slug must differ from the prior one. 50 iterations is
        // overkill given the catalog has 8 entries but keeps the test
        // forgiving against future catalog growth.
        var machine = TaleTrialMachine()
        var rng = SeededRandom(seed: 12345)
        for _ in 0..<50 {
            let previous = machine.currentPrompt.slug
            machine.reshuffle(using: &rng)
            #expect(machine.currentPrompt.slug != previous,
                    "Reshuffle landed the same prompt back-to-back: \(previous)")
            #expect(machine.lastShuffledSlug == previous)
        }
    }

    @Test func recordPlayIncrementsCounter() {
        var machine = TaleTrialMachine()
        let p = machine.recordPlay()
        #expect(machine.playsThisSession == 1)
        #expect(p.slug == machine.currentPrompt.slug)
    }

    @Test func resetReturnsToInitialState() {
        var machine = TaleTrialMachine()
        var rng = SeededRandom(seed: 1)
        machine.reshuffle(using: &rng)
        _ = machine.recordPlay()
        machine.reset()
        #expect(machine.currentPrompt.slug == TaleTrialPromptCatalog.phase2.first?.slug)
        #expect(machine.playsThisSession == 0)
        #expect(machine.lastShuffledSlug == nil)
    }

    @Test func seededPromptIsDeterministicForSameSeed() {
        let a = TaleTrialMachine.seededPrompt(daySeed: 42)
        let b = TaleTrialMachine.seededPrompt(daySeed: 42)
        #expect(a == b)
    }

    @Test func seededPromptCoversCatalogAcrossDifferentSeeds() {
        let slugs = Set((0..<TaleTrialPromptCatalog.phase2.count).map {
            TaleTrialMachine.seededPrompt(daySeed: $0).slug
        })
        // The modulo-based seed maps every catalog index to exactly one
        // catalog entry over a `0..<count` range — so the resulting set
        // covers the entire catalog.
        #expect(slugs.count == TaleTrialPromptCatalog.phase2.count)
    }
}

/// Deterministic RNG for testing. Per `@.claude/rules/testing.md` § Crash
/// Resilience Defaults #3 — kept inside the test file so test fixtures
/// don't pollute the public ``Models`` / ``AppFeature`` surface.
private struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
