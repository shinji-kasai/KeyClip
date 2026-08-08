//
//  WidthConverter.swift
//  KeyClip
//

import Foundation

enum WidthMode: String, CaseIterable, Identifiable {
    case fullWidth
    case halfWidth

    var id: String { rawValue }
    var label: String { self == .fullWidth ? "Full-width" : "Half-width" }
}

enum WidthConversionCategory: String, CaseIterable {
    case numbers, katakana, alphabet, symbols, space

    var defaultsKey: String { "widthMode.\(rawValue)" }

    var title: String {
        switch self {
        case .numbers: return "Numbers"
        case .katakana: return "Katakana"
        case .alphabet: return "Alphabet"
        case .symbols: return "Symbols"
        case .space: return "Space"
        }
    }
}

/// Converts text between full-width and half-width forms per-category
/// (Numbers/Katakana/Alphabet/Symbols/Space each independently full or half
/// width), per the spec's example: "１２３ＡＢＣ　カタカナ" becomes
/// "123ABC ｶﾀｶﾅ" if every category is set to half-width, or a mix like
/// "１２３ABC カタカナ" if only some are.
enum WidthConverter {
    static func convert(_ text: String, settings: [WidthConversionCategory: WidthMode]) -> String {
        guard !text.isEmpty else { return text }

        var result = ""
        var runCategory: WidthConversionCategory?
        var run = ""

        func flushRun() {
            guard !run.isEmpty else { return }
            if let runCategory, let mode = settings[runCategory] {
                // .fullwidthToHalfwidth's natural direction is full→half;
                // reverse:true flips it to half→full. Transforming a whole
                // same-category run at once (rather than one character at a
                // time) is what lets this correctly handle combining
                // voiced/semi-voiced katakana marks (e.g. ｶﾞ ⇄ ガ).
                result += run.applyingTransform(.fullwidthToHalfwidth, reverse: mode == .fullWidth) ?? run
            } else {
                result += run
            }
            run = ""
        }

        for character in text {
            let category = category(for: character)
            if category != runCategory {
                flushRun()
                runCategory = category
            }
            run.append(character)
        }
        flushRun()
        return result
    }

    private static func category(for character: Character) -> WidthConversionCategory? {
        // Use the base scalar, not scalars.count == 1 — a half-width
        // katakana base + its voiced/semi-voiced sound mark (e.g. ｶﾞ) is one
        // `Character` with 2 scalars, and still belongs to .katakana.
        guard let scalar = character.unicodeScalars.first else { return nil }
        let value = scalar.value

        if character == " " || value == 0x3000 {
            return .space
        }
        if (0x30...0x39).contains(value) || (0xFF10...0xFF19).contains(value) {
            return .numbers
        }
        if (0x41...0x5A).contains(value) || (0x61...0x7A).contains(value) ||
            (0xFF21...0xFF3A).contains(value) || (0xFF41...0xFF5A).contains(value) {
            return .alphabet
        }
        if (0x30A0...0x30FF).contains(value) || (0xFF61...0xFF9F).contains(value) {
            return .katakana
        }
        if character.isSymbol || character.isPunctuation {
            return .symbols
        }
        return nil
    }
}
