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
    /// Images get their own, much smaller cap — a screenshot-heavy history
    /// under the same 200-item budget as lightweight text would let a run
    /// of copied images crowd out everything else and quietly balloon disk
    /// usage (each item is a whole external file, unlike a few bytes of
    /// text).
    private let imageHistoryLimit = 30

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

        // Checked before `.string` — an app that puts both an image and a
        // string representation on the pasteboard (e.g. a file path) should
        // still be recorded as the image, since that's what was actually
        // copied.
        if let imageData = imageData(from: pasteboard) {
            recordImageCopy(imageData)
        } else if let content = pasteboard.string(forType: .string),
                  !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            recordCopy(of: content)
        }
    }

    /// Prefers PNG (already the format `recordImageCopy` stores, no
    /// re-encoding); falls back to TIFF — what most apps actually put on
    /// the pasteboard for a copied image — converted to PNG, since storing
    /// TIFF directly would be a needlessly large external file per item.
    private func imageData(from pasteboard: NSPasteboard) -> Data? {
        if let png = pasteboard.data(forType: .png) {
            return png
        }
        guard let tiff = pasteboard.data(forType: .tiff),
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }

    private func recordCopy(of content: String) {
        let descriptor = FetchDescriptor<ClipboardItem>(predicate: #Predicate { $0.content == content && $0.contentTypeRaw == "text" })
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.createdAt = .now
        } else {
            modelContext.insert(ClipboardItem(content: content))
            pruneHistoryIfNeeded(contentType: .text, limit: historyLimit)
        }
        try? modelContext.save()
    }

    /// Dedups by comparing full image bytes rather than a predicate on
    /// `imageData` directly — `@Attribute(.externalStorage)` properties
    /// aren't reliably usable inside a `#Predicate`, and history is capped
    /// small enough (`imageHistoryLimit`) that fetching and comparing in
    /// Swift is cheap.
    private func recordImageCopy(_ data: Data) {
        let descriptor = FetchDescriptor<ClipboardItem>(predicate: #Predicate { $0.contentTypeRaw == "image" })
        if let items = try? modelContext.fetch(descriptor), let existing = items.first(where: { $0.imageData == data }) {
            existing.createdAt = .now
        } else {
            modelContext.insert(ClipboardItem(imageData: data))
            pruneHistoryIfNeeded(contentType: .image, limit: imageHistoryLimit)
        }
        try? modelContext.save()
    }

    private func pruneHistoryIfNeeded(contentType: ClipboardContentType, limit: Int) {
        let rawType = contentType.rawValue
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { !$0.isPinned && !$0.isFavorite && $0.contentTypeRaw == rawType },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let items = try? modelContext.fetch(descriptor), items.count > limit else { return }
        for item in items[limit...] {
            modelContext.delete(item)
        }
    }
}
