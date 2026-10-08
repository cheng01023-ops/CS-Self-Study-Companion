import Foundation

enum ProjectVerificationStatus: String, Sendable {
    case passed
    case warning
    case failed
    case notRun

    var title: String {
        switch self {
        case .passed: "通过"
        case .warning: "警告"
        case .failed: "失败"
        case .notRun: "未运行"
        }
    }
}

struct ProjectVerificationCheck: Identifiable, Sendable {
    let id: String
    let title: String
    let detail: String
    let status: ProjectVerificationStatus
    let evidence: [String]
    let weight: Double
    let earned: Double
}

struct ProjectCommandPlan: Identifiable, Sendable {
    let id: String
    let title: String
    let displayCommand: String
    let executable: String
    let arguments: [String]
    let explanation: String
}

struct ProjectCommandResult: Identifiable, Sendable {
    let id: String
    let title: String
    let command: String
    let exitCode: Int32
    let stdout: String
    let stderr: String
    let duration: TimeInterval
    let timedOut: Bool

    var passed: Bool { exitCode == 0 && !timedOut }
}

struct ProjectScanReport: Sendable {
    let projectID: String
    let projectTitle: String
    let rootPath: String
    let scannedAt: Date
    let fileCount: Int
    let sourceCounts: [String: Int]
    let checks: [ProjectVerificationCheck]
    let commands: [ProjectCommandPlan]
    let gitBranch: String?
    let gitCommit: String?
    let gitStatus: [String]

    var score: Double {
        let totalWeight = checks.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return 0 }
        return checks.reduce(0) { $0 + $1.earned } / totalWeight
    }

    var passedChecks: Int {
        checks.filter { $0.status == .passed }.count
    }
}

enum ProjectWorkspaceService {
    static let skippedDirectories: Set<String> = [
        ".git", ".build", "DerivedData", "node_modules", "Pods",
        "build", "dist", "target", ".next", ".cache"
    ]

    static func scan(project: LearningProject, rootURL: URL) throws -> ProjectScanReport {
        let fileManager = FileManager.default
        let normalizedRoot = rootURL.standardizedFileURL
        guard fileManager.fileExists(atPath: normalizedRoot.path) else {
            throw NSError(
                domain: "ProjectWorkspaceService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "项目目录不存在。"]
            )
        }

        let relativePaths = try collectRelativePaths(in: normalizedRoot)
        let lowerPaths = relativePaths.map { $0.lowercased() }

        let structureCheck = repositoryStructureCheck(project: project, paths: lowerPaths)
        let testCheck = testsCheck(paths: lowerPaths)
        let documentationCheck = documentationCheck(paths: lowerPaths)
        let versionControlCheck = versionControlCheck(rootURL: normalizedRoot, paths: lowerPaths)
        let qualityCheck = qualityCheck(rootURL: normalizedRoot, paths: relativePaths)
        let commands = detectCommands(rootURL: normalizedRoot, paths: relativePaths)

        let buildCheck: ProjectVerificationCheck
        if let command = commands.first {
            buildCheck = ProjectVerificationCheck(
                id: "build",
                title: "构建入口",
                detail: "已识别可执行的构建或测试入口，尚未运行。",
                status: .notRun,
                evidence: [command.displayCommand],
                weight: 15,
                earned: 0
            )
        } else {
            buildCheck = ProjectVerificationCheck(
                id: "build",
                title: "构建入口",
                detail: "没有识别到 Package.swift、Makefile、CMakeLists.txt、*.xcodeproj、Cargo.toml 或 package.json。",
                status: .warning,
                evidence: [],
                weight: 15,
                earned: 5
            )
        }

        let sourceCounts = sourceFileCounts(paths: relativePaths)
        let gitInfo = gitInformation(rootURL: normalizedRoot)

        return ProjectScanReport(
            projectID: project.id,
            projectTitle: project.title,
            rootPath: normalizedRoot.path,
            scannedAt: .now,
            fileCount: relativePaths.count,
            sourceCounts: sourceCounts,
            checks: [
                structureCheck,
                testCheck,
                documentationCheck,
                versionControlCheck,
                qualityCheck,
                buildCheck
            ],
            commands: commands,
            gitBranch: gitInfo.branch,
            gitCommit: gitInfo.commit,
            gitStatus: gitInfo.status
        )
    }

