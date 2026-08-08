//
//  SymbolsView.swift
//  KeyClip
//

import SwiftUI
import SwiftData

struct SymbolsView: View {
    @EnvironmentObject private var theme: ThemeStore
    @Environment(\.copyToClipboard) private var copyToClipboard
    @Environment(\.modelContext) private var modelContext
    @Query private var usageRecords: [SymbolUsage]
    @State private var searchText = ""
    @State private var expandedCategories: Set<SymbolCategory> = Set(SymbolCategory.allCases)

    private var usageByCharacter: [String: SymbolUsage] {
        Dictionary(uniqueKeysWithValues: usageRecords.map { ($0.character, $0) })
    }

    private var favorites: [SymbolEntry] {
        let favoriteCharacters = Set(usageRecords.filter { $0.isFavorite }.map { $0.character })
        guard !favoriteCharacters.isEmpty else { return [] }
        return SymbolCategory.allSymbols.filter { favoriteCharacters.contains($0.character) }
    }

    /// Ranked by frequency of use, not just recency — a symbol used
    /// repeatedly stays near the top even if something else was used more
    /// recently once.
    private var recentlyUsed: [SymbolEntry] {
        let ranked = usageRecords
            .filter { $0.useCount > 0 }
            .sorted {
                $0.useCount != $1.useCount ? $0.useCount > $1.useCount : $0.lastUsedAt > $1.lastUsedAt
            }
            .prefix(16)
        let byCharacter = Dictionary(SymbolCategory.allSymbols.map { ($0.character, $0) }, uniquingKeysWith: { first, _ in first })
        return ranked.compactMap { byCharacter[$0.character] }
    }

    private func symbols(in category: SymbolCategory) -> [SymbolEntry] {
        guard !searchText.isEmpty else { return category.symbols }
        return category.symbols.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) || $0.character == searchText
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if searchText.isEmpty && !favorites.isEmpty {
                        labeledSection("Favorites", items: favorites)
                    }
                    if searchText.isEmpty && !recentlyUsed.isEmpty {
                        labeledSection("Recently Used", items: recentlyUsed)
                        Divider()
                    }
                    ForEach(SymbolCategory.allCases) { category in
                        let items = symbols(in: category)
                        if !items.isEmpty {
                            categorySection(category, items: items)
                        }
                    }
                }
                .padding(12)
            }
        }
        .background(theme.background)
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search symbols...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(8)
    }

    private func labeledSection(_ title: String, items: [SymbolEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(theme.text.opacity(0.6))
            grid(for: items)
        }
    }

    private func categorySection(_ category: SymbolCategory, items: [SymbolEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                toggleExpanded(category)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isExpanded(category) ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(theme.text.opacity(0.6))
                    Text(category.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.text.opacity(0.6))
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded(category) {
                grid(for: items)
            }
        }
    }

    private func isExpanded(_ category: SymbolCategory) -> Bool {
        // While searching, always show matches regardless of collapsed state.
        !searchText.isEmpty || expandedCategories.contains(category)
    }

    private func toggleExpanded(_ category: SymbolCategory) {
        if expandedCategories.contains(category) {
            expandedCategories.remove(category)
        } else {
            expandedCategories.insert(category)
        }
    }

    private func grid(for items: [SymbolEntry]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 36), spacing: 6)], spacing: 6) {
            ForEach(items) { entry in
                SymbolCell(
                    entry: entry,
                    isFavorite: usageByCharacter[entry.character]?.isFavorite ?? false,
                    onSelect: { select(entry) },
                    onToggleFavorite: { toggleFavorite(entry) }
                )
            }
        }
    }

    private func select(_ entry: SymbolEntry) {
        let usage = usageRecord(for: entry.character)
        usage.useCount += 1
        usage.lastUsedAt = .now
        try? modelContext.save()
        copyToClipboard(entry.character)
    }

    private func toggleFavorite(_ entry: SymbolEntry) {
        let usage = usageRecord(for: entry.character)
        usage.isFavorite.toggle()
        try? modelContext.save()
    }

    private func usageRecord(for character: String) -> SymbolUsage {
        if let existing = usageByCharacter[character] { return existing }
        let created = SymbolUsage(character: character)
        modelContext.insert(created)
        return created
    }
}

private struct SymbolCell: View {
    @EnvironmentObject private var theme: ThemeStore
    let entry: SymbolEntry
    let isFavorite: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void
    @State private var isHovered = false

    var body: some View {
        Text(entry.character)
            .font(.system(size: 18))
            .foregroundStyle(theme.text)
            .frame(width: 36, height: 36)
            .background(isHovered ? theme.hover : Color.clear)
            .cornerRadius(6)
            .overlay(alignment: .topTrailing) {
                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(.yellow)
                        .padding(2)
                }
            }
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .onTapGesture { onSelect() }
            .contextMenu {
                Button(isFavorite ? "Remove Favorite" : "Add Favorite", action: onToggleFavorite)
            }
            .help(entry.name)
    }
}
