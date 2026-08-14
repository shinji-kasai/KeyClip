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
    // `id` stays "tiffanyBlue" (not "turquoise") even though the displayed
    // name changed — it's the persisted `UserDefaults` key for anyone who
    // already has this preset selected, and renaming it would silently fall
    // back to System for them on next launch.
    static let turquoise = ThemePreset(
        id: "tiffanyBlue", name: "Turquoise",
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
    // Official Dracula palette (draculatheme.com/contribute): background
    // #282a36, foreground #f8f8f2, purple accent #bd93f9.
    static let dracula = ThemePreset(
        id: "dracula", name: "Dracula",
        background: Color(red: 0.157, green: 0.165, blue: 0.212),
        text: Color(red: 0.973, green: 0.973, blue: 0.949),
        hover: Color(red: 0.741, green: 0.576, blue: 0.976).opacity(0.18),
        selected: Color(red: 0.741, green: 0.576, blue: 0.976).opacity(0.35),
        selectedText: .white
    )
    // Anthropic's Claude.ai palette: cream surface, near-black text, the
    // "Crail" terracotta accent used for buttons/highlights.
    static let claude = ThemePreset(
        id: "claude", name: "Claude",
        background: Color(red: 0.961, green: 0.957, blue: 0.933),
        text: Color(red: 0.145, green: 0.137, blue: 0.129),
        hover: Color(red: 0.851, green: 0.467, blue: 0.341).opacity(0.18),
        selected: Color(red: 0.851, green: 0.467, blue: 0.341).opacity(0.35),
        selectedText: .black
    )
    // GitHub's light UI: white surface, its signature accent blue #0969DA.
    static let github = ThemePreset(
        id: "github", name: "GitHub",
        background: .white,
        text: Color(red: 0.122, green: 0.137, blue: 0.157),
        hover: Color(red: 0.024, green: 0.412, blue: 0.855).opacity(0.1),
        selected: Color(red: 0.024, green: 0.412, blue: 0.855).opacity(0.18),
        selectedText: .black
    )
    // Ubuntu's terminal aubergine (#2C001E) with its signature orange
    // accent (#E95420).
    static let ubuntu = ThemePreset(
        id: "ubuntu", name: "Ubuntu",
        background: Color(red: 0.173, green: 0.0, blue: 0.118),
        text: Color(red: 0.94, green: 0.94, blue: 0.94),
        hover: Color(red: 0.914, green: 0.329, blue: 0.125).opacity(0.2),
        selected: Color(red: 0.914, green: 0.329, blue: 0.125).opacity(0.4),
        selectedText: .white
    )
    // One Dark Pro, the most-installed VS Code color theme — Atom's "One
    // Dark" palette (#282c34 background, #61afef accent blue).
    static let oneDark = ThemePreset(
        id: "oneDark", name: "One Dark",
        background: Color(red: 0.157, green: 0.173, blue: 0.204),
        text: Color(red: 0.671, green: 0.698, blue: 0.749),
        hover: Color(red: 0.380, green: 0.686, blue: 0.937).opacity(0.18),
        selected: Color(red: 0.380, green: 0.686, blue: 0.937).opacity(0.35),
        selectedText: .white
    )

    static let all: [ThemePreset] = [
        system, light, dark, ocean, forest, orange, cream, turquoise, matrix,
        dracula, claude, github, ubuntu, oneDark,
    ]
}

/// Plain RGBA storage for a `Color`, since `Color` itself isn't `Codable`.
struct RGBAColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(_ color: Color) {
        let rgb = NSColor(color).usingColorSpace(.deviceRGB) ?? NSColor(white: 0, alpha: 1)
        red = rgb.redComponent
        green = rgb.greenComponent
        blue = rgb.blueComponent
        alpha = rgb.alphaComponent
    }

    var color: Color { Color(red: red, green: green, blue: blue, opacity: alpha) }
}

/// A user-created theme — unlike the 14 built-in `ThemePreset`s, these are
/// arbitrary in number, named, and mutable in place (editing one updates
/// its own stored colors, not a shared anonymous "Custom" slot the way this
/// used to work).
struct CustomTheme: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var background: RGBAColor
    var text: RGBAColor
    var hover: RGBAColor
    var selected: RGBAColor
    var selectedText: RGBAColor
    /// The built-in preset this was duplicated from, if any — lets `Reset`
    /// snap this theme's colors back to that preset's originals without
    /// losing its id/name/place in the list. `nil` for a theme duplicated
    /// from another custom theme, or created with no such lineage.
    var basedOn: String?
}

