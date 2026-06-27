import Foundation
import Testing
@testable import Models

/// ForgeMasteryEngine Phase B TWENTIETH-round coalescing — invariants on
/// the pure-function ``KitMasteryBandLog``. The log is the single seam
/// between the `@AppStorage`-backed last-emitted band per kit and the
/// `kitMasteryAdvanced(kit:fromBand:toBand:)` analytics emission gate;
/// locking these invariants at the unit-test level guards the
/// anti-noise discipline (no redundant emissions when the kid's score
/// oscillates) AND the anti-defeat discipline (a corrupt JSON write
/// never permanently suppresses emissions).
@Suite("KitMasteryBandLog")
struct KitMasteryBandLogTests {

    // MARK: - Empty log behavior

    @Test
    func emptyLogHasNoLastBand() {
        let log = KitMasteryBandLog()
        #expect(log.lastBand(forKit: 1) == nil)
        #expect(log.lastBand(forKit: 9) == nil)
    }

    @Test
    func emptyLogAlwaysEmits() {
        // The first emission per kit per install has no prior log
        // entry — `shouldEmit` MUST return `true` so the kid sees the
        // initial band-crossing event.
        let log = KitMasteryBandLog()
        #expect(log.shouldEmit(forKit: 1, toBand: "emerging"))
        #expect(log.shouldEmit(forKit: 1, toBand: "developing"))
        #expect(log.shouldEmit(forKit: 5, toBand: "deepening"))
    }

    @Test
    func emptyLogEncodesToEmptyString() {
        // Anti-bloat: the @AppStorage default ("") MUST remain "" until
        // a real emission happens. Encoding an empty log to "{}" would
        // bloat the @AppStorage payload without surfacing useful state.
        let log = KitMasteryBandLog()
        #expect(log.encoded() == "")
    }

    // MARK: - JSON round-trip

    @Test
    func roundTripPreservesEntries() {
        let original = KitMasteryBandLog()
            .recording(forKit: 1, band: "developing")
            .recording(forKit: 3, band: "meeting")
            .recording(forKit: 7, band: "deepening")

        let json = original.encoded()
        #expect(!json.isEmpty)

        let decoded = KitMasteryBandLog(json: json)
        #expect(decoded.lastBand(forKit: 1) == "developing")
        #expect(decoded.lastBand(forKit: 3) == "meeting")
        #expect(decoded.lastBand(forKit: 7) == "deepening")
        #expect(decoded.lastBand(forKit: 2) == nil)
    }

    @Test
    func emptyStringDecodesToEmptyLog() {
        // @AppStorage default ("") MUST decode cleanly to an empty log
        // — first-launch / never-emitted state on every install.
        let log = KitMasteryBandLog(json: "")
        #expect(log.lastBand(forKit: 1) == nil)
        #expect(log.shouldEmit(forKit: 1, toBand: "developing"))
    }

    @Test
    func corruptJSONDegradesToEmptyLog() {
        // Anti-defeat: a corrupt @AppStorage write (e.g., a future
        // migration that changes the key shape, or a partial write)
        // MUST NOT permanently suppress emissions. The worst case is
        // a few one-time re-emissions on next launch.
        let corruptInputs = [
            "{",                          // malformed JSON
            "not json",                   // not JSON at all
            "[1, 2, 3]",                  // wrong shape (array)
            "{\"key\": null}",            // wrong value type (null)
            "{\"abc\": \"developing\"}",  // wrong key type (string instead of int)
        ]
        for input in corruptInputs {
            let log = KitMasteryBandLog(json: input)
            #expect(log.lastBand(forKit: 1) == nil, "Corrupt input \(input) should degrade to empty log")
            #expect(log.shouldEmit(forKit: 1, toBand: "developing"))
        }
    }

    // MARK: - shouldEmit invariants

    @Test
    func shouldEmitFalseWhenToBandMatchesLogged() {
        // Coalescing invariant: when the new toBand equals the logged
        // band for this kit, suppress emission. The kid's wire state
        // hasn't changed from what we last recorded.
        let log = KitMasteryBandLog().recording(forKit: 1, band: "developing")
        #expect(!log.shouldEmit(forKit: 1, toBand: "developing"))
    }

    @Test
    func shouldEmitTrueWhenToBandDiffersFromLogged() {
        // Forward progress: kid was at developing per log; new score
        // bands to meeting. Emit the `developing → meeting`
        // transition.
        let log = KitMasteryBandLog().recording(forKit: 1, band: "developing")
        #expect(log.shouldEmit(forKit: 1, toBand: "meeting"))
        #expect(log.shouldEmit(forKit: 1, toBand: "deepening"))
    }

    @Test
    func shouldEmitTrueOnRegressionFromLogged() {
        // The wire surface supports both directions — regressions are
        // a legitimate cohort signal. Kid was at meeting per log; new
        // score bands back to developing. Emit the regression.
        let log = KitMasteryBandLog().recording(forKit: 1, band: "meeting")
        #expect(log.shouldEmit(forKit: 1, toBand: "developing"))
        #expect(log.shouldEmit(forKit: 1, toBand: "emerging"))
    }

