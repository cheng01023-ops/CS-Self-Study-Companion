import SwiftData
import SwiftUI
import UserNotifications

struct ReviewCenterView: View {
    @Query(sort: \ReviewItem.dueAt) private var reviewItems: [ReviewItem]

    @State private var filter: ReviewFilter = .today
    @State private var sessionItems: [ReviewItem] = []

    private var dueItems: [ReviewItem] {
        ReviewService.dueItems(from: reviewItems)
    }

    private var upcomingItems: [ReviewItem] {
        ReviewService.upcomingItems(from: reviewItems)
    }

    private var activeItems: [ReviewItem] {
        reviewItems.filter { !$0.isArchived }.sorted { $0.dueAt < $1.dueAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    summaryCard
                    filterPicker
                    reviewContent
                }
                .padding()
                .learningPageWidth()
            }
            .background(Color.appBackground)
            .navigationTitle("复习中心")
            .toolbar {
                ToolbarItem(placement: .primaryAction) { GuideLink() }
            }
            .navigationDestination(for: AppRoute.self) { route in
                AppDestinationView(route: route)
            }
            .sheet(isPresented: Binding(
                get: { !sessionItems.isEmpty },
                set: { if !$0 { sessionItems = [] } }
            )) {
                ReviewSessionView(items: sessionItems)
            }
        }
        .tint(.teal)
        .task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        }
    }

    private var summaryCard: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "0E7C78"), Color(hex: "20A77F"), Color(hex: "80C76A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "brain.head.profile")
                .font(.system(size: 94, weight: .bold))
                .foregroundStyle(.white.opacity(0.1))
                .offset(x: -18, y: 62)

            VStack(alignment: .leading, spacing: 14) {
                Text("把遗忘变成计划")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("错题和主动回忆会按照 1、3、7、30 天自动安排复习。今天先处理到期内容，再看后续计划。")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineSpacing(3)

                HStack(spacing: 18) {
                    reviewMetric("\(dueItems.count)", title: "今日到期")
                    reviewMetric("\(activeItems.count)", title: "复习中")
                    reviewMetric("\(reviewItems.filter(\.isArchived).count)", title: "已完成")
                }

                Button {
                    if !dueItems.isEmpty {
                        sessionItems = dueItems
                    }
                } label: {
                    Label(dueItems.isEmpty ? "今天没有到期复习" : "开始今日复习", systemImage: "play.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: "0E7C78"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(dueItems.isEmpty)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .shadow(color: .teal.opacity(0.18), radius: 14, y: 7)
    }

    private func reviewMetric(_ value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.monospacedDigit().bold())
                .foregroundStyle(.white)
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.78))
        }
    }

    private var filterPicker: some View {
        Picker("复习筛选", selection: $filter) {
            ForEach(ReviewFilter.allCases) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var reviewContent: some View {
        switch filter {
        case .today:
            if dueItems.isEmpty {
                emptyState(
                    title: "今日复习已完成",
                    subtitle: upcomingItems.first.map { "下一项：\(ReviewService.nextReviewText($0))" } ?? "完成更多教程后会生成复习计划。",
                    icon: "checkmark.seal.fill"
                )
            } else {
                ForEach(dueItems) { item in
                    ReviewItemCard(item: item, primaryAction: {
                        sessionItems = [item]
                    })
                }
            }

        case .wrongAnswers:
            let wrongItems = activeItems.filter { ["exercise", "coding"].contains($0.sourceType) }
            if wrongItems.isEmpty {
                emptyState(title: "暂时没有错题", subtitle: "选择题答错或手动加入编程题后，会出现在这里。", icon: "checkmark.circle")
            } else {
                ForEach(wrongItems) { item in
                    ReviewItemCard(item: item, primaryAction: {
                        sessionItems = [item]
                    })
                }
            }

        case .upcoming:
            if upcomingItems.isEmpty {
                emptyState(title: "没有待安排的复习", subtitle: "完成主动回忆或答错题目后会生成时间计划。", icon: "calendar.badge.clock")
            } else {
                ForEach(upcomingItems) { item in
                    ReviewItemCard(item: item, primaryAction: {
                        sessionItems = [item]
                    })
                }
            }
        }
    }

    private func emptyState(title: String, subtitle: String, icon: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundStyle(.teal)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .learningCard()
    }
}

private enum ReviewFilter: String, CaseIterable, Identifiable {
    case today
    case wrongAnswers
    case upcoming

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "今日复习"
        case .wrongAnswers: "错题本"
        case .upcoming: "复习计划"
        }
    }
}

