//
//  SettingsView.swift
//  KeyClip
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(FeatureTab.clipboard.visibilityDefaultsKey) private var clipboardEnabled = true
    @AppStorage(FeatureTab.snippets.visibilityDefaultsKey) private var snippetsEnabled = true
    @AppStorage(FeatureTab.symbols.visibilityDefaultsKey) private var symbolsEnabled = true
    @AppStorage(FeatureTab.developer.visibilityDefaultsKey) private var developerEnabled = true
    @AppStorage(FeatureTab.keyboard.visibilityDefaultsKey) private var keyboardEnabled = true

    @AppStorage(HotKeyBinding.openPanelDefaultsKey) private var openPanelBinding = HotKeyBinding.defaultOpenPanel

    @State private var isAccessibilityTrusted = AccessibilityPermission.isTrusted(prompt: false)

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
            }
        }
        .formStyle(.grouped)
        .onChange(of: openPanelBinding) { _, newValue in
            HotKeyManager.shared.updateBinding(newValue)
        }
        .onAppear {
            isAccessibilityTrusted = AccessibilityPermission.isTrusted(prompt: false)
        }
    }
}
