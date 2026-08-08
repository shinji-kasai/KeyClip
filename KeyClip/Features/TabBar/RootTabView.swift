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
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                        Text(tab.title)
                            .font(.callout)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .clipboard: ClipboardView()
        case .settings: SettingsView()
        case .snippets: PlaceholderView(tab: .snippets)
        case .symbols: PlaceholderView(tab: .symbols)
        case .developer: PlaceholderView(tab: .developer)
        case .keyboard: PlaceholderView(tab: .keyboard)
        }
    }
}
