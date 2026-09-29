import CryptoKit
import Foundation
@preconcurrency import MultipeerConnectivity
#if os(iOS)
import UIKit
#endif
import SwiftData
import SwiftUI

final class SyncManager: NSObject, ObservableObject {
    static let shared = SyncManager()
    static let serviceType = "cs-self-sync"

    @Published private(set) var connectedPeers: [String] = []
    @Published private(set) var statusText = "正在启动同步…"
    @Published private(set) var lastSyncAt: Date?
    @Published private(set) var isSyncing = false
    @Published private(set) var supportsRemoteCodeExecution = false
    @Published private(set) var lastRemoteCodeAt: Date?
    @Published private(set) var lastRemoteCodeSummary = "尚无远程运行"

    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var modelContext: ModelContext?
    private var timer: Timer?
    private var lastBackup: AppBackup?
    private var codeExecutionPeers: Set<MCPeerID> = []
    private var recentRemoteExecutions: [Date] = []
    private var pendingCodeRequests: [String: CheckedContinuation<CodeRunResult, Never>] = [:]
    private var codeRequestTimeouts: [String: Task<Void, Never>] = [:]

    private override init() {
        super.init()
    }

    @MainActor
    func start(context: ModelContext) {
        guard session == nil else { return }
        modelContext = context

        let peerID = MCPeerID(displayName: Self.deviceName)
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        #if os(macOS)
        let role = "mac"
        #else
        let role = "ios"
        #endif
        let advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: ["app": "CSX", "role": role],
            serviceType: Self.serviceType
        )
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser

        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser
        statusText = "等待同一局域网中的另一台设备…"
        print("[Sync] advertising as \(peerID.displayName) with service \(Self.serviceType)")

        timer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { _ in
            Task { @MainActor in
                SyncManager.shared.syncNow()
            }
        }
        if #available(macOS 14.0, iOS 17.0, *) {
            supportsRemoteCodeExecution = true
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        pendingCodeRequests.values.forEach { $0.resume(returning: .remoteUnavailable) }
        pendingCodeRequests.removeAll()
        codeRequestTimeouts.values.forEach { $0.cancel() }
        codeRequestTimeouts.removeAll()
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        session = nil
        advertiser = nil
        browser = nil
        connectedPeers = []
        statusText = "同步已停止"
    }

    @MainActor
    func syncNow(force: Bool = false) {
        guard let session, let modelContext, !session.connectedPeers.isEmpty else { return }
        guard !isSyncing else { return }
        isSyncing = true
        let syncStart = Date()

        do {
            let backup = try DataPortabilityService.backup(from: modelContext)
            let delta = SyncDeltaService.makeDelta(
                from: backup,
                baseline: force ? nil : lastBackup
            )
            guard force || !delta.isEmpty else {
                isSyncing = false
                return
            }

            let payload = try JSONEncoder().encode(SyncEnvelope.delta(delta))
            try session.send(payload, toPeers: session.connectedPeers, with: .reliable)
            lastBackup = backup
            lastSyncAt = .now
            PerformanceMonitor.shared.record(
                name: "局域网增量同步",
                duration: Date().timeIntervalSince(syncStart)
            )
            statusText = "已增量同步 \(connectedPeers.joined(separator: "、"))"
        } catch {
            statusText = "同步失败：\(error.localizedDescription)"
        }

        isSyncing = false
    }

    @MainActor
    func requestRemoteCode(
        code: String,
        language: String,
        input: String,
        arguments: [String],
        expectedOutput: String
    ) async -> CodeRunResult {
        guard code.utf8.count <= 200_000 else {
            return .remoteFailure("代码超过 Mac companion 的 200 KB 限制。")
        }
        guard let session else {
            return .remoteFailure("同步服务尚未启动。请先在两台设备上打开 App，并允许本地网络访问。")
        }
        let targetPeers = session.connectedPeers.filter { codeExecutionPeers.contains($0) }
        guard !targetPeers.isEmpty else {
            return .remoteFailure("没有检测到同一局域网中的 Mac。请先在 Mac 上打开 App，并允许本地网络访问。")
        }

        let request = RemoteCodeRequest(
            id: UUID().uuidString,
            code: code,
            language: language,
            input: input,
            arguments: arguments,
            expectedOutput: expectedOutput
        )

        do {
            let payload = try JSONEncoder().encode(SyncEnvelope.codeRequest(request))
            try session.send(payload, toPeers: targetPeers, with: .reliable)
        } catch {
            return .remoteFailure("无法发送到 Mac：\(error.localizedDescription)")
        }

        statusText = "正在请求 Mac 编译运行…"

        return await withCheckedContinuation { continuation in
            pendingCodeRequests[request.id] = continuation
            codeRequestTimeouts[request.id] = Task { @MainActor in
                try? await Task.sleep(for: .seconds(20))
                guard !Task.isCancelled else { return }
                self.finishRemoteCode(
                    id: request.id,
                    result: .remoteFailure("等待 Mac 返回超时。请确认 Mac 上的 App 仍在运行。")
                )
            }
        }
    }

    @MainActor
    private func finishRemoteCode(id: String, result: CodeRunResult) {
        codeRequestTimeouts[id]?.cancel()
        codeRequestTimeouts[id] = nil
        pendingCodeRequests.removeValue(forKey: id)?.resume(returning: result)
        statusText = result.succeeded ? "Mac 已返回运行结果" : "Mac companion 返回：\(result.message)"
    }

    private static var deviceName: String {
        #if os(iOS)
        UIDevice.current.name
        #else
        Host.current().localizedName ?? "MacBook"
        #endif
    }

    @MainActor
    private func applyRemoteData(_ data: Data) {
        guard let modelContext else { return }
        do {
            try DataPortabilityService.restore(from: data, into: modelContext)
            lastSyncAt = .now
            statusText = "已接收另一台设备的数据"
        } catch {
            statusText = "接收失败：\(error.localizedDescription)"
        }
    }

    @MainActor
    private func handleEnvelope(_ envelope: SyncEnvelope) {
        switch envelope {
        case let .backup(data):
            applyRemoteData(data)
        case let .delta(delta):
            applyRemoteDelta(delta)
        case let .codeRequest(request):
            handleRemoteCodeRequest(request)
        case let .codeResponse(response):
            finishRemoteCode(id: response.id, result: response.result)
        }
    }

    @MainActor
    private func applyRemoteDelta(_ delta: SyncDelta) {
        guard let modelContext else { return }
        do {
            try SyncDeltaService.apply(delta, into: modelContext)
            lastBackup = try? DataPortabilityService.backup(from: modelContext)
            lastSyncAt = .now
            statusText = "已接收记录级增量"
        } catch {
            statusText = "增量合并失败：\(error.localizedDescription)"
        }
    }

    @MainActor
    private func sendRemoteCodeResponse(id: String, result: CodeRunResult) {
        guard let session, !session.connectedPeers.isEmpty else { return }
        guard let payload = try? JSONEncoder().encode(
            SyncEnvelope.codeResponse(RemoteCodeResponse(id: id, result: result))
        ) else { return }
        try? session.send(payload, toPeers: session.connectedPeers, with: .reliable)
    }

    @MainActor
    private func handleRemoteCodeRequest(_ request: RemoteCodeRequest) {
        #if os(macOS)
        let remoteAllowed = UserDefaults.standard.object(forKey: "allowRemoteCodeExecution") as? Bool ?? true
        guard remoteAllowed else {
            sendRemoteCodeResponse(
                id: request.id,
                result: .remoteFailure("Mac 端已关闭远程代码执行。")
            )
            return
        }
        let now = Date()
        recentRemoteExecutions.removeAll { now.timeIntervalSince($0) > 60 }
        guard recentRemoteExecutions.count < 10 else {
            sendRemoteCodeResponse(
                id: request.id,
                result: .remoteFailure("远程运行过于频繁，请稍后再试。")
            )
            return
        }
        recentRemoteExecutions.append(now)
        guard let session, !session.connectedPeers.isEmpty else { return }
        let peers = session.connectedPeers
        lastRemoteCodeAt = now
        lastRemoteCodeSummary = "\(request.language.uppercased()) · \(request.code.utf8.count) 字节 · 执行中"
        Task {
            let result = await CodeExecutionService.run(
                code: request.code,
                language: request.language,
                input: request.input,
                arguments: request.arguments,
                expectedOutput: request.expectedOutput
            )
            guard let payload = try? JSONEncoder().encode(
                SyncEnvelope.codeResponse(RemoteCodeResponse(id: request.id, result: result))
            ) else { return }
            try? session.send(payload, toPeers: peers, with: .reliable)
            await MainActor.run {
                self.lastRemoteCodeSummary = "\(request.language.uppercased()) · \(result.passed ? "通过" : result.succeeded ? "运行成功" : "失败")"
            }
        }
        #else
        // 只有 Mac 响应远程编译请求，避免局域网中的其他 iPhone 抢先返回错误。
        _ = request
        #endif
    }
}

