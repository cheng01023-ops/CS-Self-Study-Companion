import SwiftData
import SwiftUI

struct PerformanceDashboardView: View {
    @Query private var tutorials: [Tutorial]
    @Query private var resources: [LearningResource]
    @Query private var progressRecords: [Progress]
    @StateObject private var monitor = PerformanceMonitor.shared

    private var databaseBytes: Int64 {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let store = directory.appendingPathComponent("default.store")
        let urls = [
            store,
            URL(fileURLWithPath: store.path + "-wal"),
            URL(fileURLWithPath: store.path + "-shm")
        ]
        return urls.reduce(0) { total, url in
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
            let size = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
            return total + size
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryCard
                metricsCard
                stabilityCard
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
        .navigationTitle("性能与稳定性")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("清空指标") {
                    monitor.clear()
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("运行概况", systemImage: "gauge.with.dots.needle.67percent")
                .font(.title3.bold())
            HStack {
                StatPill(icon: "book.closed", text: "\(tutorials.count) 教程")
                StatPill(icon: "link", text: "\(resources.count) 资源")
                StatPill(icon: "checkmark.circle", text: "\(progressRecords.count) 进度记录")
            }
            Text("数据库大小：\(ByteCountFormatter.string(fromByteCount: databaseBytes, countStyle: .file))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("版本：\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "未知") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"))")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .learningCard()
    }

    private var metricsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("最近性能指标", systemImage: "stopwatch.fill")
                .font(.title3.bold())
            if monitor.metrics.isEmpty {
                Text("运行一次数据库打开、同步或代码执行后，这里会出现耗时记录。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(monitor.metrics.prefix(12)) { metric in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(metric.name)
                                .font(.subheadline.weight(.semibold))
                            Text(metric.measuredAt, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int(metric.durationMilliseconds)) ms")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(metric.durationMilliseconds > 1_000 ? .orange : .green)
                    }
                }
            }
        }
        .learningCard()
    }

    private var stabilityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("稳定性检查", systemImage: "checkmark.shield.fill")
                .font(.title3.bold())
            Label("数据库失败自动备份和恢复界面", systemImage: "checkmark.circle.fill")
            Label("局域网同步只发送记录级增量", systemImage: "checkmark.circle.fill")
            Label("代码执行具有资源限制和执行配额", systemImage: "checkmark.circle.fill")
            Label("课程包更新与用户进度分离", systemImage: "checkmark.circle.fill")
        }
        .foregroundStyle(.secondary)
        .learningCard()
    }
}
