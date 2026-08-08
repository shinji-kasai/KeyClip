//
//  Snippet.swift
//  KeyClip
//

import Foundation
import SwiftData

@Model
final class Snippet {
    @Attribute(.unique) var id: UUID
    var trigger: String
    var content: String
    /// Flat category label (e.g. "Email", "Python") rather than a full
    /// editable nested tree — the Snippets tab groups rows by this string.
    var category: String
    var createdAt: Date

    init(trigger: String, content: String, category: String, createdAt: Date = .now) {
        self.id = UUID()
        self.trigger = trigger
        self.content = content
        self.category = category
        self.createdAt = createdAt
    }
}
