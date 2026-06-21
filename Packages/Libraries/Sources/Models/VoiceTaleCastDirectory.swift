import Foundation

/// Canonical directory of every named character in VoiceTale's
/// distributed-narrative cast. Surfaces all three layers — HERO (Bramble),
/// LESSONS (Lean / Pivot / Refrain / Slow), and WORLD (Heralda / Vesperline)
/// — with explicit ``Layer`` + ``Role`` discriminators so views and Bramble's
/// reflection prompts can preserve VoiceTale's listener-inversion (Bramble
/// stays the protagonist-listener; the cast supports).
///
/// Per `@Docs/HANDOFF_FROM_LABSMITH_DN_ENHANCEMENT.md` § 3.5 (suggested Swift
/// API). The shape there is advisory; this implementation collapses the
/// `assetSlug` + `catchphrase` accessors into the case data so consumers can
/// pattern-match on `Layer` + `Role` without losing type-safety.
///
/// Cluster-shared WORLD-layer assets (Heralda + Vesperline) inherit from
/// LyricForge handoff #304; per-app VoiceTale marginal cost is $0. The
/// `.world` cases expose the canonical cluster-shared asset slugs
/// (`voice_epic` / `voice_tragic`) so `ForgeIllustrations` multi-bundle
/// resolution can find the WebPs when distributed via
/// `labsmith/scripts/copy_cluster_assets_to_repos.sh`.
public enum VoiceTaleCastDirectory {
    public nonisolated enum Layer: String, Sendable, CaseIterable, Hashable {
        case hero
        case lessons
        case world
    }

    public nonisolated enum Role: String, Sendable, CaseIterable, Hashable {
        /// The primary listener-anchor. Bramble is the only `.listener`.
        case listener
        /// LESSONS cast — listen alongside Bramble; each carries one
        /// craft-primitive recognition + reflection vocabulary.
        case lessonsListener
        /// WORLD cast — appear briefly to demonstrate a register, then exit.
        /// Listener-inversion preserved: guest tellers perform short demo
        /// tales (≤3 lines), then make space for the kid to tell.
        case guestTeller
    }

    public nonisolated enum Character: String, CaseIterable, Sendable, Hashable {
        // Hero / mentor
        case bramble

        // LESSONS layer (Wave 9, PRESERVED)
        case lean
        case slow
        case pivot
        case refrain

        // WORLD layer (cluster-shared, NEW)
        case heralda      // voice_epic
        case vesperline   // voice_tragic

        public var displayName: String {
            switch self {
            case .bramble:    return "Bramble"
            case .lean:       return "Lean"
            case .slow:       return "Slow"
            case .pivot:      return "Pivot"
            case .refrain:    return "Refrain"
            case .heralda:    return "Heralda the Loud"
            case .vesperline: return "Vesperline"
            }
        }

        public var layer: Layer {
            switch self {
            case .bramble:                                          return .hero
            case .lean, .slow, .pivot, .refrain:                    return .lessons
            case .heralda, .vesperline:                             return .world
            }
        }

        public var role: Role {
            switch self {
            case .bramble:                                          return .listener
            case .lean, .slow, .pivot, .refrain:                    return .lessonsListener
            case .heralda, .vesperline:                             return .guestTeller
            }
        }

        /// Canonical asset slug for `ForgeIllustrations` lookup. WORLD-layer
        /// chars use cluster-shared slugs (`voice_epic` / `voice_tragic`);
        /// LESSONS-layer chars use the local DN-S slug.
        public var assetSlug: String {
            switch self {
            case .bramble:    return "bramble"
            case .lean:       return "lean"
            case .slow:       return "slow"
            case .pivot:      return "pivot"
            case .refrain:    return "refrain"
            case .heralda:    return "voice_epic"
            case .vesperline: return "voice_tragic"
            }
        }

        /// Static catchphrase for non-Bramble cast. Bramble's voice is
        /// generated through FoundationModels (see `AIMentor.BrambleMentor`)
        /// and so has no static catchphrase.
        public var catchphrase: String? {
            switch self {
            case .bramble:    return nil
            case .lean:       return "Hook craft is making the listener lean."
            case .slow:       return "The body knows pacing."
            case .pivot:      return "The turn is the moment."
            case .refrain:    return "Say it once at the open. Again at the close."
            case .heralda:    return "And SO the great tale begins."
            case .vesperline: return "It was. And then it wasn't."
            }
        }

        /// Kit number where this character first appears (1-indexed across
        /// the 16-kit arc). Bramble appears in every kit.
        public var firstKit: Int {
            switch self {
            case .bramble:    return 1
            case .lean:       return 1
            case .slow:       return 4
            case .heralda:    return 3
            case .pivot:      return 7
            case .vesperline: return 9
            case .refrain:    return 10
            }
        }
    }

