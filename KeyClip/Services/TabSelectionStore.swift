//
//  TabSelectionStore.swift
//  KeyClip
//

import SwiftUI
import Combine

/// Live selected-tab state, shared app-wide the same way `ThemeStore` is (a
/// singleton `ObservableObject` injected once via `.environmentObject`).
/// `RootTabView`'s own `@State` would otherwise persist for the app's
/// entire run: the panel's SwiftUI content view is built once in
/// `AppDelegate.setupPanel()` and only hidden/shown afterward
/// (`orderOut`/`makeKeyAndOrderFront`), never recreated — so whichever tab
/// you last clicked would still be showing the next time you summon the
/// panel instead of starting back on Clipboard. `AppDelegate.togglePanel()`
/// calls `resetToDefault()` every time the panel opens.
final class TabSelectionStore: ObservableObject {
    static let shared = TabSelectionStore()
    static let defaultTab: FeatureTab = .clipboard

    @Published var selectedTab: FeatureTab = defaultTab

    private init() {}

    func resetToDefault() {
        selectedTab = Self.defaultTab
    }
}
