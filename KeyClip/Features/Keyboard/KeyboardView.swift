//
//  KeyboardView.swift
//  KeyClip
//

import SwiftUI

/// A control panel for Japanese full/half-width input conversion — not an
/// on-screen keyboard. Per-category enable/disable + width choice, plus a
/// plain text field so the conversion is actually usable (type with your
/// real keyboard, or paste existing text, then copy the converted result).
/// Only meaningful with a Japanese input source active, so it disables
/// itself otherwise rather than pretending to do something useful.
struct KeyboardView: View {
    @Environment(\.copyToClipboard) private var copyToClipboard
    @StateObject private var inputSource = InputSourceObserver()

    @AppStorage("widthEnabled.numbers") private var numbersEnabled = true
    @AppStorage("widthEnabled.katakana") private var katakanaEnabled = true
    @AppStorage("widthEnabled.alphabet") private var alphabetEnabled = false
    @AppStorage("widthEnabled.symbols") private var symbolsEnabled = true
    @AppStorage("widthEnabled.space") private var spaceEnabled = true

    @AppStorage(WidthConversionCategory.numbers.defaultsKey) private var numbersMode: WidthMode = .halfWidth
    @AppStorage(WidthConversionCategory.katakana.defaultsKey) private var katakanaMode: WidthMode = .halfWidth
    @AppStorage(WidthConversionCategory.alphabet.defaultsKey) private var alphabetMode: WidthMode = .halfWidth
    @AppStorage(WidthConversionCategory.symbols.defaultsKey) private var symbolsMode: WidthMode = .halfWidth
    @AppStorage(WidthConversionCategory.space.defaultsKey) private var spaceMode: WidthMode = .halfWidth

    @State private var rawText = ""

    private var conversionSettings: [WidthConversionCategory: WidthMode] {
        var settings: [WidthConversionCategory: WidthMode] = [:]
        if numbersEnabled { settings[.numbers] = numbersMode }
        if katakanaEnabled { settings[.katakana] = katakanaMode }
        if alphabetEnabled { settings[.alphabet] = alphabetMode }
        if symbolsEnabled { settings[.symbols] = symbolsMode }
        if spaceEnabled { settings[.space] = spaceMode }
        return settings
    }

    private var convertedText: String {
        WidthConverter.convert(rawText, settings: conversionSettings)
    }

    var body: some View {
        VStack(spacing: 0) {
            if !inputSource.isJapanese {
                notice
                Divider()
            }

            Form {
                Section("Convert Width") {
                    categoryRow("Numbers", isEnabled: $numbersEnabled, mode: $numbersMode)
                    categoryRow("Katakana", isEnabled: $katakanaEnabled, mode: $katakanaMode)
                    categoryRow("Alphabet", isEnabled: $alphabetEnabled, mode: $alphabetMode)
                    categoryRow("Symbols", isEnabled: $symbolsEnabled, mode: $symbolsMode)
                    categoryRow("Space", isEnabled: $spaceEnabled, mode: $spaceMode)
                }
            }
            .formStyle(.grouped)

            Divider()
            composeArea
                .padding(12)
        }
        .disabled(!inputSource.isJapanese)
        .opacity(inputSource.isJapanese ? 1 : 0.5)
    }

    private var notice: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("Switch to a Japanese input source to use width conversion")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }

    private func categoryRow(_ title: String, isEnabled: Binding<Bool>, mode: Binding<WidthMode>) -> some View {
        HStack {
            Toggle(title, isOn: isEnabled)
            Spacer()
            Picker("", selection: mode) {
                ForEach(WidthMode.allCases) { widthMode in
                    Text(widthMode.label).tag(widthMode)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 180)
            .disabled(!isEnabled.wrappedValue)
        }
    }

    private var composeArea: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Type or paste text to convert...", text: $rawText, axis: .vertical)
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
}
