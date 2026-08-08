//
//  ClipboardMonitor.swift
//  KeyClip
//

import AppKit
import SwiftData

/// Polls `NSPasteboard.general.changeCount` since macOS has no push-based
/// clipboard-change notification, and records new copies into SwiftData.
final class ClipboardMonitor {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let modelContext: ModelContext
    private let historyLimit = 200

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.pollPasteboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func pollPasteboard() {
        let changeCount = pasteboard.changeCount
        guard changeCount != lastChangeCount else { return }
        lastChangeCount = changeCount

        guard let content = pasteboard.string(forType: .string) else { return }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        recordCopy(of: content)
    }

    private func recordCopy(of content: String) {
        let descriptor = FetchDescriptor<ClipboardItem>(predicate: #Predicate { $0.content == content })
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.createdAt = .now
        } else {
            modelContext.insert(ClipboardItem(content: content))
            pruneHistoryIfNeeded()
        }
        try? modelContext.save()
    }

    private func pruneHistoryIfNeeded() {
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { !$0.isPinned && !$0.isFavorite },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let items = try? modelContext.fetch(descriptor), items.count > historyLimit else { return }
        for item in items[historyLimit...] {
            modelContext.delete(item)
        }
    }
}