/// Live theme state, shared app-wide via `.environmentObject` from
/// `FloatingPanel`. Selecting a built-in preset (`apply(_:)`) never mutates
/// that preset — its colors are always the same next time you pick it,
/// i.e. always "resettable" by construction. Editing any individual color
/// while a built-in preset is active instead forks a new named
/// `CustomTheme` seeded from the current colors (`ensureEditableTheme()`)
/// and edits land there; editing while an existing custom theme is active
/// updates that theme in place. `customThemes` persists as JSON, replacing
/// the single anonymous "Custom" slot this used to be.
final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()

    @Published private(set) var selectedID: String
    @Published var background: Color
    @Published var text: Color
    @Published var hover: Color
    @Published var selected: Color
    @Published var selectedText: Color
    @Published private(set) var customThemes: [CustomTheme]

    private enum Keys {
        static let selectedID = "theme.selectedID"
        static let customThemes = "theme.customThemes"
    }

    private init() {
        let loadedCustomThemes = Self.loadCustomThemes()
        customThemes = loadedCustomThemes
        let storedID = UserDefaults.standard.string(forKey: Keys.selectedID) ?? ThemePresets.system.id
        if let custom = loadedCustomThemes.first(where: { $0.id.uuidString == storedID }) {
            selectedID = storedID
            background = custom.background.color
            text = custom.text.color
            hover = custom.hover.color
            selected = custom.selected.color
            selectedText = custom.selectedText.color
        } else {
            let preset = ThemePresets.all.first { $0.id == storedID } ?? ThemePresets.system
            selectedID = preset.id
            background = preset.background
            text = preset.text
            hover = preset.hover
            selected = preset.selected
            selectedText = preset.selectedText
        }
    }

    func apply(_ preset: ThemePreset) {
        selectedID = preset.id
        UserDefaults.standard.set(preset.id, forKey: Keys.selectedID)
        background = preset.background
        text = preset.text
        hover = preset.hover
        selected = preset.selected
        selectedText = preset.selectedText
    }

    func select(_ custom: CustomTheme) {
        selectedID = custom.id.uuidString
        UserDefaults.standard.set(selectedID, forKey: Keys.selectedID)
        background = custom.background.color
        text = custom.text.color
        hover = custom.hover.color
        selected = custom.selected.color
        selectedText = custom.selectedText.color
    }

    /// Creates a new named theme from whatever colors are *currently*
    /// showing — i.e. duplicates the active theme, built-in or custom —
    /// selects it, and returns it.
    @discardableResult
    func duplicateCurrentTheme(named name: String) -> CustomTheme {
        let basedOn = customThemes.first { $0.id.uuidString == selectedID }?.basedOn
            ?? ThemePresets.all.first { $0.id == selectedID }?.id
        let created = CustomTheme(
            id: UUID(), name: uniqueName(name),
            background: RGBAColor(background), text: RGBAColor(text),
            hover: RGBAColor(hover), selected: RGBAColor(selected),
            selectedText: RGBAColor(selectedText), basedOn: basedOn
        )
        customThemes.append(created)
        persistCustomThemes()
        select(created)
        return created
    }

    func rename(_ id: UUID, to newName: String) {
        guard let index = customThemes.firstIndex(where: { $0.id == id }), !newName.isEmpty else { return }
        customThemes[index].name = newName
        persistCustomThemes()
    }

    /// Falls back to System if the deleted theme was the active one.
    func delete(_ id: UUID) {
        customThemes.removeAll { $0.id == id }
        persistCustomThemes()
        if selectedID == id.uuidString {
            apply(ThemePresets.system)
        }
    }

    /// Snaps a custom theme's colors back to the built-in preset it was
    /// duplicated from — only available when `basedOn` is set (a theme
    /// created from scratch, or duplicated from another custom theme, has
    /// nothing to reset to).
    func reset(_ id: UUID) {
        guard let index = customThemes.firstIndex(where: { $0.id == id }),
              let basedOnID = customThemes[index].basedOn,
              let preset = ThemePresets.all.first(where: { $0.id == basedOnID }) else { return }
        customThemes[index].background = RGBAColor(preset.background)
        customThemes[index].text = RGBAColor(preset.text)
        customThemes[index].hover = RGBAColor(preset.hover)
        customThemes[index].selected = RGBAColor(preset.selected)
        customThemes[index].selectedText = RGBAColor(preset.selectedText)
        persistCustomThemes()
        if selectedID == id.uuidString {
            select(customThemes[index])
        }
    }

    func setBackground(_ color: Color) {
        let id = ensureEditableTheme()
        background = color
        update(id) { $0.background = RGBAColor(color) }
    }

    /// Also re-derives `hover`/`selected` from the new text color, rather
    /// than leaving them at whatever unrelated color they happened to be
    /// before — an accent picked up from a previous preset (or an earlier,
    /// now-abandoned text color) reads as a random color slapped on top of
    /// the new text rather than belonging to the same palette. Still
    /// independently overridable afterward via `setHover`/`setSelected` if
    /// a specific accent hue is wanted instead.
    func setText(_ color: Color) {
        let id = ensureEditableTheme()
        text = color
        hover = color.opacity(0.15)
        selected = color.opacity(0.3)
        update(id) {
            $0.text = RGBAColor(color)
            $0.hover = RGBAColor(hover)
            $0.selected = RGBAColor(selected)
        }
    }

    func setHover(_ color: Color) {
        let id = ensureEditableTheme()
        hover = color
        update(id) { $0.hover = RGBAColor(color) }
    }

    func setSelected(_ color: Color) {
        let id = ensureEditableTheme()
        selected = color
        update(id) { $0.selected = RGBAColor(color) }
    }

    func setSelectedText(_ color: Color) {
        let id = ensureEditableTheme()
        selectedText = color
        update(id) { $0.selectedText = RGBAColor(color) }
    }

    /// Whether native AppKit-backed chrome (the `Picker`/`ColorPicker` boxes,
    /// `HotKeyRecorderView`'s `NSColor.labelColor`/`controlBackgroundColor`,
    /// a `TextField`'s placeholder/caret) should draw dark or light. Those
    /// are rendered by AppKit itself from the view's *effective appearance*,
    /// not from our SwiftUI-level `background`/`text` colors — so without
    /// this, a dark preset picked while macOS is in Light mode renders that
    /// chrome with light (white-box, black-text) styling on top of a dark
    /// background, i.e. invisible. Pinning `preferredColorScheme` to the
    /// theme's own luminance keeps AppKit's native rendering consistent with
    /// whatever custom colors are actually on screen. `nil` for the System
    /// preset so it keeps following the real system appearance instead of
    /// being pinned to one.
    var preferredColorScheme: ColorScheme? {
        guard selectedID != ThemePresets.system.id else { return nil }
        guard let luminance = Self.luminance(background) else { return nil }
        return luminance < 0.5 ? .dark : .light
    }

    private static func luminance(_ color: Color) -> Double? {
        guard let rgb = NSColor(color).usingColorSpace(.deviceRGB) else { return nil }
        return 0.2126 * rgb.redComponent + 0.7152 * rgb.greenComponent + 0.0722 * rgb.blueComponent
    }

    /// If the active theme is already a custom one, edits land there
    /// directly. Otherwise (a built-in preset is active) forks a new custom
    /// theme seeded from the current colors — built-ins themselves are
    /// never mutated, so re-selecting one always gives its original colors
    /// back. Only forks once per "session" of edits: after the first fork,
    /// `selectedID` already points at the new theme, so subsequent edits in
    /// the same sitting find and reuse it instead of forking again.
    private func ensureEditableTheme() -> UUID {
        if let existing = customThemes.first(where: { $0.id.uuidString == selectedID }) {
            return existing.id
        }
        let baseName = ThemePresets.all.first { $0.id == selectedID }?.name ?? "Custom"
        return duplicateCurrentTheme(named: "\(baseName) Copy").id
    }

    private func update(_ id: UUID, _ mutate: (inout CustomTheme) -> Void) {
        guard let index = customThemes.firstIndex(where: { $0.id == id }) else { return }
        mutate(&customThemes[index])
        persistCustomThemes()
    }

    private func uniqueName(_ base: String) -> String {
        guard customThemes.contains(where: { $0.name == base }) else { return base }
        var counter = 2
        while customThemes.contains(where: { $0.name == "\(base) \(counter)" }) {
            counter += 1
        }
        return "\(base) \(counter)"
    }

    private func persistCustomThemes() {
        guard let data = try? JSONEncoder().encode(customThemes) else { return }
        UserDefaults.standard.set(data, forKey: Keys.customThemes)
    }

    private static func loadCustomThemes() -> [CustomTheme] {
        guard let data = UserDefaults.standard.data(forKey: Keys.customThemes),
              let decoded = try? JSONDecoder().decode([CustomTheme].self, from: data) else { return [] }
        return decoded
    }
}
