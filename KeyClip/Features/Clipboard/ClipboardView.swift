//
//  ClipboardView.swift
//  KeyClip
//

import SwiftUI
import SwiftData

struct ClipboardView: View {
    @Environment(\.copyToClipboard) private var copyToClipboard
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipboardItem.createdAt, order: .reverse) private var items: [ClipboardItem]
    @State private var searchText = ""

    private var pinnedOrFavorite: [ClipboardItem] {
        items.filter { $0.isPinned || $0.isFavorite }
    }

    private var history: [ClipboardItem] {
        let base = items.filter { !$0.isPinned && !$0.isFavorite }
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            if items.isEmpty {
                emptyState
            } else {
                list
            }
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(8)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("Copy something to see it here")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        List {
            if !pinnedOrFavorite.isEmpty {
                Section("Favorites") {
                    ForEach(pinnedOrFavorite) { row(for: $0) }
                }
                Section("History") {
                    ForEach(history) { row(for: $0) }
                }
            } else {
                ForEach(history) { row(for: $0) }
            }
        }
        .listStyle(.plain)
    }

    private func row(for item: ClipboardItem) -> some View {
        ClipboardRow(
            item: item,
            onSelect: { select(item) },
            onToggleFavorite: { toggleFavorite(item) },
            onTogglePin: { togglePin(item) },
            onDelete: { delete(item) }
        )
    }

    private func select(_ item: ClipboardItem) {
        item.useCount += 1
        copyToClipboard(item.content)
    }

    private func togglePin(_ item: ClipboardItem) {
        item.isPinned.toggle()
    }

    private func toggleFavorite(_ item: ClipboardItem) {
        item.isFavorite.toggle()
    }

    private func delete(_ item: ClipboardItem) {
        modelContext.delete(item)
    }
}

private struct ClipboardRow: View {
    let item: ClipboardItem
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack {
            Text(item.content)
                .lineLimit(2)
                .truncationMode(.tail)
            Spacer()
            Button(action: onToggleFavorite) {
                Image(systemName: item.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(item.isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(isHovered ? Color.secondary.opacity(0.12) : Color.clear)
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture { onSelect() }
        .contextMenu {
            Button(item.isPinned ? "Unpin" : "Pin", action: onTogglePin)
            Button(item.isFavorite ? "Remove Favorite" : "Add Favorite", action: onToggleFavorite)
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}
