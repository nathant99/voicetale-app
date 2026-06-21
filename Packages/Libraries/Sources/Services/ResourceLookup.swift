import Foundation

/// `Bundle.module.url(forResource:withExtension:subdirectory:)` is flaky for
/// SPM resource bundles processed via `.process("Resources")` — the API can
/// return `nil` even when the file is present at the expected path inside the
/// bundle (Xcode 26 / Swift 6.2 surface a regression here when the test
/// target runs the lookup). This helper resolves a bundled resource via
/// multiple strategies so loaders aren't at the mercy of the subdirectory
/// flag's quirks.
///
/// Resolution order:
/// 1. `Bundle.module.url(forResource:withExtension:subdirectory:)` (when
///    `subdirectory` is provided; the default Apple-recommended path).
/// 2. `Bundle.module.url(forResource:withExtension:)` (flat lookup —
///    SwiftPM's resource bundle sometimes flattens subdirectories).
/// 3. Direct path under `Bundle.module.resourceURL`'s subdirectory
///    (covers Xcode-26 SPM-bundle layout where the subdirectory is preserved
///    on disk but unreachable via the `subdirectory:` API).
enum ResourceLookup {
    static func url(
        forResource name: String,
        withExtension ext: String,
        subdirectory: String? = nil
    ) -> URL? {
        let bundle = Bundle.module

        if let subdirectory,
           let url = bundle.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
            return url
        }

        if let url = bundle.url(forResource: name, withExtension: ext) {
            return url
        }

        if let subdirectory,
           let resourceURL = bundle.resourceURL {
            let candidate = resourceURL
                .appendingPathComponent(subdirectory, isDirectory: true)
                .appendingPathComponent("\(name).\(ext)")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        return nil
    }
}
