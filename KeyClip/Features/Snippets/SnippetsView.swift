//
//  SnippetsView.swift
//  KeyClip
//

import SwiftUI
import SwiftData

struct SnippetsView: View {
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var tabSelection: TabSelectionStore
    @Environment(\.copyToClipboard) private var copyToClipboard
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Snippet.category), SortDescriptor(\Snippet.trigger)]) private var snippets: [Snippet]
    @State private var searchText = ""
    @State private var editingSnippet: Snippet?
    @State private var isPresentingEditor = false
    private let topAnchorID = "top"

    private var filtered: [Snippet] {
        guard !searchText.isEmpty else { return snippets }
        return snippets.filter {
            $0.trigger.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var grouped: [(category: String, items: [Snippet])] {
        let groups = Dictionary(grouping: filtered, by: { $0.category })
        return groups.keys.sorted().map { key in
            (category: key, items: groups[key]!.sorted { $0.trigger < $1.trigger })
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if snippets.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .sheet(isPresented: $isPresentingEditor) {
            SnippetEditorView(editing: editingSnippet)
        }
        .typeToSearch(text: $searchText)
    }

    private var header: some View {
        HStack {
            CollapsibleSearchField(text: $searchText)
            Spacer()
            Button {
                editingSnippet = nil
                isPresentingEditor = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(theme.text.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(theme.background)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(theme.text.opacity(0.45))
            Text("No snippets yet — add one to get started")
                .foregroundStyle(theme.text.opacity(0.45))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }

    private var list: some View {
        ScrollViewReader { proxy in
            List {
                Color.clear.frame(height: 0).id(topAnchorID)
                ForEach(grouped, id: \.category) { group in
                    Section {
                        ForEach(group.items) { row(for: $0) }
                    } header: {
                        Text(group.category).foregroundStyle(theme.text.opacity(0.45))
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .onChange(of: tabSelection.openGeneration) { _, _ in
                proxy.scrollTo(topAnchorID, anchor: .top)
            }
        }
    }

    private func row(for snippet: Snippet) -> some View {
        SnippetRow(
            snippet: snippet,
            searchText: searchText,
            onSelect: { copyToClipboard(snippet.content) },
            onEdit: {
                editingSnippet = snippet
                isPresentingEditor = true
            },
            onDelete: { delete(snippet) }
        )
        .listRowBackground(Color.clear)
    }

    private func delete(_ snippet: Snippet) {
        modelContext.delete(snippet)
        try? modelContext.save()
        SnippetExpansionEngine.shared.refreshTriggers()
    }
}

private struct SnippetRow: View {
    @EnvironmentObject private var theme: ThemeStore
    let snippet: Snippet
    let searchText: String
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HighlightedText(snippet.trigger, matching: searchText)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(theme.text)
            HighlightedText(snippet.content, matching: searchText)
                .font(.caption)
                .foregroundStyle(theme.text.opacity(0.45))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(isHovered ? theme.hover : Color.clear)
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture { onSelect() }
        .contextMenu {
            Button("Edit", action: onEdit)
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}
