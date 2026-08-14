//
//  CollapsibleSearchField.swift
//  KeyClip
//

import SwiftUI

/// A search `TextField` shown by default, with a magnifying-glass button
/// that collapses it (clicking it again reopens) — clearing `text` on
/// collapse too, so a hidden field never leaves a stale filter silently
/// active. Shared by Clipboard/Snippets/Symbols rather than each rolling
/// its own near-identical search row.
struct CollapsibleSearchField: View {
    @EnvironmentObject private var theme: ThemeStore
    @Binding var text: String
    var placeholder: String = "Search..."
    @State private var isVisible = true
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Button(action: toggle) {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.text.opacity(0.45))

            if isVisible {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .foregroundStyle(theme.text)
                    .focused($isFocused)
                    .onExitCommand { close() }
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(theme.text.opacity(0.5))
                }
            }
        }
        .frame(maxWidth: isVisible ? .infinity : nil, alignment: .leading)
        .onAppear {
            // A non-empty search re-opened from a previous session (state
            // persists as long as this view stays alive) should still show
            // its field rather than hiding an active filter.
            if !text.isEmpty { isVisible = true }
        }
        .onChange(of: text) { _, newValue in
            // Covers `.typeToSearch`: a keystroke captured elsewhere in the
            // tab appends straight into this binding, so reveal (and take
            // over) the field the moment that makes it non-empty, same as
            // clicking the magnifying glass would.
            if !newValue.isEmpty, !isVisible {
                isVisible = true
                isFocused = true
            }
        }
    }

    private func toggle() {
        if isVisible {
            close()
        } else {
            isVisible = true
            isFocused = true
        }
    }

    private func close() {
        isVisible = false
        text = ""
    }
}