    @Test
    func shouldEmitIsKitScoped() {
        // The log is per-kit. A recording on kit 1 MUST NOT affect
        // kit 2's emission decisions — even when both kits would map
        // to the same toBand.
        let log = KitMasteryBandLog().recording(forKit: 1, band: "developing")
        #expect(!log.shouldEmit(forKit: 1, toBand: "developing"))
        #expect(log.shouldEmit(forKit: 2, toBand: "developing"))
        #expect(log.shouldEmit(forKit: 9, toBand: "developing"))
    }

    // MARK: - recording immutability

    @Test
    func recordingProducesNewLogWithUpdatedValue() {
        let original = KitMasteryBandLog()
        let updated = original.recording(forKit: 1, band: "developing")

        // Original is unchanged (value-type immutability).
        #expect(original.lastBand(forKit: 1) == nil)
        // Updated reflects the new value.
        #expect(updated.lastBand(forKit: 1) == "developing")
    }

    @Test
    func recordingOverwritesPriorValueForSameKit() {
        // Kid was at developing; new score lands them at deepening.
        // The recorded band for kit 1 becomes deepening, replacing
        // the prior developing.
        let log = KitMasteryBandLog()
            .recording(forKit: 1, band: "developing")
            .recording(forKit: 1, band: "deepening")
        #expect(log.lastBand(forKit: 1) == "deepening")
    }

    @Test
    func recordingPreservesOtherKits() {
        // Updating kit 1's last band MUST NOT touch kit 2's record.
        let log = KitMasteryBandLog()
            .recording(forKit: 1, band: "developing")
            .recording(forKit: 2, band: "meeting")
            .recording(forKit: 1, band: "deepening")
        #expect(log.lastBand(forKit: 1) == "deepening")
        #expect(log.lastBand(forKit: 2) == "meeting")
    }

    // MARK: - Oscillation suppression scenario

    @Test
    func oscillationScenarioSuppressesRedundantEmissions() {
        // End-to-end suppression scenario the rule was codified to
        // close: kid bounces around the developing/meeting boundary
        // across many attempts in a single session. The view-side
        // controller would consult `shouldEmit` before each emission;
        // the log absorbs the second + fourth redundant transitions.
        var log = KitMasteryBandLog()

        // Attempt 1: in-memory crossing emerging → developing. Log
        // has no prior — emit + record developing.
        #expect(log.shouldEmit(forKit: 1, toBand: "developing"))
        log = log.recording(forKit: 1, band: "developing")

        // Attempt 2: in-memory crossing developing → meeting. Log
        // has developing — emit + record meeting.
        #expect(log.shouldEmit(forKit: 1, toBand: "meeting"))
        log = log.recording(forKit: 1, band: "meeting")

        // Attempt 3: regression in-memory meeting → developing. Log
        // has meeting — different from developing — emit + record
        // developing (regressions are legitimate signal).
        #expect(log.shouldEmit(forKit: 1, toBand: "developing"))
        log = log.recording(forKit: 1, band: "developing")

        // Attempt 4: in-memory crossing developing → meeting AGAIN.
        // Log has developing — different from meeting — emit +
        // record meeting (the kid bouncing back IS a new transition
        // for cohort analysis).
        #expect(log.shouldEmit(forKit: 1, toBand: "meeting"))
        log = log.recording(forKit: 1, band: "meeting")

        // Attempt 5: in-memory wobble — score lands at the same
        // meeting band per the log. Suppress redundant emission.
        // This is the canonical noise case the rule closes: the
        // existing `fromBand != toBand` in-memory guard catches
        // some of this, but a subsequent attempt that nudges the
        // score from meeting-low to meeting-high without changing
        // bands wouldn't reach the log check; a future engine
        // change that broadens the in-memory check is also
        // protected here.
        #expect(!log.shouldEmit(forKit: 1, toBand: "meeting"))
    }

    // MARK: - Codable conformance

    @Test
    func codableRoundTripsCleanly() {
        // The type is `Codable` so future migrations (e.g., moving the
        // payload from @AppStorage to a SwiftData @Model column) can
        // round-trip the log without a custom adapter.
        let original = KitMasteryBandLog()
            .recording(forKit: 1, band: "developing")
            .recording(forKit: 5, band: "deepening")

        let data = try? JSONEncoder().encode(original)
        #expect(data != nil)
        guard let data else { return }

        let decoded = try? JSONDecoder().decode(KitMasteryBandLog.self, from: data)
        #expect(decoded != nil)
        guard let decoded else { return }
        #expect(decoded.lastBand(forKit: 1) == "developing")
        #expect(decoded.lastBand(forKit: 5) == "deepening")
    }
}
