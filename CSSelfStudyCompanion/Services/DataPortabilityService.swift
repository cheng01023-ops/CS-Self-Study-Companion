import CryptoKit
import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct AppBackup: Codable {
    var version: Int = 1
    var exportedAt: Date
    var progress: [ProgressBackup]
    var bookmarks: [BookmarkBackup]
    var notes: [NoteBackup]
    var reviewItems: [ReviewBackup]
    var codeDrafts: [CodeDraftBackup]
    var masteryRecords: [MasteryBackup]
}

struct ProgressBackup: Codable {
    var itemID: String
    var isCompleted: Bool
    var score: Double?
    var lastStudiedAt: Date
    var completedAt: Date?
}

struct BookmarkBackup: Codable {
    var id: String
    var targetID: String
    var targetType: String
    var parentTutorialID: String?
    var stepIndex: Int?
    var title: String
    var subtitle: String
    var createdAt: Date
}

struct NoteBackup: Codable {
    var id: String
    var targetID: String
    var parentTutorialID: String?
    var stepIndex: Int?
    var title: String
    var body: String
    var createdAt: Date
    var updatedAt: Date
}

struct ReviewBackup: Codable {
    var id: String
    var sourceType: String
    var sourceID: String
    var title: String
    var question: String
    var referenceAnswer: String
    var explanation: String
    var userAnswer: String?
    var parentTutorialID: String?
    var stepIndex: Int?
    var dueAt: Date
    var intervalIndex: Int
    var correctStreak: Int
    var lapseCount: Int
    var createdAt: Date
    var lastReviewedAt: Date?
    var isArchived: Bool
    var easeFactor: Double?
    var stabilityDays: Double?
    var lastResponseSeconds: Double?
}

struct CodeDraftBackup: Codable {
    var exerciseID: String
    var sourceCode: String
    var input: String
    var lastOutput: String
    var lastError: String
    var passed: Bool
    var updatedAt: Date
    var lastRunAt: Date?
}

struct MasteryBackup: Codable {
    var conceptID: String
    var score: Double
    var attempts: Int
    var correctCount: Int
    var wrongCount: Int
    var lastReason: String
    var lastPracticedAt: Date
}

