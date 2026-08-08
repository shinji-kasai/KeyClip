//
//  ClipboardItem.swift
//  KeyClip
//

import Foundation
import SwiftData

@Model
final class ClipboardItem {
    @Attribute(.unique) var id: UUID
    var content: String
    var createdAt: Date
    var isPinned: Bool
    var isFavorite: Bool
    var useCount: Int
    /// "text" for M1; leaves room for image/rtf content later without a breaking migration.
    var contentTypeRaw: String

    init(content: String, createdAt: Date = .now) {
        self.id = UUID()
        self.content = content
        self.createdAt = createdAt
        self.isPinned = false
        self.isFavorite = false
        self.useCount = 0
        self.contentTypeRaw = "text"
    }
}
