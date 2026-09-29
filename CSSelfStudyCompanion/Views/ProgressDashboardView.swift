import SwiftData
import SwiftUI

struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Stage.order) private var stages: [Stage]
    @Query private var tutorials: [Tutorial]
    @Query private var exercises: [Exercise]
    @Query(sort: \Progress.lastStudiedAt, order: .reverse) private var progressRecords: [Progress]
    @Query(sort: \Concept.name) private var concepts: [Concept]
    @Query(sort: \MasteryRecord.score) private var masteryRecords: [MasteryRecord]
    @Query(sort: \ReviewItem.dueAt) private var reviewItems: [ReviewItem]

    @State private var showResetConfirmation = false
    @StateObject private var syncManager = SyncManager.shared
    @StateObject private var cloudSync = CloudSyncService.shared
    @AppStorage(StudyReminderService.enabledKey) private var reminderEnabled = false
    @AppStorage(StudyReminderService.hourKey) private var reminderHour = 20
    @AppStorage(StudyReminderService.minuteKey) private var reminderMinute = 0
    @State private var reminderTime = Date()
    @State private var reminderStatus = ""
    @AppStorage("cloudSyncEnabled") private var cloudSyncEnabled = false
    @AppStorage("cloudKitContainerIdentifier") private var cloudKitContainerIdentifier = ""
    @State private var cloudSyncMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    summaryCard
                    masteryCard
                    recommendationCard
                    focusCard
                    stageBreakdown
                    recentActivity
                    reminderCard
                    syncCard
                    cloudSyncCard
                    performanceCard
                    releaseReadinessCard
                    dataPortabilityCard
                    resetCard
                }
                .padding()
                .learningPageWidth()
            }
            .background(Color.appBackground)
            .navigationTitle("学习进度")
            .toolbar {
                ToolbarItem(placement: .primaryAction) { GuideLink() }
            }
            .navigationDestination(for: AppRoute.self) { route in
                AppDestinationView(route: route)
            }
            .confirmationDialog(
                "确定清空全部学习进度吗？",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("清空进度", role: .destructive) {
                    ProgressService.resetAll(in: modelContext)
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("课程内容不会被删除，只清除完成状态和学习记录。")
            }
        }
        .tint(.green)
        .onAppear {
            reminderTime = Calendar.current.date(
                bySettingHour: reminderHour,
                minute: reminderMinute,
                second: 0,
                of: Date()
            ) ?? Date()
            Task {
                await StudyReminderService.refreshFromDefaults()
                await cloudSync.refreshStatus()
            }
        }
    }

    private var cloudSyncCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("CloudKit 跨网络同步", systemImage: "icloud.and.arrow.up")
                    .font(.headline)
                Spacer()
                Text(cloudSync.status.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(cloudSync.status == .available ? .green : .secondary)
            }

            Toggle("启用 CloudKit", isOn: $cloudSyncEnabled)
                .onChange(of: cloudSyncEnabled) { _, _ in
                    Task { await cloudSync.refreshStatus() }
                }

            TextField("iCloud Container Identifier", text: $cloudKitContainerIdentifier)
                .textFieldStyle(.roundedBorder)
                .onChange(of: cloudKitContainerIdentifier) { _, _ in
                    Task { await cloudSync.refreshStatus() }
                }

            Text("跨网络同步需要付费 Apple Developer 账号、iCloud Container 和对应 Entitlement。未配置时，局域网 Mac ↔ iPhone 同步仍然正常工作；上传和下载只在 iCloud 状态可用时启用。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            HStack {
                Button("检查状态") {
                    Task { await cloudSync.refreshStatus() }
                }
                .buttonStyle(.bordered)

                Button("上传备份") {
                    uploadToCloud()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!cloudSyncEnabled || cloudSync.status != .available || cloudSync.isTransferring)

                Button("下载并合并") {
                    downloadFromCloud()
                }
                .buttonStyle(.bordered)
                .disabled(!cloudSyncEnabled || cloudSync.status != .available || cloudSync.isTransferring)
            }
            .controlSize(.small)

            if !cloudSyncMessage.isEmpty {
                Text(cloudSyncMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .learningCard()
    }

    private func uploadToCloud() {
        cloudSyncMessage = "正在上传…"
        Task {
            do {
                let data = try DataPortabilityService.data(from: modelContext)
                try await cloudSync.upload(data)
                await MainActor.run {
                    cloudSyncMessage = "云端备份已更新。"
                }
            } catch {
                await MainActor.run {
                    cloudSyncMessage = "上传失败：\(error.localizedDescription)"
                }
            }
        }
    }

    private func downloadFromCloud() {
        cloudSyncMessage = "正在下载…"
        Task {
            do {
                guard let data = try await cloudSync.download() else {
                    await MainActor.run { cloudSyncMessage = "云端还没有备份。" }
                    return
                }
                try DataPortabilityService.restore(from: data, into: modelContext)
                await MainActor.run { cloudSyncMessage = "云端备份已下载并合并。" }
            } catch {
                await MainActor.run {
                    cloudSyncMessage = "下载失败：\(error.localizedDescription)"
                }
            }
        }
    }

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("每日学习提醒", systemImage: "bell.badge.fill")
                .font(.title3.bold())

            Toggle("开启每日提醒", isOn: $reminderEnabled)
                .onChange(of: reminderEnabled) { _, enabled in
                    scheduleReminder(enabled: enabled)
                }

            DatePicker(
                "提醒时间",
                selection: $reminderTime,
                displayedComponents: .hourAndMinute
            )
            .disabled(!reminderEnabled)
            .onChange(of: reminderTime) { _, _ in
                guard reminderEnabled else { return }
                scheduleReminder(enabled: true)
            }

            if !reminderStatus.isEmpty {
                Text(reminderStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .learningCard()
    }

    private func scheduleReminder(enabled: Bool) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        reminderHour = components.hour ?? 20
        reminderMinute = components.minute ?? 0

        Task {
            let success = await StudyReminderService.setEnabled(
                enabled,
                hour: reminderHour,
                minute: reminderMinute
            )
            await MainActor.run {
                if enabled && !success {
                    reminderEnabled = false
                    reminderStatus = "系统未授予通知权限，请到系统设置中允许通知。"
                } else if enabled {
                    reminderStatus = "已设置每天 \(String(format: "%02d:%02d", reminderHour, reminderMinute)) 提醒。"
                } else {
                    reminderStatus = "每日提醒已关闭。"
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("总进度")
                .font(.title2.bold())
            HStack(spacing: 20) {
                progressRing(
                    value: completionRatio,
                    title: "全部任务",
                    detail: "\(completedTaskCount)/\(totalTaskCount)"
                )
                VStack(alignment: .leading, spacing: 10) {
                    metric("已完成教程", "\(completedTutorialCount)", color: .indigo)
                    metric("已完成练习", "\(completedExerciseCount)", color: .green)
                    metric("完成主题", "\(completedTopicCount)", color: .orange)
                }
            }
        }
        .learningCard()
    }

    private var masteryCard: some View {
        let activeRecords = masteryRecords.filter { $0.attempts > 0 }
        let average = MasteryService.averageMastery(records: activeRecords)
        let weak = MasteryService.weakConcepts(concepts: concepts, records: masteryRecords, limit: 4)

        return VStack(alignment: .leading, spacing: 15) {
            HStack {
                Label("知识掌握度", systemImage: "brain.head.profile")
                    .font(.title3.bold())
                Spacer()
                Text("\(Int(average * 100))%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.purple)
            }

            if activeRecords.isEmpty {
                Text("完成主动回忆、练习或代码判题后，这里会开始计算概念掌握度。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 14) {
                    masteryRing(average)
                    VStack(alignment: .leading, spacing: 8) {
                        metric("已评估概念", "\(activeRecords.count)", color: .purple)
                        metric("需要加强", "\(weak.count)", color: .orange)
                        metric("熟练概念", "\(activeRecords.filter { $0.score >= 0.85 }.count)", color: .green)
                    }
                }

                if !weak.isEmpty {
                    Divider()
                    Text("优先加强")
                        .font(.subheadline.bold())
                    ForEach(weak) { item in
                        NavigationLink(value: AppRoute.concept(item.concept.id)) {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.concept.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    LearningProgressBar(value: item.record.score, tint: .orange)
                                }
                                Text("\(Int(item.record.score * 100))%")
                                    .font(.caption.monospacedDigit().bold())
                                    .foregroundStyle(.orange)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .learningCard()
    }

    private var recommendationCard: some View {
        let dueCount = ReviewService.dueItems(from: reviewItems).count
        let weak = MasteryService.weakConcepts(concepts: concepts, records: masteryRecords, limit: 1).first

        let title: String
        let subtitle: String
        let icon: String
        let tint: Color

        if dueCount > 0 {
            title = "先完成今日复习"
            subtitle = "有 \(dueCount) 项内容已经到期，优先巩固长期记忆。"
            icon = "brain.head.profile"
            tint = .teal
        } else if let weak {
            title = "加强概念：\(weak.concept.name)"
            subtitle = "当前掌握度 \(Int(weak.record.score * 100))%。回到相关教程并完成一次主动回忆。"
            icon = "target"
            tint = .orange
        } else {
            title = "继续推进当前阶段"
            subtitle = nextStage.map { "下一阶段：\($0.title)" } ?? "开始新的学习阶段。"
            icon = "arrow.forward.circle.fill"
            tint = .indigo
        }

        return HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 4) {
                Text("个性化推荐")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .learningCard()
    }

    private func masteryRing(_ value: Double) -> some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 9)
            Circle()
                .trim(from: 0, to: value)
                .stroke(.purple.gradient, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(value * 100))%")
                .font(.subheadline.monospacedDigit().bold())
        }
        .frame(width: 92, height: 92)
    }

    @ViewBuilder
    private var focusCard: some View {
        if let stage = nextStage {
            let value = progress(for: stage)
            let color = Color(hex: stage.themeHex)

            HStack(spacing: 14) {
                Image(systemName: stage.icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 15))

                VStack(alignment: .leading, spacing: 5) {
                    Text("下一步学习")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color)
                    Text("阶段 \(stage.order) · \(stage.title)")
                        .font(.headline)
                    Text(stage.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    LearningProgressBar(value: value, tint: color)
                }
            }
            .learningCard()
        }
    }

    private var nextStage: Stage? {
        stages.first { progress(for: $0) < 0.999 } ?? stages.last
    }

    private var stageBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("阶段进度")
                .font(.title3.bold())
            ForEach(stages) { stage in
                let value = progress(for: stage)
                HStack(spacing: 12) {
                    Image(systemName: stage.icon)
                        .foregroundStyle(Color(hex: stage.themeHex))
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("阶段 \(stage.order) · \(stage.title)")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(Int(value * 100))%")
                                .font(.caption.monospacedDigit().bold())
                                .foregroundStyle(.secondary)
                        }
                        LearningProgressBar(value: value, tint: Color(hex: stage.themeHex))
                    }
                }
            }
        }
        .learningCard()
    }

    @ViewBuilder
    private var recentActivity: some View {
        let recent = progressRecords.filter(\.isCompleted).prefix(5)
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("最近完成")
                    .font(.title3.bold())
                ForEach(Array(recent)) { record in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayName(for: record.itemID))
                                .font(.subheadline.weight(.semibold))
                            Text(record.completedAt ?? record.lastStudiedAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .learningCard()
        }
    }

    private var syncCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Mac ↔ iPhone 实时同步", systemImage: "arrow.triangle.2.circlepath")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(syncManager.connectedPeers.isEmpty ? .orange : .green)
                    .frame(width: 9, height: 9)
            }

            Text(syncManager.statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("首次使用需允许本地网络访问；两台设备需要连接同一 Wi-Fi，并在前台打开 App。数据只在发生变化时增量发送。")
                .font(.caption)
                .foregroundStyle(.tertiary)

            if !syncManager.connectedPeers.isEmpty {
                Label("iPhone 可以通过这台 Mac 编译和运行代码", systemImage: "chevron.left.forwardslash.chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.indigo)
            }

            if let lastSyncAt = syncManager.lastSyncAt {
                Text("最近同步：\(lastSyncAt.formatted(date: .abbreviated, time: .standard))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            HStack {
                if syncManager.connectedPeers.isEmpty {
                    Label("请确认两台设备连接同一 Wi-Fi", systemImage: "wifi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Label(syncManager.connectedPeers.joined(separator: "、"), systemImage: "laptopcomputer.and.iphone")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
                Spacer()
                Button {
                    syncManager.syncNow()
                } label: {
                    Label("立即同步", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(syncManager.connectedPeers.isEmpty || syncManager.isSyncing)
            }
        }
        .learningCard()
    }

    private var performanceCard: some View {
        NavigationLink(value: AppRoute.performance) {
            HStack(spacing: 14) {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.purple.gradient, in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text("性能与稳定性")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("查看启动、数据库、同步和执行指标")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .learningCard()
        }
        .buttonStyle(.plain)
    }

    private var releaseReadinessCard: some View {
        NavigationLink(value: AppRoute.releaseReadiness) {
            HStack(spacing: 14) {
                Image(systemName: "shippingbox.and.arrow.backward.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.orange.gradient, in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text("发布就绪检查")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("检查版本、签名、权限和分发要求")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .learningCard()
        }
        .buttonStyle(.plain)
    }

    private var dataPortabilityCard: some View {
        NavigationLink {
            DataPortabilityView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "externaldrive.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.blue.gradient, in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text("数据与备份")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("在 Mac 与 iPhone 之间导出、导入学习数据")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .learningCard()
        }
        .buttonStyle(.plain)
    }

    private var resetCard: some View {
        Button(role: .destructive) {
            showResetConfirmation = true
        } label: {
            Label("重置全部进度", systemImage: "arrow.counterclockwise")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    private func progressRing(value: Double, title: String, detail: String) -> some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 10)
            Circle()
                .trim(from: 0, to: value)
                .stroke(.green.gradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(Int(value * 100))%")
                    .font(.title3.bold())
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 120, height: 120)
        .accessibilityLabel(title)
        .accessibilityValue("\(Int(value * 100))%")
    }

    private func metric(_ title: String, _ value: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit().bold())
        }
    }

    private var totalTaskCount: Int {
        tutorials.count + exercises.count
    }

    private var completedTaskCount: Int {
        completedTutorialCount + completedExerciseCount
    }

    private var completionRatio: Double {
        guard totalTaskCount > 0 else { return 0 }
        return Double(completedTaskCount) / Double(totalTaskCount)
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

    private var completedTopicCount: Int {
        stages.flatMap(\.topics).filter(topicCompleted).count
    }

    private func progress(for stage: Stage) -> Double {
        guard !stage.topics.isEmpty else { return 0 }
        return Double(stage.topics.filter(topicCompleted).count) / Double(stage.topics.count)
    }

    private func topicCompleted(_ topic: Topic) -> Bool {
        let itemIDs = topic.tutorials.map { String.tutorialProgressID($0.id) }
            + topic.exercises.map { String.exerciseProgressID($0.id) }
        guard !itemIDs.isEmpty else { return false }
        return itemIDs.allSatisfy { id in
            progressRecords.contains { $0.itemID == id && $0.isCompleted }
        }
    }

    private func displayName(for itemID: String) -> String {
        let parts = itemID.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return itemID }
        if parts[0] == "tutorial" {
            return tutorials.first { $0.id == parts[1] }?.title ?? "教程"
        }
        return exercises.first { $0.id == parts[1] }?.title ?? "练习"
    }
}
