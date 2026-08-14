//
//  HighlightedText.swift
//  KeyClip
//

import SwiftUI

/// Renders `text` with every case-insensitive occurrence of `query`
/// highlighted using `theme.selected` as a background — the same accent
/// already used for the selected tab, reused here rather than introducing a
/// new color token just for search. Falls back to plain text when `query`
/// is empty (the common case: not searching).
struct HighlightedText: View {
    @EnvironmentObject private var theme: ThemeStore
    let text: String
    let query: String

    init(_ text: String, matching query: String) {
        self.text = text
        self.query = query
    }

    var body: some View {
        Text(attributedString)
    }

    private var attributedString: AttributedString {
        var result = AttributedString(text)
        guard !query.isEmpty else { return result }

        var searchStart = result.startIndex
        while searchStart < result.endIndex,
              let range = result[searchStart...].range(of: query, options: .caseInsensitive) {
            result[range].backgroundColor = theme.selected
            searchStart = range.upperBound
        }
        return result
    }
}
