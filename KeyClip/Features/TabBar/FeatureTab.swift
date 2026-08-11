//
//  FeatureTab.swift
//  KeyClip
//

import Foundation

enum FeatureTab: String, CaseIterable, Identifiable {
    case clipboard, snippets, symbols, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clipboard: return "Clip"
        case .snippets: return "Snippets"
        case .symbols: return "Symbols"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .clipboard: return "doc.on.clipboard"
        case .snippets: return "text.badge.plus"
        case .symbols: return "textformat.abc"
        case .settings: return "gearshape"
        }
    }

    /// Settings is the sole tab that can never be hidden, since it's the only
    /// way to re-enable everything else.
    var isAlwaysVisible: Bool { self == .settings }

    var visibilityDefaultsKey: String { "tabEnabled.\(rawValue)" }

    /// UserDefaults key backing the user-configurable "which tab opens the
    /// panel" setting (`SettingsView`'s Default Tab picker,
    /// `TabSelectionStore.resetToDefault()`).
    static let defaultTabDefaultsKey = "defaultTab"

    /// Live visibility check against `UserDefaults` directly, for consumers
    /// (like `TabSelectionStore`) that aren't SwiftUI views and so can't read
    /// the `tabEnabled.*` flags via `@AppStorage` the way `RootTabView` and
    /// `SettingsView` do.
    static func isVisible(_ tab: FeatureTab, defaults: UserDefaults = .standard) -> Bool {
        if tab.isAlwaysVisible { return true }
        return defaults.object(forKey: tab.visibilityDefaultsKey) as? Bool ?? true
    }
}
