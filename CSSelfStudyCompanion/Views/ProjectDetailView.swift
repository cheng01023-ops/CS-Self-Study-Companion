import SwiftData
import SwiftUI

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressRecords: [Progress]

    let projectID: String

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
                        milestones(project)
                        deliverables(project)
                        acceptanceCard(project)
                    }
                    .padding()
                    .learningPageWidth()
                }
                .background(Color.appBackground)
                .navigationTitle(project.title)
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
                    Text(project.level)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color)
                    Text(project.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
            }

            HStack(spacing: 8) {
                ForEach(project.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(color.opacity(0.1), in: Capsule())
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

    private func milestones(_ project: LearningProject) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("项目实施步骤")
                .font(.title3.bold())

            ForEach(Array(project.milestones.enumerated()), id: \.element.id) { index, milestone in
                let done = isCompleted(milestone)
                Button {
                    toggle(milestone)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: done ? "checkmark.circle.fill" : "\(index + 1).circle.fill")
                            .font(.title3)
                            .foregroundStyle(done ? .green : Color(hex: project.themeHex))
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(milestone.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(milestone.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineSpacing(3)
                        }
                        Spacer()
                    }
                    .learningCard()
                }
                .buttonStyle(.plain)
            }
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

    private func acceptanceCard(_ project: LearningProject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("结业验收", systemImage: "checkmark.seal.fill")
                .font(.title3.bold())
            Text(progress >= 1 ? "项目里程碑全部完成。请按 README 从干净环境重新运行，并准备三分钟演示。" : "完成全部里程碑后，按照交付物清单从空目录重建一次，验证安装、运行、错误处理和恢复流程。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .padding(16)
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.green.opacity(0.18))
        }
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
