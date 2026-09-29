import SwiftData
import SwiftUI

struct TutorialDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tutorial.order) private var tutorials: [Tutorial]
    @Query private var progressRecords: [Progress]
    @Query(sort: \Concept.name) private var concepts: [Concept]
    @Query(sort: \Bookmark.createdAt, order: .reverse) private var bookmarks: [Bookmark]
    @Query(sort: \LearningNote.updatedAt, order: .reverse) private var notes: [LearningNote]
    @Query(sort: \ReviewItem.dueAt) private var reviewItems: [ReviewItem]

    let tutorialID: String
    let initialStepIndex: Int?

    @State private var currentStepIndex = 0
    @State private var didRestorePosition = false
    @State private var showNoteEditor = false
    @State private var learningMode: TutorialLearningMode = .standard
    @State private var recallDraft = ""
    @State private var recallScore: Double?
    @State private var teachBackEvaluation: TeachBackEvaluation?

    init(tutorialID: String, initialStepIndex: Int? = nil) {
        self.tutorialID = tutorialID
        self.initialStepIndex = initialStepIndex
        _currentStepIndex = State(initialValue: initialStepIndex ?? 0)
    }

    private var tutorial: Tutorial? {
        tutorials.first { $0.id == tutorialID }
    }

    private var tutorialItemID: String {
        .tutorialProgressID(tutorialID)
    }

    private var isTutorialCompleted: Bool {
        progressRecords.contains { $0.itemID == tutorialItemID && $0.isCompleted }
    }

    var body: some View {
        Group {
            if let tutorial {
                let steps = makeSteps(tutorial.markdown)

                if steps.isEmpty {
                    ContentUnavailableView("教程内容为空", systemImage: "doc.text")
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 18) {
                                Color.clear
                                    .frame(height: 1)
                                    .id("tutorial-top")

                                header(tutorial)
                                stepOverview(tutorial: tutorial, steps: steps)
                                resourceLinks(tutorial)
                                stepContent(
                                    steps[currentStepIndex],
                                    phase: LearningPhase.phase(for: currentStepIndex, steps: steps)
                                )

                                if currentStepIndex == 0, !tutorial.code.isEmpty {
                                    codeSection(
                                        title: "完整示例代码",
                                        code: tutorial.code,
                                        language: tutorial.codeLanguage
                                    )
                                }

                                if currentStepIndex == steps.count - 1,
                                   !(tutorial.topic?.exercises.isEmpty ?? true) {
                                    exerciseLinks(tutorial)
                                }
                            }
                            .padding()
                            .learningPageWidth()
                        }
                        .background(Color.appBackground)
                        .navigationTitle(tutorial.title)
                        .toolbar {
                            ToolbarItemGroup(placement: .primaryAction) {
                                bookmarkButton(tutorial: tutorial, step: steps[currentStepIndex])
                                noteButton(tutorial: tutorial, step: steps[currentStepIndex])
                            }
                        }
                        .sheet(isPresented: $showNoteEditor) {
                            NoteEditorView(
                                targetID: stepTargetID(steps[currentStepIndex]),
                                parentTutorialID: tutorial.id,
                                stepIndex: steps[currentStepIndex].index,
                                title: steps[currentStepIndex].title
                            )
                        }
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            bottomBar(tutorial: tutorial, steps: steps)
                        }
                        .onAppear {
                            restorePositionIfNeeded(steps: steps)
                            ProgressService.markStudied(itemID: tutorialItemID, in: modelContext)
                        }
                        .onChange(of: currentStepIndex) { _, newValue in
                            recallDraft = ""
                            recallScore = nil
                            teachBackEvaluation = nil
                            ProgressService.savePosition(
                                tutorialID: tutorialID,
                                stepIndex: newValue,
                                in: modelContext
                            )
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo("tutorial-top", anchor: .top)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView("教程不存在", systemImage: "book.closed")
            }
        }
    }

    private func header(_ tutorial: Tutorial) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StatPill(icon: "list.number", text: "分步学习")
                if isTutorialCompleted {
                    StatPill(icon: "checkmark.circle.fill", text: "已完成", tint: .green)
                }
                Spacer()
            }

            Text(tutorial.summary)
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
                .lineSpacing(5)
        }
        .learningCard()
    }

    private func stepOverview(tutorial: Tutorial, steps: [TutorialStep]) -> some View {
        let completedCount = steps.filter(isStepCompleted).count
        let progress = steps.isEmpty ? 0 : Double(completedCount) / Double(steps.count)
        let phase = LearningPhase.phase(for: currentStepIndex, steps: steps)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Label(phase.title, systemImage: phase.icon)
                    .font(.headline)
                    .foregroundStyle(phase.tint)
                Spacer()
                Text("第 \(currentStepIndex + 1) / \(steps.count) 步")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(.secondary)
            }

            Text(steps[currentStepIndex].title)
                .font(.title3.bold())

            HStack(spacing: 10) {
                LearningProgressBar(value: progress, tint: phase.tint)
                Text("\(completedCount)/\(steps.count)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(phase.tint)
                    .frame(width: 46, alignment: .trailing)
            }

            modePicker(steps: steps)
            phasePicker(steps: steps)
            stepDirectory(steps: steps)
        }
        .learningCard()
    }

    private func modePicker(steps: [TutorialStep]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("学习模式", systemImage: "slider.horizontal.3")
                    .font(.subheadline.bold())
                Spacer()
                Text(learningMode.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                ForEach(TutorialLearningMode.allCases) { mode in
                    Button {
                        learningMode = mode
                        if let first = visibleSteps(from: steps, mode: mode).first {
                            currentStepIndex = first.index
                        }
                    } label: {
                        Text(mode.title)
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(
                                learningMode == mode ? Color.indigo : Color.secondary.opacity(0.1),
                                in: Capsule()
                            )
                            .foregroundStyle(learningMode == mode ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func phasePicker(steps: [TutorialStep]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LearningPhase.all) { phase in
                    let phaseSteps = steps.filter { $0.phaseID == phase.id }
                    if let firstStep = phaseSteps.first {
                        let completed = phaseSteps.filter(isStepCompleted).count
                        Button {
                            currentStepIndex = firstStep.index
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: completed == phaseSteps.count ? "checkmark.circle.fill" : phase.icon)
                                Text(phase.shortTitle)
                                Text("\(completed)/\(phaseSteps.count)")
                                    .font(.caption2.monospacedDigit())
                                    .opacity(0.8)
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(steps[currentStepIndex].phaseID == phase.id ? .white : phase.tint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                steps[currentStepIndex].phaseID == phase.id ? phase.tint : phase.tint.opacity(0.1),
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func stepDirectory(steps: [TutorialStep]) -> some View {
        Menu {
            ForEach(LearningPhase.all) { phase in
                let phaseSteps = visibleSteps(from: steps).filter { $0.phaseID == phase.id }
                if !phaseSteps.isEmpty {
                    Section(phase.title) {
                        ForEach(phaseSteps) { step in
                            Button {
                                currentStepIndex = step.index
                            } label: {
                                Label(
                                    step.title,
                                    systemImage: isStepCompleted(step) ? "checkmark.circle.fill" : "circle"
                                )
                            }
                        }
                    }
                }
            }
        } label: {
            HStack {
                Label("步骤目录", systemImage: "list.bullet.rectangle")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(steps[currentStepIndex].title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(11)
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 11))
        }
        .buttonStyle(.plain)
    }

    private func stepContent(_ step: TutorialStep, phase: LearningPhase) -> some View {
        let readingMinutes = max(2, step.markdown.count / 420)

        return VStack(alignment: .leading, spacing: 15) {
            HStack {
                Label(phase.title, systemImage: phase.icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(phase.tint.gradient, in: Capsule())

                Text("步骤 \(step.index + 1)")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)

                Label("约 \(readingMinutes) 分钟", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if isStepCompleted(step) {
                    Label("已完成", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                } else {
                    Label("进行中", systemImage: "circle.dotted")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(phase.tint)
                }
            }

            Text(step.title)
                .font(.title2.bold())

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(phase.tint)
                Text(phaseHint(phase))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(phase.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            activeRecallCard(step)

            let related = relatedConcepts(for: step)
            if !related.isEmpty {
                conceptChips(related)
            }

            Divider()
            MarkdownText(markdown: step.markdown)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [phase.tint.opacity(0.07), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(phase.tint.opacity(0.16), lineWidth: 1)
        }
    }

    private func phaseHint(_ phase: LearningPhase) -> String {
        switch phase.id {
        case 0: return "先明确今天要完成什么。不要急着复制代码，先写下目标和验收标准。"
        case 1: return "尝试合上教程复述核心模型，再回来检查遗漏的因果关系。"
        case 2: return "这一段必须动手：运行示例、修改输入、观察结果，并保存原始日志。"
        case 3: return "开始考虑工程化：错误处理、测试、配置、日志和资源生命周期。"
        case 4: return "主动制造一次可恢复错误，用工具收集证据，再写故障复盘。"
        case 5: return "用项目和答辩检验掌握程度，能说明取舍比背出结论更重要。"
        case 6: return "把当前主题与 C、Linux、网络、数据库和操作系统连接起来。"
        case 7: return "给自己设置更高挑战：限制时间、增加规模或迁移到陌生场景。"
        default: return "保持小步验证，每一步都留下可以复现的证据。"
        }
    }

    @ViewBuilder
    private func activeRecallCard(_ step: TutorialStep) -> some View {
        let sourceID = stepTargetID(step)
        let existing = reviewItems.first { $0.sourceID == sourceID && !$0.isArchived }

        VStack(alignment: .leading, spacing: 10) {
            Label("教回去", systemImage: "person.wave.2.fill")
                .font(.headline)
                .foregroundStyle(.teal)
            Text("先不要看下面的正文。假设对方完全不懂“\(step.title)”，请按“结论—原因—例子—边界”讲清楚。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let existing {
                HStack {
                    Label("已加入 \(ReviewService.stageDescription(existing))", systemImage: "calendar.badge.clock")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.teal)
                    Spacer()
                    Button("移出复习") {
                        ReviewService.archive(existing, in: modelContext)
                    }
                    .font(.caption)
                }
            } else {
                TextEditor(text: $recallDraft)
                    .font(.body)
                    .frame(minHeight: 68)
                    .padding(7)
                    .scrollContentBackground(.hidden)
                    .background(.background, in: RoundedRectangle(cornerRadius: 9))
                    .overlay {
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(.teal.opacity(0.18))
                    }

                HStack {
                    Button {
                        let evaluation = TeachBackService.evaluate(
                            answer: recallDraft,
                            stepTitle: step.title,
                            reference: step.markdown,
                            concepts: relatedConcepts(for: step)
                        )
                        teachBackEvaluation = evaluation
                        recallScore = evaluation.score
                        KnowledgeService.saveNote(
                            targetID: "teachback:\(sourceID)",
                            parentTutorialID: tutorialID,
                            stepIndex: step.index,
                            title: "教回去：\(step.title)",
                            body: "我的解释：\n\(recallDraft)\n\n\(evaluation.noteBody)",
                            in: modelContext
                        )
                    } label: {
                        Label("评估并保存", systemImage: "checkmark.magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    .tint(.teal)
                    .disabled(recallDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if let recallScore {
                        Text("教回去评分 \(Int(recallScore * 100))%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(recallScore >= 0.6 ? .green : .orange)
                    }

                    Spacer()
                }

                if let evaluation = teachBackEvaluation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(evaluation.summary)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(evaluation.passed ? .green : .orange)
                        ForEach(evaluation.dimensions) { dimension in
                            HStack(spacing: 8) {
                                Text(dimension.title)
                                    .font(.caption)
                                    .frame(width: 76, alignment: .leading)
                                LearningProgressBar(value: dimension.score, tint: dimension.score >= 0.6 ? .teal : .orange)
                                Text("\(Int(dimension.score * 100))%")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 34, alignment: .trailing)
                            }
                        }
                        if !evaluation.gaps.isEmpty {
                            Text("下一次补充：\(evaluation.gaps.joined(separator: "；"))")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(10)
                    .background(.background.opacity(0.72), in: RoundedRectangle(cornerRadius: 10))
                }

                HStack {
                    Button {
                        let positive = (recallScore ?? 0) >= 0.6
                        MasteryService.recordStep(
                            stepIndex: step.index,
                            title: step.title,
                            text: step.markdown,
                            remembered: positive,
                            in: modelContext
                        )
                        ReviewService.addRecall(
                            tutorialID: tutorialID,
                            stepIndex: step.index,
                            title: step.title,
                            question: "请用自己的话解释：\(step.title)",
                            referenceAnswer: step.markdown,
                            needsReview: !positive,
                            in: modelContext
                        )
                    } label: {
                        Label((recallScore ?? 0) >= 0.6 ? "达到理解" : "加入复习", systemImage: (recallScore ?? 0) >= 0.6 ? "checkmark.circle" : "arrow.counterclockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint((recallScore ?? 0) >= 0.6 ? .green : .orange)

                    Button {
                        MasteryService.recordStep(
                            stepIndex: step.index,
                            title: step.title,
                            text: step.markdown,
                            remembered: false,
                            in: modelContext
                        )
                        ReviewService.addRecall(
                            tutorialID: tutorialID,
                            stepIndex: step.index,
                            title: step.title,
                            question: "请用自己的话解释：\(step.title)",
                            referenceAnswer: step.markdown,
                            needsReview: true,
                            in: modelContext
                        )
                    } label: {
                        Label("还说不清", systemImage: "questionmark.circle")
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
            }
        }
        .padding(12)
        .background(.teal.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.teal.opacity(0.16), lineWidth: 1)
        }
    }

    private func stepTargetID(_ step: TutorialStep) -> String {
        .tutorialStepProgressID(tutorialID, stepIndex: step.index)
    }

    private func isBookmarked(_ step: TutorialStep) -> Bool {
        bookmarks.contains { $0.targetID == stepTargetID(step) }
    }

    private func hasNote(_ step: TutorialStep) -> Bool {
        notes.contains { $0.targetID == stepTargetID(step) }
    }

    private func bookmarkButton(tutorial: Tutorial, step: TutorialStep) -> some View {
        let bookmarked = isBookmarked(step)
        return Button {
            KnowledgeService.toggleBookmark(
                targetID: stepTargetID(step),
                targetType: "step",
                parentTutorialID: tutorial.id,
                stepIndex: step.index,
                title: step.title,
                subtitle: tutorial.title,
                in: modelContext
            )
        } label: {
            Label(bookmarked ? "已收藏" : "收藏本步", systemImage: bookmarked ? "bookmark.fill" : "bookmark")
        }
        .help(bookmarked ? "取消收藏当前步骤" : "收藏当前步骤")
    }

    private func noteButton(tutorial: Tutorial, step: TutorialStep) -> some View {
        Button {
            showNoteEditor = true
        } label: {
            Label(hasNote(step) ? "查看笔记" : "写笔记", systemImage: hasNote(step) ? "note.text.badge.plus" : "square.and.pencil")
        }
        .help("为当前步骤记录笔记")
    }

    private func relatedConcepts(for step: TutorialStep) -> [Concept] {
        let searchable = "\(step.title) \(step.markdown)"
        return Array(
            concepts.filter { concept in
                let names = [concept.name] + concept.aliases
                return names.contains { name in
                    !name.isEmpty && searchable.localizedCaseInsensitiveContains(name)
                }
            }
            .prefix(6)
        )
    }

    private func conceptChips(_ concepts: [Concept]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("本步关联概念", systemImage: "link")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(concepts) { concept in
                        NavigationLink(value: AppRoute.concept(concept.id)) {
                            Text(concept.name)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(.indigo.opacity(0.1), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func bottomBar(tutorial: Tutorial, steps: [TutorialStep]) -> some View {
        let visible = visibleSteps(from: steps)
        let position = visible.firstIndex { $0.index == currentStepIndex } ?? 0
        let step = visible[position]
        let completed = isStepCompleted(step)
        let isLastStep = position == visible.count - 1

        return HStack(spacing: 10) {
            Button {
                currentStepIndex = visible[max(0, position - 1)].index
            } label: {
                Label("上一步", systemImage: "chevron.left")
            }
            .buttonStyle(.bordered)
            .disabled(position == 0)

            Button {
                toggleStep(step, steps: steps)
            } label: {
                Label(completed ? "已完成" : "完成本步", systemImage: completed ? "checkmark.circle.fill" : "circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(completed ? .green : .indigo)

            if isLastStep {
                Button {
                    completeTutorial(tutorial: tutorial, steps: steps)
                } label: {
                    Label(isTutorialCompleted ? "已完成" : "完成教程", systemImage: "checkmark.seal.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(isTutorialCompleted)
            } else {
                Button {
                    advanceFromStep(step, steps: steps)
                } label: {
                    Label(completed ? "下一步" : "完成并继续", systemImage: "chevron.right")
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
    }

    @ViewBuilder
    private func resourceLinks(_ tutorial: Tutorial) -> some View {
        let resources = tutorial.resources.sorted { $0.order < $1.order }
        if !resources.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("配套免费资源", systemImage: "link.circle.fill")
                        .font(.title3.bold())
                    Spacer()
                    Text("\(resources.count) 个")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text("以下资料与当前教程主题相关，建议在完成本教程后按顺序阅读和实验。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(resources) { resource in
                    ResourceRow(
                        resource: resource,
                        progressRecords: progressRecords,
                        bookmarks: bookmarks,
                        resourceNotes: notes,
                        onSaveResourceNote: { noteBody in
                            KnowledgeService.saveNote(
                                targetID: .resourceNoteTargetID(resource.id),
                                parentTutorialID: resource.tutorial?.id,
                                stepIndex: nil,
                                title: "资源笔记：\(resource.title)",
                                body: noteBody,
                                in: modelContext
                            )
                        },
                        onToggleCompleted: {
                            toggleResource(
                                resource,
                                itemID: .resourceProgressID(resource.id),
                                nextCompleted: !isResourceCompleted(resource)
                            )
                        },
                        onToggleLater: {
                            toggleResource(
                                resource,
                                itemID: .resourceLaterProgressID(resource.id),
                                nextCompleted: !isResourceLater(resource)
                            )
                        },
                        onToggleBookmark: {
                            KnowledgeService.toggleBookmark(
                                targetID: .resourceBookmarkTargetID(resource.id),
                                targetType: "resource",
                                parentTutorialID: resource.tutorial?.id,
                                stepIndex: nil,
                                title: resource.title,
                                subtitle: resource.provider,
                                in: modelContext
                            )
                        }
                    )
                }
            }
            .learningCard()
        }
    }

    private func codeSection(title: String, code: String, language: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: "curlybraces.square")
                .font(.title3.bold())
            CodeBlockView(code: code, language: language)
        }
    }

    private func exerciseLinks(_ tutorial: Tutorial) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("配套练习")
                .font(.title3.bold())
            ForEach(tutorial.topic?.exercises.sorted(by: { $0.order < $1.order }) ?? []) { exercise in
                NavigationLink(value: AppRoute.exercise(exercise.id)) {
                    HStack {
                        Image(systemName: exercise.kind == .coding ? "terminal" : "list.bullet.circle")
                            .foregroundStyle(.indigo)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(exercise.kind.title)
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
        }
    }

    private func makeSteps(_ markdown: String) -> [TutorialStep] {
        var sections: [(title: String, markdown: String)] = []
        var title = "开始阅读"
        var lines: [String] = []

        func appendSection() {
            let content = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !content.isEmpty else { return }
            sections.append((title, content))
        }

        for line in markdown.components(separatedBy: .newlines) {
            if line.hasPrefix("# ") {
                appendSection()
                title = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                lines = [line]
            } else {
                lines.append(line)
            }
        }
        appendSection()

        return sections.enumerated().map { index, section in
            TutorialStep(
                id: "tutorial-step-\(index)",
                index: index,
                title: section.title,
                markdown: section.markdown,
                phaseID: LearningPhase.phaseID(for: section.title)
            )
        }
    }

    private func visibleSteps(
        from steps: [TutorialStep],
        mode: TutorialLearningMode? = nil
    ) -> [TutorialStep] {
        let selectedMode = mode ?? learningMode
        return steps.filter { selectedMode.phaseRange.contains($0.phaseID) }
    }

    private func isStepCompleted(_ step: TutorialStep) -> Bool {
        if isTutorialCompleted { return true }
        let itemID = String.tutorialStepProgressID(tutorialID, stepIndex: step.index)
        return progressRecords.contains { $0.itemID == itemID && $0.isCompleted }
    }

    private func toggleStep(_ step: TutorialStep, steps: [TutorialStep]) {
        let itemID = String.tutorialStepProgressID(tutorialID, stepIndex: step.index)
        let nextValue = !isStepCompleted(step)
        ProgressService.setCompleted(nextValue, itemID: itemID, in: modelContext)

        guard nextValue else {
            ProgressService.setCompleted(false, itemID: tutorialItemID, in: modelContext)
            return
        }

        let allStepsCompleted = steps.allSatisfy { candidate in
            candidate.index == step.index || isStepCompleted(candidate)
        }
        if allStepsCompleted {
            ProgressService.setCompleted(true, itemID: tutorialItemID, in: modelContext)
        }
    }

    private func advanceFromStep(_ step: TutorialStep, steps: [TutorialStep]) {
        if !isStepCompleted(step) {
            toggleStep(step, steps: steps)
        }
        let visible = visibleSteps(from: steps)
        let position = visible.firstIndex { $0.index == step.index } ?? 0
        if position + 1 < visible.count {
            currentStepIndex = visible[position + 1].index
        }
    }

    private func completeTutorial(tutorial: Tutorial, steps: [TutorialStep]) {
        let step = steps[currentStepIndex]
        let stepID = String.tutorialStepProgressID(tutorialID, stepIndex: step.index)
        ProgressService.setCompleted(true, itemID: stepID, in: modelContext)
        ProgressService.setCompleted(true, itemID: tutorialItemID, in: modelContext)
    }

    private func isResourceCompleted(_ resource: LearningResource) -> Bool {
        progressRecords.contains {
            $0.itemID == .resourceProgressID(resource.id) && $0.isCompleted
        }
    }

    private func isResourceLater(_ resource: LearningResource) -> Bool {
        progressRecords.contains {
            $0.itemID == .resourceLaterProgressID(resource.id) && $0.isCompleted
        }
    }

    private func toggleResource(
        _ resource: LearningResource,
        itemID: String,
        nextCompleted: Bool
    ) {
        ProgressService.setCompleted(nextCompleted, itemID: itemID, in: modelContext)
        if nextCompleted, itemID == .resourceProgressID(resource.id) {
            ProgressService.setCompleted(
                false,
                itemID: .resourceLaterProgressID(resource.id),
                in: modelContext
            )
        }
    }

    private func restorePositionIfNeeded(steps: [TutorialStep]) {
        guard !didRestorePosition else { return }

        if let initialStepIndex {
            currentStepIndex = min(max(initialStepIndex, 0), steps.count - 1)
        } else {
            let saved = ProgressService.savedPosition(tutorialID: tutorialID, in: modelContext) ?? 0
            currentStepIndex = min(max(saved, 0), steps.count - 1)
        }
        didRestorePosition = true
    }
}

private struct ResourceRow: View {
    let resource: LearningResource
    let progressRecords: [Progress]
    let bookmarks: [Bookmark]
    let resourceNotes: [LearningNote]
    let onSaveResourceNote: (String) -> Void
    let onToggleCompleted: () -> Void
    let onToggleLater: () -> Void
    let onToggleBookmark: () -> Void

    @State private var showBrowser = false
    @State private var showResourceNote = false
    @StateObject private var linkHealth = ResourceLinkHealthService.shared

    private var url: URL? {
        URL(string: resource.urlString)
    }

    private var isCompleted: Bool {
        progressRecords.contains {
            $0.itemID == .resourceProgressID(resource.id) && $0.isCompleted
        }
    }

    private var isLater: Bool {
        progressRecords.contains {
            $0.itemID == .resourceLaterProgressID(resource.id) && $0.isCompleted
        }
    }

    private var isBookmarked: Bool {
        bookmarks.contains { $0.targetID == .resourceBookmarkTargetID(resource.id) }
    }

    private var resourceNote: LearningNote? {
        resourceNotes.first { $0.targetID == .resourceNoteTargetID(resource.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "book.closed.fill")
                    .foregroundStyle(isCompleted ? .green : .indigo)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(resource.provider)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.indigo)
                }
                Spacer()
                if resource.isFree {
                    Text("免费")
                        .font(.caption2.bold())
                        .foregroundStyle(.green)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.1), in: Capsule())
                }
            }

            Text(resource.explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            HStack {
                Text(resource.difficulty)
                Text("·")
                Text(resource.language)
                Spacer()
                Button(action: onToggleBookmark) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                }
                .buttonStyle(.borderless)
                .help(isBookmarked ? "取消收藏" : "收藏资源")
                .accessibilityLabel(isBookmarked ? "取消收藏资源" : "收藏资源")

                Button {
                    showResourceNote = true
                } label: {
                    Image(systemName: resourceNote == nil ? "note.text.badge.plus" : "note.text")
                }
                .buttonStyle(.borderless)
                .help(resourceNote == nil ? "为资源写笔记" : "查看资源笔记")
                .accessibilityLabel(resourceNote == nil ? "为资源写笔记" : "查看资源笔记")

                CopyButton(text: resource.urlString, compact: true)

                if let url {
                    Button {
                        showBrowser = true
                    } label: {
                        Label("阅读", systemImage: "book.pages")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Link(destination: url) {
                        Label("浏览器", systemImage: "arrow.up.right.square")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .font(.caption)
            .foregroundStyle(.tertiary)

            HStack(spacing: 8) {
                Button(action: onToggleLater) {
                    Label(isLater ? "稍后看中" : "稍后看", systemImage: isLater ? "clock.fill" : "clock")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(isLater ? .orange : .secondary)

                Button(action: onToggleCompleted) {
                    Label(isCompleted ? "已完成" : "标记完成", systemImage: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(isCompleted ? .green : .indigo)

                Button {
                    Task { await linkHealth.check(resource) }
                } label: {
                    Label(linkHealth.statuses[resource.id]?.title ?? "检查链接", systemImage: "network")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(
            (isCompleted ? Color.green : Color.secondary).opacity(0.06),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCompleted ? Color.green.opacity(0.18) : Color.clear, lineWidth: 1)
        }
        .sheet(isPresented: $showBrowser) {
            if let url {
                InAppBrowserView(url: url)
                    .frame(minWidth: 520, minHeight: 720)
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showResourceNote) {
            ResourceNoteEditorView(
                title: resource.title,
                initialBody: resourceNote?.body ?? "",
                onSave: onSaveResourceNote
            )
        }
    }
}

private struct TutorialStep: Identifiable {
    let id: String
    let index: Int
    let title: String
    let markdown: String
    let phaseID: Int
}

private struct LearningPhase: Identifiable {
    let id: Int
    let title: String
    let shortTitle: String
    let icon: String
    let tint: Color

    static let all: [LearningPhase] = [
        LearningPhase(id: 0, title: "开始与目标", shortTitle: "开始", icon: "flag.checkered", tint: .indigo),
        LearningPhase(id: 1, title: "理解原理", shortTitle: "理解", icon: "brain.head.profile", tint: .blue),
        LearningPhase(id: 2, title: "动手实验", shortTitle: "实践", icon: "hammer.fill", tint: .orange),
        LearningPhase(id: 3, title: "工程进阶", shortTitle: "进阶", icon: "gearshape.2.fill", tint: .purple),
        LearningPhase(id: 4, title: "排错与巩固", shortTitle: "巩固", icon: "checkmark.seal.fill", tint: .green),
        LearningPhase(id: 5, title: "强化与答辩", shortTitle: "强化", icon: "graduationcap.fill", tint: .teal),
        LearningPhase(id: 6, title: "体系融会", shortTitle: "融会", icon: "circle.hexagongrid.fill", tint: .pink),
        LearningPhase(id: 7, title: "大师挑战", shortTitle: "大师", icon: "crown.fill", tint: .orange)
    ]

    static func phaseID(for title: String) -> Int {
        guard title.hasPrefix("深度学习手册 ") else { return 0 }
        let chapterText = title.replacingOccurrences(of: "深度学习手册 ", with: "")
        let number = Int(chapterText.prefix(2)) ?? 0
        switch number {
        case 1...7: return 1
        case 8...15: return 2
        case 16...23: return 3
        case 24...31: return 4
        case 32...40: return 5
        case 41...52: return 6
        case 53...64: return 7
        default: return 0
        }
    }

    static func phase(for stepIndex: Int, steps: [TutorialStep]) -> LearningPhase {
        let phaseID = steps.indices.contains(stepIndex) ? steps[stepIndex].phaseID : 0
        return all.first { $0.id == phaseID } ?? all[0]
    }
}


private enum TutorialLearningMode: String, CaseIterable, Identifiable {
    case quick
    case standard
    case deep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quick: "快速"
        case .standard: "标准"
        case .deep: "深度"
        }
    }

    var subtitle: String {
        switch self {
        case .quick: "先掌握开始、理解和基础实验"
        case .standard: "完成理解、实践、工程和巩固"
        case .deep: "包含全部强化、体系与大师挑战"
        }
    }

    var phaseRange: ClosedRange<Int> {
        switch self {
        case .quick: 0...2
        case .standard: 0...5
        case .deep: 0...7
        }
    }
}
