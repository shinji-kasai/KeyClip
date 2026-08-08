//
//  ThemeStore.swift
//  KeyClip
//

import SwiftUI
import AppKit
import Combine

struct ThemePreset: Identifiable, Hashable {
    let id: String
    let name: String
    let background: Color
    let text: Color
    let hover: Color
    let selected: Color
    /// Text/icon color used specifically for the tab bar's currently-selected
    /// tab. Kept independent of `text` because a `selected` highlight color
    /// close in hue/lightness to `text` (e.g. green highlight behind green
    /// text) reads as low-contrast even when `text` alone is perfectly
    /// legible against `background`.
    let selectedText: Color
}

enum ThemePresets {
    static let system = ThemePreset(
        id: "system", name: "System",
        background: Color(nsColor: .windowBackgroundColor),
        text: .primary,
        hover: Color.secondary.opacity(0.12),
        selected: Color.accentColor.opacity(0.15),
        selectedText: .primary
    )
    static let light = ThemePreset(
        id: "light", name: "Light",
        background: .white,
        text: .black,
        hover: Color.black.opacity(0.06),
        selected: Color.blue.opacity(0.15),
        selectedText: .black
    )
    static let dark = ThemePreset(
        id: "dark", name: "Dark",
        background: Color(red: 0.11, green: 0.11, blue: 0.13),
        text: .white,
        hover: Color.white.opacity(0.1),
        selected: Color.blue.opacity(0.35),
        selectedText: .white
    )
    static let ocean = ThemePreset(
        id: "ocean", name: "Ocean",
        background: Color(red: 0.05, green: 0.12, blue: 0.2),
        text: Color(red: 0.85, green: 0.93, blue: 1.0),
        hover: Color.cyan.opacity(0.18),
        selected: Color.cyan.opacity(0.35),
        selectedText: .white
    )
    static let forest = ThemePreset(
        id: "forest", name: "Forest",
        background: Color(red: 0.07, green: 0.12, blue: 0.08),
        text: Color(red: 0.85, green: 0.95, blue: 0.85),
        hover: Color.green.opacity(0.18),
        selected: Color.green.opacity(0.35),
        selectedText: .white
    )
    static let orange = ThemePreset(
        id: "orange", name: "Orange",
        background: Color(red: 1.0, green: 0.93, blue: 0.82),
        text: Color(red: 0.35, green: 0.18, blue: 0.02),
        hover: Color.orange.opacity(0.2),
        selected: Color.orange.opacity(0.4),
        selectedText: .black
    )
    static let cream = ThemePreset(
        id: "cream", name: "Cream",
        background: Color(red: 0.98, green: 0.95, blue: 0.88),
        text: Color(red: 0.25, green: 0.2, blue: 0.15),
        hover: Color.brown.opacity(0.15),
        selected: Color.brown.opacity(0.3),
        selectedText: .black
    )
    static let tiffanyBlue = ThemePreset(
        id: "tiffanyBlue", name: "Tiffany Blue",
        background: Color(red: 0.93, green: 0.98, blue: 0.97),
        text: Color(red: 0.05, green: 0.2, blue: 0.19),
        hover: Color(red: 0.04, green: 0.73, blue: 0.71).opacity(0.2),
        selected: Color(red: 0.04, green: 0.73, blue: 0.71).opacity(0.4),
        selectedText: .black
    )
    static let matrix = ThemePreset(
        id: "matrix", name: "Matrix",
        background: .black,
        text: Color(red: 0.0, green: 1.0, blue: 0.25),
        hover: Color.green.opacity(0.18),
        selected: Color.green.opacity(0.4),
        // Bright green text on a green-tinted-black highlight is exactly the
        // low-contrast case this field exists to avoid — white instead.
        selectedText: .white
    )

    static let all: [ThemePreset] = [system, light, dark, ocean, forest, orange, cream, tiffanyBlue, matrix]
    static let customID = "custom"
}

/// Live theme state, shared app-wide via `.environmentObject` from
/// `FloatingPanel`. Selecting a preset overwrites all four colors; editing
/// any individual color via a `ColorPicker` switches to (and persists as)
/// a "custom" theme built from whichever preset you started from.
final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()

    @Published private(set) var presetID: String
    @Published var background: Color
    @Published var text: Color
    @Published var hover: Color
    @Published var selected: Color
    @Published var selectedText: Color

    private enum Keys {
        static let presetID = "theme.presetID"
        static let background = "theme.custom.background"
        static let text = "theme.custom.text"
        static let hover = "theme.custom.hover"
        static let selected = "theme.custom.selected"
        static let selectedText = "theme.custom.selectedText"
    }

    private init() {
        let storedID = UserDefaults.standard.string(forKey: Keys.presetID) ?? ThemePresets.system.id
        if storedID == ThemePresets.customID {
            presetID = storedID
            background = Self.loadColor(Keys.background) ?? ThemePresets.system.background
            text = Self.loadColor(Keys.text) ?? ThemePresets.system.text
            hover = Self.loadColor(Keys.hover) ?? ThemePresets.system.hover
            selected = Self.loadColor(Keys.selected) ?? ThemePresets.system.selected
            selectedText = Self.loadColor(Keys.selectedText) ?? ThemePresets.system.selectedText
        } else {
            let preset = ThemePresets.all.first { $0.id == storedID } ?? ThemePresets.system
            presetID = preset.id
            background = preset.background
            text = preset.text
            hover = preset.hover
            selected = preset.selected
            selectedText = preset.selectedText
        }
    }

    func apply(_ preset: ThemePreset) {
        presetID = preset.id
        UserDefaults.standard.set(preset.id, forKey: Keys.presetID)
        background = preset.background
        text = preset.text
        hover = preset.hover
        selected = preset.selected
        selectedText = preset.selectedText
    }

    func setBackground(_ color: Color) {
        markCustom()
        background = color
        Self.saveColor(color, key: Keys.background)
    }

    func setText(_ color: Color) {
        markCustom()
        text = color
        Self.saveColor(color, key: Keys.text)
    }

    func setHover(_ color: Color) {
        markCustom()
        hover = color
        Self.saveColor(color, key: Keys.hover)
    }

    func setSelected(_ color: Color) {
        markCustom()
        selected = color
        Self.saveColor(color, key: Keys.selected)
    }

    func setSelectedText(_ color: Color) {
        markCustom()
        selectedText = color
        Self.saveColor(color, key: Keys.selectedText)
    }

    private func markCustom() {
        guard presetID != ThemePresets.customID else { return }
        presetID = ThemePresets.customID
        UserDefaults.standard.set(ThemePresets.customID, forKey: Keys.presetID)
        // Seed all custom slots from whatever's currently showing, so
        // switching one color doesn't leave the others unset.
        Self.saveColor(background, key: Keys.background)
        Self.saveColor(text, key: Keys.text)
        Self.saveColor(hover, key: Keys.hover)
        Self.saveColor(selected, key: Keys.selected)
        Self.saveColor(selectedText, key: Keys.selectedText)
    }

    private static func saveColor(_ color: Color, key: String) {
        guard let rgba = NSColor(color).usingColorSpace(.deviceRGB) else { return }
        let components = [rgba.redComponent, rgba.greenComponent, rgba.blueComponent, rgba.alphaComponent]
        if let data = try? JSONEncoder().encode(components) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func loadColor(_ key: String) -> Color? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let components = try? JSONDecoder().decode([Double].self, from: data),
              components.count == 4 else { return nil }
        return Color(red: components[0], green: components[1], blue: components[2], opacity: components[3])
    }
}