private struct ReviewItemCard: View {
    let item: ReviewItem
    let primaryAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.headline)
                    Text(item.question)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
                Text(ReviewService.stageDescription(item))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(tint.opacity(0.1), in: Capsule())
            }

            HStack {
                Label(ReviewService.nextReviewText(item), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let route {
                    NavigationLink(value: route) {
                        Label("回到原文", systemImage: "arrow.up.right.square")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    primaryAction()
                } label: {
                    Label(item.dueAt <= .now ? "开始复习" : "提前复习", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(tint)
            }
        }
        .learningCard()
    }

    private var route: AppRoute? {
        guard let tutorialID = item.parentTutorialID else { return nil }
        if let stepIndex = item.stepIndex {
            return .tutorialStep(tutorialID: tutorialID, stepIndex: stepIndex)
        }
        return .tutorial(tutorialID)
    }

    private var icon: String {
        switch item.sourceType {
        case "exercise": "xmark.circle.fill"
        case "coding": "chevron.left.forwardslash.chevron.right"
        default: "brain.head.profile"
        }
    }

    private var tint: Color {
        switch item.sourceType {
        case "exercise": .red
        case "coding": .purple
        default: .teal
        }
    }
}

private struct ReviewSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let items: [ReviewItem]

    @State private var currentIndex = 0
    @State private var revealed = false
    @State private var responseStartedAt = Date.now

    private var currentItem: ReviewItem? {
        items.indices.contains(currentIndex) ? items[currentIndex] : nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                if let currentItem {
                    HStack {
                        Text("第 \(currentIndex + 1) / \(items.count) 项")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        LearningProgressBar(
                            value: items.isEmpty ? 0 : Double(currentIndex) / Double(items.count),
                            tint: .teal
                        )
                        .frame(width: 150)
                    }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Text(currentItem.title)
                                .font(.title2.bold())
                            Text(currentItem.question)
                                .font(.title3)
                                .lineSpacing(4)

                            if revealed {
                                Divider()
                                Label("参考答案", systemImage: "checkmark.seal")
                                    .font(.headline)
                                    .foregroundStyle(.green)
                                Text(currentItem.referenceAnswer)
                                    .font(.body)
                                    .textSelection(.enabled)
                                Text(currentItem.explanation)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineSpacing(4)
                            } else {
                                Text("先在脑中或纸上回答，再展开参考答案。不要直接点击“记住了”。")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .learningCard()
                    }

                    if revealed {
                        HStack(spacing: 10) {
                            Button {
                                record(remembered: false)
                            } label: {
                                Label("没记住", systemImage: "arrow.counterclockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)

                            Button {
                                record(remembered: true)
                            } label: {
                                Label("记住了", systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                    } else {
                        Button {
                            withAnimation {
                                revealed = true
                            }
                        } label: {
                            Label("显示参考答案", systemImage: "eye.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.teal)
                    }
                } else {
                    ContentUnavailableView("没有复习内容", systemImage: "checkmark.seal")
                }
            }
            .padding()
            .navigationTitle("间隔复习")
            .toolbar {
                Button("关闭") { dismiss() }
            }
        }
        #if os(macOS)
        .frame(minWidth: 620, minHeight: 520)
        #endif
    }

    private func record(remembered: Bool) {
        guard let currentItem else { return }
        MasteryService.recordReviewItem(currentItem, remembered: remembered, in: modelContext)
        let responseSeconds = Date.now.timeIntervalSince(responseStartedAt)
        ReviewService.review(
            currentItem,
            remembered: remembered,
            responseSeconds: responseSeconds,
            in: modelContext
        )

        if currentIndex + 1 < items.count {
            withAnimation {
                currentIndex += 1
                revealed = false
                responseStartedAt = .now
            }
        } else {
            dismiss()
        }
    }
}
