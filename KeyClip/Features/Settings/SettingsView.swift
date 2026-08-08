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
    @AppStorage(FeatureTab.developer.visibilityDefaultsKey) private var developerEnabled = true
    @AppStorage(FeatureTab.keyboard.visibilityDefaultsKey) private var keyboardEnabled = true

    @AppStorage(HotKeyBinding.openPanelDefaultsKey) private var openPanelBinding = HotKeyBinding.defaultOpenPanel

    @AppStorage(WidthConversionCategory.numbers.defaultsKey) private var numbersMode: WidthMode = .halfWidth
    @AppStorage(WidthConversionCategory.katakana.defaultsKey) private var katakanaMode: WidthMode = .halfWidth
    @AppStorage(WidthConversionCategory.alphabet.defaultsKey) private var alphabetMode: WidthMode = .halfWidth
    @AppStorage(WidthConversionCategory.symbols.defaultsKey) private var symbolsMode: WidthMode = .halfWidth
    @AppStorage(WidthConversionCategory.space.defaultsKey) private var spaceMode: WidthMode = .halfWidth

    @State private var isAccessibilityTrusted = AccessibilityPermission.isTrusted(prompt: false)
    @State private var isInputMonitoringTrusted = InputMonitoringPermission.isTrusted

    var body: some View {
        Form {
            Section("Visible Tabs") {
                Toggle("Clipboard", isOn: $clipboardEnabled)
                Toggle("Snippets", isOn: $snippetsEnabled)
                Toggle("Symbols", isOn: $symbolsEnabled)
                Toggle("Developer", isOn: $developerEnabled)
                Toggle("Keyboard", isOn: $keyboardEnabled)
            }

            Section("Shortcuts") {
                HStack {
                    Text("Open Panel")
                    Spacer()
                    HotKeyRecorderView(binding: $openPanelBinding)
                        .frame(width: 140, height: 28)
                }
            }

            Section("Input Conversion") {
                widthPicker("Numbers", selection: $numbersMode)
                widthPicker("Katakana", selection: $katakanaMode)
                widthPicker("Alphabet", selection: $alphabetMode)
                widthPicker("Symbols", selection: $symbolsMode)
                widthPicker("Space", selection: $spaceMode)
            }

            Section("Permissions") {
                HStack {
                    Image(systemName: isAccessibilityTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(isAccessibilityTrusted ? .green : .orange)
                    Text(isAccessibilityTrusted ? "Accessibility access granted" : "Accessibility access required to insert text")
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
        .onAppear {
            isAccessibilityTrusted = AccessibilityPermission.isTrusted(prompt: false)
            isInputMonitoringTrusted = InputMonitoringPermission.isTrusted
        }
    }

    private func widthPicker(_ title: String, selection: Binding<WidthMode>) -> some View {
        Picker(title, selection: selection) {
            ForEach(WidthMode.allCases) { mode in
                Text(mode.label).tag(mode)
            }
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
