import Combine
import Foundation

struct PerformanceMetric: Codable, Identifiable {
    let id: String
    let name: String
    let durationMilliseconds: Double
    let measuredAt: Date
}

@MainActor
final class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()

    @Published private(set) var metrics: [PerformanceMetric] = []

    private let storageKey = "performanceMetrics"
    private let maximumMetrics = 50

    private init() {
        load()
    }

    func record(name: String, duration: TimeInterval) {
        let metric = PerformanceMetric(
            id: UUID().uuidString,
            name: name,
            durationMilliseconds: max(0, duration * 1_000),
            measuredAt: .now
        )
        metrics.insert(metric, at: 0)
        metrics = Array(metrics.prefix(maximumMetrics))
        save()
    }

    func measure<T>(name: String, operation: () throws -> T) rethrows -> T {
        let start = Date()
        let result = try operation()
        record(name: name, duration: Date().timeIntervalSince(start))
        return result
    }

    func lastMetric(named name: String) -> PerformanceMetric? {
        metrics.first { $0.name == name }
    }

    func clear() {
        metrics = []
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        metrics = (try? decoder.decode([PerformanceMetric].self, from: data)) ?? []
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(metrics) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
