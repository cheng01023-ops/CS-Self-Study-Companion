import SwiftUI

struct DatabaseRecoveryView: View {
    let errorMessage: String?
    let backupURL: URL?
    let isWorking: Bool
    let onRetry: () -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.orange, .red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(height: 160)

            Text("学习数据库需要恢复")
                .font(.title2.bold())
            Text("App 没有删除任何内容。可以先重试；如果仍然失败，系统会把旧 Store 备份到 DatabaseRecovery 目录，再创建一个新数据库。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)

            if let errorMessage {
                VStack(alignment: .leading, spacing: 6) {
                    Text("错误信息")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(errorMessage)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
                .padding(12)
                .background(.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            }

            if let backupURL {
                Label("旧数据已备份到：\(backupURL.path)", systemImage: "externaldrive.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            HStack(spacing: 12) {
                Button(action: onRetry) {
                    Label("重试打开", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isWorking)

                Button(role: .destructive, action: onReset) {
                    Label(isWorking ? "处理中…" : "备份并重建", systemImage: "externaldrive.badge.exclamationmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isWorking)
            }
        }
        .padding(24)
        .frame(maxWidth: 680)
        .background(Color.appBackground)
        .accessibilityElement(children: .contain)
    }
}
