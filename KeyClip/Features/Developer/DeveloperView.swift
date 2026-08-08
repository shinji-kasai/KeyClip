//
//  DeveloperView.swift
//  KeyClip
//

import SwiftUI

struct DeveloperView: View {
    @Environment(\.copyToClipboard) private var copyToClipboard
    @State private var expandedCategories: Set<DeveloperCategory> = Set(DeveloperCategory.allCases)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(DeveloperCategory.allCases) { category in
                    categorySection(category)
                }
            }
            .padding(12)
        }
    }

    private func categorySection(_ category: DeveloperCategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                toggleExpanded(category)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: expandedCategories.contains(category) ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(category.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expandedCategories.contains(category) {
                FlowLayout(spacing: 6) {
                    ForEach(category.tokens) { token in
                        TokenChip(token: token, onSelect: { copyToClipboard(token.text) })
                    }
                }
            }
        }
    }

    private func toggleExpanded(_ category: DeveloperCategory) {
        if expandedCategories.contains(category) {
            expandedCategories.remove(category)
        } else {
            expandedCategories.insert(category)
        }
    }
}

private struct TokenChip: View {
    let token: DeveloperToken
    let onSelect: () -> Void
    @State private var isHovered = false

    var body: some View {
        Text(token.text)
            .font(.system(.body, design: .monospaced))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isHovered ? Color.secondary.opacity(0.18) : Color.secondary.opacity(0.08))
            .cornerRadius(6)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .onTapGesture { onSelect() }
    }
}
