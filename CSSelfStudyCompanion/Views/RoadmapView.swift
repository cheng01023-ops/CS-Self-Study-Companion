import SwiftData
import SwiftUI

struct RoadmapView: View {
    @Query(sort: \Stage.order) private var stages: [Stage]
    @Query private var progressRecords: [Progress]
    @Query private var tutorials: [Tutorial]
    @Query private var exercises: [Exercise]
    @Query(sort: \Concept.name) private var concepts: [Concept]
    @Query(sort: \MasteryRecord.score) private var masteryRecords: [MasteryRecord]
    @Query(sort: \ReviewItem.dueAt) private var reviewItems: [ReviewItem]

    @State private var path: [AppRoute] = []
    @AppStorage("recommendedStartStage") private var recommendedStartStage = 0
    @AppStorage("showAllRoadmapStages") private var showAllRoadmapStages = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    hero
                    dailyFocusCard
                    dailyPlanCard
                    adaptivePathPreview
                    quickTools
                    projectsPreview
                    labsPreview
                    ForEach(visibleStages) { stage in
                        StageCard(
                            stage: stage,
                            progress: progress(for: stage)
                        ) {
                            path.append(.stage(stage.id))
                        }
                    }
                    if stages.count > visibleStages.count || showAllRoadmapStages {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showAllRoadmapStages.toggle()
                            }
                        } label: {
                            Label(
                                showAllRoadmapStages ? "只显示当前阶段" : "展开全部 \(stages.count) 个阶段",
                                systemImage: showAllRoadmapStages ? "arrow.up.circle" : "arrow.down.circle"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("toggle-all-stages")
                    }
                }
                .padding()
                .learningPageWidth()
            }
            .background(Color.appBackground)
            .navigationTitle("CS 自学")
            .toolbar {
                ToolbarItem(placement: .primaryAction) { GuideLink() }
            }
            .navigationDestination(for: AppRoute.self) { route in
                AppDestinationView(route: route)
            }
        }
        .tint(.indigo)
        .onReceive(NotificationCenter.default.publisher(for: .openAppRoute)) { notification in
            guard let route = notification.object as? AppRoute else { return }
            path.append(route)
        }
        .task {
            await SystemIntegrationService.indexSearchableContent(
                tutorials: tutorials,
                commands: []
            )
        }
    }

    private var hero: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "263B8F"), Color(hex: "4F59C9"), Color(hex: "16A6A0")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(.white.opacity(0.1))
                .frame(width: 180, height: 180)
                .offset(x: 55, y: -65)

            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 74, weight: .bold))
                .foregroundStyle(.white.opacity(0.1))
                .offset(x: -24, y: 76)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 7) {
                    Label("从 Mac 零基础开始", systemImage: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.82))
                    Text("把计算机科学拆成一条能走完的路线")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("每个阶段都有分步教程、代码练习和命令速查。先运行，再理解，最后独立重写。")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                        .lineSpacing(3)
                }

                Divider()
                    .overlay(.white.opacity(0.25))

                HStack {
                    Label("\(completedTutorialCount)/\(tutorials.count) 篇教程", systemImage: "book.closed.fill")
                    Spacer()
                    Label("\(completedExerciseCount)/\(exercises.count) 道练习", systemImage: "checkmark.seal.fill")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.88))

                HStack(spacing: 10) {
                    LearningProgressBar(value: overallProgress, tint: .white)
                    Text("\(Int(overallProgress * 100))%")
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(.white)
                        .frame(width: 42, alignment: .trailing)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .shadow(color: .indigo.opacity(0.2), radius: 14, y: 7)
    }

    private var dailyFocusCard: some View {
        let dueCount = ReviewService.dueItems(from: reviewItems).count
        let weak = MasteryService.weakConcepts(concepts: concepts, records: masteryRecords, limit: 1).first
        let adaptive = adaptiveSnapshot.nextItem
        let stage = nextStage

        let color: Color
        let title: String
        let subtitle: String
        let icon: String
        let route: AppRoute?

        if dueCount > 0 {
            color = .teal
            title = "完成 \(dueCount) 项到期复习"
            subtitle = "先巩固长期记忆，再继续学习新内容。"
            icon = "brain.head.profile"
            route = nil
        } else if let adaptive {
            color = adaptiveColor(adaptive.level)
            title = adaptiveTitle(adaptive)
            subtitle = adaptive.reason
            icon = adaptive.level.icon
            route = adaptiveRoute(adaptive)
        } else if let weak {
            color = .orange
            title = "加强概念：\(weak.concept.name)"
            subtitle = "掌握度 \(Int(weak.record.score * 100))%，建议完成一次主动回忆和练习。"
            icon = "target"
            route = .practiceStudio
        } else {
            color = stage.map { Color(hex: $0.themeHex) } ?? .indigo
            title = stage.map { "继续阶段 \($0.order)：\($0.title)" } ?? "所有阶段都已完成"
            subtitle = stage?.subtitle ?? "可以回顾错题并完成综合项目。"
            icon = stage?.icon ?? "flag.checkered"
            route = stage.map { .stage($0.id) }
        }

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.13))
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(color)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text("今日建议")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if let route {
                NavigationLink(value: route) {
                    Image(systemName: "arrow.right")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(color.gradient, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("继续学习")
            }
        }
        .learningCard()
    }

    private var adaptivePathPreview: some View {
        let snapshot = adaptiveSnapshot
        let next = snapshot.nextItem
        return NavigationLink(value: AppRoute.adaptivePath) {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        LinearGradient(colors: [.indigo, .teal], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 13)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("自适应学习路线")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(Int(snapshot.overallReadiness * 100))% 就绪")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(.indigo)
                    }
                    if let next {
                        Text(adaptiveTitle(next))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(next.reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("所有教程均已完成，继续复习或挑战项目。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 10) {
                        Label("\(snapshot.readyCount) 可开始", systemImage: "play.circle")
                        Label("\(snapshot.bridgeCount) 需补桥", systemImage: "arrow.triangle.branch")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .learningCard()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("adaptive-path-link")
    }

    private var dailyPlanCard: some View {
        let plan = dailyPlan
        return VStack(alignment: .leading, spacing: 13) {
            HStack {
                Label("今日三步计划", systemImage: "checklist")
                    .font(.title3.bold())
                Spacer()
                Text("约 \(plan.reduce(0) { $0 + $1.minutes }) 分钟")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if recommendedStartStage > 0, !progressRecords.contains(where: { $0.itemID == .tutorialProgressID("tutorial-mac-terminal") && $0.isCompleted }) {
                Text("入学诊断建议你从阶段 \(recommendedStartStage) 开始。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.indigo)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.indigo.opacity(0.09), in: Capsule())
            }

            ForEach(plan) { item in
                if let route = item.route {
                    NavigationLink(value: route) {
                        planRow(item)
                    }
                    .buttonStyle(.plain)
                } else {
                    planRow(item)
                }
            }
        }
        .learningCard()
    }

    private func planRow(_ item: StudyPlanItem) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: item.icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.indigo)
                .frame(width: 28, height: 28)
                .background(.indigo.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text(item.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 6)
            Text("\(item.minutes)m")
                .font(.caption.monospacedDigit().weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    private var dailyPlan: [StudyPlanItem] {
        let dueCount = ReviewService.dueItems(from: reviewItems).count
        let weak = MasteryService.weakConcepts(concepts: concepts, records: masteryRecords, limit: 1).first
        let completedIDs = Set(
            tutorials
                .filter { tutorial in
                    progressRecords.contains {
                        $0.itemID == .tutorialProgressID(tutorial.id) && $0.isCompleted
                    }
                }
                .map(\.id)
        )
        return StudyPlanService.makePlan(
            dueReviewCount: dueCount,
            weakConcept: weak,
            tutorials: tutorials,
            completedTutorialIDs: completedIDs,
            preferredTutorialID: adaptiveSnapshot.nextItem?.recommendedTutorial.id
        )
    }

    private var quickTools: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                quickStat(icon: "list.number", title: "分步教程", detail: "40+ 章节", tint: .indigo)
                quickStat(icon: "chevron.left.forwardslash.chevron.right", title: "C 与 Swift", detail: "运行验证", tint: .purple)
                NavigationLink(value: AppRoute.adaptivePath) {
                    quickStat(icon: "point.3.connected.trianglepath.dotted", title: "自适应路线", detail: "\(adaptiveSnapshot.readyCount) 可开始", tint: .indigo)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("quick-adaptive-path")
                NavigationLink(value: AppRoute.practiceStudio) {
                    quickStat(icon: "bolt.fill", title: "动态训练", detail: "薄弱概念混练", tint: .orange)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("quick-practice-studio")
                NavigationLink(value: AppRoute.codeReading) {
                    quickStat(icon: "doc.text.magnifyingglass", title: "代码阅读", detail: "\(OpenSourceReadingCatalog.missions.count) 条路线", tint: .teal)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("quick-code-reading")
                quickStat(icon: "terminal.fill", title: "命令速查", detail: "52 条", tint: .orange)
                quickStat(icon: "chart.bar.xaxis", title: "进度追踪", detail: "随时续学", tint: .green)
            }
        }
    }

    private func quickStat(icon: String, title: String, detail: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(tint)
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 132, alignment: .leading)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        }
    }

    private var projectsPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("项目制课程", systemImage: "hammer.fill")
                    .font(.title3.bold())
                Spacer()
                NavigationLink(value: AppRoute.portfolio) {
                    Label("作品集", systemImage: "folder.badge.gearshape")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("project-portfolio-link")
                Text("\(ProjectCatalog.projects.count) 项工程 · \(ProjectTrack.allCases.count) 轨道")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ProjectCatalog.projects) { project in
                        NavigationLink(value: AppRoute.project(project.id)) {
                            VStack(alignment: .leading, spacing: 9) {
                                Image(systemName: project.icon)
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: project.themeHex))
                                Text(project.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(project.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                                Spacer()
                                Text("\(project.track.title) · \(project.level) · \(project.estimatedHours)h")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color(hex: project.themeHex))
                                    .lineLimit(1)
                            }
                            .padding(15)
                            .frame(width: 205, height: 172, alignment: .leading)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: project.themeHex).opacity(0.12), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 17)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 17)
                                    .stroke(Color(hex: project.themeHex).opacity(0.18))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var labsPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("互动实验室", systemImage: "testtube.2")
                .font(.title3.bold())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LabCatalog.labs) { lab in
                        NavigationLink(value: AppRoute.lab(lab.id)) {
                            VStack(alignment: .leading, spacing: 9) {
                                Image(systemName: lab.icon)
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: lab.themeHex))
                                Text(lab.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(lab.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                                Spacer()
                            }
                            .padding(15)
                            .frame(width: 210, height: 145, alignment: .leading)
                            .background(Color(hex: lab.themeHex).opacity(0.1), in: RoundedRectangle(cornerRadius: 17))
                            .overlay {
                                RoundedRectangle(cornerRadius: 17)
                                    .stroke(Color(hex: lab.themeHex).opacity(0.18))
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("lab-\(lab.id)")
                    }
                }
            }
        }
    }

    private var adaptiveSnapshot: AdaptiveLearningSnapshot {
        AdaptiveLearningService.snapshot(
            tutorials: tutorials,
            concepts: concepts,
            masteryRecords: masteryRecords,
            progressRecords: progressRecords
        )
    }

    private func adaptiveTitle(_ item: AdaptiveTutorialReadiness) -> String {
        if item.recommendedTutorial.id != item.tutorial.id {
            return "先补桥：\(item.recommendedTutorial.title)"
        }
        return "继续学习：\(item.tutorial.title)"
    }

    private func adaptiveRoute(_ item: AdaptiveTutorialReadiness) -> AppRoute {
        if item.level == .ready {
            return .tutorial(item.tutorial.id)
        }
        if let remediation = item.remediationTutorials.first {
            return .tutorial(remediation.id)
        }
        if let concept = item.missingConcepts.first {
            return .concept(concept.concept.id)
        }
        return .tutorial(item.tutorial.id)
    }

    private func adaptiveColor(_ level: AdaptiveReadinessLevel) -> Color {
        switch level {
        case .completed: .green
        case .ready: .indigo
        case .nearlyReady: .orange
        case .needsBridge: .red
        }
    }

    private var visibleStages: [Stage] {
        guard !showAllRoadmapStages, stages.count > 4 else { return stages }
        let nextOrder = nextStage?.order ?? stages.first?.order ?? 0
        let start = max(0, min(stages.count - 4, nextOrder - 1))
        return Array(stages[start..<min(stages.count, start + 4)])
    }

    private var nextStage: Stage? {
        stages.first { progress(for: $0) < 0.999 } ?? stages.last
    }

    private var overallProgress: Double {
        let total = tutorials.count + exercises.count
        guard total > 0 else { return 0 }
        return Double(completedTutorialCount + completedExerciseCount) / Double(total)
    }

    private var completedTutorialCount: Int {
        tutorials.filter { tutorial in
            progressRecords.contains { $0.itemID == .tutorialProgressID(tutorial.id) && $0.isCompleted }
        }.count
    }

    private var completedExerciseCount: Int {
        exercises.filter { exercise in
            progressRecords.contains { $0.itemID == .exerciseProgressID(exercise.id) && $0.isCompleted }
        }.count
    }

    private func progress(for stage: Stage) -> Double {
        let topicCount = stage.topics.count
        guard topicCount > 0 else { return 0 }
        let completed = stage.topics.filter(topicCompleted).count
        return Double(completed) / Double(topicCount)
    }

    private func topicCompleted(_ topic: Topic) -> Bool {
        let tutorialIDs = topic.tutorials.map { String.tutorialProgressID($0.id) }
        let exerciseIDs = topic.exercises.map { String.exerciseProgressID($0.id) }
        let required = tutorialIDs + exerciseIDs
        guard !required.isEmpty else { return false }
        return required.allSatisfy { itemID in
            progressRecords.contains { $0.itemID == itemID && $0.isCompleted }
        }
    }

}

private struct StageCard: View {
    let stage: Stage
    let progress: Double
    let action: () -> Void

    private var color: Color { Color(hex: stage.themeHex) }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(color.opacity(0.12))
                        Image(systemName: stage.icon)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(color)
                    }
                    .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("阶段 \(stage.order)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(color)
                        Text(stage.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(stage.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 10) {
                    LearningProgressBar(value: progress, tint: color)
                    Text("\(Int(progress * 100))%")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(color)
                        .frame(width: 38, alignment: .trailing)
                }

                HStack {
                    StatPill(icon: "book", text: "\(stage.topics.count) 个主题")
                    StatPill(icon: "clock", text: "\(totalMinutes) 分钟")
                    Spacer()
                }
            }
            .learningCard()
            .overlay(alignment: .topTrailing) {
                Image(systemName: stage.icon)
                    .font(.system(size: 74, weight: .bold))
                    .foregroundStyle(color.opacity(0.045))
                    .offset(x: -14, y: 22)
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("打开阶段详情")
    }

    private var totalMinutes: Int {
        stage.topics.reduce(0) { $0 + $1.estimatedMinutes }
    }
}
