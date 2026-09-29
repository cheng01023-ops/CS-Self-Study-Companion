import SwiftData
import SwiftUI

struct CommandReferenceView: View {
    @Query(sort: [SortDescriptor(\Command.category), SortDescriptor(\Command.name)])
    private var commands: [Command]

    @State private var searchText = ""
    @State private var selectedPlatform = "全部"
    @State private var selectedCategory = "全部"

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    overviewCard
                    filterBar

                    if filteredCommands.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                            .padding(.top, 60)
                    } else {
                        ForEach(filteredCommands) { command in
                            CommandCard(command: command)
                        }
                    }
                }
                .padding()
                .learningPageWidth()
            }
            .background(Color.appBackground)
            .navigationTitle("命令速查")
            .toolbar {
                ToolbarItem(placement: .primaryAction) { GuideLink() }
            }
            .searchable(text: $searchText, prompt: "搜索命令、用途或标签")
        }
        .tint(selectedPlatform == "Linux" ? .orange : .indigo)
    }

    private var overviewCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(
                    LinearGradient(colors: [.indigo, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 18)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text("终端与 Linux 命令库")
                    .font(.title3.bold())
                Text("\(commands.count) 条命令 · \(categories.count) 个分类 · 支持搜索、筛选和复制")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.indigo.opacity(0.10), Color.orange.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.indigo.opacity(0.14), lineWidth: 1)
        }
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("平台", selection: $selectedPlatform) {
                Text("全部").tag("全部")
                Text("macOS 终端").tag("macOS")
                Text("Linux").tag("Linux")
            }
            .pickerStyle(.segmented)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    filterChip("全部")
                    ForEach(categories, id: \.self) { category in
                        filterChip(category)
                    }
                }
            }
        }
        .learningCard()
    }

    private func filterChip(_ category: String) -> some View {
        Button(category) {
            selectedCategory = category
        }
        .font(.caption.weight(.semibold))
        .buttonStyle(.bordered)
        .tint(selectedCategory == category ? .indigo : .secondary)
    }

    private var categories: [String] {
        Array(Set(commands.map(\.category))).sorted()
    }

    private var filteredCommands: [Command] {
        commands.filter { command in
            let platformMatches = selectedPlatform == "全部" || command.platform == selectedPlatform
            let categoryMatches = selectedCategory == "全部" || command.category == selectedCategory
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchMatches = query.isEmpty
                || command.name.localizedCaseInsensitiveContains(query)
                || command.syntax.localizedCaseInsensitiveContains(query)
                || command.explanation.localizedCaseInsensitiveContains(query)
                || command.example.localizedCaseInsensitiveContains(query)
                || command.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            return platformMatches && categoryMatches && searchMatches
        }
    }
}

private struct CommandCard: View {
    let command: Command

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(command.name)
                        .font(.headline)
                    Text(command.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(command.platform)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(command.platform == "Linux" ? .orange : .indigo)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        (command.platform == "Linux" ? Color.orange : Color.indigo).opacity(0.1),
                        in: Capsule()
                    )
            }

            HStack {
                Text(command.syntax)
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .textSelection(.enabled)
                Spacer()
                CopyButton(text: command.example, compact: true)
            }
            .padding(12)
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

            Text(command.example)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Image(systemName: "tag")
                Text(command.tags.joined(separator: " · "))
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .learningCard()
    }
}
