//
//  ScreenRecordingPermission.swift
//  KeyClip
//

import CoreGraphics
import AppKit

/// Gates `TextCaptureService`'s use of `/usr/sbin/screencapture` — a
/// subprocess invocation of screencapture still ties the Screen Recording
/// check to the calling (parent) app, not just the immediate process,
/// confirmed empirically while building this (a plain `screencapture -x`
/// run from a shell without this permission fails with "could not create
/// image from display" — the same failure mode either way, parent or not).
enum ScreenRecordingPermission {
    static var isTrusted: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Triggers the native system consent prompt (only works the first
    /// time; once denied, macOS requires the user to flip it on manually).
    @discardableResult
    static func requestAccess() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    static func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else { return }
        NSWorkspace.shared.open(url)
    }
}
