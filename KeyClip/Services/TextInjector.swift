//
//  TextInjector.swift
//  KeyClip
//

import AppKit
import CoreGraphics

/// Injects arbitrary Unicode text into whatever app was frontmost before the
/// panel appeared, by reactivating it and posting synthetic keyboard events.
/// Shared by every tab that offers "click to insert" (Clipboard now, later
/// Snippets/Symbols/Developer/Keyboard).
enum TextInjector {
    /// `CGEvent.keyboardSetUnicodeString` silently truncates beyond a small
    /// per-event buffer, so longer text (e.g. paragraph-length clipboard
    /// entries) must be split into chunks, one down/up event pair each.
    private static let chunkSize = 20

    @discardableResult
    static func inject(_ text: String, into app: NSRunningApplication?) -> Bool {
        guard AccessibilityPermission.isTrusted(prompt: false) else { return false }
        guard !text.isEmpty else { return true }

        let post = {
            let source = CGEventSource(stateID: .combinedSessionState)
            let units = Array(text.utf16)
            var start = 0
            while start < units.count {
                let end = min(start + chunkSize, units.count)
                let chunk = Array(units[start..<end])
                if let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                   let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                    down.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: chunk)
                    up.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: chunk)
                    down.post(tap: .cghidEventTap)
                    up.post(tap: .cghidEventTap)
                }
                start = end
            }
        }

        if let app, !app.isActive {
            app.activate(options: [])
            // Heuristic delay: gives the target app time to actually become
            // frontmost before events are posted. Not a hard guarantee.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: post)
        } else {
            post()
        }
        return true
    }
}
