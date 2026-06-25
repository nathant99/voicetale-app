import Foundation

/// Per-tale context carrying the signal "this tale was started from a
/// deeper-challenge affordance on an Adventure mode-card" through the
/// recording → review → reflect flow. Closes the threading half of
/// `@Docs/PLAN_FORGEMASTERY_INTEGRATION.md` § Phase D second-half so
/// ``AIMentor/BrambleMentor`` can route the reflection through the
/// catalog-sourced "I noticed you went deeper there" register without
/// the recording flow growing a new state-machine surface.
///
/// Pure value-type per `@.claude/rules/state-machines.md` § "Pure value
/// types — automatically `Sendable`". The default is ``none`` so every
/// existing flow (Tell-tab idle start, Tale Trial, Adventure card pre-
/// affordance) carries the zero-signal value through unchanged.
///
/// `nonisolated public struct` per `@.claude/rules/spm-architecture.md`
/// § "`nonisolated` required on public value types in SPM packages with
/// default MainActor" so the value type round-trips cleanly across the
/// AppFeature ⇄ AIMentor ⇄ Services boundary.
public nonisolated struct TaleRecordingContext: Sendable, Equatable, Hashable {
    /// The dominant kit that surfaced the deeper-challenge affordance,
    /// or `nil` when the tale wasn't started from a deeper-challenge
    /// pill. The kit is the canonical seam Bramble uses to source the
    /// catalog opener line (per ``Models/KitMasteryCopyCatalog`` `.deeperChallengeOpener`
    /// kind shipped in the same round).
    public let deeperChallengeKit: KitID?

    public init(deeperChallengeKit: KitID? = nil) {
        self.deeperChallengeKit = deeperChallengeKit
    }

    /// The canonical "no signal" value. Every flow that doesn't route
    /// through the deeper-challenge affordance reads this. Equal to
    /// `TaleRecordingContext()` — distinct from `nil` because callers
    /// want a non-optional default (avoids three-state confusion
    /// between `.none` / `.some(.none)` / `.some(.kit)`).
    public static let none = TaleRecordingContext(deeperChallengeKit: nil)

    /// Convenience predicate the prompt-builder + analytics callers
    /// read. True iff the tale was started from a deeper-challenge
    /// affordance + the kit is non-nil.
    public var isDeeperChallenge: Bool {
        deeperChallengeKit != nil
    }
}
