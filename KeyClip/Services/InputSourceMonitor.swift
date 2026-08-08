//
//  InputSourceMonitor.swift
//  KeyClip
//

import Carbon.HIToolbox
import Foundation
import Combine

enum InputSourceMonitor {
    static func isJapaneseInputSourceActive() -> Bool {
        guard let sourceUnmanaged = TISCopyCurrentKeyboardInputSource() else { return false }
        let source = sourceUnmanaged.takeRetainedValue()
        guard let idPointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return false }
        let id = Unmanaged<CFString>.fromOpaque(idPointer).takeUnretainedValue() as String
        // Covers macOS's built-in Japanese IME identifiers (historically
        // "Kotoeri") across Romaji/Kana/Katakana input modes.
        return id.localizedCaseInsensitiveContains("japanese") || id.localizedCaseInsensitiveContains("kotoeri")
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
