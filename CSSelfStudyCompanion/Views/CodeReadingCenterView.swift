import SwiftData
import SwiftUI

private enum CodeReadingMode: String, CaseIterable, Identifiable {
    case reasoning
    case openSource

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reasoning: "代码推理题"
        case .openSource: "开源阅读阶梯"
        }
    }

    var icon: String {
        switch self {
        case .reasoning: "text.magnifyingglass"
        case .openSource: "books.vertical.fill"
        }
    }
}

struct CodeReadingCenterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressRecords: [Progress]
    @Query private var reviewItems: [ReviewItem]

    @State private var mode: CodeReadingMode = .reasoning
    @State private var selectedFocus = "全部"
    @State private var selectedLevel: OpenSourceReadingLevel?

    private var focuses: [String] {
        ["全部"] + Array(Set(CodeReadingCatalog.exercises.map(\.focus))).sorted()
    }

    private var exercises: [CodeReadingExercise] {
        selectedFocus == "全部"
            ? CodeReadingCatalog.exercises
            : CodeReadingCatalog.exercises.filter { $0.focus == selectedFocus }
    }

    private var completedExerciseCount: Int {
        CodeReadingCatalog.exercises.filter { exercise in
            progressRecords.contains {
                $0.itemID == itemID(exercise) && $0.isCompleted
            }
        }.count
    }

    private var completedMissionCount: Int {
        OpenSourceReadingCatalog.missions.filter { mission in
            OpenSourceReadingStage.allCases.allSatisfy { stage in
                progressRecords.contains {
                    $0.itemID == OpenSourceReadingCatalog.stageProgressID(missionID: mission.id, stage: stage.rawValue)
                        && $0.isCompleted
                }
            }
        }.count
    }

    private var visibleLevels: [OpenSourceReadingLevel] {
        OpenSourceReadingLevel.allCases.filter { selectedLevel == nil || $0 == selectedLevel }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                header
                modePicker

                switch mode {
                case .reasoning:
                    reasoningContent
                case .openSource:
                    openSourceContent
                }
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
        .navigationTitle("代码阅读训练")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Label("从推理题走向真实源码", systemImage: "doc.text.magnifyingglass")
                        .font(.title3.bold())
                    Text("先用短代码训练预测和找错，再进入 coreutils、curl、Redis、Linux、LLVM 等真实仓库，建立可复用的源码阅读方法。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
                Spacer()
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.title)
                    .foregroundStyle(.indigo.opacity(0.7))
            }

            HStack {
                StatPill(icon: "text.magnifyingglass", text: "\(completedExerciseCount)/\(CodeReadingCatalog.exercises.count) 推理题", tint: .indigo)
                StatPill(icon: "books.vertical.fill", text: "\(completedMissionCount)/\(OpenSourceReadingCatalog.missions.count) 阅读路线", tint: .teal)
            }
        }
        .learningCard()
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(CodeReadingMode.allCases) { item in
                Button {
                    mode = item
                } label: {
                    Label(item.title, systemImage: item.icon)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(mode == item ? Color.indigo : Color.secondary.opacity(0.08), in: Capsule())
                        .foregroundStyle(mode == item ? .white : .primary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(item == .openSource ? "open-source-reading-mode" : "reasoning-mode")
            }
        }
    }

    @ViewBuilder
    private var reasoningContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("先阅读、预测、找错，再查看解释。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                LearningProgressBar(
                    value: CodeReadingCatalog.exercises.isEmpty ? 0 : Double(completedExerciseCount) / Double(CodeReadingCatalog.exercises.count),
                    tint: .indigo
                )
                .frame(width: 120)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(focuses, id: \.self) { focus in
                        Button {
                            selectedFocus = focus
                        } label: {
                            Text(focus)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 11)
                                .padding(.vertical, 7)
                                .background(
                                    selectedFocus == focus ? Color.indigo : Color.secondary.opacity(0.09),
                                    in: Capsule()
                                )
                                .foregroundStyle(selectedFocus == focus ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .learningCard()

        ForEach(exercises) { exercise in
            exerciseCard(exercise)
        }
    }

    @ViewBuilder
    private var openSourceContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("六级阅读阶梯")
                        .font(.headline)
                    Text("每一级只增加一个阅读维度：入口、模块、协议、存储、系统边界、语言运行时。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(OpenSourceReadingCatalog.missions.count) 条路线")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.teal)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    levelButton(title: "全部等级", level: nil)
                    ForEach(OpenSourceReadingLevel.allCases) { level in
                        levelButton(title: level.title, level: level)
                    }
                }
            }
        }
        .learningCard()

        ForEach(visibleLevels) { level in
            let missions = OpenSourceReadingCatalog.missions(in: level)
            if !missions.isEmpty {
                openSourceLevelSection(level, missions: missions)
            }
        }
    }

    private func levelButton(title: String, level: OpenSourceReadingLevel?) -> some View {
        let selected = selectedLevel == level
        let color = level.map(levelColor) ?? .teal
        return Button {
            selectedLevel = level
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? .white : color)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(selected ? color : color.opacity(0.1), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func openSourceLevelSection(
        _ level: OpenSourceReadingLevel,
        missions: [OpenSourceReadingMission]
    ) -> some View {
        let color = levelColor(level)
        let completed = missions.filter(isMissionCompleted).count

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: level.icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.title)
                        .font(.title3.bold())
                    Text(level.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(completed)/\(missions.count)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(color)
            }

            ForEach(missions) { mission in
                NavigationLink {
                    OpenSourceReadingDetailView(missionID: mission.id)
                } label: {
                    openSourceMissionCard(mission, color: color)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func openSourceMissionCard(_ mission: OpenSourceReadingMission, color: Color) -> some View {
        let completed = isMissionCompleted(mission)
        let completedStages = OpenSourceReadingStage.allCases.filter { stage in
            progressRecords.contains {
                $0.itemID == OpenSourceReadingCatalog.stageProgressID(missionID: mission.id, stage: stage.rawValue)
                    && $0.isCompleted
            }
        }.count

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(mission.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(mission.repoName) · \(mission.language) · \(mission.license)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(color)
                }
                Spacer()
                Text(completed ? "已完成" : "\(completedStages)/6")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(completed ? .green : color)
            }

            Text(mission.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Label("\(mission.entryPoints.count) 个入口", systemImage: "folder")
                Label("\(mission.estimatedMinutes) 分钟", systemImage: "clock")
                Label("\(mission.tasks.count) 个追踪任务", systemImage: "list.bullet.clipboard")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            LearningProgressBar(value: Double(completedStages) / 6, tint: color)
        }
        .learningCard()
    }

    private func isMissionCompleted(_ mission: OpenSourceReadingMission) -> Bool {
        OpenSourceReadingStage.allCases.allSatisfy { stage in
            progressRecords.contains {
                $0.itemID == OpenSourceReadingCatalog.stageProgressID(missionID: mission.id, stage: stage.rawValue)
                    && $0.isCompleted
            }
        }
    }

    private func exerciseCard(_ exercise: CodeReadingExercise) -> some View {
        let selected = answers[exercise.id]
        let isCorrect = selected == exercise.correctIndex
        let completed = progressRecords.contains {
            $0.itemID == itemID(exercise) && $0.isCompleted
        }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.title)
                        .font(.headline)
                    Text("\(exercise.focus) · \(exercise.language.uppercased())")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.indigo)
                }
                Spacer()
                if completed {
                    Label("已掌握", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }

            CodeBlockView(code: exercise.code, language: exercise.language)

            Text(exercise.prompt)
                .font(.subheadline.weight(.semibold))

            ForEach(Array(exercise.options.enumerated()), id: \.offset) { index, option in
                Button {
                    select(index, for: exercise)
                } label: {
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: optionIcon(index, selected: selected, correctIndex: exercise.correctIndex))
                            .foregroundStyle(optionColor(index, selected: selected, correctIndex: exercise.correctIndex))
                        Text(option)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(10)
                    .background(
                        optionBackground(index, selected: selected, correctIndex: exercise.correctIndex),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .buttonStyle(.plain)
            }

            if selected != nil {
                VStack(alignment: .leading, spacing: 6) {
                    Label(isCorrect ? "判断正确" : "需要重新分析", systemImage: isCorrect ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(isCorrect ? .green : .orange)
                    Text(exercise.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                .padding(11)
                .background((isCorrect ? Color.green : Color.orange).opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .learningCard()
    }

    @State private var answers: [String: Int] = [:]

    private func select(_ index: Int, for exercise: CodeReadingExercise) {
        guard answers[exercise.id] == nil else { return }
        answers[exercise.id] = index
        let correct = index == exercise.correctIndex

        ProgressService.setCompleted(
            correct,
            itemID: itemID(exercise),
            score: correct ? 1 : 0,
            in: modelContext
        )
        MasteryService.recordText(
            "\(exercise.title) \(exercise.prompt) \(exercise.explanation)",
            positive: correct,
            reason: correct ? "代码阅读分析正确" : "代码阅读分析错误",
            in: modelContext
        )

        if !correct {
            addToReview(exercise)
        }
    }

    private func addToReview(_ exercise: CodeReadingExercise) {
        let sourceID = "code-reading:\(exercise.id)"
        if let existing = reviewItems.first(where: { $0.sourceID == sourceID }) {
            existing.isArchived = false
            existing.dueAt = .now
            try? modelContext.save()
            return
        }

        modelContext.insert(
            ReviewItem(
                id: "review:\(sourceID)",
                sourceType: "code-reading",
                sourceID: sourceID,
                title: exercise.title,
                question: exercise.prompt,
                referenceAnswer: exercise.options[exercise.correctIndex],
                explanation: exercise.explanation,
                dueAt: .now
            )
        )
        try? modelContext.save()
    }

    private func itemID(_ exercise: CodeReadingExercise) -> String {
        "code-reading:\(exercise.id)"
    }

    private func optionIcon(_ index: Int, selected: Int?, correctIndex: Int) -> String {
        guard let selected else { return "circle" }
        if index == correctIndex { return "checkmark.circle.fill" }
        if index == selected { return "xmark.circle.fill" }
        return "circle"
    }

    private func optionColor(_ index: Int, selected: Int?, correctIndex: Int) -> Color {
        guard let selected else { return .secondary }
        if index == correctIndex { return .green }
        if index == selected { return .red }
        return .secondary
    }

    private func optionBackground(_ index: Int, selected: Int?, correctIndex: Int) -> Color {
        guard let selected else { return Color.secondary.opacity(0.06) }
        if index == correctIndex { return Color.green.opacity(0.1) }
        if index == selected { return Color.red.opacity(0.1) }
        return Color.secondary.opacity(0.05)
    }

    private func levelColor(_ level: OpenSourceReadingLevel) -> Color {
        switch level {
        case .singleFile: .teal
        case .moduleMap: .blue
        case .protocolTrace: .indigo
        case .dataStructure: .orange
        case .systemBoundary: .purple
        case .languageRuntime: .pink
        }
    }
}

private enum OpenSourceReadingStage: Int, CaseIterable, Identifiable {
    case goal
    case repositoryMap
    case entryPoints
    case traceTasks
    case evidence
    case reflection

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .goal: "目标"
        case .repositoryMap: "仓库地图"
        case .entryPoints: "入口路径"
        case .traceTasks: "追踪任务"
        case .evidence: "证据"
        case .reflection: "复盘"
        }
    }

    var subtitle: String {
        switch self {
        case .goal: "明确本次要回答的源码问题"
        case .repositoryMap: "先建立目录和模块地图"
        case .entryPoints: "记录入口、符号和搜索线索"
        case .traceTasks: "沿调用链完成任务清单"
        case .evidence: "保存源码位置、输出和运行证据"
        case .reflection: "写出调用链、边界和未解决问题"
        }
    }

    var icon: String {
        switch self {
        case .goal: "scope"
        case .repositoryMap: "square.grid.3x3.fill"
        case .entryPoints: "signpost.right.and.left.fill"
        case .traceTasks: "point.topleft.down.to.point.bottomright.curvepath"
        case .evidence: "doc.text.magnifyingglass"
        case .reflection: "arrow.triangle.2.circlepath.circle.fill"
        }
    }
}

struct OpenSourceReadingDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressRecords: [Progress]
    @Query private var notes: [LearningNote]
    @Query private var reviewItems: [ReviewItem]

    let missionID: String

    @State private var currentStage = 0
    @State private var evidence = OpenSourceReadingEvidence.empty
    @State private var completedStages: Set<Int> = []
    @State private var completedCheckpoints: Set<Int> = []
    @State private var didLoad = false
    @State private var saveMessage = ""
    @State private var showBrowser = false
    @State private var reviewAdded = false

    private var mission: OpenSourceReadingMission? {
        OpenSourceReadingCatalog.mission(id: missionID)
    }

    private var hasReviewItem: Bool {
        let sourceID = "open-source:\(missionID):review"
        return reviewItems.contains { $0.sourceID == sourceID && !$0.isArchived }
    }

    var body: some View {
        Group {
            if let mission {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        header(mission)
                        stageRail(mission)
                        stageContent(mission)
                    }
                    .padding()
                    .learningPageWidth(maxWidth: 1080)
                }
                .background(Color.appBackground)
                .navigationTitle("开源阅读")
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            showBrowser = true
                        } label: {
                            Label("打开仓库", systemImage: "safari")
                        }
                        Button {
                            saveEvidence(mission)
                        } label: {
                            Label("保存", systemImage: "square.and.arrow.down")
                        }
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomBar(mission)
                }
                .onAppear {
                    loadState(mission)
                }
                .onChange(of: progressRecords.count) { _, _ in
                    refreshCompletion(mission)
                }
                .sheet(isPresented: $showBrowser) {
                    if let url = URL(string: mission.repositoryURL) {
                        InAppBrowserView(url: url)
                            .frame(minWidth: 520, minHeight: 720)
                            .ignoresSafeArea()
                    }
                }
            } else {
                ContentUnavailableView("阅读任务不存在", systemImage: "books.vertical")
            }
        }
    }

    private func header(_ mission: OpenSourceReadingMission) -> some View {
        let color = levelColor(mission.level)
        return VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: mission.level.icon)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 4) {
                    Text(mission.level.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color)
                    Text(mission.repoName)
                        .font(.title3.bold())
                    Text(mission.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                Spacer()
            }

            HStack {
                StatPill(icon: "clock", text: "\(mission.estimatedMinutes) 分钟", tint: color)
                StatPill(icon: "chevron.left.forwardslash.chevron.right", text: mission.language, tint: .indigo)
                StatPill(icon: "doc.badge.gearshape", text: mission.license, tint: .green)
            }

            HStack(spacing: 10) {
                LearningProgressBar(value: Double(completedStages.count) / 6, tint: color)
                Text("\(completedStages.count)/6")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(color)
                    .frame(width: 34, alignment: .trailing)
            }
        }
        .learningCard()
    }

    private func stageRail(_ mission: OpenSourceReadingMission) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(OpenSourceReadingStage.allCases) { stage in
                    let completed = completedStages.contains(stage.rawValue)
                    let unlocked = isStageUnlocked(stage.rawValue)
                    let color = levelColor(mission.level)
                    Button {
                        guard unlocked else { return }
                        currentStage = stage.rawValue
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: completed ? "checkmark.circle.fill" : stage.icon)
                                .font(.title3)
                            Text(stage.title)
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(completed ? .white : unlocked ? color : .secondary)
                        .frame(width: 78)
                        .padding(.vertical, 10)
                        .background(
                            completed ? color : unlocked ? color.opacity(0.1) : Color.secondary.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 13)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!unlocked)
                }
            }
        }
    }

    private func stageContent(_ mission: OpenSourceReadingMission) -> some View {
        let stage = OpenSourceReadingStage(rawValue: currentStage) ?? .goal
        let color = levelColor(mission.level)
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: stage.icon)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(currentStage + 1) / 6 · \(stage.title)")
                        .font(.title2.bold())
                    Text(stage.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            Divider()

            switch stage {
            case .goal:
                goalStage(mission, color: color)
            case .repositoryMap:
                repositoryMapStage(mission, color: color)
            case .entryPoints:
                entryPointsStage(mission)
            case .traceTasks:
                traceTasksStage(mission)
            case .evidence:
                evidenceStage(mission)
            case .reflection:
                reflectionStage(mission)
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [color.opacity(0.08), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(color.opacity(0.17), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func goalStage(_ mission: OpenSourceReadingMission, color: Color) -> some View {
        Text("这次阅读不是浏览仓库首页，而是回答一个可验证的问题：\(mission.reflectionQuestion)")
            .lineSpacing(4)

        VStack(alignment: .leading, spacing: 9) {
            Label("开始前条件", systemImage: "checklist")
                .font(.headline)
            ForEach(mission.prerequisites, id: \.self) { item in
                Label(item, systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))

        HStack {
            if let url = URL(string: mission.repositoryURL) {
                Link(destination: url) {
                    Label("在浏览器打开仓库", systemImage: "safari")
                }
                .buttonStyle(.borderedProminent)
                .tint(color)
            }

            Button {
                showBrowser = true
            } label: {
                Label("应用内阅读", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(.bordered)
            .disabled(URL(string: mission.repositoryURL) == nil)
        }
    }

    @ViewBuilder
    private func repositoryMapStage(_ mission: OpenSourceReadingMission, color: Color) -> some View {
        Text("先根据目录和入口路径建立模块地图。不要从仓库第一行开始阅读。")
            .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 10) {
            Label("入口路径", systemImage: "folder.fill")
                .font(.headline)
            ForEach(mission.entryPoints, id: \.self) { path in
                Text(path)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(color)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
            }
        }

        VStack(alignment: .leading, spacing: 8) {
            Label("建议搜索符号", systemImage: "magnifyingglass")
                .font(.headline)
            FlowLikeText(values: mission.searchSymbols, color: color)
        }

        evidenceEditor(
            title: "仓库地图记录",
            hint: "写出主要模块、调用方向、构建入口和你最不确定的边界……",
            text: $evidence.repositorySnapshot,
            minHeight: 120
        )
    }

    @ViewBuilder
    private func entryPointsStage(_ mission: OpenSourceReadingMission) -> some View {
        Text("为每个入口记录：文件位置、主要函数、谁调用它、它又调用谁。")
            .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 8) {
            Label("搜索线索", systemImage: "text.magnifyingglass")
                .font(.headline)
            ForEach(mission.searchSymbols, id: \.self) { symbol in
                HStack {
                    Text(symbol)
                        .font(.system(.subheadline, design: .monospaced))
                    Spacer()
                    CopyButton(text: symbol, compact: true)
                }
                .padding(10)
                .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            }
        }

        evidenceEditor(
            title: "入口与符号笔记",
            hint: "记录文件、行号、函数、调用者和关键条件……",
            text: $evidence.entryPointNotes,
            minHeight: 150
        )
    }

    @ViewBuilder
    private func traceTasksStage(_ mission: OpenSourceReadingMission) -> some View {
        Text("完成追踪任务并勾选检查点。每一项都应该能在源码或运行证据中定位。")
            .foregroundStyle(.secondary)

        ForEach(Array(mission.tasks.enumerated()), id: \.offset) { index, task in
            Button {
                toggleCheckpoint(index, mission: mission)
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: completedCheckpoints.contains(index) ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundStyle(completedCheckpoints.contains(index) ? .green : .secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        if mission.checkpoints.indices.contains(index) {
                            Text("通过标准：\(mission.checkpoints[index])")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    Spacer()
                }
                .padding(11)
                .background(
                    completedCheckpoints.contains(index) ? Color.green.opacity(0.08) : Color.secondary.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 11)
                )
            }
            .buttonStyle(.plain)
        }

        evidenceEditor(
            title: "调用链记录",
            hint: "用 A → B → C 写出路径，并标出关键分支、错误返回和所有权变化……",
            text: $evidence.callChain,
            minHeight: 160
        )
    }

    @ViewBuilder
    private func evidenceStage(_ mission: OpenSourceReadingMission) -> some View {
        Text("证据要能支持你的结论，而不是只写“我看懂了”。")
            .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 8) {
            Label("本任务需要留下的证据", systemImage: "checkmark.shield.fill")
                .font(.headline)
            ForEach(mission.evidence, id: \.self) { item in
                Label(item, systemImage: "doc.text")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))

        evidenceEditor(
            title: "原始证据",
            hint: "粘贴源码路径、关键函数、命令输出、IR、trace 或测试结果……",
            text: $evidence.rawEvidence,
            minHeight: 180
        )
    }

    @ViewBuilder
    private func reflectionStage(_ mission: OpenSourceReadingMission) -> some View {
        Text("最后用自己的话重建调用链，并明确仍然不确定的边界。")
            .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 8) {
            Label("复盘问题", systemImage: "questionmark.bubble.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text(mission.reflectionQuestion)
                .font(.subheadline)
                .lineSpacing(4)
        }
        .padding(12)
        .background(.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))

        evidenceEditor(
            title: "未解决问题",
            hint: "哪些分支没有追完？哪项结论缺少证据？下一步查什么？",
            text: $evidence.unresolvedQuestions,
            minHeight: 100
        )

        evidenceEditor(
            title: "最终复盘",
            hint: "用不超过 300 字说明入口、调用链、关键数据结构和边界……",
            text: $evidence.reflection,
            minHeight: 140
        )

        HStack {
            Button {
                saveEvidence(mission)
            } label: {
                Label("保存阅读证据", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)

            Button {
                addToReview(mission)
            } label: {
                Label(hasReviewItem || reviewAdded ? "已加入复习" : "加入复习", systemImage: hasReviewItem || reviewAdded ? "checkmark.circle.fill" : "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .tint(hasReviewItem || reviewAdded ? .green : .orange)
            .disabled(hasReviewItem || reviewAdded)
        }
    }

    private func bottomBar(_ mission: OpenSourceReadingMission) -> some View {
        let stage = OpenSourceReadingStage(rawValue: currentStage) ?? .goal
        let completed = completedStages.contains(stage.rawValue)
        let canComplete = canCompleteStage(stage, mission: mission)
        let canMoveForward = completed || canComplete

        return HStack(spacing: 10) {
            Button {
                currentStage = max(0, currentStage - 1)
            } label: {
                Label("上一步", systemImage: "chevron.left")
            }
            .buttonStyle(.bordered)
            .disabled(currentStage == 0)

            Button {
                completeStage(stage, mission: mission)
            } label: {
                Label(completed ? "已完成" : "完成本阶段", systemImage: completed ? "checkmark.circle.fill" : "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(completed ? .green : .teal)
            .disabled(completed || !canComplete)

            if currentStage < OpenSourceReadingStage.allCases.count - 1 {
                Button {
                    if !completed {
                        completeStage(stage, mission: mission)
                    }
                    currentStage += 1
                } label: {
                    Label("完成并继续", systemImage: "chevron.right")
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .disabled(!canMoveForward)
            } else {
                Button("完成路线") {
                    if !completed {
                        completeStage(stage, mission: mission)
                    }
                    saveEvidence(mission)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(!canMoveForward)
            }
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private func evidenceEditor(
        title: String,
        hint: String,
        text: Binding<String>,
        minHeight: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.subheadline.bold())
            TextEditor(text: text)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .topLeading) {
                    if text.wrappedValue.isEmpty {
                        Text(hint)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
                .frame(minHeight: minHeight)
        }
    }

    private func loadState(_ mission: OpenSourceReadingMission) {
        guard !didLoad else { return }
        didLoad = true
        if let note = notes.first(where: { $0.targetID == OpenSourceReadingCatalog.evidenceTargetID(mission.id) }) {
            evidence = OpenSourceReadingEvidenceCodec.decode(note.body)
            saveMessage = "已恢复"
        }
        refreshCompletion(mission)
        currentStage = OpenSourceReadingStage.allCases.firstIndex { !completedStages.contains($0.rawValue) } ?? 0
    }

    private func refreshCompletion(_ mission: OpenSourceReadingMission) {
        let stages = OpenSourceReadingStage.allCases.filter { stage in
            progressRecords.contains {
                $0.itemID == OpenSourceReadingCatalog.stageProgressID(missionID: mission.id, stage: stage.rawValue)
                    && $0.isCompleted
            }
        }.map(\.rawValue)
        completedStages.formUnion(stages)

        let checks = mission.tasks.indices.filter { index in
            progressRecords.contains {
                $0.itemID == OpenSourceReadingCatalog.checkpointProgressID(missionID: mission.id, checkpointIndex: index)
                    && $0.isCompleted
            }
        }
        completedCheckpoints.formUnion(checks)
    }

    private func isStageUnlocked(_ index: Int) -> Bool {
        if index == 0 { return true }
        let highest = completedStages.max() ?? -1
        return index <= highest + 1
    }

    private func canCompleteStage(
        _ stage: OpenSourceReadingStage,
        mission: OpenSourceReadingMission
    ) -> Bool {
        switch stage {
        case .goal:
            return true
        case .repositoryMap:
            return !evidence.repositorySnapshot.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .entryPoints:
            return !evidence.entryPointNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .traceTasks:
            return mission.tasks.indices.allSatisfy { completedCheckpoints.contains($0) }
        case .evidence:
            return !evidence.rawEvidence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .reflection:
            return !evidence.reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func completeStage(_ stage: OpenSourceReadingStage, mission: OpenSourceReadingMission) {
        guard canCompleteStage(stage, mission: mission) else { return }
        completedStages.insert(stage.rawValue)
        ProgressService.setCompleted(
            true,
            itemID: OpenSourceReadingCatalog.stageProgressID(missionID: mission.id, stage: stage.rawValue),
            in: modelContext
        )
        saveEvidence(mission)
    }

    private func toggleCheckpoint(_ index: Int, mission: OpenSourceReadingMission) {
        let next: Bool
        if completedCheckpoints.contains(index) {
            completedCheckpoints.remove(index)
            next = false
        } else {
            completedCheckpoints.insert(index)
            next = true
        }
        ProgressService.setCompleted(
            next,
            itemID: OpenSourceReadingCatalog.checkpointProgressID(missionID: mission.id, checkpointIndex: index),
            in: modelContext
        )
        saveEvidence(mission)
    }

    private func saveEvidence(_ mission: OpenSourceReadingMission) {
        KnowledgeService.saveNote(
            targetID: OpenSourceReadingCatalog.evidenceTargetID(mission.id),
            parentTutorialID: nil,
            stepIndex: nil,
            title: "开源阅读证据：\(mission.repoName)",
            body: OpenSourceReadingEvidenceCodec.encode(evidence),
            in: modelContext
        )
        saveMessage = "已保存"
    }

    private func addToReview(_ mission: OpenSourceReadingMission) {
        ReviewService.addOpenSourceReading(
            missionID: mission.id,
            title: "开源阅读：\(mission.repoName)",
            question: mission.reflectionQuestion,
            referenceAnswer: "入口：\(mission.entryPoints.joined(separator: "、"))\n\n我的复盘：\(evidence.reflection)",
            in: modelContext
        )
        reviewAdded = true
    }

    private func levelColor(_ level: OpenSourceReadingLevel) -> Color {
        switch level {
        case .singleFile: .teal
        case .moduleMap: .blue
        case .protocolTrace: .indigo
        case .dataStructure: .orange
        case .systemBoundary: .purple
        case .languageRuntime: .pink
        }
    }
}

private struct FlowLikeText: View {
    let values: [String]
    let color: Color

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(values, id: \.self) { value in
                    Text(value)
                        .font(.system(.caption, design: .monospaced).weight(.semibold))
                        .foregroundStyle(color)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(color.opacity(0.1), in: Capsule())
                }
            }
        }
    }
}
