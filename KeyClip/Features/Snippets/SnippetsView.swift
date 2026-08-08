//
//  SnippetsView.swift
//  KeyClip
//

import SwiftUI
import SwiftData

struct SnippetsView: View {
    @EnvironmentObject private var theme: ThemeStore
    @Environment(\.copyToClipboard) private var copyToClipboard
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Snippet.category), SortDescriptor(\Snippet.trigger)]) private var snippets: [Snippet]
    @State private var searchText = ""
    @State private var editingSnippet: Snippet?
    @State private var isPresentingEditor = false

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
    }

    private var header: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search...", text: $searchText)
                .textFieldStyle(.plain)
            Spacer()
            Button {
                editingSnippet = nil
                isPresentingEditor = true
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            .buttonStyle(.plain)
        }
        .padding(8)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No snippets yet — add one to get started")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        List {
            ForEach(grouped, id: \.category) { group in
                Section(group.category) {
                    ForEach(group.items) { row(for: $0) }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(theme.background)
    }

    private func row(for snippet: Snippet) -> some View {
        SnippetRow(
            snippet: snippet,
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
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(snippet.trigger)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(theme.text)
            Text(snippet.content)
                .font(.caption)
                .foregroundStyle(theme.text.opacity(0.6))
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
