import XCTest
@testable import CSSelfStudyCompanion

final class CloudSyncServiceTests: XCTestCase {
    func testConfigurationStates() {
        XCTAssertEqual(
            CloudSyncService.configurationState(enabled: false, containerIdentifier: ""),
            .disabled
        )
        XCTAssertEqual(
            CloudSyncService.configurationState(enabled: true, containerIdentifier: ""),
            .missingContainer
        )
        XCTAssertEqual(
            CloudSyncService.configurationState(
                enabled: true,
                containerIdentifier: "iCloud.example.csxuexi"
            ),
            .checking
        )
    }
}
