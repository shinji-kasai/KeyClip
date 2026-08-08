//
//  FeatureTab.swift
//  KeyClip
//

import Foundation

enum FeatureTab: String, CaseIterable, Identifiable {
    case clipboard, snippets, symbols, developer, keyboard, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clipboard: return "Clip"
        case .snippets: return "Snippets"
        case .symbols: return "Symbols"
        case .developer: return "Dev"
        case .keyboard: return "Keyboard"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .clipboard: return "doc.on.clipboard"
        case .snippets: return "text.badge.plus"
        case .symbols: return "textformat.abc"
        case .developer: return "chevron.left.forwardslash.chevron.right"
        case .keyboard: return "keyboard"
        case .settings: return "gearshape"
        }
    }

    /// Settings is the sole tab that can never be hidden, since it's the only
    /// way to re-enable everything else.
    var isAlwaysVisible: Bool { self == .settings }

    var visibilityDefaultsKey: String { "tabEnabled.\(rawValue)" }
}
