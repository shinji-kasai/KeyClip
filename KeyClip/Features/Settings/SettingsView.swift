//
//  SettingsView.swift
//  KeyClip
//

import SwiftUI
import SwiftData

struct SettingsView: View {
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
            Section("Visible Tabs") {
                Toggle("Clipboard", isOn: $clipboardEnabled)
                Toggle("Snippets", isOn: $snippetsEnabled)
                Toggle("Symbols", isOn: $symbolsEnabled)
            }

            Section("Shortcuts") {
                HStack {
                    Text("Open Panel")
                    Spacer()
                    HotKeyRecorderView(binding: $openPanelBinding)
                        .frame(width: 140, height: 28)
                }
                Toggle("Double-⌘ to Open Panel", isOn: $doubleCommandTapEnabled)
            }

            Section("Permissions") {
                HStack {
                    Image(systemName: isAccessibilityTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(isAccessibilityTrusted ? .green : .orange)
                    Text(isAccessibilityTrusted ? "Accessibility access granted" : "Accessibility access required to insert text and for Double-⌘ to open the panel")
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
                    Spacer()
                    if !isInputMonitoringTrusted {
                        Button("Grant Access") {
                            requestInputMonitoringAccess()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
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

    private func requestInputMonitoringAccess() {
        if InputMonitoringPermission.requestAccess() {
            isInputMonitoringTrusted = true
            SnippetExpansionEngine.shared.start(modelContext: modelContext)
        } else {
            InputMonitoringPermission.openSystemSettings()
        }
    }
}
