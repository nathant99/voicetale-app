import Foundation
import SwiftData

@Model
public final class PersistentVoiceTaleEntry {
    public var id: UUID = UUID()
    public var audioFileRelativePath: String = ""
    public var encodedMetadata: Data = Data()

    public init(
        id: UUID = UUID(),
        audioFileRelativePath: String = "",
        encodedMetadata: Data = Data()
    ) {
        self.id = id
        self.audioFileRelativePath = audioFileRelativePath
        self.encodedMetadata = encodedMetadata
    }
}

public enum VoiceTaleSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [PersistentVoiceTaleEntry.self]
    }
}
