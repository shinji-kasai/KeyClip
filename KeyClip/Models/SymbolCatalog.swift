//
//  SymbolCatalog.swift
//  KeyClip
//

import Foundation

/// A single insertable character plus a searchable name (e.g. "left arrow"
/// for ←), so the search field can match on name the way the spec's
/// "search 'arrow'" example expects.
struct SymbolEntry: Identifiable, Hashable {
    let character: String
    let name: String
    var id: String { character }
}

/// Built-in reference data, not user content — there's nothing to persist
/// here beyond per-symbol favorite/usage state (`SymbolUsage`).
enum SymbolCategory: String, CaseIterable, Identifiable {
    case marks = "Marks"
    case arrows = "Arrows"
    case math = "Math"
    case science = "Science"
    case greek = "Greek"

    var id: String { rawValue }

    var symbols: [SymbolEntry] {
        switch self {
        case .marks:
            return [
                SymbolEntry(character: "✓", name: "check mark"),
                SymbolEntry(character: "✕", name: "cross mark"),
                SymbolEntry(character: "★", name: "star"),
                SymbolEntry(character: "☆", name: "outline star"),
                SymbolEntry(character: "©", name: "copyright"),
                SymbolEntry(character: "®", name: "registered"),
                SymbolEntry(character: "™", name: "trademark"),
            ]
        case .arrows:
            return [
                SymbolEntry(character: "←", name: "left arrow"),
                SymbolEntry(character: "→", name: "right arrow"),
                SymbolEntry(character: "↑", name: "up arrow"),
                SymbolEntry(character: "↓", name: "down arrow"),
                SymbolEntry(character: "↔", name: "left right arrow"),
                SymbolEntry(character: "↕", name: "up down arrow"),
                SymbolEntry(character: "⇐", name: "left double arrow"),
                SymbolEntry(character: "⇒", name: "right double arrow"),
                SymbolEntry(character: "⇑", name: "up double arrow"),
                SymbolEntry(character: "⇓", name: "down double arrow"),
                SymbolEntry(character: "↖", name: "up left arrow"),
                SymbolEntry(character: "↗", name: "up right arrow"),
                SymbolEntry(character: "↘", name: "down right arrow"),
                SymbolEntry(character: "↙", name: "down left arrow"),
            ]
        case .math:
            return [
                SymbolEntry(character: "±", name: "plus minus"),
                SymbolEntry(character: "×", name: "multiplication"),
                SymbolEntry(character: "÷", name: "division"),
                SymbolEntry(character: "≠", name: "not equal"),
                SymbolEntry(character: "≤", name: "less than or equal"),
                SymbolEntry(character: "≥", name: "greater than or equal"),
                SymbolEntry(character: "∞", name: "infinity"),
                SymbolEntry(character: "√", name: "square root"),
                SymbolEntry(character: "∑", name: "summation"),
                SymbolEntry(character: "∏", name: "product"),
                SymbolEntry(character: "∫", name: "integral"),
                SymbolEntry(character: "≈", name: "approximately equal"),
                SymbolEntry(character: "≡", name: "identical to"),
                SymbolEntry(character: "∝", name: "proportional to"),
            ]
        case .science:
            return [
                SymbolEntry(character: "℃", name: "degrees celsius"),
                SymbolEntry(character: "℉", name: "degrees fahrenheit"),
                SymbolEntry(character: "Å", name: "angstrom"),
                SymbolEntry(character: "Ω", name: "ohm"),
            ]
        case .greek:
            return [
                SymbolEntry(character: "α", name: "alpha"),
                SymbolEntry(character: "β", name: "beta"),
                SymbolEntry(character: "γ", name: "gamma"),
                SymbolEntry(character: "δ", name: "delta"),
                SymbolEntry(character: "ε", name: "epsilon"),
                SymbolEntry(character: "ζ", name: "zeta"),
                SymbolEntry(character: "η", name: "eta"),
                SymbolEntry(character: "θ", name: "theta"),
                SymbolEntry(character: "ι", name: "iota"),
                SymbolEntry(character: "κ", name: "kappa"),
                SymbolEntry(character: "λ", name: "lambda"),
                SymbolEntry(character: "μ", name: "mu"),
                SymbolEntry(character: "ν", name: "nu"),
                SymbolEntry(character: "ξ", name: "xi"),
                SymbolEntry(character: "ο", name: "omicron"),
                SymbolEntry(character: "π", name: "pi"),
                SymbolEntry(character: "ρ", name: "rho"),
                SymbolEntry(character: "σ", name: "sigma"),
                SymbolEntry(character: "τ", name: "tau"),
                SymbolEntry(character: "υ", name: "upsilon"),
                SymbolEntry(character: "φ", name: "phi"),
                SymbolEntry(character: "χ", name: "chi"),
                SymbolEntry(character: "ψ", name: "psi"),
                SymbolEntry(character: "ω", name: "omega"),
            ]
        }
    }

    static var allSymbols: [SymbolEntry] {
        allCases.flatMap { $0.symbols }
    }
}
