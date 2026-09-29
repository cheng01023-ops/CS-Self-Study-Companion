import XCTest

final class AppNavigationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMainLearningTabsLaunchAndNavigate() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-disable-sync", "-disable-diagnostic"]
        app.launch()

        let expectedTabs = ["学习路线", "知识中心", "复习", "命令速查", "学习进度"]
        for title in expectedTabs {
            XCTAssertTrue(
                app.tabBars.buttons[title].waitForExistence(timeout: 20),
                "找不到标签：\(title)"
            )
        }

        app.tabBars.buttons["命令速查"].tap()
        XCTAssertTrue(
            app.navigationBars["命令速查"].waitForExistence(timeout: 10)
                || app.staticTexts["终端与 Linux 命令库"].waitForExistence(timeout: 3)
        )
        XCTAssertTrue(app.searchFields.firstMatch.exists)
    }

    @MainActor
    func testRoadmapExposesContinueLearningEntry() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-disable-sync", "-disable-diagnostic"]
        app.launch()

        XCTAssertTrue(app.staticTexts["CS 自学"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["今日建议"].waitForExistence(timeout: 10))
    }
}
