import Foundation
import SwiftData
import SwiftUI

@main
struct CSSelfStudyCompanionApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(CSStudyAppDelegate.self) private var appDelegate
    #endif
    @StateObject private var dataStore = AppDataStore()
    @StateObject private var syncManager = SyncManager.shared

    var body: some Scene {
        WindowGroup(id: "main") {
            Group {
                if let modelContainer = dataStore.container {
                    RootView()
                        .modelContainer(modelContainer)
                } else {
                    DatabaseRecoveryView(
                        errorMessage: dataStore.errorMessage,
                        backupURL: dataStore.backupURL,
                        isWorking: dataStore.isWorking,
                        onRetry: { dataStore.open() },
                        onReset: { dataStore.resetStore() }
                    )
                }
            }
        }
        #if os(macOS)
        .commands {
            CommandMenu("学习") {
                Button("学习路线") {
                    NotificationCenter.default.post(name: .openRootTab, object: RootTab.roadmap)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("知识中心") {
                    NotificationCenter.default.post(name: .openRootTab, object: RootTab.knowledge)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("复习") {
                    NotificationCenter.default.post(name: .openRootTab, object: RootTab.review)
                }
                .keyboardShortcut("3", modifiers: .command)

                Button("命令速查") {
                    NotificationCenter.default.post(name: .openRootTab, object: RootTab.commands)
                }
                .keyboardShortcut("4", modifiers: .command)

                Button("学习进度") {
                    NotificationCenter.default.post(name: .openRootTab, object: RootTab.progress)
                }
                .keyboardShortcut("5", modifiers: .command)

                Divider()

                Button("打开使用指南") {
                    NotificationCenter.default.post(name: .openGuide, object: nil)
                }
                .keyboardShortcut("/", modifiers: [.command, .shift])
            }
        }
        #endif

        #if os(macOS)
        MenuBarExtra(
            "CS 自学",
            systemImage: syncManager.connectedPeers.isEmpty ? "terminal" : "terminal.fill"
        ) {
            MacMenuBarView(syncManager: syncManager)
        }
        .menuBarExtraStyle(.menu)
        #endif
    }
}
