import Foundation

/// Phase 1.1 voice-character preset catalog. Each preset describes a
/// pitch + rate transform applied to the kid's own recorded voice via
/// on-device DSP (`AVAudioUnitTimePitch` — wired in Phase 1.1 follow-on
/// PR). NO voice cloning, NO server-side processing — every transform is
/// strictly a tuning of the kid's existing recording.
///
/// Per `@Docs/FEATURE_PLAN.md` § Phase 1.1 — "Voice-Character Chooser":
/// 2-3 voice-character recordings; light pitch + timbre shift presets;
/// per-character voice picker for each beat. This PR lays the foundation
/// (types + catalog + display metadata); the follow-on PR wires
/// `AVAudioEngine` + `AVAudioUnitTimePitch` for actual processing and the
/// per-beat picker UI on the TellView.
public nonisolated enum VoiceCharacterPreset: String, Codable, Sendable, CaseIterable, Identifiable, Hashable {
    /// Natural baseline — no pitch / rate shift. The kid's voice as-is.
    case narrator
    /// Slightly higher + faster — playful hero register for the protagonist.
    case hero
    /// Deeper + slower — measured wise-elder register.
    case sage
    /// One octave higher + faster — chipmunk-like comedic sidekick.
    case sprite
    /// One octave lower + slower — heavy ogre or monster register.
    case ogre

    public nonisolated var id: String { rawValue }

    /// Kid-readable display name shown in the picker.
    public nonisolated var displayName: String {
        switch self {
        case .narrator: return "Narrator"
        case .hero:     return "Hero"
        case .sage:     return "Sage"
        case .sprite:   return "Sprite"
        case .ogre:     return "Ogre"
        }
    }

    /// SF Symbol shown beside the chip label. Selected purely for kid
    /// readability — these are not bound to ForgeKit / DN cast iconography.
    public nonisolated var symbolName: String {
        switch self {
        case .narrator: return "person.fill"
        case .hero:     return "shield.lefthalf.filled"
        case .sage:     return "books.vertical.fill"
        case .sprite:   return "sparkles"
        case .ogre:     return "tornado"
        }
    }

    /// One-line description used in tooltips + accessibility hints.
    public nonisolated var description: String {
        switch self {
        case .narrator: return "Your natural voice."
        case .hero:     return "A little higher and faster."
        case .sage:     return "Deeper and slower."
        case .sprite:   return "Squeaky and bright."
        case .ogre:     return "Deep and grumbly."
        }
    }

    /// Pitch shift in cents (semitones × 100). `AVAudioUnitTimePitch.pitch`
    /// accepts values in the range -2400 ... 2400. All Phase 1.1 presets
    /// stay safely inside that band.
    public nonisolated var pitchShiftCents: Int {
        switch self {
        case .narrator: return 0
        case .hero:     return 200
        case .sage:     return -300
        case .sprite:   return 800
        case .ogre:     return -800
        }
    }

    /// Playback rate multiplier. `AVAudioUnitTimePitch.rate` accepts values
    /// in the range 1/32 ... 32. We stay within roughly 0.85x ... 1.18x so
    /// the tale stays intelligible at every preset.
    public nonisolated var rate: Float {
        switch self {
        case .narrator: return 1.0
        case .hero:     return 1.05
        case .sage:     return 0.92
        case .sprite:   return 1.15
        case .ogre:     return 0.88
        }
    }
}

/// Static catalog of voice-character presets shipped in Phase 1.1. The
/// order here matches the UI picker order — narrator (default) lands left.
public nonisolated enum VoiceCharacterCatalog {
    /// Phase 1.1 preset ship list. 5 entries by design — small enough to
    /// fit on one row of the picker chip strip without horizontal scroll.
    public static let phase1: [VoiceCharacterPreset] = [
        .narrator,
        .hero,
        .sage,
        .sprite,
        .ogre,
    ]

    /// Resolve a slug to the matching preset, returning `.narrator` when
    /// the slug doesn't match (kid-safe default — natural voice).
    public nonisolated static func preset(forSlug slug: String) -> VoiceCharacterPreset {
        VoiceCharacterPreset(rawValue: slug) ?? .narrator
    }
}
