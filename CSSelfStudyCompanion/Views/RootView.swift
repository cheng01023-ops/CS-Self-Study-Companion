import SwiftData
import SwiftUI

enum RootTab: Hashable {
    case roadmap
    case knowledge
    case review
    case commands
    case progress
}

extension Notification.Name {
    static let openRootTab = Notification.Name("openRootTab")
    static let openGuide = Notification.Name("openGuide")
    static let openAppRoute = Notification.Name("openAppRoute")
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedDiagnostic") private var hasCompletedDiagnostic = false
    @State private var showDiagnostic = false
    @State private var showGuide = false
    @State private var selectedTab: RootTab = .roadmap

    var body: some View {
        TabView(selection: $selectedTab) {
            RoadmapView()
                .tabItem {
                    Label("学习路线", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                }
                .tag(RootTab.roadmap)
                .accessibilityIdentifier("tab-roadmap")

            KnowledgeSearchView()
                .tabItem {
                    Label("知识中心", systemImage: "magnifyingglass")
                }
                .tag(RootTab.knowledge)
                .accessibilityIdentifier("tab-knowledge")

            ReviewCenterView()
                .tabItem {
                    Label("复习", systemImage: "brain.head.profile")
                }
                .tag(RootTab.review)
                .accessibilityIdentifier("tab-review")

            CommandReferenceView()
                .tabItem {
                    Label("命令速查", systemImage: "terminal")
                }
                .tag(RootTab.commands)
                .accessibilityIdentifier("tab-commands")

            ProgressDashboardView()
                .tabItem {
                    Label("学习进度", systemImage: "chart.bar.xaxis")
                }
                .tag(RootTab.progress)
                .accessibilityIdentifier("tab-progress")
        }
        .task {
            let arguments = ProcessInfo.processInfo.arguments
            let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            if !hasCompletedDiagnostic && !arguments.contains("-disable-diagnostic") && !isRunningTests {
                showDiagnostic = true
            }
            SeedService.seedIfNeeded(in: modelContext)
            if !arguments.contains("-disable-sync") && !isRunningTests {
                SyncManager.shared.start(context: modelContext)
            }
        }
        .sheet(isPresented: $showDiagnostic) {
            OnboardingDiagnosticView()
        }
        .sheet(isPresented: $showGuide) {
            NavigationStack {
                GuideView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("完成") { showGuide = false }
                        }
                    }
            }
            #if os(macOS)
            .frame(minWidth: 680, minHeight: 760)
            #endif
        }
        .onReceive(NotificationCenter.default.publisher(for: .openRootTab)) { notification in
            guard let tab = notification.object as? RootTab else { return }
            selectedTab = tab
        }
        .onReceive(NotificationCenter.default.publisher(for: .openGuide)) { _ in
            showGuide = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openAppRoute)) { _ in
            selectedTab = .roadmap
        }
        .onOpenURL { url in
            guard let route = SystemIntegrationService.route(for: url) else { return }
            selectedTab = .roadmap
            NotificationCenter.default.post(name: .openAppRoute, object: route)
        }
        .onContinueUserActivity(SystemIntegrationService.tutorialActivityType) { activity in
            guard let tutorialID = activity.userInfo?["tutorialID"] as? String else { return }
            selectedTab = .roadmap
            NotificationCenter.default.post(name: .openAppRoute, object: AppRoute.tutorial(tutorialID))
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [
            Stage.self,
            Topic.self,
            Tutorial.self,
            Exercise.self,
            Progress.self,
            Command.self,
            LearningResource.self,
            Concept.self,
            Bookmark.self,
            LearningNote.self,
            ReviewItem.self,
            CodeDraft.self,
            MasteryRecord.self
        ], inMemory: true)
}
