import Foundation
import Models

/// Pure-function resolver for the tradition-layer audio samples. Scaffold
/// surface per `@Docs/HANDOFF_FROM_APP_TRADITION_AUDIO_SAMPLES.md` —
/// labsmith asset gen for the 5 audio CAFs is pending; this resolver wires
/// the consumer side so the moment a CAF lands the play affordance lights
/// up without further code change.
///
/// Mirrors the easter-eggs Phase B pattern (`TraditionUnlockEvaluator` PR
/// #107): conservative-hide on missing input. A `nil` filename or a
/// filename pointing at a file that isn't bundled returns `nil` — the
/// caller (gallery row) gates the play affordance accordingly.
///
/// With ZERO audio CAFs bundled today (`traditions.json` ships
/// `audioSampleFilename: null` for all 5 entries), every call returns
/// `nil` so the wiring is inert. Tests lock the scaffold so the moment a
/// non-null filename lands, the resolver flips on cleanly.
nonisolated public enum TraditionAudioCatalog {
    /// Resolve a bundled audio sample to a file URL. Returns `nil` when:
    /// - The filename is `nil` (legacy / pre-asset-gen state)
    /// - The filename is non-empty but the file is missing from `Bundle.module`
    /// - The filename is whitespace-only (defensive)
    ///
    /// Pure-function + `nonisolated` per `@.claude/rules/concurrency.md`
    /// — can be invoked from any actor context. The bundle lookup itself
    /// is a `Bundle.module.url(forResource:withExtension:)` call which is
    /// safe off the main actor.
    public static func resolveBundleURL(forFilename filename: String?) -> URL? {
        guard let raw = filename?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty
        else { return nil }
        // Split the filename into base + extension so Bundle.module's
        // canonical (resource:withExtension:) lookup applies. The handoff
        // doc's expected shape is `audio/<slug>.caf`; future asset waves
        // may ship other extensions (e.g., `.m4a`) per portfolio audio-
        // pipeline rules.
        let url = URL(fileURLWithPath: raw)
        let ext = url.pathExtension                     // e.g. "caf"
        let stem = url.deletingPathExtension().path     // e.g. "audio/griot"
        let resource = ext.isEmpty ? raw : stem
        let lookupExt: String? = ext.isEmpty ? nil : ext
        return Bundle.module.url(forResource: resource, withExtension: lookupExt)
    }

    /// Convenience overload that takes a ``TraditionEntry`` and pulls the
    /// filename off it. Returns `nil` for entries without an audio
    /// sample.
    public static func resolveBundleURL(for entry: TraditionEntry) -> URL? {
        resolveBundleURL(forFilename: entry.audioSampleFilename)
    }

    /// True when the entry has both a non-nil filename + the file is
    /// actually present in the bundle. The gallery row should gate the
    /// play affordance on this so a typo'd filename never renders a
    /// broken-when-tapped play button.
    public static func hasPlayableSample(for entry: TraditionEntry) -> Bool {
        resolveBundleURL(for: entry) != nil
    }
}