    /// All cast members in canonical order — Bramble first, then LESSONS
    /// (Wave-9 order), then WORLD (cluster-shared).
    public static var allCharacters: [Character] {
        [.bramble, .lean, .slow, .pivot, .refrain, .heralda, .vesperline]
    }

    /// Cast members for a given layer (in canonical order).
    public static func characters(in layer: Layer) -> [Character] {
        allCharacters.filter { $0.layer == layer }
    }

    /// Cast members for a given role (in canonical order).
    public static func characters(in role: Role) -> [Character] {
        allCharacters.filter { $0.role == role }
    }
}

/// Static demo-tale a WORLD-layer guest teller performs once, then exits.
/// Per `@Docs/HANDOFF_FROM_LABSMITH_DN_ENHANCEMENT.md` § 3.1 — Heralda + Vesperline
/// don't speak via FoundationModels; they appear with their static catchphrase
/// + a short scripted demo-tale (≤3 lines) so Bramble + the kid can listen.
///
/// `lines` capped at 3 (Pattern B + listener-inversion + "guest tellers
/// perform briefly so the kid can hear the register, then exit").
public nonisolated struct GuestTellerDemoTale: Sendable, Equatable {
    public let character: VoiceTaleCastDirectory.Character
    public let register: String        // e.g., "Epic / High Heroic"
    public let lines: [String]         // ≤ 3 lines; reads as a short performance
    public let firstFeaturedKit: Int   // kit where Bramble first plays this demo-tale

    public init(
        character: VoiceTaleCastDirectory.Character,
        register: String,
        lines: [String],
        firstFeaturedKit: Int
    ) {
        precondition(lines.count <= 3, "Guest-teller demo tales cap at 3 lines per Pattern B + listener-inversion (HANDOFF_FROM_LABSMITH_DN_ENHANCEMENT § 3.1).")
        precondition(character.role == .guestTeller, "Only WORLD-layer guest tellers ship demo tales.")
        self.character = character
        self.register = register
        self.lines = lines
        self.firstFeaturedKit = firstFeaturedKit
    }
}

/// Canonical demo-tale catalog for the 2 WORLD-layer guest tellers. Lines
/// are GENERIC structural-register exemplars (NOT specific cultural tradition
/// content) per § 3.2 (cultural-sensitivity gate preserved + extended).
public enum VoiceTaleGuestTellerCatalog {
    public static let heralda = GuestTellerDemoTale(
        character: .heralda,
        register: "Epic / High Heroic",
        lines: [
            "AND SO the great storm came over the hills.",
            "The villagers gathered at the gate, waiting for the one who knew the old words.",
            "The hero stepped forward, and the storm grew quiet to listen.",
        ],
        firstFeaturedKit: 3
    )

    public static let vesperline = GuestTellerDemoTale(
        character: .vesperline,
        register: "Tragic / Pastoral",
        lines: [
            "It was a small lantern, the kind that burns out by morning.",
            "It was. And then it wasn't.",
            "We walked home in the dark, and the dark was full of what we had loved.",
        ],
        firstFeaturedKit: 9
    )

    public static var all: [GuestTellerDemoTale] {
        [heralda, vesperline]
    }
}
