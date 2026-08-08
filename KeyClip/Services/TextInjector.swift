//
//  TextInjector.swift
//  KeyClip
//

import AppKit
import CoreGraphics
import Carbon.HIToolbox

/// Injects arbitrary Unicode text into whatever app currently has keyboard
/// focus, by posting synthetic keyboard events. Shared by every tab that
/// offers "click to insert" and by `SnippetExpansionEngine`'s typing-trigger
/// expansion.
enum TextInjector {
    /// `CGEvent.keyboardSetUnicodeString` silently truncates beyond a small
    /// per-event buffer, so longer text (e.g. paragraph-length clipboard
    /// entries) must be split into chunks, one down/up event pair each.
    private static let chunkSize = 20

    /// Tag every event this service posts with this marker (via the
    /// `eventSourceUserData` field) so `SnippetExpansionEngine`'s keystroke
    /// listener can recognize and ignore its own synthetic events instead of
    /// feeding them back into its trigger-matching buffer.
    static let syntheticEventMarker: Int64 = 0x4B79_436C_4B79

    /// Reactivates `app` (if it isn't already active) and types `text` into
    /// it. Used for the panel's "click to insert directly" flows.
    @discardableResult
    static func inject(_ text: String, into app: NSRunningApplication?) -> Bool {
        guard AccessibilityPermission.isTrusted(prompt: false) else { return false }
        guard !text.isEmpty else { return true }

        if let app, !app.isActive {
            app.activate(options: [])
            // Heuristic delay: gives the target app time to actually become
            // frontmost before events are posted. Not a hard guarantee.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                typeText(text)
            }
        } else {
            typeText(text)
        }
        return true
    }

    /// Types `text` into whatever currently has keyboard focus, with no
    /// app-activation step. Used by `SnippetExpansionEngine`, where focus is
    /// already correct (the user is actively typing there).
    static func typeText(_ text: String) {
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
                tagSynthetic(down)
                tagSynthetic(up)
                down.post(tap: .cghidEventTap)
                up.post(tap: .cghidEventTap)
            }
            start = end
        }
    }

    /// Posts `count` backspace keystrokes, used to delete a just-typed
    /// trigger before substituting its expansion.
    static func deleteBackward(count: Int) {
        guard count > 0 else { return }
        let source = CGEventSource(stateID: .combinedSessionState)
        for _ in 0..<count {
            guard let down = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Delete), keyDown: true),
                  let up = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Delete), keyDown: false) else { continue }
            tagSynthetic(down)
            tagSynthetic(up)
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
        }
    }

    private static func tagSynthetic(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: syntheticEventMarker)
    }
}
