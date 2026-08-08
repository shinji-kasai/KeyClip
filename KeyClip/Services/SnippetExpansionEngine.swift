//
//  SnippetExpansionEngine.swift
//  KeyClip
//

import AppKit
import CoreGraphics
import Carbon.HIToolbox
import SwiftData

/// Watches keystrokes system-wide via a *listen-only* `CGEventTap` (it never
/// blocks or modifies the user's actual typing) for a match against any
/// registered snippet trigger, then deletes the just-typed trigger and types
/// its expansion in its place.
///
/// This is a distinct mechanism from `TextInjector`: that one *posts*
/// synthetic keystrokes (gated by Accessibility trust); this one *observes*
/// real keystrokes system-wide (gated by the separate Input Monitoring TCC
/// category). Events this engine's own expansion posts are tagged with
/// `TextInjector.syntheticEventMarker` so they're ignored here instead of
/// feeding back into the trigger-matching buffer.
final class SnippetExpansionEngine {
    static let shared = SnippetExpansionEngine()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var modelContext: ModelContext?
    private var triggers: [String: String] = [:]
    private var buffer = ""
    private let bufferLimit = 40

    private init() {}

    /// Safe to call repeatedly (once at launch, then again after the user
    /// grants Input Monitoring access from Settings) — no-ops if a tap is
    /// already running or permission still isn't granted.
    func start(modelContext: ModelContext) {
        self.modelContext = modelContext
        refreshTriggers()

        guard eventTap == nil else { return }
        guard InputMonitoringPermission.isTrusted else { return }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let engine = Unmanaged<SnippetExpansionEngine>.fromOpaque(refcon).takeUnretainedValue()
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    engine.reenable()
                } else {
                    engine.handle(event)
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return }

        eventTap = tap
        if let source = CFMachPortCreateRunLoopSource(nil, tap, 0) {
            runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    /// Call after any Snippet is added/edited/deleted so new triggers take
    /// effect immediately.
    func refreshTriggers() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<Snippet>()
        let snippets = (try? modelContext.fetch(descriptor)) ?? []
        triggers = Dictionary(snippets.map { ($0.trigger, $0.content) }, uniquingKeysWith: { first, _ in first })
    }

    private func reenable() {
        guard let eventTap else { return }
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    private func handle(_ event: CGEvent) {
        // Ignore events we posted ourselves (backspace/expansion typing).
        guard event.getIntegerValueField(.eventSourceUserData) != TextInjector.syntheticEventMarker else { return }

        // A modified keystroke (⌘C, ⌃Space, etc.) isn't plain typing —
        // don't let it corrupt an in-progress trigger match.
        let flags = event.flags
        if flags.contains(.maskCommand) || flags.contains(.maskControl) || flags.contains(.maskAlternate) {
            buffer.removeAll()
            return
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        if keyCode == Int64(kVK_Delete) {
            if !buffer.isEmpty { buffer.removeLast() }
            return
        }
        if keyCode == Int64(kVK_Return) || keyCode == Int64(kVK_Tab) || keyCode == Int64(kVK_Escape) {
            buffer.removeAll()
            return
        }

        var length = 0
        var chars = [UniChar](repeating: 0, count: 4)
        event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &length, unicodeString: &chars)
        guard length > 0 else { return }
        buffer.append(String(utf16CodeUnits: chars, count: length))
        if buffer.count > bufferLimit {
            buffer.removeFirst(buffer.count - bufferLimit)
        }

        for (trigger, content) in triggers where !trigger.isEmpty && buffer.hasSuffix(trigger) {
            expand(trigger: trigger, content: content)
            break
        }
    }

    private func expand(trigger: String, content: String) {
        buffer.removeAll()
        // Post outside the tap callback's call stack rather than inline.
        DispatchQueue.main.async {
            TextInjector.deleteBackward(count: trigger.count)
            TextInjector.typeText(content)
        }
    }
}
