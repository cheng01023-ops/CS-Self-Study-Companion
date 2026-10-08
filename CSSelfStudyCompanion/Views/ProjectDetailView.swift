import SwiftData
import SwiftUI

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressRecords: [Progress]
    @Query(sort: \LearningNote.updatedAt, order: .reverse) private var notes: [LearningNote]

    let projectID: String
    @State private var noteMilestone: ProjectMilestone?

    private var project: LearningProject? {
        ProjectCatalog.projects.first { $0.id == projectID }
    }

    private var completedCount: Int {
        guard let project else { return 0 }
        return project.milestones.filter(isCompleted).count
    }

    private var progress: Double {
        guard let project, !project.milestones.isEmpty else { return 0 }
        return Double(completedCount) / Double(project.milestones.count)
    }

    var body: some View {
        Group {
            if let project {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        header(project)
                        engineeringPath(project)
                        prerequisites(project)
                        repositoryMap(project)
                        workspaceCard(project)
                        milestones(project)
                        qualityGates(project)
                        openSourceReading(project)
                        deliverables(project)
                        releaseChecklist(project)
                        acceptanceCard(project)
                    }
                    .padding()
                    .learningPageWidth()
                }
                .background(Color.appBackground)
                .navigationTitle(project.title)
                .sheet(item: $noteMilestone) { milestone in
                    NoteEditorView(
                        targetID: evidenceTargetID(milestone),
                        parentTutorialID: nil,
                        stepIndex: nil,
                        title: "工程证据：\(milestone.title)"
                    )
                }
            } else {
                ContentUnavailableView("项目不存在", systemImage: "hammer")
            }
        }
    }

    private func header(_ project: LearningProject) -> some View {
        let color = Color(hex: project.themeHex)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: project.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 17))

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(project.track.title) · \(project.level)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color)
                    Text(project.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                Spacer()
            }

            HStack {
                StatPill(icon: "number", text: "第 \(project.order) 项", tint: color)
                StatPill(icon: "clock", text: "约 \(project.estimatedHours) 小时", tint: .orange)
                StatPill(icon: "checkmark.circle", text: "\(project.milestones.count) 个里程碑", tint: .green)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(project.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(color.opacity(0.1), in: Capsule())
                    }
                }
            }

            HStack(spacing: 10) {
                LearningProgressBar(value: progress, tint: color)
                Text("\(Int(progress * 100))%")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(color)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .learningCard()
    }

    private func engineeringPath(_ project: LearningProject) -> some View {
        let color = Color(hex: project.themeHex)
        return VStack(alignment: .leading, spacing: 12) {
            Label("工程实施路径", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                .font(.title3.bold())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ProjectEngineeringPhase.allCases) { phase in
                        let matching = project.milestones.filter { $0.phase == phase }
                        let done = matching.filter(isCompleted).count
                        HStack(spacing: 7) {
                            Image(systemName: matching.isEmpty ? "circle.dotted" : done == matching.count ? "checkmark.circle.fill" : phase.icon)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(phase.title)
                                    .font(.caption.weight(.bold))
                                Text(matching.isEmpty ? "无任务" : "\(done)/\(matching.count)")
                                    .font(.caption2.monospacedDigit())
                                    .opacity(0.72)
                            }
                        }
                        .foregroundStyle(matching.isEmpty ? .secondary : color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            matching.isEmpty ? Color.secondary.opacity(0.05) : color.opacity(0.09),
                            in: RoundedRectangle(cornerRadius: 11)
                        )
                    }
                }
            }

            Text("项目不是一次性写完全部代码。先冻结接口，再做最小核心，随后补测试、加固和发布证据。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .learningCard()
    }

    private func prerequisites(_ project: LearningProject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("开始前条件", systemImage: "checklist")
                .font(.title3.bold())
            ForEach(Array(project.prerequisites.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 9) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color(hex: project.themeHex), in: Circle())
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .learningCard()
    }

    private func repositoryMap(_ project: LearningProject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("仓库地图", systemImage: "folder.fill")
                    .font(.title3.bold())
                Spacer()
                CopyButton(text: projectBrief(project), compact: true)
            }

            ForEach(project.repository) { area in
                HStack(alignment: .top, spacing: 10) {
                    Text(area.path)
                        .font(.system(.caption, design: .monospaced).weight(.semibold))
                        .foregroundStyle(Color(hex: project.themeHex))
                        .frame(width: 150, alignment: .leading)
                    Text(area.purpose)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 3)
            }

            Text("先创建目录和空接口，再逐步填充实现。复制按钮会生成一份包含规格、仓库结构和质量门禁的 README 草案。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .learningCard()
    }

    private func workspaceCard(_ project: LearningProject) -> some View {
        let color = Color(hex: project.themeHex)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) {
                    Text("工程验收工作台")
                        .font(.title3.bold())
                    Text("选择本地项目目录，检查仓库地图、README、测试入口、Git 状态，并在 Mac 上运行构建与测试命令。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                Spacer()
            }

            HStack {
                StatPill(icon: "folder", text: "静态扫描", tint: .indigo)
                StatPill(icon: "hammer", text: "构建验证", tint: .orange)
                StatPill(
                    icon: hasWorkspaceReport(project) ? "checkmark.seal.fill" : "doc.text",
                    text: hasWorkspaceReport(project) ? "已有报告" : "验收报告",
                    tint: .green
                )
            }

            NavigationLink(value: AppRoute.projectWorkspace(project.id)) {
                Label("打开工程验收工作台", systemImage: "arrow.right.circle.fill")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(color)
            .accessibilityIdentifier("project-workspace-link")
        }
        .learningCard()
    }

    private func hasWorkspaceReport(_ project: LearningProject) -> Bool {
        notes.contains { $0.targetID == "project:\(project.id):verification" }
    }

    private func milestones(_ project: LearningProject) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("项目实施步骤")
                .font(.title3.bold())

            ForEach(Array(project.milestones.enumerated()), id: \.element.id) { index, milestone in
                let done = isCompleted(milestone)
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: done ? "checkmark.circle.fill" : "\(index + 1).circle.fill")
                            .font(.title3)
                            .foregroundStyle(done ? .green : Color(hex: project.themeHex))
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(milestone.phase.title)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color(hex: project.themeHex))
                                Spacer()
                                if hasEvidence(milestone) {
                                    Label("有证据", systemImage: "paperclip")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.blue)
                                }
                                if done {
                                    Text("已完成")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.green)
                                }
                            }
                            Text(milestone.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(milestone.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineSpacing(3)
                        }
                    }

                    if !milestone.outputs.isEmpty {
                        detailLine(title: "产物", values: milestone.outputs, icon: "shippingbox")
                    }
                    if !milestone.checks.isEmpty {
                        detailLine(title: "通过标准", values: milestone.checks, icon: "checkmark.shield")
                    }

                    HStack {
                        Button {
                            noteMilestone = milestone
                        } label: {
                            Label(hasEvidence(milestone) ? "查看证据" : "写工程证据", systemImage: hasEvidence(milestone) ? "note.text" : "square.and.pencil")
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)

                        Spacer()

                        Button {
                            toggle(milestone)
                        } label: {
                            Label(done ? "标记未完成" : "通过本阶段", systemImage: done ? "arrow.uturn.backward" : "checkmark.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(done ? .secondary : .green)
                    }
                }
                .learningCard()
            }
        }
    }

    private func detailLine(title: String, values: [String], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(values, id: \.self) { value in
                Text("· \(value)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 42)
    }

    private func qualityGates(_ project: LearningProject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("质量门禁", systemImage: "checkmark.shield.fill")
                .font(.title3.bold())
            ForEach(project.qualityGates, id: \.self) { gate in
                Label(gate, systemImage: "diamond.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .learningCard()
    }

    @ViewBuilder
    private func openSourceReading(_ project: LearningProject) -> some View {
        let missions = project.readingMissionIDs.compactMap(OpenSourceReadingCatalog.mission)
        if !missions.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("配套开源阅读", systemImage: "doc.text.magnifyingglass")
                    .font(.title3.bold())
                Text("先读真实项目的结构，再回来实现自己的版本。每项阅读都有入口路径、追踪任务和证据要求。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(missions) { mission in
                    NavigationLink {
                        OpenSourceReadingDetailView(missionID: mission.id)
                    } label: {
                        HStack(spacing: 11) {
                            Image(systemName: mission.level.icon)
                                .foregroundStyle(.teal)
                                .frame(width: 32, height: 32)
                                .background(.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 9))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mission.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                                Text("\(mission.level.title) · \(mission.repoName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(.tertiary)
                        }
                        .padding(10)
                        .background(.teal.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .learningCard()
        }
    }

    private func deliverables(_ project: LearningProject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("交付物", systemImage: "shippingbox.fill")
                .font(.title3.bold())
            ForEach(project.deliverables, id: \.self) { deliverable in
                Label(deliverable, systemImage: "checkmark.square")
                    .font(.subheadline)
            }
        }
        .learningCard()
    }

    private func releaseChecklist(_ project: LearningProject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("发布清单", systemImage: "flag.checkered")
                .font(.title3.bold())
            ForEach(project.releaseChecklist, id: \.self) { item in
                Label(item, systemImage: "square")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .learningCard()
    }

    private func acceptanceCard(_ project: LearningProject) -> some View {
        let color = Color(hex: project.themeHex)
        return VStack(alignment: .leading, spacing: 10) {
            Label("结业验收", systemImage: "checkmark.seal.fill")
                .font(.title3.bold())
            Text(progress >= 1 ? "项目里程碑全部完成。请按 README 从干净环境重新运行，提供质量门禁和发布清单证据，并准备三分钟演示。" : "完成全部里程碑后，按照仓库地图从空目录重建一次，验证安装、运行、错误处理、安全边界和恢复流程。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .padding(16)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.18))
        }
    }

    private func projectBrief(_ project: LearningProject) -> String {
        var lines = [
            "# \(project.title)",
            "",
            project.summary,
            "",
            "## 目标",
            "",
            "- 工程轨道：\(project.track.title)",
            "- 难度：\(project.level)",
            "- 预计工时：\(project.estimatedHours) 小时",
            "- 技术标签：\(project.tags.joined(separator: "、"))",
            "",
            "## 仓库结构",
            ""
        ]
        lines += project.repository.map { "- `\($0.path)`：\($0.purpose)" }
        lines += ["", "## 质量门禁", ""]
        lines += project.qualityGates.map { "- [ ] \($0)" }
        lines += ["", "## 里程碑", ""]
        lines += project.milestones.enumerated().map { "\($0.offset + 1). \($0.element.title)：\($0.element.detail)" }
        lines += ["", "## 发布清单", ""]
        lines += project.releaseChecklist.map { "- [ ] \($0)" }
        return lines.joined(separator: "\n")
    }

    private func evidenceTargetID(_ milestone: ProjectMilestone) -> String {
        "project:\(projectID):milestone:\(milestone.id):evidence"
    }

    private func hasEvidence(_ milestone: ProjectMilestone) -> Bool {
        notes.contains { $0.targetID == evidenceTargetID(milestone) }
    }

    private func itemID(_ milestone: ProjectMilestone) -> String {
        "project:\(projectID):milestone:\(milestone.id)"
    }

    private func isCompleted(_ milestone: ProjectMilestone) -> Bool {
        progressRecords.contains { $0.itemID == itemID(milestone) && $0.isCompleted }
    }

    private func toggle(_ milestone: ProjectMilestone) {
        ProgressService.setCompleted(!isCompleted(milestone), itemID: itemID(milestone), in: modelContext)
    }
}
