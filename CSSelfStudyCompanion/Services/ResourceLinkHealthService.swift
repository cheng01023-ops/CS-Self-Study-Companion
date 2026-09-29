import Combine
import Foundation

enum ResourceLinkStatus: Equatable {
    case unknown
    case checking
    case available(Int)
    case failed(String)

    var title: String {
        switch self {
        case .unknown: "未检查"
        case .checking: "检查中"
        case let .available(code): "可用 \(code)"
        case .failed: "不可访问"
        }
    }
}

@MainActor
final class ResourceLinkHealthService: ObservableObject {
    static let shared = ResourceLinkHealthService()

    @Published private(set) var statuses: [String: ResourceLinkStatus] = [:]

    private init() {}

    nonisolated static func validationError(for url: URL?) -> String? {
        guard let url else { return "链接格式无效。" }
        guard url.scheme == "https" else { return "只检查 HTTPS 链接。" }
        guard url.host != nil else { return "链接缺少主机名。" }
        return nil
    }

    func check(_ resource: LearningResource) async {
        guard let url = URL(string: resource.urlString),
              Self.validationError(for: url) == nil else {
            statuses[resource.id] = .failed("链接格式无效")
            return
        }

        statuses[resource.id] = .checking
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        request.setValue("CS-SelfStudy-LinkCheck/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                statuses[resource.id] = .failed("没有收到 HTTP 响应")
                return
            }
            if (200..<400).contains(http.statusCode) {
                statuses[resource.id] = .available(http.statusCode)
            } else {
                statuses[resource.id] = .failed("HTTP \(http.statusCode)")
            }
        } catch {
            statuses[resource.id] = .failed(error.localizedDescription)
        }
    }
}
