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

    @AppStorage(HotKeyBinding.openPanelDefaultsKey) private var openPanelBinding = HotKeyBinding.defaultOpenPanel
    @AppStorage(DoubleCommandTapDetector.enabledDefaultsKey) private var doubleCommandTapEnabled = true

    @State private var isAccessibilityTrusted = AccessibilityPermission.isTrusted(prompt: false)
    @State private var isInputMonitoringTrusted = InputMonitoringPermission.isTrusted

    var body: some View {
        Form {
            Section {
                themedToggle("Clipboard", isOn: $clipboardEnabled)
                themedToggle("Snippets", isOn: $snippetsEnabled)
                themedToggle("Symbols", isOn: $symbolsEnabled)
            } header: {
                sectionHeader("Visible Tabs")
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
                Picker("Theme", selection: presetBinding) {
                    ForEach(ThemePresets.all) { preset in
                        Text(preset.name).tag(preset.id)
                    }
                    Text("Custom").tag(ThemePresets.customID)
                }
                .foregroundStyle(theme.text)
                ColorPicker("Background", selection: Binding(
                    get: { theme.background },
                    set: { theme.setBackground($0) }
                ))
                .foregroundStyle(theme.text)
                ColorPicker("Text", selection: Binding(
                    get: { theme.text },
                    set: { theme.setText($0) }
                ))
                .foregroundStyle(theme.text)
                ColorPicker("Hover Highlight", selection: Binding(
                    get: { theme.hover },
                    set: { theme.setHover($0) }
                ))
                .foregroundStyle(theme.text)
                ColorPicker("Selected Highlight", selection: Binding(
                    get: { theme.selected },
                    set: { theme.setSelected($0) }
                ))
                .foregroundStyle(theme.text)
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
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(theme.background)
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

    private var presetBinding: Binding<String> {
        Binding(
            get: { theme.presetID },
            set: { newID in
                guard let preset = ThemePresets.all.first(where: { $0.id == newID }) else { return }
                theme.apply(preset)
            }
        )
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
