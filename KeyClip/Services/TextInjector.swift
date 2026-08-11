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

    /// UserDefaults key backing Settings → Startup & Behavior's "Auto-Paste
    /// on Select" toggle. Gates whether `AppDelegate.copyAndHide` follows the
    /// pasteboard write with a synthetic ⌘V (`pasteFromClipboard`) or leaves
    /// the content on the pasteboard for a manual paste. Defaults to on,
    /// matching the original (non-configurable) auto-paste behavior.
    static let autoPasteDefaultsKey = "autoPasteEnabled"

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

    /// Reactivates `app` and posts a synthetic ⌘V, so pasteboard content set
    /// immediately beforehand (`AppDelegate.copyAndHide`) lands in the
    /// target app without the user pressing ⌘V themselves. Unlike `inject`,
    /// this never types the text out character-by-character — the
    /// `keyboardSetUnicodeString` chunking is what risks mangling long or
    /// unicode-heavy text — it only triggers the target app's own native
    /// paste handling, so that risk doesn't apply here. Always activates
    /// `app` regardless of Accessibility trust (that's just window
    /// activation, no permission needed) so the content is at least a manual
    /// ⌘V away; only the synthetic keystroke itself is gated.
    @discardableResult
    static func pasteFromClipboard(into app: NSRunningApplication?) -> Bool {
        app?.activate(options: [])
        guard AccessibilityPermission.isTrusted(prompt: false) else { return false }
        // Always deferred — even when `app` already reported `isActive`.
        // KeyClip's panel is a `.nonactivatingPanel`, so the app that was
        // frontmost before the panel opened keeps `NSRunningApplication.isActive
        // == true` the *entire* time the panel has key-window status; only
        // window-server key status moves, not OS-level app activation. This
        // used to skip the delay whenever `isActive` was already true and
        // post the keystroke synchronously, racing `AppDelegate.copyAndHide`'s
        // `panel.hideUnlessPresentingSheet()` (an `orderOut`) for who actually
        // held key-window status — the keystroke frequently lost that race
        // and landed nowhere, which is why auto-paste looked like it silently
        // did nothing. The same short heuristic delay `inject` already uses
        // for its own reactivation case fixes it here too.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            postPasteKeystroke()
        }
        return true
    }

    private static func postPasteKeystroke() {
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) else { return }
        down.flags = .maskCommand
        up.flags = .maskCommand
        tagSynthetic(down)
        tagSynthetic(up)
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    private static func tagSynthetic(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: syntheticEventMarker)
    }
}
