import Foundation
import SwiftData
import Models

/// Typed CRUD facade over ``ModelContext`` for VoiceTale's domain. Per
/// `@.claude/rules/swiftdata.md` § "ModelContext injection — Pass from view's
/// onAppear to ViewModel, NOT in init", each method takes the context as a
/// parameter so callers control the lifecycle.
///
/// Every save call uses a `do { try } catch` block (NOT silent `try?`) so
/// failures surface via ``DebugLog/data(_:_:error:)`` per
/// `@.claude/rules/debug-logging.md` § "Replace silent try? with logged catches".
@MainActor
public enum VoiceTaleStore {
    // MARK: - Tales

    /// Inserts a new tale + saves. Mood/anthology counters are updated atomically.
    public static func insertTale(
        _ entry: VoiceTaleEntry,
        audioFileRelativePath: String,
        in context: ModelContext
    ) throws {
        let payload = try JSONEncoder().encode(entry)
        let record = PersistentVoiceTaleEntry(
            id: entry.id,
            audioFileRelativePath: audioFileRelativePath,
            encodedMetadata: payload,
            recordedAt: entry.recordedAt
        )
        context.insert(record)
        try bumpMoodCounter(entry.mood, by: 1, at: entry.recordedAt, in: context)
        do {
            try context.save()
        } catch {
            DebugLog.data("VoiceTaleStore.insertTale — save failed", error: error)
            throw error
        }
    }