    static func run(
        command: ProjectCommandPlan,
        rootURL: URL,
        timeout: TimeInterval = 180
    ) -> ProjectCommandResult {
#if os(macOS)
        let start = Date()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command.executable)
        process.arguments = command.arguments
        process.currentDirectoryURL = rootURL
        process.environment = ProcessInfo.processInfo.environment

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let stdoutHandle = stdoutPipe.fileHandleForReading
        let stderrHandle = stderrPipe.fileHandleForReading
        let lock = NSLock()
        var stdoutData = Data()
        var stderrData = Data()

        stdoutHandle.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            lock.lock()
            stdoutData.append(data)
            lock.unlock()
        }
        stderrHandle.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            lock.lock()
            stderrData.append(data)
            lock.unlock()
        }

        do {
            try process.run()
        } catch {
            stdoutHandle.readabilityHandler = nil
            stderrHandle.readabilityHandler = nil
            return ProjectCommandResult(
                id: UUID().uuidString,
                title: command.title,
                command: command.displayCommand,
                exitCode: -1,
                stdout: "",
                stderr: error.localizedDescription,
                duration: Date().timeIntervalSince(start),
                timedOut: false
            )
        }

        var timedOut = false
        let deadline = Date().addingTimeInterval(max(5, timeout))
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.1)
        }
        if process.isRunning {
            timedOut = true
            process.terminate()
            process.waitUntilExit()
        }

        stdoutHandle.readabilityHandler = nil
        stderrHandle.readabilityHandler = nil
        lock.lock()
        let finalStdout = stdoutData
        let finalStderr = stderrData
        lock.unlock()

        return ProjectCommandResult(
            id: UUID().uuidString,
            title: command.title,
            command: command.displayCommand,
            exitCode: process.terminationStatus,
            stdout: String(data: finalStdout, encoding: .utf8) ?? "",
            stderr: String(data: finalStderr, encoding: .utf8) ?? "",
            duration: Date().timeIntervalSince(start),
            timedOut: timedOut
        )
#else
        return ProjectCommandResult(
            id: UUID().uuidString,
            title: command.title,
            command: command.displayCommand,
            exitCode: -1,
            stdout: "",
            stderr: "iOS 版不能直接运行仓库构建命令。请先在 Mac 版工程验收工作台运行。",
            duration: 0,
            timedOut: false
        )