@MainActor
enum DataPortabilityService {
    static func backup(from context: ModelContext) throws -> AppBackup {
        let progresses = try context.fetch(FetchDescriptor<Progress>())
        let bookmarks = try context.fetch(FetchDescriptor<Bookmark>())
        let notes = try context.fetch(FetchDescriptor<LearningNote>())
        let reviews = try context.fetch(FetchDescriptor<ReviewItem>())
        let drafts = try context.fetch(FetchDescriptor<CodeDraft>())
        let mastery = try context.fetch(FetchDescriptor<MasteryRecord>())

        return AppBackup(
            exportedAt: .now,
            progress: progresses.map {
                ProgressBackup(
                    itemID: $0.itemID,
                    isCompleted: $0.isCompleted,
                    score: $0.score,
                    lastStudiedAt: $0.lastStudiedAt,
                    completedAt: $0.completedAt
                )
            },
            bookmarks: bookmarks.map {
                BookmarkBackup(
                    id: $0.id,
                    targetID: $0.targetID,
                    targetType: $0.targetType,
                    parentTutorialID: $0.parentTutorialID,
                    stepIndex: $0.stepIndex,
                    title: $0.title,
                    subtitle: $0.subtitle,
                    createdAt: $0.createdAt
                )
            },
            notes: notes.map {
                NoteBackup(
                    id: $0.id,
                    targetID: $0.targetID,
                    parentTutorialID: $0.parentTutorialID,
                    stepIndex: $0.stepIndex,
                    title: $0.title,
                    body: $0.body,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            },
            reviewItems: reviews.map {
                ReviewBackup(
                    id: $0.id,
                    sourceType: $0.sourceType,
                    sourceID: $0.sourceID,
                    title: $0.title,
                    question: $0.question,
                    referenceAnswer: $0.referenceAnswer,
                    explanation: $0.explanation,
                    userAnswer: $0.userAnswer,
                    parentTutorialID: $0.parentTutorialID,
                    stepIndex: $0.stepIndex,
                    dueAt: $0.dueAt,
                    intervalIndex: $0.intervalIndex,
                    correctStreak: $0.correctStreak,
                    lapseCount: $0.lapseCount,
                    createdAt: $0.createdAt,
                    lastReviewedAt: $0.lastReviewedAt,
                    isArchived: $0.isArchived,
                    easeFactor: $0.easeFactor,
                    stabilityDays: $0.stabilityDays,
                    lastResponseSeconds: $0.lastResponseSeconds
                )
            },
            codeDrafts: drafts.map {
                CodeDraftBackup(
                    exerciseID: $0.exerciseID,
                    sourceCode: $0.sourceCode,
                    input: $0.input,
                    lastOutput: $0.lastOutput,
                    lastError: $0.lastError,
                    passed: $0.passed,
                    updatedAt: $0.updatedAt,
                    lastRunAt: $0.lastRunAt
                )
            },
            masteryRecords: mastery.map {
                MasteryBackup(
                    conceptID: $0.conceptID,
                    score: $0.score,
                    attempts: $0.attempts,
                    correctCount: $0.correctCount,
                    wrongCount: $0.wrongCount,
                    lastReason: $0.lastReason,
                    lastPracticedAt: $0.lastPracticedAt
                )
            }
        )
    }

    static func data(from context: ModelContext) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup(from: context))
    }

    static func encryptedData(from context: ModelContext, password: String) throws -> Data {
        let plain = try data(from: context)
        let key = SymmetricKey(data: SHA256.hash(data: Data(password.utf8)))
        let sealed = try AES.GCM.seal(plain, using: key)
        guard let combined = sealed.combined else {
            throw CocoaError(.fileWriteUnknown)
        }
        return combined
    }

    static func restore(from data: Data, password: String? = nil, into context: ModelContext) throws {
        let plainData: Data
        if let password, !password.isEmpty, let sealed = try? AES.GCM.SealedBox(combined: data) {
            let key = SymmetricKey(data: SHA256.hash(data: Data(password.utf8)))
            plainData = try AES.GCM.open(sealed, using: key)
        } else {
            plainData = data
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(AppBackup.self, from: plainData)

        let existingProgress = try context.fetch(FetchDescriptor<Progress>())
        let existingBookmarks = try context.fetch(FetchDescriptor<Bookmark>())
        let existingNotes = try context.fetch(FetchDescriptor<LearningNote>())
        let existingReviews = try context.fetch(FetchDescriptor<ReviewItem>())
        let existingDrafts = try context.fetch(FetchDescriptor<CodeDraft>())
        let existingMastery = try context.fetch(FetchDescriptor<MasteryRecord>())

        let progressMap = Dictionary(uniqueKeysWithValues: existingProgress.map { ($0.itemID, $0) })
        let bookmarkMap = Dictionary(uniqueKeysWithValues: existingBookmarks.map { ($0.targetID, $0) })
        let noteMap = Dictionary(uniqueKeysWithValues: existingNotes.map { ($0.targetID, $0) })
        let reviewMap = Dictionary(uniqueKeysWithValues: existingReviews.map { ($0.sourceID, $0) })
        let draftMap = Dictionary(uniqueKeysWithValues: existingDrafts.map { ($0.exerciseID, $0) })
        let masteryMap = Dictionary(uniqueKeysWithValues: existingMastery.map { ($0.conceptID, $0) })

        for item in backup.progress {
            if let existing = progressMap[item.itemID], existing.lastStudiedAt > item.lastStudiedAt {
                continue
            }
            let record = progressMap[item.itemID] ?? Progress(itemID: item.itemID)
            if progressMap[item.itemID] == nil { context.insert(record) }
            record.isCompleted = item.isCompleted
            record.score = item.score
            record.lastStudiedAt = item.lastStudiedAt
            record.completedAt = item.completedAt
        }

        for item in backup.bookmarks {
            if let existing = bookmarkMap[item.targetID], existing.createdAt > item.createdAt {
                continue
            }
            let record = bookmarkMap[item.targetID] ?? Bookmark(
                id: item.id,
                targetID: item.targetID,
                targetType: item.targetType,
                title: item.title,
                subtitle: item.subtitle
            )
            if bookmarkMap[item.targetID] == nil { context.insert(record) }
            record.parentTutorialID = item.parentTutorialID
            record.stepIndex = item.stepIndex
            record.createdAt = item.createdAt
        }

        for item in backup.notes {
            if let existing = noteMap[item.targetID], existing.updatedAt > item.updatedAt {
                continue
            }
            let record = noteMap[item.targetID] ?? LearningNote(
                id: item.id,
                targetID: item.targetID,
                title: item.title
            )
            if noteMap[item.targetID] == nil { context.insert(record) }
            record.parentTutorialID = item.parentTutorialID
            record.stepIndex = item.stepIndex
            record.body = item.body
            record.createdAt = item.createdAt
            record.updatedAt = item.updatedAt
        }

        for item in backup.reviewItems {
            if let existing = reviewMap[item.sourceID],
               let existingDate = existing.lastReviewedAt ?? Optional(existing.createdAt),
               let incomingDate = item.lastReviewedAt ?? Optional(item.createdAt),
               existingDate > incomingDate {
                continue
            }
            let record = reviewMap[item.sourceID] ?? ReviewItem(
                id: item.id,
                sourceType: item.sourceType,
                sourceID: item.sourceID,
                title: item.title,
                question: item.question,
                referenceAnswer: item.referenceAnswer,
                explanation: item.explanation,
                dueAt: item.dueAt
            )
            if reviewMap[item.sourceID] == nil { context.insert(record) }
            record.title = item.title
            record.question = item.question
            record.referenceAnswer = item.referenceAnswer
            record.explanation = item.explanation
            record.userAnswer = item.userAnswer
            record.parentTutorialID = item.parentTutorialID
            record.stepIndex = item.stepIndex
            record.dueAt = item.dueAt
            record.intervalIndex = item.intervalIndex
            record.correctStreak = item.correctStreak
            record.lapseCount = item.lapseCount
            record.lastReviewedAt = item.lastReviewedAt
            record.isArchived = item.isArchived
            if let easeFactor = item.easeFactor { record.easeFactor = easeFactor }
            if let stabilityDays = item.stabilityDays { record.stabilityDays = stabilityDays }
            if let lastResponseSeconds = item.lastResponseSeconds { record.lastResponseSeconds = lastResponseSeconds }
        }

        for item in backup.codeDrafts {
            if let existing = draftMap[item.exerciseID], existing.updatedAt > item.updatedAt {
                continue
            }
            let record = draftMap[item.exerciseID] ?? CodeDraft(exerciseID: item.exerciseID, sourceCode: item.sourceCode)
            if draftMap[item.exerciseID] == nil { context.insert(record) }
            record.sourceCode = item.sourceCode
            record.input = item.input
            record.lastOutput = item.lastOutput
            record.lastError = item.lastError
            record.passed = item.passed
            record.updatedAt = item.updatedAt
            record.lastRunAt = item.lastRunAt
        }

        for item in backup.masteryRecords {
            if let existing = masteryMap[item.conceptID], existing.lastPracticedAt > item.lastPracticedAt {
                continue
            }
            let record = masteryMap[item.conceptID] ?? MasteryRecord(conceptID: item.conceptID)
            if masteryMap[item.conceptID] == nil { context.insert(record) }
            record.score = item.score
            record.attempts = item.attempts
            record.correctCount = item.correctCount
            record.wrongCount = item.wrongCount
            record.lastReason = item.lastReason
            record.lastPracticedAt = item.lastPracticedAt
        }

        try context.save()
    }
}

