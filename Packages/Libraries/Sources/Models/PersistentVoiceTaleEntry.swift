import Foundation
import SwiftData

/// Persistent record of a told tale. Audio lives on disk under the relative
/// path; metadata (title, mood, beat timeline, transcript, reflection) is
/// JSON-encoded into ``encodedMetadata``. The shape of the decoded payload is
/// ``VoiceTaleEntry`` in this target.
@Model
public final class PersistentVoiceTaleEntry {
    public var id: UUID = UUID()
    public var audioFileRelativePath: String = ""
    public var encodedMetadata: Data = Data()
    public var recordedAt: Date = Date.distantPast

    public init(
        id: UUID = UUID(),
        audioFileRelativePath: String = "",
        encodedMetadata: Data = Data(),
        recordedAt: Date = Date()
    ) {
        self.id = id
        self.audioFileRelativePath = audioFileRelativePath
        self.encodedMetadata = encodedMetadata
        self.recordedAt = recordedAt
    }
}
