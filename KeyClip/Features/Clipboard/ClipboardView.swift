//
//  ClipboardView.swift
//  KeyClip
//

import SwiftUI
import SwiftData

struct ClipboardView: View {
    @Environment(\.injectText) private var injectText
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
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.content)
                    .lineLimit(2)
                    .truncationMode(.tail)
                Text(item.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                toggleFavorite(item)
            } label: {
                Image(systemName: item.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(item.isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            select(item)
        }
        .contextMenu {
            Button(item.isPinned ? "Unpin" : "Pin") { togglePin(item) }
            Button(item.isFavorite ? "Remove Favorite" : "Add Favorite") { toggleFavorite(item) }
            Button("Delete", role: .destructive) { delete(item) }
        }
    }

    private func select(_ item: ClipboardItem) {
        item.useCount += 1
        injectText(item.content)
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
