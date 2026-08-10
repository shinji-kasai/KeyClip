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

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var lastCommandDownTime: Date?
    private var previousFlags: NSEvent.ModifierFlags = []
    private var handler: (() -> Void)?

    private init() {}

    func setHandler(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    /// A global monitor alone only sees taps while some *other* app is
    /// frontmost — it never receives events targeted at KeyClip's own
    /// windows (per `NSEvent.addGlobalMonitorForEvents` docs). Once the
    /// panel opens and becomes key, KeyClip itself is the focused app, so a
    /// second double-tap meant to close the panel would go unseen without a
    /// local monitor too. The two are mutually exclusive (an event targets
    /// either this app or another one), so combining them covers both
    /// directions of the toggle with no risk of double-firing.
    func start() {
        guard globalMonitor == nil else { return }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        globalMonitor = nil
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        localMonitor = nil
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