struct AppBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .data] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct DataPortabilityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var document: AppBackupDocument?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var statusMessage = ""
    @State private var useEncryption = false
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("学习数据备份", systemImage: "externaldrive.fill")
                        .font(.title2.bold())
                    Text("导出 JSON 后，可通过 AirDrop、iCloud Drive 或文件 App 传到另一台设备，再导入恢复。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                .learningCard()

                NavigationLink {
                    CoursePackView()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "shippingbox.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.orange.gradient, in: RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("课程包与更新")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("导出、导入课程内容，或通过 HTTPS 更新教程和资源")
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

                VStack(alignment: .leading, spacing: 10) {
                    Text("备份内容")
                        .font(.headline)
                    ForEach(["学习进度", "收藏", "笔记", "错题与复习计划", "代码草稿", "概念掌握度"], id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle")
                            .font(.subheadline)
                    }
                }
                .learningCard()

                Toggle(isOn: $useEncryption) {
                    Label("AES-GCM 加密备份", systemImage: "lock.shield.fill")
                }

                if useEncryption {
                    SecureField("设置备份密码", text: $password)
                        .textFieldStyle(.roundedBorder)
                }

                Button {
                    do {
                        let backupData: Data
                        if useEncryption {
                            guard password.count >= 6 else {
                                statusMessage = "加密密码至少需要 6 个字符。"
                                return
                            }
                            backupData = try DataPortabilityService.encryptedData(from: modelContext, password: password)
                        } else {
                            backupData = try DataPortabilityService.data(from: modelContext)
                        }
                        document = AppBackupDocument(data: backupData)
                        isExporting = true
                    } catch {
                        statusMessage = "导出失败：\(error.localizedDescription)"
                    }
                } label: {
                    Label("导出学习数据", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)

                Button {
                    isImporting = true
                } label: {
                    Label("导入学习数据", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.green)

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .learningCard()
                }
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
        .navigationTitle("数据与备份")
        .fileExporter(
            isPresented: $isExporting,
            document: document,
            contentType: useEncryption ? .data : .json,
            defaultFilename: "CS自学备份-\(Date.now.formatted(.dateTime.year().month().day()))"
        ) { result in
            switch result {
            case .success: statusMessage = "备份已导出。"
            case let .failure(error): statusMessage = "导出失败：\(error.localizedDescription)"
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json, .data]) { result in
            do {
                let url = try result.get()
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                try DataPortabilityService.restore(
                    from: Data(contentsOf: url),
                    password: useEncryption ? password : nil,
                    into: modelContext
                )
                statusMessage = "数据导入成功，学习记录已合并。"
            } catch {
                statusMessage = "导入失败：\(error.localizedDescription)"
            }
        }
    }
}
