//
//  SettingsView.swift
//  KeyClip
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var theme: ThemeStore
    @Environment(\.modelContext) private var modelContext
    @AppStorage(FeatureTab.clipboard.visibilityDefaultsKey) private var clipboardEnabled = true
    @AppStorage(FeatureTab.snippets.visibilityDefaultsKey) private var snippetsEnabled = true
    @AppStorage(FeatureTab.symbols.visibilityDefaultsKey) private var symbolsEnabled = true
    @AppStorage(NowPlayingBar.enabledDefaultsKey) private var nowPlayingEnabled = true

    @AppStorage(FeatureTab.defaultTabDefaultsKey) private var defaultTab: FeatureTab = .clipboard
    @AppStorage(TextInjector.autoPasteDefaultsKey) private var autoPasteEnabled = true

    @AppStorage(HotKeyBinding.openPanelDefaultsKey) private var openPanelBinding = HotKeyBinding.defaultOpenPanel
    @AppStorage(DoubleCommandTapDetector.enabledDefaultsKey) private var doubleCommandTapEnabled = true

    @State private var isAccessibilityTrusted = AccessibilityPermission.isTrusted(prompt: false)
    @State private var isInputMonitoringTrusted = InputMonitoringPermission.isTrusted
    @State private var updateCheckResult: UpdateCheckResult?
    @State private var isCheckingForUpdate = false
    @State private var isShowingClearHistoryConfirmation = false

    var body: some View {
        Form {
            Section {
                themedToggle("Clipboard", isOn: $clipboardEnabled)
                themedToggle("Snippets", isOn: $snippetsEnabled)
                themedToggle("Symbols", isOn: $symbolsEnabled)
                themedToggle("Now Playing", isOn: $nowPlayingEnabled)
            } header: {
                sectionHeader("Visible Tabs")
            }

            Section {
                Picker("Default Tab", selection: $defaultTab) {
                    ForEach(defaultTabOptions) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                themedToggle("Auto-Paste on Select", isOn: $autoPasteEnabled)
            } header: {
                sectionHeader("Startup & Behavior")
            } footer: {
                Text("Default Tab is what the panel opens to. Auto-Paste immediately pastes what you click into the app you were using — turn it off to only copy it to the clipboard instead.")
                    .foregroundStyle(theme.text.opacity(0.6))
            }

            Section {
                HStack {
                    Text("Open Panel").foregroundStyle(theme.text)
                    Spacer()
                    HotKeyRecorderView(binding: $openPanelBinding)
                        .frame(width: 140, height: 28)
                }
                themedToggle("Double-⌘ to Open Panel", isOn: $doubleCommandTapEnabled)
            } header: {
                sectionHeader("Shortcuts")
            }

            Section {
                // The Theme `Picker` is a native control that draws its own
                // box chrome regardless of the surrounding background, so it
                // deliberately does NOT get `.foregroundStyle(theme.text)`
                // here — forcing that on it fought its own chrome and was
                // reported as hard to read. Let macOS handle its label
                // color. `ColorSwatchPicker`'s swatches are custom-drawn,
                // not native chrome, so they don't have that problem — see
                // its doc comment.
                Picker("Theme", selection: presetBinding) {
                    ForEach(ThemePresets.all) { preset in
                        Text(preset.name).tag(preset.id)
                    }
                    Text("Custom").tag(ThemePresets.customID)
                }
                ColorSwatchPicker(title: "Background", selection: Binding(
                    get: { theme.background },
                    set: { theme.setBackground($0) }
                ))
                ColorSwatchPicker(title: "Text", selection: Binding(
                    get: { theme.text },
                    set: { theme.setText($0) }
                ))
                ColorSwatchPicker(title: "Hover Highlight", selection: Binding(
                    get: { theme.hover },
                    set: { theme.setHover($0) }
                ))
                ColorSwatchPicker(title: "Selected Highlight", selection: Binding(
                    get: { theme.selected },
                    set: { theme.setSelected($0) }
                ))
                ColorSwatchPicker(title: "Selected Text", selection: Binding(
                    get: { theme.selectedText },
                    set: { theme.setSelectedText($0) }
                ))
            } header: {
                sectionHeader("Appearance")
            }

            Section {
                HStack {
                    Image(systemName: isAccessibilityTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(isAccessibilityTrusted ? .green : .orange)
                    Text(isAccessibilityTrusted ? "Accessibility access granted" : "Accessibility access required to insert text and for Double-⌘ to open the panel")
                        .foregroundStyle(theme.text)
                    Spacer()
                    if !isAccessibilityTrusted {
                        Button("Open System Settings") {
                            AccessibilityPermission.openSystemSettings()
                        }
                    }
                }
                HStack {
                    Image(systemName: isInputMonitoringTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(isInputMonitoringTrusted ? .green : .orange)
                    Text(isInputMonitoringTrusted ? "Input Monitoring access granted" : "Input Monitoring access required for snippet typing-triggers")
                        .foregroundStyle(theme.text)
                    Spacer()
                    if !isInputMonitoringTrusted {
                        Button("Grant Access") {
                            requestInputMonitoringAccess()
                        }
                    }
                }
            } header: {
                sectionHeader("Permissions")
            }

            Section {
                HStack {
                    Text("Version \(UpdateChecker.currentVersion())")
                        .foregroundStyle(theme.text)
                    Spacer()
                    updateStatusView
                }
            } header: {
                sectionHeader("Updates")
            }

            Section {
                HStack {
                    Text("Clear Clipboard History").foregroundStyle(theme.text)
                    Spacer()
                    Button("Clear…", role: .destructive) {
                        isShowingClearHistoryConfirmation = true
                    }
                }
            } header: {
                sectionHeader("Data")
            } footer: {
                Text("Removes clipboard history. Pinned and favorited items are kept.")
                    .foregroundStyle(theme.text.opacity(0.6))
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .confirmationDialog(
            "Clear clipboard history?",
            isPresented: $isShowingClearHistoryConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear History", role: .destructive) {
                clearClipboardHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Pinned and favorited items are kept. This can't be undone.")
        }
        .onChange(of: openPanelBinding) { _, newValue in
            HotKeyManager.shared.updateBinding(newValue)
        }
        .onChange(of: doubleCommandTapEnabled) { _, newValue in
            if newValue {
                DoubleCommandTapDetector.shared.start()
            } else {
                DoubleCommandTapDetector.shared.stop()
            }
        }
        .onChange(of: clipboardEnabled) { _, _ in resetDefaultTabIfHidden() }
        .onChange(of: snippetsEnabled) { _, _ in resetDefaultTabIfHidden() }
        .onChange(of: symbolsEnabled) { _, _ in resetDefaultTabIfHidden() }
        .onAppear {
            isAccessibilityTrusted = AccessibilityPermission.isTrusted(prompt: false)
            isInputMonitoringTrusted = InputMonitoringPermission.isTrusted
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title).foregroundStyle(theme.text.opacity(0.6))
    }

    private func themedToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title).foregroundStyle(theme.text)
        }
    }

    /// Tabs the Default Tab picker offers — mirrors `RootTabView`'s own
    /// visibility filter so the picker can never point at a hidden tab.
    private var defaultTabOptions: [FeatureTab] {
        FeatureTab.allCases.filter(isTabVisible)
    }

    private func isTabVisible(_ tab: FeatureTab) -> Bool {
        switch tab {
        case .clipboard: return clipboardEnabled
        case .snippets: return snippetsEnabled
        case .symbols: return symbolsEnabled
        case .settings: return true
        }
    }

    /// If a tab gets hidden in Visible Tabs while it's the configured
    /// default, fall back rather than leaving Default Tab pointed at
    /// something the picker no longer lists.
    private func resetDefaultTabIfHidden() {
        if !isTabVisible(defaultTab) {
            defaultTab = defaultTabOptions.first ?? .settings
        }
    }

    private var presetBinding: Binding<String> {
        Binding(
            get: { theme.presetID },
            set: { newID in
                if newID == ThemePresets.customID {
                    theme.selectCustom()
                } else if let preset = ThemePresets.all.first(where: { $0.id == newID }) {
                    theme.apply(preset)
                }
            }
        )
    }

    @ViewBuilder
    private var updateStatusView: some View {
        if isCheckingForUpdate {
            ProgressView()
                .controlSize(.small)
        } else {
            switch updateCheckResult {
            case .none:
                Button("Check for Updates") { checkForUpdate() }
            case .upToDate:
                Text("Up to date").foregroundStyle(theme.text.opacity(0.6))
                Button("Check Again") { checkForUpdate() }
            case .updateAvailable(let info):
                Text("v\(info.version) available").foregroundStyle(.orange)
                Button("View Release") { NSWorkspace.shared.open(info.url) }
            case .failed:
                Text("Check failed").foregroundStyle(.red)
                Button("Retry") { checkForUpdate() }
            }
        }
    }

    private func checkForUpdate() {
        isCheckingForUpdate = true
        Task { @MainActor in
            updateCheckResult = await UpdateChecker.checkForUpdate()
            isCheckingForUpdate = false
        }
    }

    /// Deletes all non-pinned, non-favorite clipboard history — mirrors
    /// `ClipboardMonitor.pruneHistoryIfNeeded`'s convention of never
    /// touching pinned/favorite rows.
    private func clearClipboardHistory() {
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { !$0.isPinned && !$0.isFavorite }
        )
        guard let items = try? modelContext.fetch(descriptor) else { return }
        for item in items {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }

    private func requestInputMonitoringAccess() {
        if InputMonitoringPermission.requestAccess() {
            isInputMonitoringTrusted = true
            SnippetExpansionEngine.shared.start(modelContext: modelContext)
        } else {
            InputMonitoringPermission.openSystemSettings()
        }
    }
}
