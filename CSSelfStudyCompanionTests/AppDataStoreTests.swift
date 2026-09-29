import XCTest
@testable import CSSelfStudyCompanion

@MainActor
final class AppDataStoreTests: XCTestCase {
    func testBackupStoreFilesCopiesMainStoreAndSidecars() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("cs-self-recovery-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = directory.appendingPathComponent("default.store")
        let wal = URL(fileURLWithPath: store.path + "-wal")
        let shm = URL(fileURLWithPath: store.path + "-shm")
        try Data("store".utf8).write(to: store)
        try Data("wal".utf8).write(to: wal)
        try Data("shm".utf8).write(to: shm)

        let backup = try AppDataStore.backupStoreFiles(in: directory, reason: "test")
        XCTAssertTrue(FileManager.default.fileExists(atPath: backup.appendingPathComponent("default.store").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: backup.appendingPathComponent("default.store-wal").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: backup.appendingPathComponent("default.store-shm").path))
    }
}
