import SwiftData
import SwiftUI

struct KnowledgeSearchView: View {
    @Query(sort: \Tutorial.order) private var tutorials: [Tutorial]
    @Query(sort: \Command.name) private var commands: [Command]
    @Query(sort: \Concept.name) private var concepts: [Concept]
    @Query(sort: \Bookmark.createdAt, order: .reverse) private var bookmarks: [Bookmark]
    @Query(sort: \LearningNote.updatedAt, order: .reverse) private var notes: [LearningNote]

    @State private var searchText = ""
    @State private var resultIDs = SearchResultSet()
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if trimmedQuery.isEmpty {
                        knowledgeOverview
                    } else {
                        searchResults
                    }
                }
                .padding()
                .learningPageWidth()
            }
            .background(Color.appBackground)
            .navigationTitle("知识中心")
            .toolbar {
                ToolbarItem(placement: .primaryAction) { GuideLink() }
            }
            .searchable(text: $searchText, prompt: "搜索教程、章节、概念、命令、收藏和笔记")
            .task(id: trimmedQuery) {
                await updateSearchResults()
            }
            .navigationDestination(for: AppRoute.self) { route in
                AppDestinationView(route: route)
            }
        }
        .tint(.indigo)
    }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var knowledgeOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "332B78"), Color(hex: "7555C8"), Color(hex: "18A9A0")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 92, weight: .bold))
                    .foregroundStyle(.white.opacity(0.1))
                    .offset(x: -18, y: 62)

                VStack(alignment: .leading, spacing: 8) {
                    Text("知识中心")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("把教程、术语、命令、收藏和笔记放在同一个入口，随时找到下一步要学的内容。")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineSpacing(3)

                    HStack {
                        Label("\(tutorials.count) 篇教程", systemImage: "book.closed.fill")
                        Label("\(concepts.count) 个概念", systemImage: "lightbulb.fill")
                        Label("\(commands.count) 条命令", systemImage: "terminal.fill")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 4)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .shadow(color: .purple.opacity(0.18), radius: 12, y: 6)

            if !bookmarks.isEmpty {
                sectionHeader("最近收藏", icon: "bookmark.fill", tint: .orange)
                ForEach(bookmarks.prefix(4)) { bookmark in
                    NavigationLink(value: route(for: bookmark)) {
                        knowledgeRow(
                            icon: bookmark.targetType == "step" ? "bookmark.fill" : "book.closed.fill",
                            title: bookmark.title,
                            subtitle: bookmark.subtitle,
                            tint: .orange
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if !notes.isEmpty {
                sectionHeader("最近笔记", icon: "note.text", tint: .green)
                ForEach(notes.prefix(4)) { note in
                    NavigationLink(value: route(for: note)) {
                        knowledgeRow(
                            icon: "note.text",
                            title: note.title,
                            subtitle: note.body.replacingOccurrences(of: "\n", with: " "),
                            tint: .green
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            sectionHeader("概念分类", icon: "square.grid.2x2.fill", tint: .indigo)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(conceptCategories, id: \.self) { category in
                        let count = concepts.filter { $0.category == category }.count
                        Button {
                            searchText = category
                        } label: {
                            VStack(alignment: .leading, spacing: 7) {
                                Image(systemName: conceptIcon(for: category))
                                    .foregroundStyle(.indigo)
                                Text(category)
                                    .font(.subheadline.bold())
                                Text("\(count) 个概念")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(14)
                            .frame(width: 138, alignment: .leading)
                            .background(.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        let tutorialMatches = filteredTutorials
        let conceptMatches = filteredConcepts
        let commandMatches = filteredCommands
        let bookmarkMatches = filteredBookmarks
        let noteMatches = filteredNotes

        if isSearching {
            HStack {
                ProgressView()
                Text("正在后台搜索…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }

        if tutorialMatches.isEmpty && conceptMatches.isEmpty && commandMatches.isEmpty && bookmarkMatches.isEmpty && noteMatches.isEmpty {
            if !isSearching {
                ContentUnavailableView.search(text: trimmedQuery)
                    .padding(.top, 60)
            }
        } else {
            if !tutorialMatches.isEmpty {
                sectionHeader("教程与章节", icon: "book.pages.fill", tint: .indigo)
                ForEach(tutorialMatches.prefix(12)) { tutorial in
                    NavigationLink(value: AppRoute.tutorial(tutorial.id)) {
                        tutorialResult(tutorial)
                    }
                    .buttonStyle(.plain)
                }
            }

            if !conceptMatches.isEmpty {
                sectionHeader("概念", icon: "lightbulb.fill", tint: .yellow)
                ForEach(conceptMatches.prefix(12)) { concept in
                    NavigationLink(value: AppRoute.concept(concept.id)) {
                        knowledgeRow(icon: "lightbulb.fill", title: concept.name, subtitle: concept.summary, tint: .yellow)
                    }
                    .buttonStyle(.plain)
                }
            }

            if !commandMatches.isEmpty {
                sectionHeader("命令", icon: "terminal.fill", tint: .orange)
                ForEach(commandMatches.prefix(10)) { command in
                    commandResult(command)
                }
            }

            if !bookmarkMatches.isEmpty {
                sectionHeader("收藏", icon: "bookmark.fill", tint: .pink)
                ForEach(bookmarkMatches.prefix(10)) { bookmark in
                    NavigationLink(value: route(for: bookmark)) {
                        knowledgeRow(icon: "bookmark.fill", title: bookmark.title, subtitle: bookmark.subtitle, tint: .pink)
                    }
                    .buttonStyle(.plain)
                }
            }

            if !noteMatches.isEmpty {
                sectionHeader("笔记", icon: "note.text", tint: .green)
                ForEach(noteMatches.prefix(10)) { note in
                    NavigationLink(value: route(for: note)) {
                        knowledgeRow(icon: "note.text", title: note.title, subtitle: note.body, tint: .green)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sectionHeader(_ title: String, icon: String, tint: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(tint)
            .padding(.top, 2)
    }

    private func knowledgeRow(icon: String, title: String, subtitle: String, tint: Color) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle.replacingOccurrences(of: "\n", with: " "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .learningCard()
    }

    private func tutorialResult(_ tutorial: Tutorial) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(.indigo.opacity(0.1))
                Image(systemName: "book.pages.fill")
                    .foregroundStyle(.indigo)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(tutorial.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(matchedHeading(in: tutorial.markdown))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.indigo)
                Text(excerpt(from: tutorial.markdown))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .learningCard()
    }

    private func commandResult(_ command: Command) -> some View {
        HStack(spacing: 13) {
            Image(systemName: "terminal.fill")
                .font(.headline)
                .foregroundStyle(.orange)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(command.name)
                    .font(.headline)
                Text(command.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(command.example)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            Spacer()
            CopyButton(text: command.example, compact: true)
        }
        .learningCard()
    }

    private var filteredTutorials: [Tutorial] {
        tutorials.filter { resultIDs.tutorialIDs.contains($0.id) }
    }

    private var filteredConcepts: [Concept] {
        concepts.filter { resultIDs.conceptIDs.contains($0.id) }
    }

    private var filteredCommands: [Command] {
        commands.filter { resultIDs.commandIDs.contains($0.id) }
    }

    private var filteredBookmarks: [Bookmark] {
        bookmarks.filter { resultIDs.bookmarkIDs.contains($0.id) }
    }

    private var filteredNotes: [LearningNote] {
        notes.filter { resultIDs.noteIDs.contains($0.id) }
    }

    private func updateSearchResults() async {
        let query = trimmedQuery
        guard !query.isEmpty else {
            resultIDs = SearchResultSet()
            isSearching = false
            return
        }

        isSearching = true
        let documents = SearchDocuments(
            tutorials: tutorials.map {
                SearchDocument(id: $0.id, text: [$0.title, $0.summary, $0.markdown].joined(separator: " "))
            },
            concepts: concepts.map {
                SearchDocument(id: $0.id, text: ([$0.name, $0.summary, $0.details, $0.category] + $0.aliases).joined(separator: " "))
            },
            commands: commands.map {
                SearchDocument(id: $0.id, text: ([$0.name, $0.syntax, $0.explanation, $0.example] + $0.tags).joined(separator: " "))
            },
            bookmarks: bookmarks.map {
                SearchDocument(id: $0.id, text: [$0.title, $0.subtitle].joined(separator: " "))
            },
            notes: notes.map {
                SearchDocument(id: $0.id, text: [$0.title, $0.body].joined(separator: " "))
            }
        )

        try? await Task.sleep(for: .milliseconds(220))
        let results = await Task.detached(priority: .userInitiated) {
            SearchIndex.search(documents: documents, query: query)
        }.value

        guard query == trimmedQuery else { return }
        resultIDs = results
        isSearching = false
    }

    private var conceptCategories: [String] {
        Array(Set(concepts.map(\.category))).sorted()
    }

    private func conceptIcon(for category: String) -> String {
        switch category {
        case "C 与内存": return "memorychip.fill"
        case "架构": return "cpu.fill"
        case "工具链": return "hammer.fill"
        case "操作系统": return "gearshape.2.fill"
        case "并发", "系统编程": return "arrow.triangle.branch"
        case "网络": return "network"
        case "数据结构", "算法": return "point.3.connected.trianglepath.dotted"
        case "数据库": return "cylinder.split.1x2.fill"
        case "编译原理": return "textformat.abc.dottedunderline"
        case "容器": return "shippingbox.fill"
        default: return "lightbulb.fill"
        }
    }

    private func route(for bookmark: Bookmark) -> AppRoute {
        if let tutorialID = bookmark.parentTutorialID, let stepIndex = bookmark.stepIndex {
            return .tutorialStep(tutorialID: tutorialID, stepIndex: stepIndex)
        }
        if let tutorialID = bookmark.parentTutorialID {
            return .tutorial(tutorialID)
        }
        return .tutorial(bookmark.parentTutorialID ?? bookmark.targetID)
    }

    private func route(for note: LearningNote) -> AppRoute {
        if let tutorialID = note.parentTutorialID, let stepIndex = note.stepIndex {
            return .tutorialStep(tutorialID: tutorialID, stepIndex: stepIndex)
        }
        return .tutorial(note.parentTutorialID ?? note.targetID)
    }

    private func matchedHeading(in markdown: String) -> String {
        let matchingHeading = markdown
            .components(separatedBy: .newlines)
            .first { $0.hasPrefix("# ") && $0.localizedCaseInsensitiveContains(trimmedQuery) }

        if let matchingHeading {
            return String(matchingHeading.dropFirst(2))
        }
        return "匹配教程正文"
    }

    private func excerpt(from text: String) -> String {
        guard let range = text.range(of: trimmedQuery, options: .caseInsensitive) else {
            return String(text.prefix(120))
        }

        let lower = text.index(range.lowerBound, offsetBy: -50, limitedBy: text.startIndex) ?? text.startIndex
        let upper = text.index(range.upperBound, offsetBy: 90, limitedBy: text.endIndex) ?? text.endIndex
        return String(text[lower..<upper]).replacingOccurrences(of: "\n", with: " ")
    }
}


private struct SearchDocument {
    let id: String
    let text: String
}

private struct SearchDocuments {
    let tutorials: [SearchDocument]
    let concepts: [SearchDocument]
    let commands: [SearchDocument]
    let bookmarks: [SearchDocument]
    let notes: [SearchDocument]
}

private struct SearchResultSet {
    var tutorialIDs: Set<String> = []
    var conceptIDs: Set<String> = []
    var commandIDs: Set<String> = []
    var bookmarkIDs: Set<String> = []
    var noteIDs: Set<String> = []
}

private enum SearchIndex {
    static func search(documents: SearchDocuments, query: String) -> SearchResultSet {
        SearchResultSet(
            tutorialIDs: ids(in: documents.tutorials, query: query),
            conceptIDs: ids(in: documents.concepts, query: query),
            commandIDs: ids(in: documents.commands, query: query),
            bookmarkIDs: ids(in: documents.bookmarks, query: query),
            noteIDs: ids(in: documents.notes, query: query)
        )
    }

    private static func ids(in documents: [SearchDocument], query: String) -> Set<String> {
        Set(
            documents
                .filter { $0.text.localizedCaseInsensitiveContains(query) }
                .map(\.id)
        )
    }
}
