import XCTest
@testable import CSSelfStudyCompanion

final class ContentVersionHistoryServiceTests: XCTestCase {
    func testHistoryKeepsNewestEntriesAndDeduplicatesVersion() {
        let suite = "ContentVersionHistoryTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        ContentVersionHistoryService.record(
            version: "1.0",
            summary: "初始课程",
            updatedAt: Date(timeIntervalSince1970: 1),
            defaults: defaults
        )
        ContentVersionHistoryService.record(
            version: "1.1",
            summary: "更新教程",
            updatedAt: Date(timeIntervalSince1970: 2),
            defaults: defaults
        )
        ContentVersionHistoryService.record(
            version: "1.0",
            summary: "修订初始课程",
            updatedAt: Date(timeIntervalSince1970: 3),
            defaults: defaults
        )

        let history = ContentVersionHistoryService.load(from: defaults)
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history.first?.version, "1.0")
        XCTAssertEqual(history.first?.summary, "修订初始课程")
    }
}
