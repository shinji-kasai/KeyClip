//
//  TextCaptureService.swift
//  KeyClip
//

import AppKit
import Vision

/// Lets the user drag-select a screen region — or click a window, via
/// `screencapture`'s own interactive mode (press Space to toggle, identical
/// to ⌘⇧4) — and extracts whatever text is visible there via on-device OCR
/// (Vision framework, the same underlying capability as macOS's own Live
/// Text). Useful for text that isn't otherwise selectable: a PDF that's
/// actually a scanned image, a screenshot, text baked into a window that
/// doesn't support text selection at all.
enum TextCaptureService {
    /// Shells out to the system `screencapture` tool for the actual
    /// region/window selection UI rather than building a custom overlay —
    /// reuses the exact same native selection experience as ⌘⇧4 (marching
    /// ants, Space-to-toggle-window-mode) instead of a hand-rolled
    /// transparent-window-plus-mouse-tracking reimplementation, which would
    /// also need its own multi-monitor handling. Requires Screen Recording
    /// access (`ScreenRecordingPermission`) — check before calling, since a
    /// missing grant makes `screencapture` silently fail to write a file,
    /// which this treats the same as a user-cancelled (Escape) selection:
    /// no error, just does nothing. That matches how a cancelled ⌘⇧4 also
    /// shows no error, so a real permission gap isn't distinguishable here
    /// from "changed my mind" — surface the permission check separately in
    /// Settings instead of guessing at this layer.
    @MainActor
    static func captureAndRecognizeText(target: NSRunningApplication?, autoPaste: Bool) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("KeyClipCapture-\(UUID().uuidString).png")

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        task.arguments = ["-i", "-x", tempURL.path]
        task.terminationHandler = { _ in
            handleCapture(at: tempURL, target: target, autoPaste: autoPaste)
        }
        try? task.run()
    }

    /// `nonisolated` so the Vision request (CPU-bound, potentially a second
    /// or more for a big region at `.accurate`) can run off the main actor
    /// without blocking the UI — only the final pasteboard-touching step
    /// hops back via `deliver`.
    nonisolated private static func handleCapture(at url: URL, target: NSRunningApplication?, autoPaste: Bool) {
        guard let data = try? Data(contentsOf: url) else { return }
        try? FileManager.default.removeItem(at: url)

        guard let image = NSImage(data: data),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        let request = VNRecognizeTextRequest { request, _ in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            // Vision's coordinate space is bottom-left-origin, so a higher
            // `origin.y` is higher up on screen — sorting descending puts
            // observations back into top-to-bottom reading order.
            let text = observations
                .sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")
            guard !text.isEmpty else { return }
            Task { @MainActor in
                deliver(text, target: target, autoPaste: autoPaste)
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }

    /// Same shape as `AppDelegate.copyAndHide` — writes to the pasteboard
    /// (which `ClipboardMonitor`'s existing poll picks up into history
    /// automatically, no separate recording needed here) and reuses the
    /// same auto-paste synthetic-⌘V path.
    @MainActor
    private static func deliver(_ text: String, target: NSRunningApplication?, autoPaste: Bool) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        if autoPaste {
            TextInjector.pasteFromClipboard(into: target)
        } else {
            target?.activate(options: [])
        }
    }
}
