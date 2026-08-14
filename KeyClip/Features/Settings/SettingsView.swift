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
    @State private var isInstallingUpdate = false
    @State private var installUpdateError: String?
    @State private var isShowingClearHistoryConfirmation = false
    @State private var isShowingDuplicatePrompt = false
    @State private var duplicateName = ""
    @State private var isShowingRenamePrompt = false
    @State private var renameText = ""

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
                HStack {
                    Text("Default Tab").foregroundStyle(theme.text)
                    Spacer()
                    ThemedMenuPicker(
                        selection: $defaultTab,
                        options: defaultTabOptions.map { ($0.title, $0) }
                    )
                }
                themedToggle("Auto-Paste on Select", isOn: $autoPasteEnabled)
            } header: {
                sectionHeader("Startup & Behavior")
            } footer: {
                Text("Default Tab is what the panel opens to. Auto-Paste immediately pastes what you click into the app you were using — turn it off to only copy it to the clipboard instead.")
                    .foregroundStyle(theme.text.opacity(0.45))
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
                // `ThemedMenuPicker` (Menu-based, not native `Picker` box
                // chrome) so the visible button text can be exactly
                // `theme.text` — e.g. Matrix's green, not a generic native
                // white/gray. A plain `Picker` ignores `.foregroundStyle`
                // applied to it (tried before, reported hard to read).
                // `ColorSwatchPicker`'s swatches are similarly custom-drawn
                // rather than native chrome — see its doc comment.
                HStack {
                    Text("Theme").foregroundStyle(theme.text)
                    Spacer()
                    ThemedMenuPicker(
                        selection: themeSelectionBinding,
                        options: themeOptions
                    )
                }
                // Editing any swatch below while a built-in preset is active
                // forks a new custom theme automatically (see
                // `ThemeStore.ensureEditableTheme`) — these buttons cover
                // the deliberate paths: naming a duplicate up front, and
                // managing a custom theme once one's active.
                HStack(spacing: 14) {
                    Button("Duplicate…") {
                        duplicateName = "\(currentThemeName) Copy"
                        isShowingDuplicatePrompt = true
                    }
                    if let current = currentCustomTheme {
                        Button("Rename…") {
                            renameText = current.name
                            isShowingRenamePrompt = true
                        }
                        Button("Delete", role: .destructive) {
                            theme.delete(current.id)
                        }
                        if current.basedOn != nil {
                            Button("Reset") {
                                theme.reset(current.id)
                            }
                        }
                    }
                }
                .font(.caption)
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
                    .foregroundStyle(theme.text.opacity(0.45))
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
            } footer: {
                if let installUpdateError {
                    Text(installUpdateError).foregroundStyle(.red)
                }
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
        .alert("Duplicate Theme", isPresented: $isShowingDuplicatePrompt) {
            TextField("Name", text: $duplicateName)
            Button("Create") {
                theme.duplicateCurrentTheme(named: duplicateName.trimmingCharacters(in: .whitespaces).isEmpty ? "Custom" : duplicateName)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Creates a copy of the current theme's colors that you can edit freely, without changing the original.")
        }
        .alert("Rename Theme", isPresented: $isShowingRenamePrompt) {
            TextField("Name", text: $renameText)
            Button("Save") {
                if let current = currentCustomTheme {
                    theme.rename(current.id, to: renameText.trimmingCharacters(in: .whitespaces))
                }
            }
            Button("Cancel", role: .cancel) {}
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
        Text(title).foregroundStyle(theme.text.opacity(0.45))
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

    private var themeSelectionBinding: Binding<String> {
        Binding(
            get: { theme.selectedID },
            set: { newID in
                if let custom = theme.customThemes.first(where: { $0.id.uuidString == newID }) {
                    theme.select(custom)
                } else if let preset = ThemePresets.all.first(where: { $0.id == newID }) {
                    theme.apply(preset)
                }
            }
        )
    }

    private var themeOptions: [(label: String, value: String)] {
        ThemePresets.all.map { ($0.name, $0.id) } + theme.customThemes.map { ($0.name, $0.id.uuidString) }
    }

    private var currentCustomTheme: CustomTheme? {
        theme.customThemes.first { $0.id.uuidString == theme.selectedID }
    }

    private var currentThemeName: String {
        currentCustomTheme?.name ?? ThemePresets.all.first { $0.id == theme.selectedID }?.name ?? "Theme"
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
                Text("Up to date").foregroundStyle(theme.text.opacity(0.45))
                Button("Check Again") { checkForUpdate() }
            case .updateAvailable(let info):
                if isInstallingUpdate {
                    Text("Installing…").foregroundStyle(theme.text.opacity(0.45))
                    ProgressView().controlSize(.small)
                } else {
                    Text("v\(info.version) available").foregroundStyle(.orange)
                    Button("Update & Relaunch") { installUpdate(info) }
                        .disabled(info.assetURL == nil)
                    Button("View Release") { NSWorkspace.shared.open(info.url) }
                }
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

    /// Only returns on failure — `AppUpdateInstaller` quits the app itself
    /// once the swap-and-relaunch is safely queued, so there's no "success"
    /// state to show here.
    private func installUpdate(_ info: ReleaseInfo) {
        guard let assetURL = info.assetURL else { return }
        isInstallingUpdate = true
        installUpdateError = nil
        Task { @MainActor in
            do {
                try await AppUpdateInstaller.installAndRelaunch(from: assetURL)
            } catch {
                isInstallingUpdate = false
                installUpdateError = "Couldn't install the update automatically — try \"View Release\" instead."
            }
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