extension SyncManager: MCSessionDelegate {
    @objc func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        Task { @MainActor in
            connectedPeers = session.connectedPeers.map(\.displayName).sorted()
            switch state {
            case .connected:
                statusText = "已连接 \(peerID.displayName)"
                lastBackup = nil
                syncNow()
            case .connecting:
                statusText = "正在连接 \(peerID.displayName)…"
            case .notConnected:
                codeExecutionPeers.remove(peerID)
                statusText = connectedPeers.isEmpty ? "等待同一局域网中的另一台设备…" : "已连接 \(connectedPeers.joined(separator: "、"))"
            @unknown default:
                statusText = "同步状态未知"
            }
        }
    }

    @objc func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        Task { @MainActor in
            if let envelope = try? JSONDecoder().decode(SyncEnvelope.self, from: data) {
                handleEnvelope(envelope)
            } else {
                // 兼容旧版本直接发送备份数据的格式。
                applyRemoteData(data)
            }
        }
    }

    @objc func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {}

    @objc func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Foundation.Progress
    ) {}

    @objc func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {}
}

extension SyncManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("[Sync] advertiser failed: \(error.localizedDescription)")
        Task { @MainActor in statusText = "无法广播：\(error.localizedDescription)" }
    }

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }
}

extension SyncManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("[Sync] browser failed: \(error.localizedDescription)")
        Task { @MainActor in statusText = "无法搜索设备：\(error.localizedDescription)" }
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String : String]?
    ) {
        guard info?["app"] == "CSX" else { return }
        Task { @MainActor in
            if info?["role"] == "mac" {
                self.codeExecutionPeers.insert(peerID)
            }
            guard let session = self.session else { return }
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 15)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.codeExecutionPeers.remove(peerID)
            connectedPeers = session?.connectedPeers.map(\.displayName).sorted() ?? []
        }
    }
}
