//
//  RootTabView.swift
//  KeyClip
//

import SwiftUI

struct RootTabView: View {
    @AppStorage(FeatureTab.clipboard.visibilityDefaultsKey) private var clipboardEnabled = true
    @AppStorage(FeatureTab.snippets.visibilityDefaultsKey) private var snippetsEnabled = true
    @AppStorage(FeatureTab.symbols.visibilityDefaultsKey) private var symbolsEnabled = true
    @AppStorage(FeatureTab.developer.visibilityDefaultsKey) private var developerEnabled = true
    @AppStorage(FeatureTab.keyboard.visibilityDefaultsKey) private var keyboardEnabled = true

    @State private var selectedTab: FeatureTab = .clipboard

    private var visibleTabs: [FeatureTab] {
        FeatureTab.allCases.filter(isVisible)
    }

    private func isVisible(_ tab: FeatureTab) -> Bool {
        switch tab {
        case .clipboard: return clipboardEnabled
        case .snippets: return snippetsEnabled
        case .symbols: return symbolsEnabled
        case .developer: return developerEnabled
        case .keyboard: return keyboardEnabled
        case .settings: return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            tabBar
            Divider()
            content
        }
        .frame(minWidth: 480, minHeight: 600)
        .onChange(of: visibleTabs) { _, newValue in
            if !newValue.contains(selectedTab) {
                selectedTab = newValue.first ?? .settings
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("KeyClip")
                .font(.headline)
            Text(appVersion)
                .font(.caption)
                .foregroundStyle(.secondary)
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
                TabBarButton(tab: tab, isSelected: selectedTab == tab) {
                    selectedTab = tab
                }
            }
        }
        .padding(8)
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .clipboard: ClipboardView()
        case .settings: SettingsView()
        case .snippets: SnippetsView()
        case .symbols: SymbolsView()
        case .developer: DeveloperView()
        case .keyboard: KeyboardView()
        }
    }
}

private struct TabBarButton: View {
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
        if isSelected { return Color.accentColor.opacity(0.15) }
        if isHovered { return Color.secondary.opacity(0.12) }
        return .clear
    }
}
