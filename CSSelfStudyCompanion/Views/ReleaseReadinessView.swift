import SwiftUI

struct ReleaseReadinessView: View {
    private let checks = ReleaseReadinessService.checks()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("发布就绪检查", systemImage: "shippingbox.and.arrow.backward.fill")
                        .font(.title2.bold())
                    Text("检查版本、深链接、本地网络权限、图标和签名。发布到其他用户设备时，仍必须使用 Apple 允许的分发渠道。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                .learningCard()

                ForEach(checks) { check in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: icon(for: check.status))
                            .font(.title3)
                            .foregroundStyle(color(for: check.status))
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(check.title)
                                    .font(.headline)
                                Spacer()
                                Text(check.status.title)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(color(for: check.status))
                            }
                            Text(check.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineSpacing(3)
                        }
                    }
                    .learningCard()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("正式分发路径", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                    Text("iOS：TestFlight 或 App Store。macOS：Developer ID 签名、公证后分发。免费 Personal Team 的 7 天签名只适合开发设备，不是公开下载方案。")
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
        .navigationTitle("发布就绪")
    }

    private func icon(for status: ReleaseCheckStatus) -> String {
        switch status {
        case .passed: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .blocked: "xmark.octagon.fill"
        }
    }

    private func color(for status: ReleaseCheckStatus) -> Color {
        switch status {
        case .passed: .green
        case .warning: .orange
        case .blocked: .red
        }
    }
}
