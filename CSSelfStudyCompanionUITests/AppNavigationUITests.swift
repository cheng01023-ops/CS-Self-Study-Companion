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
    func testOpenVerifiableLabFromTutorial() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-disable-sync", "-disable-diagnostic"]
        app.launch()

        let continueButton = app.buttons["继续学习"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 20))
        continueButton.tap()

        let topic = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "从 Finder 走进终端")
        ).firstMatch
        XCTAssertTrue(topic.waitForExistence(timeout: 10))
        topic.tap()

        let tutorial = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "终端、文件权限与第一套工具链")
        ).firstMatch
        XCTAssertTrue(tutorial.waitForExistence(timeout: 10))
        tutorial.tap()

        let labLabel = app.staticTexts["可验证实验课"]
        if !labLabel.waitForExistence(timeout: 5) {
            app.swipeUp()
        }
        XCTAssertTrue(labLabel.waitForExistence(timeout: 10))

        let startButton = app.buttons["开始六步实验"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 10))
        startButton.tap()

        XCTAssertTrue(app.navigationBars["可验证实验课"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["1 / 6 · 目标"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testTheoryInteractiveLab() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-disable-sync", "-disable-diagnostic"]
        app.launch()

        let lab = app.buttons["lab-logic"]
        for _ in 0..<8 where !lab.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(lab.waitForExistence(timeout: 10))
        lab.tap()

        XCTAssertTrue(app.navigationBars["逻辑真值表"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["当前结论"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["P → Q"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testProjectEngineeringLadderAndDetail() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-disable-sync", "-disable-diagnostic"]
        app.launch()

        let portfolio = app.buttons["project-portfolio-link"]
        for _ in 0..<5 where !portfolio.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(portfolio.waitForExistence(timeout: 10))
        portfolio.tap()

        XCTAssertTrue(app.navigationBars["项目作品集"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["工程作品阶梯"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["推荐下一项工程"].waitForExistence(timeout: 10))

        let project = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "命令行通讯录")
        ).firstMatch
        XCTAssertTrue(project.waitForExistence(timeout: 10))
        project.tap()

        XCTAssertTrue(app.navigationBars["命令行通讯录"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["工程实施路径"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["仓库地图"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testOpenSourceReadingLadderAndMission() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-disable-sync", "-disable-diagnostic"]
        app.launch()

        let codeReading = app.buttons["quick-code-reading"]
        for _ in 0..<5 where !codeReading.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(codeReading.waitForExistence(timeout: 10))
        codeReading.tap()

        XCTAssertTrue(app.navigationBars["代码阅读训练"].waitForExistence(timeout: 10))
        let openSourceMode = app.buttons["open-source-reading-mode"]
        XCTAssertTrue(openSourceMode.waitForExistence(timeout: 10))
        openSourceMode.tap()

        XCTAssertTrue(app.staticTexts["六级阅读阶梯"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["L0 单文件入口"].waitForExistence(timeout: 10))

        let mission = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "coreutils/coreutils")
        ).firstMatch
        XCTAssertTrue(mission.waitForExistence(timeout: 10))
        mission.tap()

        XCTAssertTrue(app.navigationBars["开源阅读"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["1 / 6 · 目标"].waitForExistence(timeout: 10))
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
