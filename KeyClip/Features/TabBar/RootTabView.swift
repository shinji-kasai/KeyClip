//
//  RootTabView.swift
//  KeyClip
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var theme: ThemeStore
    @AppStorage(FeatureTab.clipboard.visibilityDefaultsKey) private var clipboardEnabled = true
    @AppStorage(FeatureTab.snippets.visibilityDefaultsKey) private var snippetsEnabled = true
    @AppStorage(FeatureTab.symbols.visibilityDefaultsKey) private var symbolsEnabled = true

    @EnvironmentObject private var tabSelection: TabSelectionStore

    private var visibleTabs: [FeatureTab] {
        FeatureTab.allCases.filter(isVisible)
    }

    private func isVisible(_ tab: FeatureTab) -> Bool {
        switch tab {
        case .clipboard: return clipboardEnabled
        case .snippets: return snippetsEnabled
        case .symbols: return symbolsEnabled
        case .settings: return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            NowPlayingBar()
            tabBar
            Divider()
            content
        }
        .frame(minWidth: 480, minHeight: 600)
        .background(theme.background)
        .preferredColorScheme(theme.preferredColorScheme)
        .onChange(of: visibleTabs) { _, newValue in
            if !newValue.contains(tabSelection.selectedTab) {
                tabSelection.selectedTab = newValue.first ?? .settings
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("KeyClip")
                .font(.headline)
                .foregroundStyle(theme.text)
            Text(appVersion)
                .font(.caption)
                .foregroundStyle(theme.text.opacity(0.6))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(version)"
    }

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(visibleTabs) { tab in
                TabBarButton(tab: tab, isSelected: tabSelection.selectedTab == tab) {
                    tabSelection.selectedTab = tab
                }
            }
        }
        .padding(8)
    }

    @ViewBuilder
    private var content: some View {
        switch tabSelection.selectedTab {
        case .clipboard: ClipboardView()
        case .settings: SettingsView()
        case .snippets: SnippetsView()
        case .symbols: SymbolsView()
        }
    }
}

private struct TabBarButton: View {
    @EnvironmentObject private var theme: ThemeStore
    let tab: FeatureTab
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                Text(tab.title)
                    .font(.callout)
            }
            .foregroundStyle(isSelected ? theme.selectedText : theme.text)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var backgroundColor: Color {
        if isSelected { return theme.selected }
        if isHovered { return theme.hover }
        return .clear
    }
}
