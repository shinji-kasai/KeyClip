//
//  DeveloperCatalog.swift
//  KeyClip
//

import Foundation

/// Built-in reference tokens, not user content — same spirit as
/// `SymbolCatalog`, just multi-character strings instead of single glyphs.
struct DeveloperToken: Identifiable, Hashable {
    let text: String
    var id: String { text }
}

enum DeveloperCategory: String, CaseIterable, Identifiable {
    case brackets = "Brackets"
    case operators = "Operators"
    case sql = "SQL"
    case python = "Python"
    case javascript = "JavaScript"

    var id: String { rawValue }

    var tokens: [DeveloperToken] {
        switch self {
        case .brackets:
            return ["{", "}", "[", "]", "(", ")", "<", ">"].map { DeveloperToken(text: $0) }
        case .operators:
            return ["=>", "->", "==", "===", "!=", "!==", "&&", "||", "++", "--", "+=", "-="].map { DeveloperToken(text: $0) }
        case .sql:
            return ["SELECT", "FROM", "WHERE", "JOIN", "GROUP BY", "ORDER BY"].map { DeveloperToken(text: $0) }
        case .python:
            return ["def", "class", "self", "None", "True", "False"].map { DeveloperToken(text: $0) }
        case .javascript:
            return ["const", "let", "async", "await", "Promise"].map { DeveloperToken(text: $0) }
        }
    }
}
