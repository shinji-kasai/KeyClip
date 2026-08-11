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
/// panel instead of starting back on the user's configured default tab.
/// `AppDelegate.togglePanel()` calls `resetToDefault()` every time the panel
/// opens.
final class TabSelectionStore: ObservableObject {
    static let shared = TabSelectionStore()

    @Published var selectedTab: FeatureTab = .clipboard

    /// Bumped every time the panel opens (`resetToDefault()`), so a
    /// list/grid-based tab can reset its scroll position back to the top —
    /// needed because the panel's content view is never recreated, only
    /// hidden/shown, so a `List`/`ScrollView`'s scroll offset otherwise
    /// survives a hide/reopen cycle exactly like `selectedTab` used to
    /// before `resetToDefault()` existed. Tabs observe this via
    /// `.onChange(of: tabSelection.openGeneration)` and call
    /// `ScrollViewReader.scrollTo(_:anchor:.top)`.
    @Published private(set) var openGeneration = 0

    private init() {}

    func resetToDefault() {
        selectedTab = Self.currentDefaultTab()
        openGeneration += 1
    }

    /// Reads `SettingsView`'s Default Tab picker straight from
    /// `UserDefaults` (this isn't a SwiftUI view, so no `@AppStorage`) and
    /// falls back to the first still-visible tab if the configured default
    /// has since been hidden in Settings → Visible Tabs.
    private static func currentDefaultTab() -> FeatureTab {
        let configured = UserDefaults.standard.string(forKey: FeatureTab.defaultTabDefaultsKey)
            .flatMap(FeatureTab.init(rawValue:)) ?? .clipboard
        if FeatureTab.isVisible(configured) { return configured }
        return FeatureTab.allCases.first(where: { FeatureTab.isVisible($0) }) ?? .settings
    }
}
