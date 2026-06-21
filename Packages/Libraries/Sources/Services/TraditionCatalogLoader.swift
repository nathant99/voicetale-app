import Foundation
import Models

/// Loads the bundled `traditions.json` from the `Services` target via
/// `Bundle.module`. Per `@.claude/rules/spm-architecture.md` § "Bundle.module
/// for resources".
public enum TraditionCatalogLoader {
    public enum LoaderError: Error, Sendable, Equatable {
        case resourceMissing
        case decodingFailed(String)
    }

    public static func loadBundled() throws -> TraditionCatalog {
        guard let url = ResourceLookup.url(
            forResource: "traditions",
            withExtension: "json",
            subdirectory: "Traditions"
        ) else {
            throw LoaderError.resourceMissing
        }
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode(TraditionCatalog.self, from: data)
        } catch {
            throw LoaderError.decodingFailed("\(error)")
        }
    }
}