    /// Returns all tales sorted by `recordedAt` descending (newest first).
    /// Use `mood:` to filter the cache before view rendering.
    public static func fetchTales(
        mood: VoiceTaleMood? = nil,
        in context: ModelContext
    ) -> [VoiceTaleEntry] {
        var descriptor = FetchDescriptor<PersistentVoiceTaleEntry>(
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 500
        let records: [PersistentVoiceTaleEntry]
        do {
            records = try context.fetch(descriptor)
        } catch {
            DebugLog.data("VoiceTaleStore.fetchTales — fetch failed", error: error)
            return []
        }
        let decoded: [VoiceTaleEntry] = records.compactMap { record in
            do {
                return try JSONDecoder().decode(VoiceTaleEntry.self, from: record.encodedMetadata)
            } catch {
                DebugLog.data(
                    "VoiceTaleStore.fetchTales — decode failed for id=\(record.id)",
                    error: error
                )
                return nil
            }
        }
        if let mood {
            return decoded.filter { $0.mood == mood }
        }
        return decoded
    }

    /// Returns the on-disk audio file URL for ``taleID`` if the persistent
    /// record carries a `audioFileRelativePath`. The path is the bare
    /// filename — tales live under `<Documents>/Tales/<filename>.m4a`. Returns
    /// `nil` if the tale isn't found OR the relative path is empty (older
    /// records that pre-dated the audio-file capture path).
    public static func audioFileURL(for taleID: UUID, in context: ModelContext) -> URL? {
        let descriptor = FetchDescriptor<PersistentVoiceTaleEntry>(
            predicate: #Predicate { $0.id == taleID }
        )
        let record: PersistentVoiceTaleEntry?
        do {
            record = try context.fetch(descriptor).first
        } catch {
            DebugLog.data("VoiceTaleStore.audioFileURL — fetch failed", error: error)
            return nil
        }
        guard let relative = record?.audioFileRelativePath, !relative.isEmpty else {
            return nil
        }
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return docs
            .appendingPathComponent("Tales", isDirectory: true)
            .appendingPathComponent(relative)
    }

    public static func deleteTale(id: UUID, in context: ModelContext) {
        let descriptor = FetchDescriptor<PersistentVoiceTaleEntry>(
            predicate: #Predicate { $0.id == id }
        )
        let records: [PersistentVoiceTaleEntry]
        do {
            records = try context.fetch(descriptor)
        } catch {
            DebugLog.data("VoiceTaleStore.deleteTale — fetch failed", error: error)
            return
        }
        for record in records {
            if let decoded = try? JSONDecoder().decode(VoiceTaleEntry.self, from: record.encodedMetadata) {
                try? bumpMoodCounter(decoded.mood, by: -1, at: nil, in: context)
            }
            context.delete(record)
        }
        do {
            try context.save()
        } catch {
            DebugLog.data("VoiceTaleStore.deleteTale — save failed", error: error)
        }
    }

    // MARK: - Tradition exploration state

    public static func recordTraditionExplored(
        slug: String,
        at now: Date = Date(),
        in context: ModelContext
    ) {
        let entry = fetchTraditionRecord(slug: slug, in: context) ?? {
            let new = PersistentTraditionEntry(slug: slug, firstExploredAt: now)
            context.insert(new)
            return new
        }()
        if entry.firstExploredAt == nil {
            entry.firstExploredAt = now
        }
        entry.lastListenedAt = now
        entry.listenCount += 1
        do {
            try context.save()
        } catch {
            DebugLog.data("VoiceTaleStore.recordTraditionExplored — save failed", error: error)
        }
    }

    public static func fetchTraditionExploration(in context: ModelContext) -> [TraditionExploreData] {
        let descriptor = FetchDescriptor<PersistentTraditionEntry>(
            sortBy: [SortDescriptor(\.lastListenedAt, order: .reverse)]
        )
        let records: [PersistentTraditionEntry]
        do {
            records = try context.fetch(descriptor)
        } catch {
            DebugLog.data("VoiceTaleStore.fetchTraditionExploration — fetch failed", error: error)
            return []
        }
        return records.map {
            TraditionExploreData(
                slug: $0.slug,
                firstExploredAt: $0.firstExploredAt,
                lastListenedAt: $0.lastListenedAt,
                listenCount: $0.listenCount
            )
        }
    }

    // MARK: - Player progress

    /// Fetch-or-create the single player-progress row.
    public static func fetchOrCreateProgress(in context: ModelContext) -> PersistentPlayerProgress {
        let descriptor = FetchDescriptor<PersistentPlayerProgress>()
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let new = PersistentPlayerProgress()
        context.insert(new)
        do {
            try context.save()
        } catch {
            DebugLog.data("VoiceTaleStore.fetchOrCreateProgress — initial save failed", error: error)
        }
        return new
    }

    public static func progressSnapshot(in context: ModelContext) -> PlayerProgressData {
        let record = fetchOrCreateProgress(in: context)
        return PlayerProgressData(
            xpTotal: record.xpTotal,
            currentStreakDays: record.currentStreakDays,
            maxStreakDays: record.maxStreakDays,
            availableStreakFreezes: record.availableStreakFreezes,
            lastSessionAt: record.lastSessionAt,
            tutorialCompletedAt: record.tutorialCompletedAt,
            completedKitIDs: Set(record.completedKitIDsRaw)
        )
    }

    public static func updateProgress(
        _ mutate: (PersistentPlayerProgress) -> Void,
        in context: ModelContext
    ) {
        let record = fetchOrCreateProgress(in: context)
        mutate(record)
        do {
            try context.save()
        } catch {
            DebugLog.data("VoiceTaleStore.updateProgress — save failed", error: error)
        }
    }

    // MARK: - Anthology mood

    public static func fetchAnthologyMoods(in context: ModelContext) -> [AnthologyMoodData] {
        let descriptor = FetchDescriptor<PersistentAnthologyMood>()
        let records: [PersistentAnthologyMood]
        do {
            records = try context.fetch(descriptor)
        } catch {
            DebugLog.data("VoiceTaleStore.fetchAnthologyMoods — fetch failed", error: error)
            return []
        }
        return records.compactMap { record in
            guard let mood = VoiceTaleMood(rawValue: record.mood) else { return nil }
            return AnthologyMoodData(
                mood: mood,
                customLabel: record.customLabel,
                taleCount: record.taleCount,
                lastTaleAt: record.lastTaleAt
            )
        }
    }

    public static func setMoodCustomLabel(
        _ mood: VoiceTaleMood,
        label: String?,
        in context: ModelContext
    ) {
        let record = fetchOrCreateMoodRecord(mood, in: context)
        record.customLabel = (label?.isEmpty == true) ? nil : label
        do {
            try context.save()
        } catch {
            DebugLog.data("VoiceTaleStore.setMoodCustomLabel — save failed", error: error)
        }
    }

    // MARK: - Internals

    private static func fetchTraditionRecord(slug: String, in context: ModelContext) -> PersistentTraditionEntry? {
        let descriptor = FetchDescriptor<PersistentTraditionEntry>(
            predicate: #Predicate { $0.slug == slug }
        )
        return (try? context.fetch(descriptor))?.first
    }

    private static func fetchOrCreateMoodRecord(
        _ mood: VoiceTaleMood,
        in context: ModelContext
    ) -> PersistentAnthologyMood {
        let rawValue = mood.rawValue
        let descriptor = FetchDescriptor<PersistentAnthologyMood>(
            predicate: #Predicate { $0.mood == rawValue }
        )
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let new = PersistentAnthologyMood(mood: rawValue)
        context.insert(new)
        return new
    }

    private static func bumpMoodCounter(
        _ mood: VoiceTaleMood,
        by delta: Int,
        at timestamp: Date?,
        in context: ModelContext
    ) throws {
        let record = fetchOrCreateMoodRecord(mood, in: context)
        record.taleCount = max(0, record.taleCount + delta)
        if let timestamp, delta > 0 {
            record.lastTaleAt = timestamp
        }
    }
}
