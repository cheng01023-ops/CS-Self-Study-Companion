import XCTest
@testable import CSSelfStudyCompanion

final class SystemIntegrationServiceTests: XCTestCase {
    func testDeepLinkRoutes() {
        XCTAssertEqual(
            SystemIntegrationService.route(for: URL(string: "csxuexi://tutorial/tutorial-c-foundation")!),
            .tutorial("tutorial-c-foundation")
        )
        XCTAssertEqual(
            SystemIntegrationService.route(for: URL(string: "csxuexi://project/mini-shell")!),
            .project("mini-shell")
        )
        XCTAssertEqual(
            SystemIntegrationService.route(for: URL(string: "csxuexi://code-reading")!),
            .codeReading
        )
        XCTAssertNil(SystemIntegrationService.route(for: URL(string: "https://example.com")!))
    }
}
