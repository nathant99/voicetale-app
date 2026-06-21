import Testing
import Foundation
@testable import Models

/// Tests for ``VoiceTaleCastDirectory`` + ``VoiceTaleGuestTellerCatalog``.
/// Codifies the load-bearing rules from
/// `@Docs/HANDOFF_FROM_LABSMITH_DN_ENHANCEMENT.md`:
///
/// - 7 characters total (1 hero + 4 LESSONS + 2 WORLD)
/// - Bramble is the only `.listener` role (listener-inversion)
/// - WORLD-layer chars are `.guestTeller` role with ≤3-line demo tales
/// - cluster-shared WORLD chars use the canonical `voice_epic` /
///   `voice_tragic` asset slugs (NOT a per-app slug)
/// - Bramble has no static catchphrase (FoundationModels-voiced)
@Suite("VoiceTaleCastDirectory")
struct VoiceTaleCastDirectoryTests {
    @Test func castHasSevenMembers() {
        #expect(VoiceTaleCastDirectory.allCharacters.count == 7)
    }

    @Test func brambleIsTheOnlyListenerAnchor() {
        let listeners = VoiceTaleCastDirectory.characters(in: .listener)
        #expect(listeners == [.bramble])
    }

    @Test func fourLessonsLayerListeners() {
        let lessons = VoiceTaleCastDirectory.characters(in: .lessons)
        let expected: Set<VoiceTaleCastDirectory.Character> = [.lean, .slow, .pivot, .refrain]
        #expect(Set(lessons) == expected)
        for character in lessons {
            #expect(character.role == .lessonsListener)
        }
    }

    @Test func twoWorldLayerGuestTellers() {
        let world = VoiceTaleCastDirectory.characters(in: .world)
        let expected: Set<VoiceTaleCastDirectory.Character> = [.heralda, .vesperline]
        #expect(Set(world) == expected)
        for character in world {
            #expect(character.role == .guestTeller)
        }
    }

    @Test func brambleHasNoStaticCatchphrase() {
        #expect(VoiceTaleCastDirectory.Character.bramble.catchphrase == nil)
    }

    @Test func everyNonBrambleCharacterHasACatchphrase() {
        for character in VoiceTaleCastDirectory.Character.allCases where character != .bramble {
            let phrase = character.catchphrase
            #expect(phrase?.isEmpty == false, "Missing catchphrase for \(character.rawValue)")
        }
    }

    @Test func worldLayerUsesClusterSharedAssetSlugs() {
        // Cluster-shared assets per HANDOFF_FROM_LABSMITH_DN_ENHANCEMENT § 3.4
        #expect(VoiceTaleCastDirectory.Character.heralda.assetSlug == "voice_epic")
        #expect(VoiceTaleCastDirectory.Character.vesperline.assetSlug == "voice_tragic")
    }

    @Test func brambleAppearsAtKitOne() {
        #expect(VoiceTaleCastDirectory.Character.bramble.firstKit == 1)
    }

    @Test func heraldaEntersAtKitThree() {
        // Per § 4.1 introduction schedule — Heralda's epic-bardic register
        // is the foundational sustained-rising-action exemplar (kit 3).
        #expect(VoiceTaleCastDirectory.Character.heralda.firstKit == 3)
    }

    @Test func vesperlineEntersAtKitNine() {
        // Per § 4.1 — Vesperline's tragic-pastoral register pairs with the
        // griot-tradition + mourning-songs kit.
        #expect(VoiceTaleCastDirectory.Character.vesperline.firstKit == 9)
    }
}

@Suite("VoiceTaleGuestTellerCatalog")
struct VoiceTaleGuestTellerCatalogTests {
    @Test func catalogShipsTwoTales() {
        #expect(VoiceTaleGuestTellerCatalog.all.count == 2)
    }

    @Test func everyDemoTaleStaysWithinThreeLines() {
        for tale in VoiceTaleGuestTellerCatalog.all {
            #expect(tale.lines.count <= 3,
                    "Demo tale for \(tale.character) exceeds 3-line cap per Pattern B + listener-inversion (HANDOFF_FROM_LABSMITH_DN_ENHANCEMENT § 3.1).")
        }
    }

    @Test func heraldaDemoTaleIsEpicRegister() {
        let tale = VoiceTaleGuestTellerCatalog.heralda
        #expect(tale.character == .heralda)
        #expect(tale.register.contains("Epic"))
        #expect(tale.firstFeaturedKit == 3)
    }

    @Test func vesperlineDemoTaleIsTragicRegister() {
        let tale = VoiceTaleGuestTellerCatalog.vesperline
        #expect(tale.character == .vesperline)
        #expect(tale.register.contains("Tragic"))
        #expect(tale.firstFeaturedKit == 9)
    }

    @Test func demoTaleLinesAreGenericStructuralRegisterNotTraditionSpecific() {
        // Per § 3.2 — demo-tale lines are GENERIC heroic/tragic register;
        // they reference no specific culture's hero-cycle or elegy tradition.
        let forbiddenCulturalMarkers = [
            // West African griot lineages
            "griot", "Mali", "Wolof",
            // Irish seanchaí lineages
            "seanchai", "Eire",
            // Japanese rakugo lineages
            "rakugo", "Edo", "Tokugawa",
            // Indigenous American oral-history lineages
            "Cherokee", "Lakota", "Navajo", "Diné",
            // Specific cultural deities
            "Zeus", "Odin", "Anansi",
        ]
        for tale in VoiceTaleGuestTellerCatalog.all {
            let joined = tale.lines.joined(separator: " ").lowercased()
            for marker in forbiddenCulturalMarkers {
                #expect(!joined.contains(marker.lowercased()),
                        "Demo tale for \(tale.character) references a specific tradition (\(marker)) — must stay structural register only per § 3.2.")
            }
        }
    }
}
