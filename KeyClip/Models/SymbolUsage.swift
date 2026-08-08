//
//  SymbolUsage.swift
//  KeyClip
//

import Foundation
import SwiftData

/// Per-symbol favorite/usage state, keyed by the character itself. The
/// symbols are built-in reference data (`SymbolCatalog.swift`), not user
/// content, so this only needs to exist for symbols the user has actually
/// favorited or used at least once.
@Model
final class SymbolUsage {
    @Attribute(.unique) var character: String
    var isFavorite: Bool
    var useCount: Int
    var lastUsedAt: Date

    init(character: String) {
        self.character = character
        self.isFavorite = false
        self.useCount = 0
        self.lastUsedAt = .now
    }
}
