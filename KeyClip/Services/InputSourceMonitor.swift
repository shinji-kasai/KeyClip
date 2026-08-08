//
//  InputSourceMonitor.swift
//  KeyClip
//

import Carbon.HIToolbox
import Foundation
import Combine

enum InputSourceMonitor {
    /// Deliberately does NOT use `TISCopyCurrentKeyboardInputSource()` —
    /// that reflects the input source "current" for the *calling process*,
    /// which is unreliable here: KeyClip's panel is a non-activating
    /// `NSPanel` that never makes KeyClip the truly-active app, so that call
    /// can report a stale/default source even while the menu bar correctly
    /// shows Japanese selected for whatever app the user is actually in.
    /// Scanning every installed input source for whichever one carries
    /// `kTISPropertyInputSourceIsSelected` reads the shared system-wide
    /// selection state instead, which isn't scoped to the caller.
    static func isJapaneseInputSourceActive() -> Bool {
        guard let listUnmanaged = TISCreateInputSourceList(nil, false) else { return false }
        guard let sources = listUnmanaged.takeRetainedValue() as? [TISInputSource] else { return false }

        for source in sources {
            guard let selectedPointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelected) else { continue }
            let isSelected = Unmanaged<CFBoolean>.fromOpaque(selectedPointer).takeUnretainedValue()
            guard CFBooleanGetValue(isSelected) else { continue }

            guard let idPointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { continue }
            let id = Unmanaged<CFString>.fromOpaque(idPointer).takeUnretainedValue() as String
            // Covers macOS's built-in Japanese IME identifiers (historically
            // "Kotoeri") across Romaji/Kana/Katakana input modes.
            return id.localizedCaseInsensitiveContains("japanese") || id.localizedCaseInsensitiveContains("kotoeri")
        }
        return false
    }
}

/// Publishes live changes to whether the active keyboard input source is
/// Japanese, so the Keyboard tab can enable/disable itself in real time
/// instead of only checking once when the tab appears.
final class InputSourceObserver: ObservableObject {
    @Published private(set) var isJapanese: Bool

    private var token: NSObjectProtocol?

    init() {
        isJapanese = InputSourceMonitor.isJapaneseInputSourceActive()
        token = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isJapanese = InputSourceMonitor.isJapaneseInputSourceActive()
        }
    }

    deinit {
        if let token {
            DistributedNotificationCenter.default().removeObserver(token)
        }
    }
}
