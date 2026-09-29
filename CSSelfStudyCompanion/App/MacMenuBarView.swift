#if os(macOS)
import AppKit
import SwiftUI

final class CSStudyAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

struct MacMenuBarView: View {
    @ObservedObject var syncManager: SyncManager
    @AppStorage("allowRemoteCodeExecution") private var allowRemoteCodeExecution = true
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text("CS 自学 Mac Companion")
            .font(.headline)

        Text(syncManager.statusText)
        if !syncManager.connectedPeers.isEmpty {
            Text("已连接：\(syncManager.connectedPeers.joined(separator: "、"))")
        }

        if let lastRemoteCodeAt = syncManager.lastRemoteCodeAt {
            Text("最近远程运行：\(lastRemoteCodeAt.formatted(date: .omitted, time: .shortened))")
            Text(syncManager.lastRemoteCodeSummary)
                .foregroundStyle(.secondary)
        }

        Divider()

        Toggle("允许 iPhone 远程运行代码", isOn: $allowRemoteCodeExecution)

        Button("打开 CS 自学") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }

        Button("立即同步") {
            syncManager.syncNow(force: true)
        }
        .disabled(syncManager.connectedPeers.isEmpty)

        Divider()

        Button("退出") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
#endif
