import Foundation
import Models

/// Loads VoiceTale's bundled companion-pack assets from
/// `Services/Resources/CompanionPack/` via `Bundle.module`. The PDFs at
/// `Resources/CompanionPack/` at repo root are the labsmith-authoring
/// source; a per-build copy lives in the SPM target so it ships inside the
/// app binary without an Xcode-UI bundling step.
public enum CompanionPackLoader {
    public enum LoaderError: Error, Sendable, Equatable {
        case manifestMissing
        case manifestDecodeFailed(String)
        case pdfMissing(String)
    }

    public static func loadManifest() throws -> CompanionPackManifest {
        guard let url = Bundle.module.url(
            forResource: "companion_pack",
            withExtension: "json",
            subdirectory: "CompanionPack"
        ) else {
            throw LoaderError.manifestMissing
        }
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode(CompanionPackManifest.self, from: data)
        } catch {
            throw LoaderError.manifestDecodeFailed("\(error)")
        }
    }

    public static func url(forPDF fileName: String) throws -> URL {
        // Bundle.module.url(forResource:withExtension:) wants name without
        // extension. The manifest uses canonical `<name>.pdf` filenames.
        let stem = (fileName as NSString).deletingPathExtension
        guard let url = Bundle.module.url(
            forResource: stem,
            withExtension: "pdf",
            subdirectory: "CompanionPack"
        ) else {
            throw LoaderError.pdfMissing(fileName)
        }
        return url
    }

    /// Builds the UI-ready entry list by joining the manifest's `pdfs` array
    /// with the static known-entry mapping in
    /// ``CompanionPackPDF/knownEntries``. PDFs the loader doesn't know about
    /// are silently skipped — the manifest is allowed to evolve without
    /// requiring an app rev.
    public static func loadEntries() throws -> [CompanionPackPDF] {
        let manifest = try loadManifest()
        return manifest.pdfs.compactMap { CompanionPackPDF.knownEntries[$0] }
    }
}
