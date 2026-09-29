import Combine
import Foundation
import SwiftData

@MainActor
final class AppDataStore: ObservableObject {
    @Published private(set) var container: ModelContainer?
    @Published private(set) var errorMessage: String?
    @Published private(set) var backupURL: URL?
    @Published private(set) var isWorking = false

    private let applicationSupportURL: URL

    init(applicationSupportURL: URL? = nil) {
        self.applicationSupportURL = applicationSupportURL
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        open()
    }

    func open() {
        let schema = Schema(versionedSchema: AppSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema)

        let start = Date()
        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [configuration]
            )
            errorMessage = nil
            PerformanceMonitor.shared.record(
                name: "数据库打开",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            container = nil
            errorMessage = error.localizedDescription
            backupURL = try? Self.backupStoreFiles(
                in: applicationSupportURL,
                reason: "open-failure"
            )
        }
    }

    func resetStore() {
        isWorking = true
        defer { isWorking = false }

        backupURL = try? Self.backupStoreFiles(
            in: applicationSupportURL,
            reason: "reset"
        )
        Self.removeStoreFiles(in: applicationSupportURL)
        open()
    }

    static func backupStoreFiles(
        in directory: URL,
        reason: String
    ) throws -> URL {
        let fileManager = FileManager.default
        let storeURL = directory.appendingPathComponent("default.store")
        let sidecarURLs = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-wal"),
            URL(fileURLWithPath: storeURL.path + "-shm")
        ].filter { fileManager.fileExists(atPath: $0.path) }

        let stamp = ISO8601DateFormatter()
            .string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
        let backupDirectory = directory
            .appendingPathComponent("DatabaseRecovery", isDirectory: true)
            .appendingPathComponent("\(reason)-\(stamp)", isDirectory: true)
        try fileManager.createDirectory(
            at: backupDirectory,
            withIntermediateDirectories: true
        )

        for source in sidecarURLs {
            let destination = backupDirectory.appendingPathComponent(source.lastPathComponent)
            try fileManager.copyItem(at: source, to: destination)
        }

        return backupDirectory
    }

    private static func removeStoreFiles(in directory: URL) {
        let storeURL = directory.appendingPathComponent("default.store")
        let paths = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-wal"),
            URL(fileURLWithPath: storeURL.path + "-shm")
        ]

        for url in paths {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
