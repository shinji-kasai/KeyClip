//
//  HotKeyRecorderView.swift
//  KeyClip
//

import SwiftUI
import AppKit
import Carbon.HIToolbox

/// A click-to-record control for a global shortcut. Reads raw `NSEvent`
/// keyCode/modifierFlags directly (not SwiftUI's character-based `.onKeyPress`,
/// which would need a reverse `UCKeyTranslate` lookup to get back to the
/// virtual keycodes Carbon's `RegisterEventHotKey` needs).
struct HotKeyRecorderView: NSViewRepresentable {
    @Binding var binding: HotKeyBinding

    func makeNSView(context: Context) -> RecorderNSView {
        let view = RecorderNSView()
        view.onCapture = { keyCode, modifiers in
            binding = HotKeyBinding(keyCode: keyCode, modifiers: modifiers)
        }
        view.currentBinding = binding
        return view
    }

    func updateNSView(_ nsView: RecorderNSView, context: Context) {
        nsView.currentBinding = binding
    }
}

final class RecorderNSView: NSView {
    var onCapture: ((UInt32, UInt32) -> Void)?
    var currentBinding: HotKeyBinding? {
        didSet { needsDisplay = true }
    }
    private var isRecording = false {
        didSet { needsDisplay = true }
    }

    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 140, height: 28) }

    override func becomeFirstResponder() -> Bool {
        isRecording = true
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        return super.resignFirstResponder()
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        var carbonModifiers: UInt32 = 0
        let flags = event.modifierFlags
        if flags.contains(.control) { carbonModifiers |= UInt32(controlKey) }
        if flags.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if flags.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
        if flags.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        guard carbonModifiers != 0 else { return }
        onCapture?(UInt32(event.keyCode), carbonModifiers)
        window?.makeFirstResponder(nil)
    }

    override func draw(_ dirtyRect: NSRect) {
        let background: NSColor = isRecording ? NSColor.controlAccentColor.withAlphaComponent(0.2) : NSColor.controlBackgroundColor
        background.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6).fill()

        let text = isRecording ? "Press keys…" : (currentBinding?.displayString ?? "Not Set")
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.labelColor,
            .font: NSFont.systemFont(ofSize: 13),
        ]
        let size = text.size(withAttributes: attributes)
        let point = NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2)
        text.draw(at: point, withAttributes: attributes)
    }
}
