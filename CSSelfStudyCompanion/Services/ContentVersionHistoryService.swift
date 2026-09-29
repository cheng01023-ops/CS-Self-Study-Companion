import Foundation

struct ContentVersionEntry: Codable, Identifiable {
    let id: String
    let version: String
    let updatedAt: Date
    let summary: String
}

enum ContentVersionHistoryService {
    static let storageKey = "coursePackVersionHistory"

    static func load(from defaults: UserDefaults = .standard) -> [ContentVersionEntry] {
        guard let data = defaults.data(forKey: storageKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([ContentVersionEntry].self, from: data)) ?? []
    }

    static func record(
        version: String,
        summary: String,
        updatedAt: Date = .now,
        defaults: UserDefaults = .standard
    ) {
        var entries = load(from: defaults)
        entries.removeAll { $0.version == version }
        entries.insert(
            ContentVersionEntry(
                id: UUID().uuidString,
                version: version,
                updatedAt: updatedAt,
                summary: summary
            ),
            at: 0
        )
        entries = Array(entries.prefix(20))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(entries) {
            defaults.set(data, forKey: storageKey)
        }
    }

    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: storageKey)
    }
}
