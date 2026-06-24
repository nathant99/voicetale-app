import Foundation
import Testing
@testable import Models

/// Coverage for the published-tale-certificate Phase Delight & Polish
/// carry-over shipped in PR-F of the 2026-06-24 NINTH-round wire-up.
/// Locks the pure-function ``PublishedTaleCertificate/compose(from:)``
/// composition + the mood × beat-count headline matrix + the anti-shame
/// copy contract (the headline never names shame tokens regardless of
/// beat count).
///
/// Per @Docs/FEATURE_PLAN.md § Phase Delight & Polish — Share-worthy
/// moments — published-tale certificates carry-over.
@Suite("PublishedTaleCertificate")
struct PublishedTaleCertificateTests {

    // MARK: - compose(from:) — happy path

    @Test func composeYieldsKidReadableComposition() {
        let tale = makeTale(
            title: "Grandma's biscuit recipe",
            mood: .tender,
            inToleranceCount: 5
        )
        let cert = PublishedTaleCertificate.compose(
            from: tale,
            locale: Locale(identifier: "en_US"),
            calendar: Calendar(identifier: .gregorian)
        )
        #expect(cert.title == "Grandma's biscuit recipe")
        #expect(cert.moodLabel == "Tender")
        #expect(cert.beatBadge == "5 of 5 beats")
        #expect(cert.dateLabel.isEmpty == false)
        #expect(cert.headline.isEmpty == false)
    }

    @Test func composeHonorsShortTales() {
        // A 3-of-5-beats tale must still get a complete certificate.
        // The beat badge names the kid-completed count without framing
        // anything as missed.
        let tale = makeTale(title: "Half tale", mood: .funny, inToleranceCount: 3)
        let cert = PublishedTaleCertificate.compose(from: tale)
        #expect(cert.beatBadge == "3 of 5 beats")
        #expect(cert.headline.isEmpty == false)
    }

    @Test func composeHandlesEmptyTimelineDefensively() {
        let tale = VoiceTaleEntry(
            title: "Empty timeline",
            mood: .wild,
            durationSeconds: 30,
            beatTimeline: [],
            transcript: "transcript"
        )
        let cert = PublishedTaleCertificate.compose(from: tale)
        // The beat badge falls back to a kid-readable placeholder so
        // we never render "0 of 0 beats" (which reads as a deficiency).
        #expect(cert.beatBadge == "Held tale")
    }

    // MARK: - Headline matrix — mood × beat-count

    @Test func headlineForFiveBeatsNamesArc() {
        // Every mood's 5-beat headline names "hook through close" —
        // the kid held the arc.
        for mood in VoiceTaleMood.allCases {
            let headline = PublishedTaleCertificate.headline(forMood: mood, inToleranceBeats: 5)
            #expect(headline.contains("hook through close"),
                    "expected hook-through-close framing for \(mood); got: \(headline)")
        }
    }

    @Test func headlineForShortTalesNamesTheCraftNotTheMiss() {
        // Every mood's < 5-beat headline names the craft the kid
        // exercised ("takes timing" / "takes nerve" / "takes care" /
        // "takes voice"). The kid told something — that's what the
        // copy recognizes.
        let expectedTokens: [VoiceTaleMood: String] = [
            .funny:  "timing",
            .scary:  "nerve",
            .tender: "care",
            .wild:   "voice",
        ]
        for (mood, token) in expectedTokens {
            let headline = PublishedTaleCertificate.headline(forMood: mood, inToleranceBeats: 3)
            #expect(headline.lowercased().contains(token),
                    "expected \(mood) headline to contain craft token '\(token)'; got: \(headline)")
        }
    }

    // MARK: - Anti-shame contract

    @Test func headlineNeverNamesShameTokens() {
        // Identical to the established Bramble-register anti-shame
        // guard: no shame tokens in any branch of the matrix.
        let stopList: [String] = [
            "broke", "fail", "lost", "lazy", "missed", "should", "didn't",
            "no tale", "incomplete", "not enough", "deficient", "barely"
        ]
        for mood in VoiceTaleMood.allCases {
            for beatCount in [0, 1, 2, 3, 4, 5] {
                let headline = PublishedTaleCertificate.headline(
                    forMood: mood, inToleranceBeats: beatCount
                )
                let lowered = headline.lowercased()
                for token in stopList {
                    #expect(lowered.contains(token) == false,
                            "shame token '\(token)' in headline for mood=\(mood) beats=\(beatCount): \(headline)")
                }
            }
        }
    }

    @Test func headlineIsNonEmptyForEveryMoodAndBeatCount() {
        for mood in VoiceTaleMood.allCases {
            for beatCount in 0...5 {
                let headline = PublishedTaleCertificate.headline(
                    forMood: mood, inToleranceBeats: beatCount
                )
                #expect(headline.isEmpty == false,
                        "empty headline for mood=\(mood) beats=\(beatCount)")
            }
        }
    }

    // MARK: - Deterministic date formatting

    @Test func dateLabelIsLocaleDeterministicForFixedDate() {
        // Locked locale + calendar + a stable date → stable label.
        // Useful when the certificate is rasterized via ImageRenderer
        // and the kid saves to Photos: the date in the saved image
        // matches the date shown at compose time.
        let fixedDate = Date(timeIntervalSince1970: 1_780_000_000)  // 2026-06-21
        let tale = VoiceTaleEntry(
            title: "Fixed date tale",
            mood: .funny,
            recordedAt: fixedDate,
            durationSeconds: 60,
            beatTimeline: makeBeats(inToleranceCount: 5),
            transcript: "transcript"
        )
        let cert = PublishedTaleCertificate.compose(
            from: tale,
            locale: Locale(identifier: "en_US"),
            calendar: Calendar(identifier: .gregorian)
        )
        // en_US long style → "Month Day, Year" form.
        #expect(cert.dateLabel.contains("2026"))
    }

    // MARK: - Helpers

    private func makeTale(
        title: String,
        mood: VoiceTaleMood,
        inToleranceCount: Int
    ) -> VoiceTaleEntry {
        VoiceTaleEntry(
            title: title,
            mood: mood,
            durationSeconds: 90,
            beatTimeline: makeBeats(inToleranceCount: inToleranceCount),
            transcript: "transcript"
        )
    }

    private func makeBeats(inToleranceCount: Int) -> [BeatSegment] {
        let beats: [ArcBeat] = [.hook, .setup, .rising, .turn, .close]
        return beats.enumerated().map { idx, beat in
            // First `inToleranceCount` beats are in tolerance
            // (actual == target); the rest are out of tolerance
            // (actual = target * 2).
            let target = beat.targetSeconds
            let actual = idx < inToleranceCount ? target : target * 2
            return BeatSegment(
                beat: beat,
                targetSeconds: target,
                actualSeconds: actual,
                tolerance: 0.20
            )
        }
    }
}
