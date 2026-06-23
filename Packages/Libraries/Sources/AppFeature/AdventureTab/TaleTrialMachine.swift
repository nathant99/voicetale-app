import Foundation
import Models

/// Phase 2 Tale Trial state machine. Top-level `*Machine` struct per
/// `@.claude/rules/state-machines.md` § "*Machine Structs (Local View
/// State)". Pure value-type — no closures, no service refs.
///
/// The machine has three relevant pieces of state:
/// 1. `currentPrompt` — the prompt the kid is looking at (the surface of
///    the trial card)
/// 2. `lastShuffledSlug` — the previous prompt's slug, so reshuffle never
///    lands the same prompt twice in a row
/// 3. `playsThisSession` — count of "Tell this one" taps in the current
///    session; surfaces a kid-readable cadence indicator on the card
///    ("2 trials this session — Bramble's listening")
nonisolated public struct TaleTrialMachine: Sendable, Equatable {
    public var currentPrompt: TaleTrialPrompt
    public var lastShuffledSlug: String?
    public var playsThisSession: Int

    public init(
        currentPrompt: TaleTrialPrompt = TaleTrialPromptCatalog.phase2.first
            ?? TaleTrialPrompt(slug: "missing", text: ""),
        lastShuffledSlug: String? = nil,
        playsThisSession: Int = 0
    ) {
        self.currentPrompt = currentPrompt
        self.lastShuffledSlug = lastShuffledSlug
        self.playsThisSession = playsThisSession
    }

    public mutating func reset() {
        self = TaleTrialMachine()
    }

    /// Roll a fresh prompt that isn't the current one. Deterministic if a
    /// seed is supplied (used by tests + the perf-friendly init path);
    /// non-deterministic in production via the default `SystemRandomNumberGenerator`.
    public mutating func reshuffle<G: RandomNumberGenerator>(using rng: inout G) {
        let candidates = TaleTrialPromptCatalog.phase2
            .filter { $0.slug != currentPrompt.slug }
        guard candidates.isEmpty == false else { return }
        let pick = candidates.randomElement(using: &rng) ?? candidates[0]
        lastShuffledSlug = currentPrompt.slug
        currentPrompt = pick
    }

    public mutating func reshuffle() {
        var rng = SystemRandomNumberGenerator()
        reshuffle(using: &rng)
    }

    /// Records that the kid tapped "Tell this one" + returns the prompt
    /// to the caller so the analytics + persistence emission can use a
    /// consistent slug. The caller is responsible for bumping the
    /// persistent `taleTrialPlays` counter on the player progress row.
    public mutating func recordPlay() -> TaleTrialPrompt {
        playsThisSession += 1
        return currentPrompt
    }

    /// Pure-function helper used by the entry point to seed the initial
    /// prompt deterministically across cold launches within a single
    /// calendar day. Falls back to the first prompt if the catalog is
    /// empty (shouldn't happen in production — kept for safety).
    public static func seededPrompt(daySeed: Int) -> TaleTrialPrompt {
        let catalog = TaleTrialPromptCatalog.phase2
        guard catalog.isEmpty == false else {
            return TaleTrialPrompt(slug: "missing", text: "")
        }
        let safeIndex = abs(daySeed) % catalog.count
        return catalog[safeIndex]
    }
}
