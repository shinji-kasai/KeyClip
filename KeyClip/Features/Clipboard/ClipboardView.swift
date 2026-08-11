//
//  ClipboardView.swift
//  KeyClip
//

import SwiftUI
import SwiftData

struct ClipboardView: View {
    @EnvironmentObject private var theme: ThemeStore
    @EnvironmentObject private var tabSelection: TabSelectionStore
    @Environment(\.copyToClipboard) private var copyToClipboard
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipboardItem.createdAt, order: .reverse) private var items: [ClipboardItem]
    @State private var searchText = ""
    private let topAnchorID = "top"

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
            Image(systemName: "magnifyingglass").foregroundStyle(theme.text.opacity(0.6))
            TextField("Search...", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundStyle(theme.text)
        }
        .padding(8)
        .background(theme.background)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 32))
                .foregroundStyle(theme.text.opacity(0.6))
            Text("Copy something to see it here")
                .foregroundStyle(theme.text.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }

    private var list: some View {
        ScrollViewReader { proxy in
            List {
                Color.clear.frame(height: 0).id(topAnchorID)
                if !pinnedOrFavorite.isEmpty {
                    Section {
                        ForEach(pinnedOrFavorite) { row(for: $0) }
                    } header: {
                        sectionHeader("Favorites")
                    }
                    Section {
                        ForEach(history) { row(for: $0) }
                    } header: {
                        sectionHeader("History")
                    }
                } else {
                    ForEach(history) { row(for: $0) }
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

    private func sectionHeader(_ title: String) -> some View {
        Text(title).foregroundStyle(theme.text.opacity(0.6))
    }

    private func row(for item: ClipboardItem) -> some View {
        ClipboardRow(
            item: item,
            onSelect: { select(item) },
            onToggleFavorite: { toggleFavorite(item) },
            onTogglePin: { togglePin(item) },
            onDelete: { delete(item) }
        )
        .listRowBackground(Color.clear)
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
    @EnvironmentObject private var theme: ThemeStore
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
                .foregroundStyle(theme.text)
            Spacer()
            Button(action: onToggleFavorite) {
                Image(systemName: item.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(item.isFavorite ? .yellow : theme.text.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(isHovered ? theme.hover : Color.clear)
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
