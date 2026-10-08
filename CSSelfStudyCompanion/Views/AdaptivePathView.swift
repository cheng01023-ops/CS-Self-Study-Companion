import SwiftData
import SwiftUI

struct AdaptivePathView: View {
    @Query(sort: \Tutorial.order) private var tutorials: [Tutorial]
    @Query(sort: \Concept.name) private var concepts: [Concept]
    @Query(sort: \MasteryRecord.score) private var masteryRecords: [MasteryRecord]
    @Query private var progressRecords: [Progress]

    private var snapshot: AdaptiveLearningSnapshot {
        AdaptiveLearningService.snapshot(
            tutorials: tutorials,
            concepts: concepts,
            masteryRecords: masteryRecords,
            progressRecords: progressRecords
        )
    }

    var body: some View {
        let snapshot = snapshot

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                header(snapshot)
                if let next = snapshot.nextItem {
                    nextStepCard(next)
                    prerequisiteCard(next)
                } else {
                    allCompleteCard
                }
                readySection(snapshot.readyItems)
                bridgeSection(snapshot.bridgeItems)
            }
            .padding()
            .learningPageWidth(maxWidth: 1080)
        }
        .background(Color.appBackground)
        .navigationTitle("自适应路线")
    }

    private func header(_ snapshot: AdaptiveLearningSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(
                        LinearGradient(
                            colors: [.indigo, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text("知识依赖图谱驱动的学习路线")
                        .font(.title3.bold())
                    Text("系统会结合概念前置关系、教程完成度、练习与复习掌握度，判断下一步应该学习什么，以及是否需要先补桥。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
            }

            HStack(spacing: 10) {
                LearningProgressBar(value: snapshot.overallReadiness, tint: .indigo)
                Text("\(Int(snapshot.overallReadiness * 100))%")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(.indigo)
                    .frame(width: 42, alignment: .trailing)
            }

            HStack {
                StatPill(icon: "checkmark.circle.fill", text: "\(snapshot.completedCount) 已完成", tint: .green)
                StatPill(icon: "play.circle.fill", text: "\(snapshot.readyCount) 可开始", tint: .indigo)
                StatPill(icon: "arrow.triangle.branch", text: "\(snapshot.bridgeCount) 需补桥", tint: .orange)
            }
        }
        .learningCard()
    }

    private func nextStepCard(_ item: AdaptiveTutorialReadiness) -> some View {
        let color = color(for: item.level)
        let action = item.recommendedTutorial
        let actionIsBridge = action.id != item.tutorial.id

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: item.level.icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 42, height: 42)
                    .background(color.opacity(0.11), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(actionIsBridge ? "下一步：先补桥" : "下一步推荐")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color)
                    Text(action.title)
                        .font(.title3.bold())
                    Text(item.reason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                Spacer()
            }

            HStack {
                StatPill(icon: "target", text: "目标：\(item.tutorial.title)", tint: .secondary)
                Spacer()
                Text("\(Int(item.score * 100))% 就绪")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(color)
            }

            NavigationLink(value: AppRoute.tutorial(action.id)) {
                Label(actionIsBridge ? "开始补桥教程" : "开始推荐教程", systemImage: "arrow.right.circle.fill")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(color)
        }
        .learningCard()
    }

    @ViewBuilder
    private func prerequisiteCard(_ item: AdaptiveTutorialReadiness) -> some View {
        if !item.prerequisiteConcepts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("前置概念检查", systemImage: "checklist")
                        .font(.title3.bold())
                    Spacer()
                    Text("\(item.missingConcepts.count) 项待补")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(item.missingConcepts.isEmpty ? .green : .orange)
                }

                ForEach(item.prerequisiteConcepts) { readiness in
                    conceptRow(readiness)
                }

                if !item.remediationTutorials.isEmpty {
                    Divider()
                    Text("建议补桥顺序")
                        .font(.subheadline.bold())
                    ForEach(item.remediationTutorials.prefix(4)) { tutorial in
                        NavigationLink(value: AppRoute.tutorial(tutorial.id)) {
                            HStack(spacing: 10) {
                                Image(systemName: "book.pages.fill")
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tutorial.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(tutorial.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(10)
                            .background(.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .learningCard()
        }
    }

    private func conceptRow(_ readiness: AdaptiveConceptReadiness) -> some View {
        let color: Color = readiness.isMastered ? .green : readiness.score >= 0.55 ? .orange : .red
        return VStack(alignment: .leading, spacing: 7) {
            HStack {
                NavigationLink(value: AppRoute.concept(readiness.concept.id)) {
                    Text(readiness.concept.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                Spacer()
                Text("\(Int(readiness.score * 100))%")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(color)
            }
            LearningProgressBar(value: readiness.score, tint: color)
            Text(readiness.evidence.title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func readySection(_ items: [AdaptiveTutorialReadiness]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("现在可以开始", systemImage: "play.circle.fill")
                        .font(.title3.bold())
                        .foregroundStyle(.indigo)
                    Spacer()
                    Text("\(items.count) 项")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }

                ForEach(items.prefix(8)) { item in
                    NavigationLink(value: AppRoute.tutorial(item.tutorial.id)) {
                        readinessRow(item, tint: .indigo, showReason: false)
                    }
                    .buttonStyle(.plain)
                }
            }
            .learningCard()
        }
    }

    @ViewBuilder
    private func bridgeSection(_ items: [AdaptiveTutorialReadiness]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("需要补桥的内容", systemImage: "arrow.triangle.branch")
                        .font(.title3.bold())
                        .foregroundStyle(.orange)
                    Spacer()
                    Text("\(items.count) 项")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }

                ForEach(items.prefix(8)) { item in
                    NavigationLink(value: AppRoute.tutorial(item.recommendedTutorial.id)) {
                        readinessRow(item, tint: color(for: item.level), showReason: true)
                    }
                    .buttonStyle(.plain)
                }
            }
            .learningCard()
        }
    }

    private func readinessRow(
        _ item: AdaptiveTutorialReadiness,
        tint: Color,
        showReason: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: item.level.icon)
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 3) {
                Text(item.tutorial.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                if showReason {
                    Text(item.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    Text(item.tutorial.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(item.level.title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
            Image(systemName: "chevron.right")
                .font(.caption2.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(tint.opacity(0.05), in: RoundedRectangle(cornerRadius: 11))
    }

    private var allCompleteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("主线已经完成", systemImage: "checkmark.seal.fill")
                .font(.title3.bold())
                .foregroundStyle(.green)
            Text("当前教程没有未完成项。可以回到复习中心、挑战综合项目，或通过概念图谱继续查漏补缺。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .learningCard()
    }

    private func color(for level: AdaptiveReadinessLevel) -> Color {
        switch level {
        case .completed: .green
        case .ready: .indigo
        case .nearlyReady: .orange
        case .needsBridge: .red
        }
    }
}

#Preview {
    NavigationStack {
        AdaptivePathView()
    }
    .modelContainer(
        for: [Tutorial.self, Topic.self, Stage.self, Concept.self, MasteryRecord.self, Progress.self],
        inMemory: true
    )
}
