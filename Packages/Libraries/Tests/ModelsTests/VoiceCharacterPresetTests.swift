import Testing
@testable import Models

@Suite("VoiceCharacterPreset")
struct VoiceCharacterPresetTests {
    @Test func phase1CatalogShipsExpectedPresets() {
        let presets = VoiceCharacterCatalog.phase1
        #expect(presets.count == 5)
        let slugs = Set(presets.map(\.rawValue))
        #expect(slugs == ["narrator", "hero", "sage", "sprite", "ogre"])
    }

    @Test func narratorIsTheNeutralBaseline() {
        let preset: VoiceCharacterPreset = .narrator
        #expect(preset.pitchShiftCents == 0)
        #expect(preset.rate == 1.0)
        #expect(preset.displayName.isEmpty == false)
        #expect(preset.description.isEmpty == false)
    }

    @Test func pitchShiftStaysInsideAVAudioUnitTimePitchSafeRange() {
        // AVAudioUnitTimePitch accepts pitch values in -2400 ... 2400 cents.
        // Every preset MUST stay strictly inside that band so the engine
        // never has to clip a configured value at process time.
        for preset in VoiceCharacterCatalog.phase1 {
            #expect(preset.pitchShiftCents >= -2400,
                    "Preset \(preset.rawValue) pitch below -2400 cents")
            #expect(preset.pitchShiftCents <= 2400,
                    "Preset \(preset.rawValue) pitch above 2400 cents")
        }
    }

    @Test func rateStaysInsideIntelligibleRange() {
        // AVAudioUnitTimePitch accepts rate 1/32 ... 32, but we cap our
        // presets to 0.85 ... 1.18 so the tale stays intelligible at
        // every preset (per Phase 1.1 design — no chipmunk-illegibility).
        for preset in VoiceCharacterCatalog.phase1 {
            #expect(preset.rate >= 0.85,
                    "Preset \(preset.rawValue) rate below 0.85")
            #expect(preset.rate <= 1.18,
                    "Preset \(preset.rawValue) rate above 1.18")
        }
    }

    @Test func everyPresetHasUniqueTuning() {
        let tunings = VoiceCharacterCatalog.phase1.map { "\($0.pitchShiftCents):\($0.rate)" }
        let unique = Set(tunings)
        #expect(tunings.count == unique.count,
                "Two presets share the same (pitch, rate) — that defeats the picker.")
    }

    @Test func everyPresetHasDistinctDisplayNameAndSymbol() {
        let names = Set(VoiceCharacterCatalog.phase1.map(\.displayName))
        let symbols = Set(VoiceCharacterCatalog.phase1.map(\.symbolName))
        #expect(names.count == VoiceCharacterCatalog.phase1.count)
        #expect(symbols.count == VoiceCharacterCatalog.phase1.count)
    }

    @Test func slugLookupRoundTrips() {
        for preset in VoiceCharacterCatalog.phase1 {
            #expect(VoiceCharacterCatalog.preset(forSlug: preset.rawValue) == preset)
        }
    }

    @Test func unknownSlugFallsBackToNarrator() {
        #expect(VoiceCharacterCatalog.preset(forSlug: "not-a-real-preset") == .narrator)
        #expect(VoiceCharacterCatalog.preset(forSlug: "") == .narrator)
    }
}
