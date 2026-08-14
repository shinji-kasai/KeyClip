//
//  ThemedMenuPicker.swift
//  KeyClip
//

import SwiftUI

/// A `Picker` replacement built from `Menu` rather than native `Picker`
/// chrome, so the always-visible button face can be exactly `theme.text` —
/// a plain `Picker` renders its own native box+text regardless of
/// `.foregroundStyle` applied to the picker itself (tried before, reported
/// hard to read — see `SettingsView`'s Theme `Picker` history). Menu's
/// label is fully custom SwiftUI content rather than opaque native
/// rendering, so it styles reliably. The dropdown list itself, once opened,
/// is still native `NSMenu` styling (system light/dark) — only the button
/// face is themed, which is the part visible without interacting with it.
struct ThemedMenuPicker<Value: Hashable>: View {
    @EnvironmentObject private var theme: ThemeStore
    @Binding var selection: Value
    let options: [(label: String, value: Value)]

    var body: some View {
        Menu {
            ForEach(options, id: \.value) { option in
                Button(option.label) { selection = option.value }
            }
        } label: {
            HStack(spacing: 4) {
                Text(options.first { $0.value == selection }?.label ?? "")
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(theme.text)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
