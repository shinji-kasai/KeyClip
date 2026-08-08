//
//  InputMonitoringPermission.swift
//  KeyClip
//

import IOKit.hid
import AppKit

/// A global keystroke *listener* (`SnippetExpansionEngine`'s `CGEventTap`) is
/// gated by "Input Monitoring" — a separate TCC category from Accessibility,
/// which only gates keystroke/click *injection* and UI automation.
enum InputMonitoringPermission {
    static var isTrusted: Bool {
        IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
    }

    /// Triggers the native system consent prompt (only works the first time;
    /// once denied, macOS requires the user to flip it on manually).
    @discardableResult
    static func requestAccess() -> Bool {
        IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
    }

    static func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") else { return }
        NSWorkspace.shared.open(url)
    }
}
