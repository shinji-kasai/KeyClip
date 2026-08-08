//
//  KeyboardView.swift
//  KeyClip
//

import SwiftUI

struct KeyboardView: View {
    @Environment(\.copyToClipboard) private var copyToClipboard

    @AppStorage(WidthConversionCategory.numbers.defaultsKey) private var numbersMode: WidthMode = .halfWidth
    @AppStorage(WidthConversionCategory.katakana.defaultsKey) private var katakanaMode: WidthMode = .halfWidth
    @AppStorage(WidthConversionCategory.alphabet.defaultsKey) private var alphabetMode: WidthMode = .halfWidth
    @AppStorage(WidthConversionCategory.symbols.defaultsKey) private var symbolsMode: WidthMode = .halfWidth
    @AppStorage(WidthConversionCategory.space.defaultsKey) private var spaceMode: WidthMode = .halfWidth

    @State private var rawText = ""
    @State private var isShifted = false

    private static let rows: [[String]] = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"],
    ]

    private var settings: [WidthConversionCategory: WidthMode] {
        [
            .numbers: numbersMode,
            .katakana: katakanaMode,
            .alphabet: alphabetMode,
            .symbols: symbolsMode,
            .space: spaceMode,
        ]
    }

    private var convertedText: String {
        WidthConverter.convert(rawText, settings: settings)
    }

    var body: some View {
        VStack(spacing: 12) {
            composeArea
            Divider()
            keyboard
        }
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var composeArea: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Type here, or paste text to convert...", text: $rawText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)

            if !convertedText.isEmpty {
                Text(convertedText)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(6)
            }

            HStack {
                Button("Clear") { rawText = "" }
                    .disabled(rawText.isEmpty)
                Spacer()
                Button("Copy") {
                    copyToClipboard(convertedText)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(rawText.isEmpty)
            }
        }
    }

    private var keyboard: some View {
        VStack(spacing: 6) {
            ForEach(Self.rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { key in
                        KeyButton(label: key) {
                            appendLetterOrDigit(key)
                        }
                    }
                }
            }
            HStack(spacing: 6) {
                KeyButton(label: "⇧", isToggled: isShifted) {
                    isShifted.toggle()
                }
                KeyButton(label: "space", widthMultiplier: 5) {
                    rawText += " "
                }
                KeyButton(label: "⌫") {
                    backspace()
                }
            }
        }
    }

    private func appendLetterOrDigit(_ key: String) {
        if key.rangeOfCharacter(from: .letters) != nil {
            rawText += isShifted ? key.uppercased() : key.lowercased()
        } else {
            rawText += key
        }
    }

    private func backspace() {
        guard !rawText.isEmpty else { return }
        rawText.removeLast()
    }
}

private struct KeyButton: View {
    let label: String
    var isToggled: Bool = false
    var widthMultiplier: CGFloat = 1
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .frame(minWidth: 28 * widthMultiplier, minHeight: 28)
        }
        .buttonStyle(.plain)
        .background(backgroundColor)
        .cornerRadius(6)
        .onHover { isHovered = $0 }
    }

    private var backgroundColor: Color {
        if isToggled { return Color.accentColor.opacity(0.3) }
        if isHovered { return Color.secondary.opacity(0.18) }
        return Color.secondary.opacity(0.08)
    }
}
