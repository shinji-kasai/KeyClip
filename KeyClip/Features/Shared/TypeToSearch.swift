//
//  TypeToSearch.swift
//  KeyClip
//

import SwiftUI

/// Lets the user start filtering just by typing while the list has focus,
/// instead of first clicking the magnifying glass — the same "type-ahead"
/// convention Finder/Mail use. Attach to the list/scroll container
/// alongside a `CollapsibleSearchField` bound to the same `text`: the first
/// keystroke lands here and appends into `text`, which
/// `CollapsibleSearchField`'s own `onChange(of: text)` then notices and
/// reveals/focuses itself for — after that, focus has moved to the actual
/// text field, so further typing is handled natively there, not here.
private struct TypeToSearchModifier: ViewModifier {
    @Binding var text: String
    @FocusState private var isContainerFocused: Bool

    func body(content: Content) -> some View {
        content
            .focusable()
            .focusEffectDisabled()
            .focused($isContainerFocused)
            .onKeyPress(characters: .alphanumerics.union(.whitespaces).union(CharacterSet(charactersIn: "-_.,!?'\""))) { keyPress in
                text.append(keyPress.characters)
                return .handled
            }
            .task {
                isContainerFocused = true
            }
            .onChange(of: text) { _, newValue in
                // Once the field closes (or is cleared) and drops its own
                // focus, nothing is left focused to catch the next
                // keystroke — reclaim it here so typing works again.
                if newValue.isEmpty {
                    isContainerFocused = true
                }
            }
    }
}

extension View {
    func typeToSearch(text: Binding<String>) -> some View {
        modifier(TypeToSearchModifier(text: text))
    }
}
