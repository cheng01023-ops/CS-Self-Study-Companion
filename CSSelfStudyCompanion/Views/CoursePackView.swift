import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct CoursePackView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(CoursePackService.versionKey) private var contentVersion = "1.0"
    @AppStorage(CoursePackService.updatedAtKey) private var updatedAtText = ""
    @State private var document: AppBackupDocument?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var remoteURL = ""
    @State private var expectedSHA256 = ""
    @State private var statusMessage = ""
    @State private var isDownloading = false
    @State private var versionHistory: [ContentVersionEntry] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("课程内容包", systemImage: "shippingbox.fill")
                        .font(.title2.bold())
                    Text("课程包只更新阶段、教程、练习和资源。学习进度、笔记、收藏、错题和复习计划按稳定 ID 独立保存，不会被课程更新重置。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                    Text("当前内容版本：\(contentVersion)")
                        .font(.caption.monospaced().weight(.semibold))
                        .foregroundStyle(.indigo)
                    if !updatedAtText.isEmpty {
                        Text("最近更新：\(updatedAtText)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .learningCard()

                HStack {
                    Button {
                        exportPack()
                    } label: {
                        Label("导出当前课程包", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)

                    Button {
                        isImporting = true
                    } label: {
                        Label("导入本地课程包", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("联网更新", systemImage: "network")
                        .font(.headline)
                    TextField("HTTPS 课程包地址", text: $remoteURL)
                        .textFieldStyle(.roundedBorder)
                    TextField("可选：课程包 SHA-256", text: $expectedSHA256)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        downloadPack()
                    } label: {
                        HStack {
                            if isDownloading { ProgressView().controlSize(.small) }
                            Label(isDownloading ? "正在下载…" : "下载并更新课程", systemImage: "arrow.down.circle.fill")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(isDownloading)
                }
                .learningCard()

                Text("课程包格式版本：1。远程更新只接受 HTTPS；填写 SHA-256 后会先校验内容再导入。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !versionHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("更新历史", systemImage: "clock.arrow.circlepath")
                            .font(.headline)
                        ForEach(versionHistory.prefix(8)) { entry in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("版本 \(entry.version)")
                                        .font(.subheadline.weight(.semibold))
                                    Text(entry.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(entry.updatedAt, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .learningCard()
                }

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
        .navigationTitle("课程包与更新")
        .onAppear {
            versionHistory = ContentVersionHistoryService.load()
        }
        .fileExporter(
            isPresented: $isExporting,
            document: document,
            contentType: .json,
            defaultFilename: "CS自学课程包-\(contentVersion)"
        ) { result in
            switch result {
            case .success:
                statusMessage = "课程包已导出。"
            case let .failure(error):
                statusMessage = "导出失败：\(error.localizedDescription)"
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let report = try CoursePackService.importPack(
                    try Data(contentsOf: url),
                    into: modelContext
                )
                contentVersion = UserDefaults.standard.string(forKey: CoursePackService.versionKey) ?? contentVersion
                updatedAtText = UserDefaults.standard.string(forKey: CoursePackService.updatedAtKey) ?? ""
                ContentVersionHistoryService.record(version: contentVersion, summary: report.summary)
                versionHistory = ContentVersionHistoryService.load()
                statusMessage = "课程包导入成功：\(report.summary)"
            } catch {
                statusMessage = "导入失败：\(error.localizedDescription)"
            }
        }
    }

    private func exportPack() {
        do {
            document = AppBackupDocument(data: try CoursePackService.data(from: modelContext))
            isExporting = true
        } catch {
            statusMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    private func downloadPack() {
        guard let url = URL(string: remoteURL) else {
            statusMessage = "课程包地址无效。"
            return
        }
        isDownloading = true
        statusMessage = "正在下载课程包…"
        Task {
            do {
                let report = try await CoursePackService.download(
                    from: url,
                    expectedSHA256: expectedSHA256,
                    into: modelContext
                )
                await MainActor.run {
                    contentVersion = UserDefaults.standard.string(forKey: CoursePackService.versionKey) ?? contentVersion
                    updatedAtText = UserDefaults.standard.string(forKey: CoursePackService.updatedAtKey) ?? ""
                    ContentVersionHistoryService.record(version: contentVersion, summary: report.summary)
                    versionHistory = ContentVersionHistoryService.load()
                    statusMessage = "课程更新成功：\(report.summary)"
                    isDownloading = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = "更新失败：\(error.localizedDescription)"
                    isDownloading = false
                }
            }
        }
    }
}
