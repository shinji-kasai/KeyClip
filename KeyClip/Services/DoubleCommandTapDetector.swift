//
//  DoubleCommandTapDetector.swift
//  KeyClip
//

import AppKit

/// Detects two Command-key presses in quick succession, with no other key
/// pressed in between. Carbon's `RegisterEventHotKey` (used by
/// `HotKeyManager`) can't represent this — it needs a real virtual key plus
/// modifiers, and a bare modifier tap never fires a "hotkey pressed" event
/// through that channel. This instead watches `.flagsChanged` events via a
/// global `NSEvent` monitor, which (like `TextInjector`'s posting) is gated
/// by Accessibility trust for key-related events from other apps — no new
/// permission category needed beyond what KeyClip already requests.
final class DoubleCommandTapDetector {
    static let shared = DoubleCommandTapDetector()
    static let enabledDefaultsKey = "doubleCommandTapEnabled"

    /// Max gap between the two taps to count as a double-tap.
    private let threshold: TimeInterval = 0.35

    private var monitor: Any?
    private var lastCommandDownTime: Date?
    private var previousFlags: NSEvent.ModifierFlags = []
    private var handler: (() -> Void)?

    private init() {}

    func setHandler(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(event)
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    private func handle(_ event: NSEvent) {
        let relevant = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        defer { previousFlags = relevant }

        // Only care about the rising edge of Command being pressed.
        guard relevant.contains(.command), !previousFlags.contains(.command) else { return }

        // Command held alongside another modifier (⌘⇧, ⌘⌥, ...) is presumably
        // part of some other shortcut, not a deliberate bare-Command tap —
        // don't let it count toward (or falsely complete) a double-tap.
        guard relevant == .command else {
            lastCommandDownTime = nil
            return
        }

        let now = Date()
        if let last = lastCommandDownTime, now.timeIntervalSince(last) <= threshold {
            lastCommandDownTime = nil
            handler?()
        } else {
            lastCommandDownTime = now
        }
    }
}
