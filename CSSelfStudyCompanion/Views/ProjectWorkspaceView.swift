#if os(macOS)
import AppKit
#endif
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ProjectWorkspaceView: View {
    @Environment(\.modelContext) private var modelContext

    let projectID: String

    @State private var rootURL: URL?
    @State private var report: ProjectScanReport?
    @State private var commandResults: [ProjectCommandResult] = []
    @State private var isScanning = false
    @State private var isRunning = false
    @State private var showImporter = false
    @State private var statusMessage = ""
    @State private var activeSecurityScopedURL: URL?

    private var project: LearningProject? {
        ProjectCatalog.projects.first { $0.id == projectID }
    }

    private var displayReport: ProjectScanReport? {
        guard let report else { return nil }
        return ProjectWorkspaceService.applying(commandResults: commandResults, to: report)
    }

    private var reportMarkdown: String {
        guard let displayReport else { return "" }
        return ProjectWorkspaceService.reportMarkdown(
            report: displayReport,
            commandResults: commandResults
        )
    }

    var body: some View {
        Group {
            if let project {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        header(project)
                        workspaceSelector(project)

                        if isScanning {
                            scanningCard
                        } else if let report = displayReport {
                            reportSummary(report)
                            checksSection(report)
                            commandsSection(report)
                            gitSection(report)
                            reportActions(report)
                        }

                        if !statusMessage.isEmpty {
                            Text(statusMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .learningCard()
                        }
                    }
                    .padding()
                    .learningPageWidth(maxWidth: 1080)
                }
                .background(Color.appBackground)
                .navigationTitle("工程验收工作台")
                .fileImporter(
                    isPresented: $showImporter,
                    allowedContentTypes: [.folder],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case let .success(urls):
                        if let url = urls.first {
                            beginScan(url)
                        }
                    case let .failure(error):
                        statusMessage = "选择目录失败：\(error.localizedDescription)"
                    }
                }
                .onAppear {
                    restoreWorkspaceIfAvailable()
                }
                .onDisappear {
                    activeSecurityScopedURL?.stopAccessingSecurityScopedResource()
                    activeSecurityScopedURL = nil
                }
            } else {
                ContentUnavailableView("项目不存在", systemImage: "folder.badge.questionmark")
            }
        }
    }

    private func header(_ project: LearningProject) -> some View {
        let color = Color(hex: project.themeHex)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: "shippingbox.and.arrow.backward.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(.title3.bold())
                    Text("把项目目录变成真实验收报告：检查结构、文档、测试入口、Git 状态，并在 Mac 上运行构建命令。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                Spacer()
            }

            HStack {
                StatPill(icon: "folder.fill", text: project.track.title, tint: color)
                StatPill(icon: "checkmark.shield", text: "\(project.qualityGates.count) 项质量门禁", tint: .green)
                StatPill(icon: "list.number", text: "\(project.milestones.count) 个里程碑", tint: .orange)
            }
        }
        .learningCard()
    }

    @ViewBuilder
    private func workspaceSelector(_ project: LearningProject) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("项目目录", systemImage: "externaldrive")
                    .font(.title3.bold())
                Spacer()
                if rootURL != nil {
                    Button("更换目录") {
                        showImporter = true
                    }
                    .buttonStyle(.bordered)
                }
            }

            if let rootURL {
                Text(rootURL.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(3)

                HStack {
                    Button {
                        beginScan(rootURL)
                    } label: {
                        Label("重新扫描", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: project.themeHex))

                    Button("在 Finder 中显示") {
#if os(macOS)
                        NSWorkspace.shared.activateFileViewerSelecting([rootURL])
#endif
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Text("选择一个本地 Git 仓库、C 项目、Swift Package 或 Xcode 工程。静态扫描在 iOS 和 macOS 都可用；构建和测试命令只会在 macOS 上运行。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)

                Button {
                    showImporter = true
                } label: {
                    Label("选择项目目录", systemImage: "folder.badge.plus")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: project.themeHex))
            }
        }
        .learningCard()
    }

    private var scanningCard: some View {
        HStack(spacing: 12) {
            ProgressView()
            VStack(alignment: .leading, spacing: 3) {
                Text("正在扫描仓库")
                    .font(.headline)
                Text("检查目录结构、测试、文档、代码卫生和可用构建入口……")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .learningCard()
    }

    private func reportSummary(_ report: ProjectScanReport) -> some View {
        let color: Color = report.score >= 0.8 ? .green : report.score >= 0.55 ? .orange : .red
        return VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("静态验收得分")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text("\(Int(report.score * 100))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    StatPill(icon: "doc", text: "\(report.fileCount) 个文件", tint: .indigo)
                    StatPill(icon: "checkmark.circle", text: "\(report.passedChecks)/\(report.checks.count) 项通过", tint: .green)
                }
            }

            LearningProgressBar(value: report.score, tint: color)

            if !report.sourceCounts.isEmpty {
                Text(sourceSummary(report.sourceCounts))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("静态检查只判断仓库是否具备工程证据，不能替代真实构建、测试和人工代码审查。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .learningCard()
    }

    private func checksSection(_ report: ProjectScanReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("验收检查", systemImage: "checklist.checked")
                .font(.title3.bold())

            ForEach(report.checks) { check in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Image(systemName: statusIcon(check.status))
                            .foregroundStyle(statusColor(check.status))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(check.title)
                                .font(.headline)
                            Text(check.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineSpacing(3)
                        }
                        Spacer()
                        Text("\(Int(check.earned))/\(Int(check.weight))")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(statusColor(check.status))
                    }

                    if !check.evidence.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(check.evidence.prefix(8), id: \.self) { item in
                                    Text(item)
                                        .font(.system(.caption2, design: .monospaced))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(statusColor(check.status).opacity(0.08), in: Capsule())
                                }
                            }
                        }
                    }
                }
                .padding(11)
                .background(statusColor(check.status).opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .learningCard()
    }

    @ViewBuilder
    private func commandsSection(_ report: ProjectScanReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("构建与测试", systemImage: "hammer.fill")
                .font(.title3.bold())

#if os(macOS)
            Text("命令由检测到的构建系统生成，不接收任意输入。单条命令最长运行 180 秒。")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(report.commands) { command in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(command.title)
                                .font(.headline)
                            Text(command.displayCommand)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        Spacer()
                        Button {
                            run(command)
                        } label: {
                            if isRunning {
                                ProgressView().controlSize(.small)
                            } else {
                                Label("运行", systemImage: "play.fill")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isRunning)
                    }
                    Text(command.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(11)
                .background(.indigo.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            }

            if !commandResults.isEmpty {
                Divider()
                Label("实际运行结果", systemImage: "terminal")
                    .font(.headline)
                ForEach(commandResults) { result in
                    commandResultView(result)
                }
            }
#else
            Label("iPhone/iPad 仅执行静态验收", systemImage: "iphone")
                .font(.headline)
                .foregroundStyle(.orange)
            Text("iOS 无法直接运行 xcodebuild、make、cmake 或测试进程。请使用 Mac 版工作台运行命令，或在 Mac 运行完成后同步报告。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
#endif
        }
        .learningCard()
    }

    @ViewBuilder
    private func gitSection(_ report: ProjectScanReport) -> some View {
        if report.gitBranch != nil || report.gitCommit != nil || !report.gitStatus.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("Git 状态", systemImage: "arrow.triangle.branch")
                    .font(.title3.bold())
                if let branch = report.gitBranch {
                    Label("分支：\(branch)", systemImage: "arrow.triangle.branch")
                }
                if let commit = report.gitCommit {
                    Label("提交：\(commit)", systemImage: "number")
                }
                if !report.gitStatus.isEmpty {
                    Text("未提交改动")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ForEach(report.gitStatus.prefix(12), id: \.self) { line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .learningCard()
        }
    }

    private func reportActions(_ report: ProjectScanReport) -> some View {
        HStack {
            CopyButton(text: reportMarkdown)
            ShareLink(item: reportMarkdown) {
                Label("分享报告", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
            Button {
                saveReport(report)
            } label: {
                Label("保存到项目证据", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .learningCard()
    }

    private func commandResultView(_ result: ProjectCommandResult) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(result.passed ? "通过" : "失败", systemImage: result.passed ? "checkmark.circle.fill" : "xmark.octagon.fill")
                    .font(.headline)
                    .foregroundStyle(result.passed ? .green : .red)
                Spacer()
                Text("退出码 \(result.exitCode) · \(String(format: "%.2f", result.duration))s")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text(result.command)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)

            if !result.stdout.isEmpty {
                DisclosureGroup("标准输出") {
                    outputText(result.stdout, color: .primary)
                }
            }
            if !result.stderr.isEmpty {
                DisclosureGroup("标准错误") {
                    outputText(result.stderr, color: .red)
                }
            }
        }
        .padding(11)
        .background((result.passed ? Color.green : Color.red).opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    private func outputText(_ value: String, color: Color) -> some View {
        Text(String(value.suffix(8_000)))
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(color)
            .textSelection(.enabled)
            .padding(.top, 6)
    }

    private func beginScan(_ url: URL) {
        guard let project else { return }
        activeSecurityScopedURL?.stopAccessingSecurityScopedResource()
        let didAccess = url.startAccessingSecurityScopedResource()
        if didAccess {
            activeSecurityScopedURL = url
        }

        rootURL = url
        persistWorkspace(url)
        isScanning = true
        statusMessage = ""
        report = nil
        commandResults = []

        Task {
            do {
                let scanned = try await Task.detached(priority: .userInitiated) {
                    try ProjectWorkspaceService.scan(project: project, rootURL: url)
                }.value
                await MainActor.run {
                    report = scanned
                    isScanning = false
                    saveReport(scanned)
                    statusMessage = "扫描完成：\(scanned.fileCount) 个文件。"
                }
            } catch {
                await MainActor.run {
                    isScanning = false
                    statusMessage = "扫描失败：\(error.localizedDescription)"
                }
            }
        }
    }

    private func run(_ command: ProjectCommandPlan) {
        guard let rootURL, let report else { return }
        isRunning = true
        statusMessage = "正在运行：\(command.displayCommand)"

        Task {
            let result = await Task.detached(priority: .userInitiated) {
                ProjectWorkspaceService.run(command: command, rootURL: rootURL)
            }.value
            await MainActor.run {
                commandResults.append(result)
                isRunning = false
                let updated = ProjectWorkspaceService.applying(commandResults: commandResults, to: report)
                saveReport(updated)
                statusMessage = result.passed ? "命令运行通过。" : "命令运行失败，请查看标准错误。"
            }
        }
    }

    private func saveReport(_ report: ProjectScanReport) {
        KnowledgeService.saveNote(
            targetID: "project:\(projectID):verification",
            parentTutorialID: nil,
            stepIndex: nil,
            title: "\(report.projectTitle) 工程验收报告",
            body: ProjectWorkspaceService.reportMarkdown(
                report: ProjectWorkspaceService.applying(commandResults: commandResults, to: report),
                commandResults: commandResults
            ),
            in: modelContext
        )
    }

    private func persistWorkspace(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: pathKey)
#if os(macOS)
        if let bookmark = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) {
            UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
        }
#endif
    }

    private func restoreWorkspaceIfAvailable() {
#if os(macOS)
        if let data = UserDefaults.standard.data(forKey: bookmarkKey) {
            var stale = false
            if let url = try? URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ) {
                beginScan(url)
                return
            }
        }
#endif
        if let path = UserDefaults.standard.string(forKey: pathKey) {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                beginScan(url)
            }
        }
    }

    private var pathKey: String { "projectWorkspacePath.\(projectID)" }
    private var bookmarkKey: String { "projectWorkspaceBookmark.\(projectID)" }

    private func statusIcon(_ status: ProjectVerificationStatus) -> String {
        switch status {
        case .passed: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .failed: "xmark.octagon.fill"
        case .notRun: "play.circle"
        }
    }

    private func statusColor(_ status: ProjectVerificationStatus) -> Color {
        switch status {
        case .passed: .green
        case .warning: .orange
        case .failed: .red
        case .notRun: .indigo
        }
    }

    private func sourceSummary(_ counts: [String: Int]) -> String {
        counts
            .sorted { $0.value > $1.value }
            .prefix(8)
            .map { "\($0.key.uppercased()) \($0.value)" }
            .joined(separator: " · ")
    }
}
