//
//  ClipboardItem.swift
//  KeyClip
//

import Foundation
import SwiftData

enum ClipboardContentType: String {
    case text
    case image
}

@Model
final class ClipboardItem {
    @Attribute(.unique) var id: UUID
    var content: String
    var createdAt: Date
    var isPinned: Bool
    var isFavorite: Bool
    var useCount: Int
    /// "text" or "image" — was reserved from the start ("leaves room for
    /// image/rtf content later without a breaking migration"), so adding
    /// `imageData` below is a lightweight SwiftData migration (a new
    /// optional property), not a schema break.
    var contentTypeRaw: String
    /// `.externalStorage` tells SwiftData/CoreData to keep large blobs as
    /// separate files next to the store rather than inline in the main
    /// database file, so a history full of screenshots doesn't bloat the
    /// one file every query touches. `nil` for text items.
    @Attribute(.externalStorage) var imageData: Data?

    var contentType: ClipboardContentType {
        ClipboardContentType(rawValue: contentTypeRaw) ?? .text
    }

    init(content: String, createdAt: Date = .now) {
        self.id = UUID()
        self.content = content
        self.createdAt = createdAt
        self.isPinned = false
        self.isFavorite = false
        self.useCount = 0
        self.contentTypeRaw = ClipboardContentType.text.rawValue
        self.imageData = nil
    }

    init(imageData: Data, createdAt: Date = .now) {
        self.id = UUID()
        self.content = ""
        self.createdAt = createdAt
        self.isPinned = false
        self.isFavorite = false
        self.useCount = 0
        self.contentTypeRaw = ClipboardContentType.image.rawValue
        self.imageData = imageData
    }
}
