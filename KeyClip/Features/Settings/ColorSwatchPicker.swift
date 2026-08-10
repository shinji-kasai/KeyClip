//
//  ColorSwatchPicker.swift
//  KeyClip
//

import SwiftUI
import AppKit

/// A labeled color-selection row: title on its own line, then a horizontal
/// row of clickable swatches, a "more colors" well, and a hex field — click
/// a swatch, pick from the full system panel, or type/paste a hex code
/// directly; the hex field also always displays the current selection's
/// hex when it's not being edited. Mirrors the font-color dropdown in apps
/// like Word (a grid of common colors you click straight from, with a full
/// picker as the fallback for anything not on the grid) rather than
/// macOS's bare `ColorPicker`, which is just a single swatch button that
/// always opens the system color panel even for a plain color swap. Each
/// swatch is a custom-drawn `Circle`, not AppKit chrome, so — unlike
/// `ColorPicker`'s own swatch — it always renders in the exact color it
/// represents regardless of the app's current light/dark effective
/// appearance.
///
/// The title used to share a row with the swatches (`Text` + `Spacer` +
/// swatches in an `HStack`), which squeezed everything into whatever
/// trailing space was left in a `Form` row — on `FloatingPanel`'s fixed
/// (non-resizable) 480pt width that read as cramped and hard to make out.
/// Stacking title above swatches gives the swatch row the section's full
/// width instead.
struct ColorSwatchPicker: View {
    @EnvironmentObject private var theme: ThemeStore
    let title: String
    @Binding var selection: Color

    /// A small curated set rather than a full standard-colors grid: covers
    /// the neutrals a background/text color is likely to want plus one
    /// swatch per hue. Kept short enough (plus the color well and hex
    /// field) to fit on one line at the panel's fixed 480pt width without
    /// wrapping or scrolling.
    private static let swatches: [Color] = [
        .black, Color(white: 0.5), .white,
        .red, .orange, .yellow, .green, .teal, .blue, .indigo, .purple, .brown,
    ]

    @State private var hexText: String = ""
    @FocusState private var isHexFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).foregroundStyle(theme.text)
            HStack(spacing: 5) {
                ForEach(Self.swatches, id: \.self) { color in
                    swatch(color)
                }
                ColorPicker("", selection: $selection)
                    .labelsHidden()
                    .help("More Colors…")
                TextField("Hex", text: $hexText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))
                    .frame(width: 74)
                    .focused($isHexFieldFocused)
                    .onSubmit(commitHex)
                    .onChange(of: isHexFieldFocused) { wasFocused, isFocused in
                        if wasFocused && !isFocused { commitHex() }
                    }
            }
        }
        .onAppear { hexText = Self.hexString(from: selection) }
        .onChange(of: selection) { _, newValue in
            guard !isHexFieldFocused else { return }
            hexText = Self.hexString(from: newValue)
        }
    }

    private func swatch(_ color: Color) -> some View {
        Button {
            selection = color
        } label: {
            Circle()
                .fill(color)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle().stroke(Color.primary.opacity(0.25), lineWidth: 0.5)
                )
                .overlay {
                    if isSelected(color) {
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 2)
                            .padding(-2)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func isSelected(_ color: Color) -> Bool {
        guard let a = NSColor(color).usingColorSpace(.deviceRGB),
              let b = NSColor(selection).usingColorSpace(.deviceRGB) else { return false }
        return abs(a.redComponent - b.redComponent) < 0.01
            && abs(a.greenComponent - b.greenComponent) < 0.01
            && abs(a.blueComponent - b.blueComponent) < 0.01
            && abs(a.alphaComponent - b.alphaComponent) < 0.01
    }

    /// Applies whatever's typed in the hex field, or — if it doesn't parse
    /// as a valid 6-digit hex color — snaps the field back to the current
    /// selection's hex rather than leaving garbage displayed.
    private func commitHex() {
        if let parsed = Self.color(fromHex: hexText) {
            selection = parsed
        }
        hexText = Self.hexString(from: selection)
    }

    private static func hexString(from color: Color) -> String {
        guard let rgb = NSColor(color).usingColorSpace(.deviceRGB) else { return "" }
        let r = Int((rgb.redComponent * 255).rounded())
        let g = Int((rgb.greenComponent * 255).rounded())
        let b = Int((rgb.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    private static func color(fromHex hex: String) -> Color? {
        var trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") { trimmed.removeFirst() }
        guard trimmed.count == 6, let value = UInt32(trimmed, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        return Color(red: r, green: g, blue: b)
    }
}
