import XCTest
@testable import CSSelfStudyCompanion

final class ProjectPortfolioServiceTests: XCTestCase {
    func testPortfolioCalculatesMilestoneProgress() {
        let project = ProjectCatalog.projects[0]
        let milestone = project.milestones[0]
        let record = Progress(
            itemID: "project:\(project.id):milestone:\(milestone.id)",
            isCompleted: true,
            completedAt: .now
        )

        let items = ProjectPortfolioService.items(progressRecords: [record])
        let item = items.first { $0.project.id == project.id }

        XCTAssertEqual(item?.completedMilestones, 1)
        XCTAssertEqual(item?.totalMilestones, project.milestones.count)
        XCTAssertFalse(item?.isCompleted ?? true)
    }

    func testProjectLadderHasEngineeringProfilesAndReadingLinks() {
        let projects = ProjectCatalog.projects
        let readingIDs = Set(OpenSourceReadingCatalog.missions.map(\.id))

        XCTAssertGreaterThanOrEqual(projects.count, 10)
        XCTAssertEqual(Set(projects.map(\.id)).count, projects.count)
        XCTAssertEqual(Set(projects.map(\.order)), Set(1...projects.count))
        XCTAssertEqual(Set(projects.map(\.track)), Set(ProjectTrack.allCases))

        for project in projects {
            XCTAssertGreaterThanOrEqual(project.estimatedHours, 10)
            XCTAssertGreaterThanOrEqual(project.prerequisites.count, 2)
            XCTAssertGreaterThanOrEqual(project.repository.count, 4)
            XCTAssertGreaterThanOrEqual(project.qualityGates.count, 3)
            XCTAssertGreaterThanOrEqual(project.releaseChecklist.count, 3)
            XCTAssertGreaterThanOrEqual(project.milestones.count, 4)
            XCTAssertFalse(project.readingMissionIDs.isEmpty)
            XCTAssertTrue(project.readingMissionIDs.allSatisfy { readingIDs.contains($0) })
            XCTAssertTrue(project.milestones.allSatisfy {
                !$0.title.isEmpty && !$0.outputs.isEmpty && !$0.checks.isEmpty
            })
        }
    }

    func testRecommendedNextIgnoresCompletedProjects() {
        let first = ProjectCatalog.projects[0]
        let firstProgress = first.milestones.map {
            Progress(itemID: "project:\(first.id):milestone:\($0.id)", isCompleted: true)
        }

        let next = ProjectPortfolioService.recommendedNext(progressRecords: firstProgress)
        XCTAssertNotEqual(next?.project.id, first.id)
        XCTAssertEqual(next?.project.id, ProjectCatalog.projects[1].id)
    }

    func testProjectWorkspaceScanFindsStructureTestsAndBuildCommand() throws {
        let project = try XCTUnwrap(ProjectCatalog.projects.first { $0.id == "cli-contacts" })
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("cs-workspace-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("tests"), withIntermediateDirectories: true)
        try "int main(void) { return 0; }".write(to: root.appendingPathComponent("src/main.c"), atomically: true, encoding: .utf8)
        try "".write(to: root.appendingPathComponent("src/contacts.c"), atomically: true, encoding: .utf8)
        try "".write(to: root.appendingPathComponent("include/contacts.h"), atomically: true, encoding: .utf8)
        try "".write(to: root.appendingPathComponent("tests/test_contacts.c"), atomically: true, encoding: .utf8)
        try "# CLI Contacts".write(to: root.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try "MIT".write(to: root.appendingPathComponent("LICENSE"), atomically: true, encoding: .utf8)
        try ".build/".write(to: root.appendingPathComponent(".gitignore"), atomically: true, encoding: .utf8)
        try "test:\n\t@true\n".write(to: root.appendingPathComponent("Makefile"), atomically: true, encoding: .utf8)
        try FileManager.default.createDirectory(at: root.appendingPathComponent(".git"), withIntermediateDirectories: true)

        let report = try ProjectWorkspaceService.scan(project: project, rootURL: root)
        XCTAssertEqual(report.projectID, project.id)
        XCTAssertGreaterThanOrEqual(report.sourceCounts["c", default: 0], 3)
        XCTAssertEqual(report.checks.first { $0.id == "structure" }?.status, .passed)
        XCTAssertEqual(report.checks.first { $0.id == "tests" }?.status, .passed)
        XCTAssertTrue(report.commands.contains { $0.displayCommand == "make test" })
        XCTAssertGreaterThan(report.score, 0.8)

        let passing = ProjectCommandResult(
            id: "run",
            title: "Make 构建",
            command: "make test",
            exitCode: 0,
            stdout: "ok",
            stderr: "",
            duration: 0.1,
            timedOut: false
        )
        let verified = ProjectWorkspaceService.applying(commandResults: [passing], to: report)
        XCTAssertEqual(verified.checks.first { $0.id == "build" }?.status, .passed)
        XCTAssertEqual(verified.score, 1, accuracy: 0.0001)

        let markdown = ProjectWorkspaceService.reportMarkdown(report: verified, commandResults: [passing])
        XCTAssertTrue(markdown.contains("工程验收报告"))
        XCTAssertTrue(markdown.contains("make test"))

#if os(macOS)
        let echoCommand = ProjectCommandPlan(
            id: "echo",
            title: "输出测试",
            displayCommand: "printf workspace-ok",
            executable: "/bin/zsh",
            arguments: ["-lc", "printf workspace-ok"],
            explanation: "测试受控命令执行。"
        )
        let echoResult = ProjectWorkspaceService.run(command: echoCommand, rootURL: root, timeout: 10)
        XCTAssertTrue(echoResult.passed, echoResult.stderr)
        XCTAssertTrue(echoResult.stdout.contains("workspace-ok"))
#endif
    }

    func testMarkdownContainsCompletionAndDeliverables() {
        let project = ProjectCatalog.projects[0]
        let progress = project.milestones.map {
            Progress(
                itemID: "project:\(project.id):milestone:\($0.id)",
                isCompleted: true,
                completedAt: .now
            )
        }

        let markdown = ProjectPortfolioService.markdown(progressRecords: progress)
        XCTAssertTrue(markdown.contains("# CS 自学项目作品集"))
        XCTAssertTrue(markdown.contains(project.title))
        XCTAssertTrue(markdown.contains("- [x]"))
        XCTAssertTrue(markdown.contains("交付物"))
        XCTAssertTrue(markdown.contains("仓库地图"))
        XCTAssertTrue(markdown.contains("质量门禁"))
    }
}
