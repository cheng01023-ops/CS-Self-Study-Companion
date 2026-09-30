import SwiftData
import SwiftUI

struct InteractiveLabView: View {
    let labID: String

    var body: some View {
        Group {
            switch labID {
            case "bits": BitLabView()
            case "memory": MemoryLabView()
            case "tcp": TCPHandshakeLabView()
            case "hash": HashLabView()
            case "logic": LogicLabView()
            case "automata": AutomataLabView()
            case "probability": ProbabilityLabView()
            case "growth": ComplexityGrowthLabView()
            default: ContentUnavailableView("实验不存在", systemImage: "testtube.2")
            }
        }
        .navigationTitle(labTitle)
    }

    private var labTitle: String {
        LabCatalog.labs.first { $0.id == labID }?.title ?? "互动实验室"
    }
}

struct TutorialLabSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tutorial.order) private var tutorials: [Tutorial]
    @Query private var progressRecords: [Progress]
    @Query(sort: \LearningNote.updatedAt, order: .reverse) private var notes: [LearningNote]
    @Query(sort: \ReviewItem.dueAt) private var reviewItems: [ReviewItem]

    let tutorialID: String

    @State private var currentStage = 0
    @State private var evidence = TutorialLabEvidence.empty
    @State private var completedStages: Set<Int> = []
    @State private var completedCheckpoints: Set<String> = []
    @State private var didLoad = false
    @State private var isRunning = false
    @State private var runResult: CodeRunResult?
    @State private var saveMessage: String?
    @State private var reviewAdded = false

    private var tutorial: Tutorial? {
        tutorials.first { $0.id == tutorialID }
    }

    private var blueprint: TutorialLabBlueprint? {
        guard let tutorial else { return nil }
        return TutorialLabCatalog.blueprint(
            tutorialID: tutorial.id,
            title: tutorial.title,
            summary: tutorial.summary,
            codeLanguage: tutorial.codeLanguage,
            code: tutorial.code
        )
    }

    private var hasLabReviewItem: Bool {
        let sourceID = "lab:\(tutorialID):review"
        return reviewItems.contains { $0.sourceID == sourceID && !$0.isArchived }
    }

    var body: some View {
        Group {
            if let tutorial, let blueprint {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        overviewCard(tutorial: tutorial, blueprint: blueprint)
                        stageRail(blueprint: blueprint)
                        stageContent(blueprint: blueprint)
                    }
                    .padding()
                    .learningPageWidth(maxWidth: 1080)
                }
                .background(Color.appBackground)
                .navigationTitle("可验证实验课")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            saveEvidence(blueprint: blueprint)
                        } label: {
                            Label("保存证据", systemImage: "square.and.arrow.down")
                        }
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomBar(blueprint: blueprint)
                }
                .onAppear {
                    loadState(blueprint: blueprint)
                }
                .onChange(of: progressRecords.count) { _, _ in
                    refreshCompletionState(blueprint: blueprint)
                }
            } else {
                ContentUnavailableView("实验教程不存在", systemImage: "testtube.2")
            }
        }
    }

    private func overviewCard(tutorial: Tutorial, blueprint: TutorialLabBlueprint) -> some View {
        let progress = Double(completedStages.count) / Double(TutorialLabStage.allCases.count)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.orange, .pink.opacity(0.82)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "testtube.2")
                        .font(.system(size: 27, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 5) {
                    Text(tutorial.title)
                        .font(.title3.bold())
                    Text(blueprint.objective)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                LearningProgressBar(value: progress, tint: .orange)
                Text("\(completedStages.count)/6")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(.orange)
                    .frame(width: 34, alignment: .trailing)
            }

            HStack {
                StatPill(icon: "clock", text: "约 \(blueprint.estimatedMinutes) 分钟", tint: .orange)
                if saveMessage != nil {
                    StatPill(icon: "checkmark.circle.fill", text: "证据已保存", tint: .green)
                }
                Spacer()
                Text("先预测，再执行")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .learningCard()
    }

    private func stageRail(blueprint: TutorialLabBlueprint) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TutorialLabStage.allCases) { stage in
                    let completed = completedStages.contains(stage.rawValue)
                    let unlocked = isStageUnlocked(stage.rawValue)

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
                        .foregroundStyle(completed ? .white : unlocked ? .orange : .secondary)
                        .frame(width: 72)
                        .padding(.vertical, 10)
                        .background(
                            completed ? Color.orange : unlocked ? Color.orange.opacity(0.1) : Color.secondary.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!unlocked)
                }
            }
        }
    }

    private func stageContent(blueprint: TutorialLabBlueprint) -> some View {
        let stage = TutorialLabStage(rawValue: currentStage) ?? .brief

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: stage.icon)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.orange.gradient, in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(currentStage + 1) / \(TutorialLabStage.allCases.count) · \(stage.title)")
                        .font(.title2.bold())
                    Text(stage.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if completedStages.contains(stage.rawValue) {
                    Label("已完成", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                }
            }

            Divider()

            switch stage {
            case .brief:
                briefStage(blueprint: blueprint)
            case .predict:
                predictStage()
            case .prepare:
                prepareStage(blueprint: blueprint)
            case .run:
                runStage(blueprint: blueprint)
            case .verify:
                verifyStage(blueprint: blueprint)
            case .reflect:
                reflectStage(blueprint: blueprint)
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.07), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.orange.opacity(0.16), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func briefStage(blueprint: TutorialLabBlueprint) -> some View {
        Text(blueprint.scenario)
            .lineSpacing(4)

        VStack(alignment: .leading, spacing: 9) {
            Label("开始前条件", systemImage: "checklist")
                .font(.headline)
            ForEach(Array(blueprint.prerequisites.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(.orange, in: Circle())
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))

        Label(blueprint.safetyNote, systemImage: "shield.lefthalf.filled")
            .font(.subheadline)
            .foregroundStyle(.orange)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func predictStage() -> some View {
        Text("先写预测，不要运行后再补答案。预测越具体，后面的证据越有价值。")
            .foregroundStyle(.secondary)

        evidenceEditor(
            title: "我的预测",
            hint: "预期输出、退出码、文件状态、进程或权限变化……",
            text: $evidence.prediction,
            minHeight: 150
        )
    }

    @ViewBuilder
    private func prepareStage(blueprint: TutorialLabBlueprint) -> some View {
        Text("把环境和回滚方式写清楚，再开始修改系统。")
            .foregroundStyle(.secondary)

        Toggle(isOn: $evidence.preparationConfirmed) {
            VStack(alignment: .leading, spacing: 3) {
                Text("已确认使用隔离环境")
                    .font(.headline)
                Text("临时目录、练习容器或可恢复的虚拟机，不使用唯一数据副本。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.orange)
        .padding(12)
        .background(.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))

        evidenceEditor(
            title: "回滚或清理方案",
            hint: "例如：删除 /tmp/cs-lab、停止实验进程、恢复备份……",
            text: $evidence.rollbackPlan,
            minHeight: 90
        )

        if !blueprint.terminalCommand.isEmpty {
            commandCard(title: "准备命令", command: blueprint.terminalCommand)
        }
    }

    @ViewBuilder
    private func runStage(blueprint: TutorialLabBlueprint) -> some View {
        Text("执行最小实验并保存原始输出。不要只记录“成功”或“失败”。")
            .foregroundStyle(.secondary)

        if !blueprint.terminalCommand.isEmpty {
            commandCard(title: "终端实验命令", command: blueprint.terminalCommand)
        }

        if blueprint.isRunnableInApp {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("App 内代码运行", systemImage: "hammer.fill")
                        .font(.headline)
                    Spacer()
                    Button {
                        runSample(blueprint: blueprint)
                    } label: {
                        if isRunning {
                            ProgressView().controlSize(.small)
                        } else {
                            Label("编译并运行", systemImage: "play.fill")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(isRunning)
                }

                DisclosureGroup("查看最小代码") {
                    CodeBlockView(code: blueprint.code, language: blueprint.codeLanguage)
                        .padding(.top, 8)
                }
                .font(.subheadline.weight(.semibold))
            }
            .padding(12)
            .background(.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        }

        if let runResult {
            runResultView(runResult)
        }

        VStack(alignment: .leading, spacing: 10) {
            TextField("实际使用的命令", text: $evidence.commandUsed, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

            TextField("退出码，例如 0", text: $evidence.exitCode)
                .textFieldStyle(.roundedBorder)

            evidenceEditor(
                title: "原始输出",
                hint: "粘贴 stdout、stderr、关键日志或系统状态；保留错误原文。",
                text: $evidence.observedOutput,
                minHeight: 160
            )

            evidenceEditor(
                title: "异常与差异",
                hint: "哪些现象与预测不同？是否可重复？还缺少什么证据？",
                text: $evidence.anomaly,
                minHeight: 90
            )
        }
    }

    @ViewBuilder
    private func verifyStage(blueprint: TutorialLabBlueprint) -> some View {
        let detected = blueprint.expectedSignals.filter { signalDetected($0) }.count

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("预期信号", systemImage: "waveform.path.ecg")
                    .font(.headline)
                Spacer()
                if !evidence.observedOutput.isEmpty {
                    Text("自动识别 \(detected)/\(blueprint.expectedSignals.count)")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(detected == blueprint.expectedSignals.count ? .green : .orange)
                }
            }

            ForEach(blueprint.expectedSignals) { signal in
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: signalDetected(signal) ? "checkmark.circle.fill" : "circle.dotted")
                        .foregroundStyle(signalDetected(signal) ? .green : .secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(signal.label)
                            .font(.subheadline)
                        if !signal.marker.isEmpty {
                            Text("检索标记：\(signal.marker)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if signal.required {
                        Text("必验")
                            .font(.caption2.bold())
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, 3)
            }
        }
        .padding(12)
        .background(.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))

        VStack(alignment: .leading, spacing: 10) {
            Label("验收清单", systemImage: "checkmark.shield.fill")
                .font(.headline)
            ForEach(blueprint.checkpoints) { checkpoint in
                Button {
                    toggleCheckpoint(checkpoint, blueprint: blueprint)
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: completedCheckpoints.contains(checkpoint.id) ? "checkmark.square.fill" : "square")
                            .font(.title3)
                            .foregroundStyle(completedCheckpoints.contains(checkpoint.id) ? .green : .secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(checkpoint.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(checkpoint.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("通过标准：\(checkpoint.successCriterion)")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        Spacer()
                    }
                    .padding(11)
                    .background(
                        completedCheckpoints.contains(checkpoint.id) ? Color.green.opacity(0.08) : Color.secondary.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 11)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func reflectStage(blueprint: TutorialLabBlueprint) -> some View {
        Text("复盘不是重抄输出，而是说明预测、证据、根因和下一次如何更早发现问题。")
            .foregroundStyle(.secondary)

        evidenceEditor(
            title: "根因与修复",
            hint: "症状 → 证据 → 根因 → 修复；如果实验通过，也要写一个未验证边界。",
            text: $evidence.rootCause,
            minHeight: 120
        )

        evidenceEditor(
            title: "最重要的收获",
            hint: "一句话说明下次遇到相似问题时，你会先检查什么。",
            text: $evidence.insight,
            minHeight: 100
        )

        VStack(alignment: .leading, spacing: 8) {
            Label("失败演练", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text(blueprint.failureDrill)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding(12)
        .background(.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))

        HStack {
            Button {
                saveEvidence(blueprint: blueprint)
            } label: {
                Label("保存实验证据", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)

            Button {
                addToReview(blueprint: blueprint)
            } label: {
                Label(hasLabReviewItem || reviewAdded ? "已加入复习" : "加入复习", systemImage: hasLabReviewItem || reviewAdded ? "checkmark.circle.fill" : "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .tint(hasLabReviewItem || reviewAdded ? .green : .orange)
            .disabled(hasLabReviewItem || reviewAdded)
        }
    }

    private func bottomBar(blueprint: TutorialLabBlueprint) -> some View {
        let stage = TutorialLabStage(rawValue: currentStage) ?? .brief
        let canMark = canComplete(stage, blueprint: blueprint)
        let isCompleted = completedStages.contains(stage.rawValue)
        let canMoveForward = canMark || isCompleted

        return HStack(spacing: 10) {
            Button {
                currentStage = max(0, currentStage - 1)
            } label: {
                Label("上一步", systemImage: "chevron.left")
            }
            .buttonStyle(.bordered)
            .disabled(currentStage == 0)

            Button {
                markStageComplete(stage, blueprint: blueprint)
            } label: {
                Label(isCompleted ? "本阶段已完成" : "完成本阶段", systemImage: isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isCompleted ? .green : .orange)
            .disabled(isCompleted || !canMark)

            if currentStage < TutorialLabStage.allCases.count - 1 {
                Button {
                    if !isCompleted {
                        markStageComplete(stage, blueprint: blueprint)
                    }
                    if currentStage < TutorialLabStage.allCases.count - 1 {
                        currentStage += 1
                    }
                } label: {
                    Label("完成并继续", systemImage: "chevron.right")
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(!canMoveForward)
            } else {
                Button("完成实验") {
                    if !isCompleted {
                        markStageComplete(stage, blueprint: blueprint)
                    }
                    saveEvidence(blueprint: blueprint)
                    dismiss()
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

    private func commandCard(title: String, command: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label(title, systemImage: "terminal.fill")
                    .font(.headline)
                Spacer()
                CopyButton(text: command, compact: true)
            }
            CodeBlockView(code: command, language: "bash")
        }
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

    private func runResultView(_ result: CodeRunResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                result.succeeded ? "程序运行结束" : "程序未正常结束",
                systemImage: result.succeeded ? "checkmark.circle.fill" : "xmark.octagon.fill"
            )
            .font(.headline)
            .foregroundStyle(result.succeeded ? .green : .red)

            Text("退出码：\(result.exitCode)")
                .font(.caption.monospaced().weight(.semibold))

            if !result.stdout.isEmpty {
                Text("stdout")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(result.stdout)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }

            if !result.stderr.isEmpty {
                Text("stderr")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(result.stderr)
                    .font(.caption.monospaced())
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            Text(result.message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }

    private func loadState(blueprint: TutorialLabBlueprint) {
        guard !didLoad else { return }
        didLoad = true

        if let note = notes.first(where: { $0.targetID == blueprint.evidenceTargetID }) {
            evidence = TutorialLabEvidenceCodec.decode(note.body)
            saveMessage = "已恢复"
        }

        refreshCompletionState(blueprint: blueprint)
        currentStage = TutorialLabStage.allCases.firstIndex { !completedStages.contains($0.rawValue) } ?? 0
    }

    private func refreshCompletionState(blueprint: TutorialLabBlueprint) {
        let completed = TutorialLabStage.allCases
            .filter { stage in
                progressRecords.contains {
                    $0.itemID == .tutorialLabStageProgressID(tutorialID, stage: stage.rawValue) && $0.isCompleted
                }
            }
            .map(\.rawValue)
        completedStages.formUnion(completed)

        let checks = blueprint.checkpoints
            .filter { checkpoint in
                progressRecords.contains {
                    $0.itemID == .tutorialLabCheckpointProgressID(tutorialID, checkpointID: checkpoint.id) && $0.isCompleted
                }
            }
            .map(\.id)
        completedCheckpoints.formUnion(checks)
    }

    private func isStageUnlocked(_ index: Int) -> Bool {
        if index == 0 { return true }
        let highestCompleted = completedStages.max() ?? -1
        return index <= highestCompleted + 1
    }

    private func canComplete(_ stage: TutorialLabStage, blueprint: TutorialLabBlueprint) -> Bool {
        switch stage {
        case .brief:
            return true
        case .predict:
            return !evidence.prediction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .prepare:
            return evidence.preparationConfirmed
                && !evidence.rollbackPlan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .run:
            return !evidence.observedOutput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !evidence.commandUsed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || runResult?.succeeded == true
        case .verify:
            return blueprint.checkpoints.allSatisfy { completedCheckpoints.contains($0.id) }
        case .reflect:
            return !evidence.rootCause.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !evidence.insight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func markStageComplete(_ stage: TutorialLabStage, blueprint: TutorialLabBlueprint) {
        guard canComplete(stage, blueprint: blueprint) else { return }
        completedStages.insert(stage.rawValue)
        ProgressService.setCompleted(
            true,
            itemID: .tutorialLabStageProgressID(tutorialID, stage: stage.rawValue),
            in: modelContext
        )
        saveEvidence(blueprint: blueprint)
    }

    private func toggleCheckpoint(_ checkpoint: TutorialLabCheckpoint, blueprint: TutorialLabBlueprint) {
        let next: Bool
        if completedCheckpoints.contains(checkpoint.id) {
            completedCheckpoints.remove(checkpoint.id)
            next = false
        } else {
            completedCheckpoints.insert(checkpoint.id)
            next = true
        }

        ProgressService.setCompleted(
            next,
            itemID: .tutorialLabCheckpointProgressID(tutorialID, checkpointID: checkpoint.id),
            in: modelContext
        )
        saveEvidence(blueprint: blueprint)
    }

    private func saveEvidence(blueprint: TutorialLabBlueprint) {
        KnowledgeService.saveNote(
            targetID: blueprint.evidenceTargetID,
            parentTutorialID: tutorialID,
            stepIndex: nil,
            title: "可验证实验证据：\(tutorial?.title ?? blueprint.title)",
            body: TutorialLabEvidenceCodec.encode(evidence),
            in: modelContext
        )
        saveMessage = "已保存"
    }

    private func addToReview(blueprint: TutorialLabBlueprint) {
        ReviewService.addLabFailure(
            tutorialID: tutorialID,
            title: "实验复盘：\(blueprint.title)",
            question: "请重新说明 \(blueprint.title) 的正常路径、失败路径和验证证据。",
            referenceAnswer: "\(blueprint.objective)\n\n失败演练：\(blueprint.failureDrill)\n\n我的收获：\(evidence.insight)",
            in: modelContext
        )
        reviewAdded = true
    }

    private func signalDetected(_ signal: TutorialLabSignal) -> Bool {
        guard !signal.marker.isEmpty else { return false }
        return evidence.observedOutput.localizedCaseInsensitiveContains(signal.marker)
    }

    private func runSample(blueprint: TutorialLabBlueprint) {
        guard blueprint.isRunnableInApp else { return }
        isRunning = true
        runResult = nil

        Task {
            let result = await CodeExecutionService.run(
                code: blueprint.code,
                language: blueprint.codeLanguage,
                input: blueprint.standardInput,
                expectedOutput: ""
            )

            await MainActor.run {
                isRunning = false
                runResult = result
                evidence.commandUsed = "App 内运行 \(blueprint.codeLanguage.uppercased()) 最小实验"
                evidence.exitCode = String(result.exitCode)
                evidence.observedOutput = [result.stdout, result.stderr]
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .joined(separator: "\n--- stderr ---\n")
                if evidence.observedOutput.isEmpty {
                    evidence.observedOutput = result.message
                }
                saveEvidence(blueprint: blueprint)
            }
        }
    }
}

private struct LogicLabView: View {
    @State private var p = true
    @State private var q = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("命题逻辑是数学证明、条件判断和类型检查的共同语言。切换 P 与 Q，观察不同连接词的真假。")
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    toggle("P", value: $p, color: .indigo)
                    toggle("Q", value: $q, color: .teal)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("当前结论")
                        .font(.headline)
                    resultRow("P ∧ Q", String(p && q), tint: .green)
                    resultRow("P ∨ Q", String(p || q), tint: .orange)
                    resultRow("¬P", String(!p), tint: .pink)
                    resultRow("P → Q", String(!p || q), tint: .indigo)
                    resultRow("P ↔ Q", String(p == q), tint: .teal)
                }
                .learningCard()

                VStack(alignment: .leading, spacing: 8) {
                    Label("重点提醒", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Text("蕴含 P → Q 只在 P 为真而 Q 为假时为假。P 为假时，无论 Q 是什么，整个蕴含都为真。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                .learningCard()
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
    }

    private func toggle(_ title: String, value: Binding<Bool>, color: Color) -> some View {
        Button {
            value.wrappedValue.toggle()
        } label: {
            VStack(spacing: 7) {
                Text(title)
                    .font(.title2.bold())
                Text(value.wrappedValue ? "真" : "假")
                    .font(.headline.monospaced())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(value.wrappedValue ? color : Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(value.wrappedValue ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func resultRow(_ expression: String, _ value: String, tint: Color) -> some View {
        HStack {
            Text(expression)
                .font(.system(.body, design: .monospaced).weight(.semibold))
            Spacer()
            Text(value)
                .font(.headline.monospaced())
                .foregroundStyle(value == "true" ? tint : .red)
        }
        .padding(10)
        .background(tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct AutomataLabView: View {
    @State private var state = 0
    @State private var input = ""

    private let stateNames = ["起始", "刚读到 0", "已接受 01"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("这是识别“以 01 结尾”的确定性有限自动机。每次点击 0 或 1，观察状态如何变化。")
                    .foregroundStyle(.secondary)

                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { index in
                        VStack(spacing: 7) {
                            Text("\(index)")
                                .font(.headline)
                                .frame(width: 36, height: 36)
                                .background(index == state ? Color.purple : Color.secondary.opacity(0.1), in: Circle())
                                .foregroundStyle(index == state ? .white : .primary)
                            Text(stateNames[index])
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(index == state ? .purple : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .learningCard()

                VStack(alignment: .leading, spacing: 10) {
                    Text("输入序列")
                        .font(.headline)
                    Text(input.isEmpty ? "尚未输入" : input)
                        .font(.system(.title3, design: .monospaced).weight(.bold))
                        .foregroundStyle(.purple)
                    HStack {
                        Button("输入 0") { append("0") }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                        Button("输入 1") { append("1") }
                            .buttonStyle(.borderedProminent)
                            .tint(.indigo)
                        Button("重置") {
                            state = 0
                            input = ""
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .learningCard()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("当前状态")
                            .font(.headline)
                        Spacer()
                        Text(state == 2 ? "接受" : "未接受")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(state == 2 ? .green : .red)
                    }
                    Text("状态 \(state)：\(stateNames[state])")
                        .font(.system(.body, design: .monospaced))
                    Text(state == 2 ? "输入以 01 结尾。" : "输入尚未以 01 结尾。")
                        .foregroundStyle(state == 2 ? .green : .secondary)
                }
                .learningCard()
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
    }

    private func append(_ symbol: String) {
        input += symbol
        switch state {
        case 0:
            state = symbol == "0" ? 1 : 0
        case 1:
            state = symbol == "1" ? 2 : 1
        case 2:
            state = symbol == "0" ? 1 : 0
        default:
            state = 0
        }
    }
}

private struct ProbabilityLabView: View {
    @State private var diceCount = 2
    @State private var trials = 0
    @State private var targetSum = 7
    @State private var hits = 0

    private var estimate: Double {
        trials == 0 ? 0 : Double(hits) / Double(trials)
    }

    private var theoretical: Double {
        let outcomes = diceCount == 1 ? 6.0 : pow(6.0, Double(diceCount))
        let favorable = diceCount == 2 ? max(0, 6 - abs(targetSum - 7)) : 0
        return Double(favorable) / outcomes
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("概率描述长期频率。设置骰子数量和目标和，运行多次模拟，观察经验频率逐渐靠近理论值。")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    Stepper("骰子数量：\(diceCount)", value: $diceCount, in: 1...3)
                    Stepper("目标和：\(targetSum)", value: $targetSum, in: 2...18)

                    HStack {
                        Button("模拟 1,000 次") { run(1_000) }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        Button("重置") {
                            trials = 0
                            hits = 0
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .learningCard()

                HStack(spacing: 12) {
                    metric("试验次数", "\(trials)")
                    metric("命中次数", "\(hits)")
                    metric("经验频率", trials == 0 ? "—" : String(format: "%.3f", estimate))
                    metric("理论概率", diceCount == 2 ? String(format: "%.3f", theoretical) : "仅支持直观观察")
                }

                VStack(alignment: .leading, spacing: 8) {
                    LearningProgressBar(value: min(1, estimate), tint: .orange)
                    Text("随机波动正常存在：样本量越大，经验频率通常越接近期望，但不会保证每次实验都精确等于理论值。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                .learningCard()
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
    }

    private func run(_ amount: Int) {
        for _ in 0..<amount {
            let sum = diceCount == 1 ? Int.random(in: 1...6) : (0..<diceCount).reduce(0) { partial, _ in
                partial + Int.random(in: 1...6)
            }
            if sum == targetSum { hits += 1 }
        }
        trials += amount
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ComplexityGrowthLabView: View {
    @State private var n = 32.0

    private var rows: [(String, Double, Color)] {
        [
            ("O(1)", 1, .green),
            ("O(log n)", log2(max(2, n)), .teal),
            ("O(n)", n, .blue),
            ("O(n log n)", n * log2(max(2, n)), .orange),
            ("O(n²)", n * n, .red)
        ]
    }

    private var maxValue: Double {
        max(1, rows.map(\.1).max() ?? 1)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("复杂度增长描述输入规模变大时资源消耗如何变化。拖动 n，比较不同增长曲线。")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("输入规模 n")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(n))")
                            .font(.title3.monospacedDigit().bold())
                            .foregroundStyle(.pink)
                    }
                    Slider(value: $n, in: 2...256, step: 1)
                        .tint(.pink)
                }
                .learningCard()

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(row.0)
                                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                                Spacer()
                                Text(row.1.formatted(.number.precision(.fractionLength(0))))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            GeometryReader { proxy in
                                Capsule()
                                    .fill(row.2.gradient)
                                    .frame(width: max(4, proxy.size.width * row.1 / maxValue))
                            }
                            .frame(height: 9)
                        }
                    }
                }
                .learningCard()

                Text("条形宽度只用于相对比较；真实程序还受常数因子、缓存、I/O、并发和输入分布影响。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .learningCard()
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
    }
}

private struct BitLabView: View {
    @State private var value = 5

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("点击每一位，让它变成 0 或 1。位权从高到低是 128、64、32、16、8、4、2、1。")
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach((0..<8).reversed(), id: \.self) { bit in
                        bitButton(bit)
                    }
                }

                HStack {
                    metric("十进制", "\(value)")
                    metric("十六进制", String(format: "0x%02X", value))
                    metric("二进制", String(value, radix: 2))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("权限解释")
                        .font(.headline)
                    Text("READ = \(value & 1)   WRITE = \((value >> 1) & 1)   EXECUTE = \((value >> 2) & 1)")
                        .font(.system(.body, design: .monospaced))
                    Text("计算机常用位标志在一个整数中保存多个开关，按位与用于检查某个开关是否打开。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .learningCard()
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
    }

    private func bitButton(_ bit: Int) -> some View {
        let isOn = (value & (1 << bit)) != 0

        return Button {
            value ^= (1 << bit)
        } label: {
            VStack(spacing: 5) {
                Text(isOn ? "1" : "0")
                    .font(.title.bold().monospacedDigit())
                Text("1<<\(bit)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isOn ? Color.indigo : Color.secondary.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .foregroundStyle(isOn ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline.monospaced())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct MemoryLabView: View {
    private let segments = [
        ("代码段", "只读指令和常量", "可执行、只读", "text"),
        ("全局/静态区", "全局变量和静态变量", "程序启动到结束", "globe"),
        ("堆", "malloc/calloc 动态分配", "程序员显式释放", "arrow.up.and.down"),
        ("栈", "局部变量、参数、返回地址", "函数调用期间", "square.stack.3d.up")
    ]

    @State private var selected = 3

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("进程地址空间是理解 C、指针、递归和系统编程的底层地图。点击区域查看生命周期。")
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                        Button {
                            selected = index
                        } label: {
                            HStack {
                                Image(systemName: segment.3)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(segment.0).font(.headline)
                                    Text(segment.1).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(index == selected ? "查看中" : "")
                                    .font(.caption.weight(.bold))
                            }
                            .padding(14)
                            .background(index == selected ? Color.teal.opacity(0.15) : Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))
                        }
                        .buttonStyle(.plain)
                    }
                }

                let current = segments[selected]
                VStack(alignment: .leading, spacing: 8) {
                    Text(current.0).font(.title3.bold())
                    Text(current.1).foregroundStyle(.secondary)
                    Text("生命周期：\(current.2)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.teal)
                }
                .learningCard()
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
    }
}

private struct TCPHandshakeLabView: View {
    @State private var step = 0
    private let steps = [
        ("客户端", "服务器", "SYN", "客户端请求建立连接，并发送自己的初始序号。"),
        ("服务器", "客户端", "SYN-ACK", "服务器同意连接，同时发送自己的初始序号并确认客户端序号。"),
        ("客户端", "服务器", "ACK", "客户端确认服务器序号，连接进入 ESTABLISHED。")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("逐帧观察 TCP 三次握手。实际网络还会受延迟、丢包、重传和超时影响。")
                    .foregroundStyle(.secondary)

                HStack(spacing: 40) {
                    endpoint("客户端", icon: "laptopcomputer")
                    Image(systemName: step < 3 ? "arrow.right" : "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(step < 3 ? .blue : .green)
                    endpoint("服务器", icon: "server.rack")
                }
                .frame(maxWidth: .infinity)

                if step < steps.count {
                    let item = steps[step]
                    VStack(alignment: .leading, spacing: 10) {
                        Text("第 \(step + 1) 步 · \(item.2)")
                            .font(.title3.bold())
                        Text("\(item.0) → \(item.1)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.blue)
                        Text(item.3)
                            .foregroundStyle(.secondary)
                    }
                    .learningCard()
                } else {
                    Label("连接已建立", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .foregroundStyle(.green)
                        .learningCard()
                }

                Button {
                    if step < steps.count { step += 1 } else { step = 0 }
                } label: {
                    Label(step < steps.count ? "发送下一帧" : "重新演示", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
    }

    private func endpoint(_ name: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 42)).foregroundStyle(.blue)
            Text(name).font(.headline)
        }
    }
}

private struct HashLabView: View {
    @State private var keys: [String] = ["apple", "banana", "cherry"]

    private let candidates = ["date", "elder", "fig", "grape", "kiwi", "lemon"]

    private func bucket(_ key: String) -> Int {
        key.unicodeScalars.reduce(0) { ($0 + Int($1.value)) % 5 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("哈希函数把键映射到桶。不同键落到同一个桶就叫碰撞，链地址法用链表保存它们。")
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { index in
                        let bucketKeys = keys.filter { bucket($0) == index }
                        HStack {
                            Text("桶 \(index)")
                                .font(.headline.monospacedDigit())
                                .frame(width: 52, alignment: .leading)
                            if bucketKeys.isEmpty {
                                Text("空").foregroundStyle(.secondary)
                            } else {
                                ForEach(bucketKeys, id: \.self) { key in
                                    Text(key)
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(.orange.opacity(0.12), in: Capsule())
                                    Image(systemName: "arrow.right").font(.caption)
                                }
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                HStack {
                    Text("元素：\(keys.count) · 桶：5 · 负载因子：\(String(format: "%.1f", Double(keys.count) / 5.0))")
                        .font(.subheadline)
                    Spacer()
                    Button("加入键") {
                        let next = candidates[keys.count % candidates.count]
                        keys.append(next)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                .learningCard()
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
    }
}