#endif
    }

    static func applying(
        commandResults: [ProjectCommandResult],
        to report: ProjectScanReport
    ) -> ProjectScanReport {
        guard !commandResults.isEmpty else { return report }
        let passed = commandResults.contains { $0.passed }
        let checks = report.checks.map { check in
            guard check.id == "build" else { return check }
            return ProjectVerificationCheck(
                id: check.id,
                title: check.title,
                detail: passed
                    ? "至少一个构建或测试命令已通过。"
                    : "已运行构建命令，但当前没有通过的结果。",
                status: passed ? .passed : .failed,
                evidence: commandResults.map { $0.command },
                weight: check.weight,
                earned: passed ? check.weight : 0
            )
        }
        return ProjectScanReport(
            projectID: report.projectID,
            projectTitle: report.projectTitle,
            rootPath: report.rootPath,
            scannedAt: report.scannedAt,
            fileCount: report.fileCount,
            sourceCounts: report.sourceCounts,
            checks: checks,
            commands: report.commands,
            gitBranch: report.gitBranch,
            gitCommit: report.gitCommit,
            gitStatus: report.gitStatus
        )
    }

    static func reportMarkdown(
        report: ProjectScanReport,
        commandResults: [ProjectCommandResult] = []
    ) -> String {
        var lines = [
            "# \(report.projectTitle) 工程验收报告",
            "",
            "- 扫描目录：`\(report.rootPath)`",
            "- 扫描时间：\(report.scannedAt.formatted(date: .numeric, time: .standard))",
            "- 文件数量：\(report.fileCount)",
            "- 静态检查得分：\(Int(report.score * 100))%",
            "- Git 分支：\(report.gitBranch ?? "未检测到")",
            "- Git 提交：\(report.gitCommit ?? "未检测到")",
            ""
        ]

        if !report.gitStatus.isEmpty {
            lines += ["## Git 状态", ""]
            lines += report.gitStatus.map { "- `\($0)`" }
            lines.append("")
        }

        lines += ["## 结构检查", ""]
        for check in report.checks {
            lines += [
                "### \(check.status.title)：\(check.title)",
                "",
                check.detail,
                "",
                "得分：\(Int(check.earned))/\(Int(check.weight))",
                ""
            ]
            if !check.evidence.isEmpty {
                lines += check.evidence.map { "- `\($0)`" }
                lines.append("")
            }
        }

        if !report.commands.isEmpty {
            lines += ["## 可用构建命令", ""]
            lines += report.commands.map { "- `\($0.displayCommand)`：\($0.explanation)" }
            lines.append("")
        }

        if !commandResults.isEmpty {
            lines += ["## 实际运行结果", ""]
            for result in commandResults {
                lines += [
                    "### \(result.passed ? "通过" : "失败")：\(result.title)",
                    "",
                    "命令：`\(result.command)`",
                    "",
                    "退出码：\(result.exitCode)，耗时：\(String(format: "%.2f", result.duration)) 秒",
                    ""
                ]
                if !result.stdout.isEmpty {
                    lines += ["```text", result.stdout.trimmingCharacters(in: .whitespacesAndNewlines), "```", ""]
                }
                if !result.stderr.isEmpty {
                    lines += ["```text", result.stderr.trimmingCharacters(in: .whitespacesAndNewlines), "```", ""]
                }
            }
        }

        lines += [
            "---",
            "",
            "说明：报告由 CS 自学工程验收工作台生成。静态检查不能替代真实构建、测试和人工代码审查。"
        ]
        return lines.joined(separator: "\n")
    }

    private static func collectRelativePaths(in rootURL: URL) throws -> [String] {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsPackageDescendants]
        ) else {
            return []
        }

        let rootPath = rootURL.resolvingSymlinksInPath().path
        var paths: [String] = []
        for case let url as URL in enumerator {
            let filePath = url.resolvingSymlinksInPath().path
            let relative: String
            if filePath == rootPath {
                continue
            } else if filePath.hasPrefix(rootPath + "/") {
                relative = String(filePath.dropFirst(rootPath.count + 1))
            } else {
                relative = url.lastPathComponent
            }

            let components = relative.split(separator: "/").map(String.init)
            if components.contains(where: { skippedDirectories.contains($0) }) {
                if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                    enumerator.skipDescendants()
                }
                continue
            }
            paths.append(relative)
        }
        return paths
    }

    private static func repositoryStructureCheck(
        project: LearningProject,
        paths: [String]
    ) -> ProjectVerificationCheck {
        var found: [String] = []
        var missing: [String] = []

        for area in project.repository {
            let expected = area.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
            let matched = paths.contains { path in
                path == expected
                    || path.hasPrefix(expected + "/")
                    || path.contains("/" + expected + "/")
            }
            if matched {
                found.append(area.path)
            } else {
                missing.append(area.path)
            }
        }

        let ratio = project.repository.isEmpty
            ? 1
            : Double(found.count) / Double(project.repository.count)
        let status: ProjectVerificationStatus = missing.isEmpty
            ? .passed
            : ratio >= 0.6 ? .warning : .failed
        return ProjectVerificationCheck(
            id: "structure",
            title: "仓库结构",
            detail: missing.isEmpty
                ? "仓库地图中的路径均已找到。"
                : "缺少 \(missing.count) 个预期路径：\(missing.joined(separator: "、"))",
            status: status,
            evidence: found,
            weight: 30,
            earned: 30 * ratio
        )
    }

    private static func testsCheck(paths: [String]) -> ProjectVerificationCheck {
        let testPaths = paths.filter { path in
            let lower = path.lowercased()
            return lower.contains("test")
                || lower.contains("spec")
                || lower.hasSuffix("makefile")
                || lower.hasSuffix("package.swift")
        }
        let hasTests = testPaths.contains { $0.lowercased().contains("test") || $0.lowercased().contains("spec") }
        let score: Double = hasTests ? 20 : 5
        return ProjectVerificationCheck(
            id: "tests",
            title: "测试入口",
            detail: hasTests ? "检测到测试目录或测试文件。" : "没有检测到明显的单元测试、集成测试或测试脚本。",
            status: hasTests ? .passed : .warning,
            evidence: Array(testPaths.prefix(12)),
            weight: 20,
            earned: score
        )
    }

    private static func documentationCheck(paths: [String]) -> ProjectVerificationCheck {
        let hasReadme = paths.contains { $0.lowercased().hasPrefix("readme") || $0.lowercased().contains("/readme") }
        let hasLicense = paths.contains { $0.lowercased().hasPrefix("license") || $0.lowercased().contains("/license") }
        var evidence: [String] = []
        if hasReadme { evidence.append("README") }
        if hasLicense { evidence.append("LICENSE") }
        let ratio = (hasReadme ? 0.75 : 0) + (hasLicense ? 0.25 : 0)
        let status: ProjectVerificationStatus = hasReadme ? .passed : .warning
        return ProjectVerificationCheck(
            id: "docs",
            title: "文档与许可证",
            detail: hasReadme ? "README 已存在。许可证\(hasLicense ? "已包含。" : "尚未包含，公开前需要确认。")" : "至少需要一个 README，说明构建、运行、测试和已知限制。",
            status: status,
            evidence: evidence,
            weight: 15,
            earned: 15 * ratio
        )
    }

    private static func versionControlCheck(rootURL: URL, paths: [String]) -> ProjectVerificationCheck {
        let hasGit = FileManager.default.fileExists(atPath: rootURL.appendingPathComponent(".git").path)
        let hasIgnore = paths.contains { $0 == ".gitignore" || $0.hasSuffix("/.gitignore") }
        let ratio = (hasGit ? 0.7 : 0) + (hasIgnore ? 0.3 : 0)
        let status: ProjectVerificationStatus = hasGit ? .passed : .warning
        return ProjectVerificationCheck(
            id: "git",
            title: "版本控制",
            detail: hasGit ? "检测到 Git 仓库\(hasIgnore ? "和 .gitignore。" : "，但缺少 .gitignore。")" : "没有检测到本地 Git 仓库。",
            status: status,
            evidence: [hasGit ? ".git" : "", hasIgnore ? ".gitignore" : ""].filter { !$0.isEmpty },
            weight: 10,
            earned: 10 * ratio
        )
    }

    private static func qualityCheck(rootURL: URL, paths: [String]) -> ProjectVerificationCheck {
        let sourceExtensions = Set(["c", "h", "swift", "cpp", "hpp", "sh", "py", "js", "ts", "rs", "go", "java"])
        var todoCount = 0
        var sampledFiles = 0
        let fileManager = FileManager.default

        for path in paths where sampledFiles < 200 {
            let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
            guard sourceExtensions.contains(ext) else { continue }
            let url = rootURL.appendingPathComponent(path)
            guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
                  let size = attributes[.size] as? NSNumber,
                  size.intValue <= 1_500_000,
                  let content = try? String(contentsOf: url, encoding: .utf8) else { continue }
            sampledFiles += 1
            let upper = content.uppercased()
            todoCount += upper.components(separatedBy: "TODO").count - 1
            todoCount += upper.components(separatedBy: "FIXME").count - 1
        }

        let status: ProjectVerificationStatus = todoCount <= 8 ? .passed : todoCount <= 20 ? .warning : .failed
        let earned: Double = todoCount <= 8 ? 10 : todoCount <= 20 ? 6 : 2
        return ProjectVerificationCheck(
            id: "quality",
            title: "代码卫生",
            detail: todoCount <= 8
                ? "采样源码中的 TODO/FIXME 数量较低。"
                : "采样源码中发现 \(todoCount) 个 TODO/FIXME，建议在发布前分类处理。",
            status: status,
            evidence: ["抽样源码文件：\(sampledFiles)"],
            weight: 10,
            earned: earned
        )
    }

    private static func detectCommands(rootURL: URL, paths: [String]) -> [ProjectCommandPlan] {
        var commands: [ProjectCommandPlan] = []

        if paths.contains(where: { $0 == "Package.swift" }) {
            commands.append(shellCommand(
                id: "swift-test",
                title: "Swift Package 测试",
                command: "swift test",
                explanation: "运行 Swift Package Manager 测试。"
            ))
        }

        if let xcodeproj = paths.first(where: { $0.hasSuffix(".xcodeproj") }) {
            let scheme = firstSchemeName(in: rootURL, projectPath: xcodeproj)
            let command: String
            if let scheme {
                command = "xcodebuild -project \(shellQuote(xcodeproj)) -scheme \(shellQuote(scheme)) test"
            } else {
                command = "xcodebuild -project \(shellQuote(xcodeproj)) build"
            }
            commands.append(shellCommand(
                id: "xcode-test",
                title: "Xcode 构建",
                command: command,
                explanation: scheme == nil ? "未找到 scheme，先执行默认构建。" : "运行 Xcode scheme 的测试动作。"
            ))
        }

        if paths.contains(where: { $0 == "Makefile" || $0 == "makefile" }) {
            let makefile = rootURL.appendingPathComponent("Makefile")
            let content = (try? String(contentsOf: makefile, encoding: .utf8)) ?? ""
            let command = content.contains("test:") ? "make test" : "make"
            commands.append(shellCommand(
                id: "make-test",
                title: "Make 构建",
                command: command,
                explanation: command == "make test" ? "运行 Makefile 中的 test 目标。" : "运行默认 Make 目标。"
            ))
        }

        if paths.contains(where: { $0 == "CMakeLists.txt" }) {
            commands.append(shellCommand(
                id: "cmake-build",
                title: "CMake 构建",
                command: "cmake -S . -B build && cmake --build build",
                explanation: "配置并构建 CMake 项目。"
            ))
        }

        if paths.contains(where: { $0 == "Cargo.toml" }) {
            commands.append(shellCommand(
                id: "cargo-test",
                title: "Cargo 测试",
                command: "cargo test",
                explanation: "运行 Rust Cargo 测试。"
            ))
        }

        if paths.contains(where: { $0 == "package.json" }) {
            commands.append(shellCommand(
                id: "npm-test",
                title: "npm 测试",
                command: "npm test -- --runInBand",
                explanation: "运行 package.json 中的测试脚本。若项目未配置测试，命令会明确失败。"
            ))
        }

        if commands.isEmpty {
            commands.append(shellCommand(
                id: "git-status",
                title: "只读检查",
                command: "git status --short && find . -maxdepth 2 -type f | sort | head -80",
                explanation: "没有识别到标准构建系统，只执行只读状态和文件检查。"
            ))
        }
        return commands
    }

    private static func shellCommand(
        id: String,
        title: String,
        command: String,
        explanation: String
    ) -> ProjectCommandPlan {
        ProjectCommandPlan(
            id: id,
            title: title,
            displayCommand: command,
            executable: "/bin/zsh",
            arguments: ["-lc", command],
            explanation: explanation
        )
    }

    private static func firstSchemeName(in rootURL: URL, projectPath: String) -> String? {
        let projectURL = rootURL.appendingPathComponent(projectPath)
        guard let enumerator = FileManager.default.enumerator(at: projectURL, includingPropertiesForKeys: nil) else {
            return nil
        }
        for case let url as URL in enumerator where url.pathExtension == "xcscheme" {
            return url.deletingPathExtension().lastPathComponent
        }
        return nil
    }

    private static func sourceFileCounts(paths: [String]) -> [String: Int] {
        var counts: [String: Int] = [:]
        for path in paths {
            let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
            guard !ext.isEmpty else { continue }
            guard ["c", "h", "swift", "cpp", "hpp", "sh", "py", "js", "ts", "rs", "go", "java", "sql", "md"].contains(ext) else { continue }
            counts[ext, default: 0] += 1
        }
        return counts
    }

    private static func gitInformation(rootURL: URL) -> (branch: String?, commit: String?, status: [String]) {
        guard FileManager.default.fileExists(atPath: rootURL.appendingPathComponent(".git").path) else {
            return (nil, nil, [])
        }
#if os(macOS)
        let branch = runCapture(executable: "/usr/bin/git", arguments: ["-C", rootURL.path, "branch", "--show-current"])
        let commit = runCapture(executable: "/usr/bin/git", arguments: ["-C", rootURL.path, "rev-parse", "--short", "HEAD"])
        let status = runCapture(executable: "/usr/bin/git", arguments: ["-C", rootURL.path, "status", "--short"])
        return (
            branch.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            commit.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            status.components(separatedBy: .newlines).filter { !$0.isEmpty }
        )
#else
        return (nil, nil, ["iOS 版仅检查到本地 Git 目录，请使用 Mac 版读取分支和提交信息。"])
#endif
    }

#if os(macOS)
    private static func runCapture(executable: String, arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
#endif

    private static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
