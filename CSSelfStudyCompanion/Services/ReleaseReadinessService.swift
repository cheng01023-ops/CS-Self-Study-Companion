import Foundation

enum ReleaseCheckStatus: String {
    case passed
    case warning
    case blocked

    var title: String {
        switch self {
        case .passed: "通过"
        case .warning: "提醒"
        case .blocked: "阻塞"
        }
    }
}

struct ReleaseCheck: Identifiable {
    let id: String
    let title: String
    let status: ReleaseCheckStatus
    let detail: String
}

enum ReleaseReadinessService {
    static func checks() -> [ReleaseCheck] {
        let info = Bundle.main.infoDictionary ?? [:]
        let bundleID = info["CFBundleIdentifier"] as? String ?? ""
        let version = info["CFBundleShortVersionString"] as? String ?? "未知"
        let build = info["CFBundleVersion"] as? String ?? "未知"
        let urlTypes = info["CFBundleURLTypes"] as? [[String: Any]] ?? []
        let urlSchemes = urlTypes.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        let localNetworkText = info["NSLocalNetworkUsageDescription"] as? String
        let profileURL = Bundle.main.bundleURL.appendingPathComponent("embedded.mobileprovision")
        let hasProfile = FileManager.default.fileExists(atPath: profileURL.path)
        let iconName = info["CFBundleIcons"] != nil || info["CFBundleIconName"] != nil

        return [
            ReleaseCheck(
                id: "bundle",
                title: "Bundle Identifier",
                status: bundleID == "com.example.CSXuexi" ? .passed : .warning,
                detail: bundleID
            ),
            ReleaseCheck(
                id: "version",
                title: "版本和构建号",
                status: version == "未知" || build == "未知" ? .warning : .passed,
                detail: "\(version) (\(build))"
            ),
            ReleaseCheck(
                id: "url",
                title: "深链接 URL Scheme",
                status: urlSchemes.contains("csxuexi") ? .passed : .blocked,
                detail: urlSchemes.isEmpty ? "未配置" : urlSchemes.joined(separator: "、")
            ),
            ReleaseCheck(
                id: "local-network",
                title: "本地网络权限说明",
                status: localNetworkText?.isEmpty == false ? .passed : .warning,
                detail: localNetworkText ?? "未配置"
            ),
            ReleaseCheck(
                id: "signing",
                title: "iOS 描述文件",
                status: hasProfile ? .passed : .warning,
                detail: hasProfile ? "存在 embedded.mobileprovision" : "当前进程没有嵌入描述文件，可能是 macOS 构建"
            ),
            ReleaseCheck(
                id: "icon",
                title: "App Icon",
                status: iconName ? .passed : .warning,
                detail: iconName ? "已配置" : "没有检测到图标信息"
            ),
            ReleaseCheck(
                id: "distribution",
                title: "公开分发",
                status: .warning,
                detail: "Personal Team 只能安装到自己的已配对该设备。公开 iOS 分发需要 TestFlight/App Store，macOS 公共分发需要 Developer ID 和公证。"
            )
        ]
    }
}
