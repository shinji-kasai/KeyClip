//
//  FloatingPanel.swift
//  KeyClip
//

import AppKit
import SwiftUI
import SwiftData

/// A borderless, non-activating panel that overlays the frontmost app without
/// stealing its activation (mirrors Spotlight/Raycast-style summon panels).
final class FloatingPanel: NSPanel {
    convenience init(
        modelContainer: ModelContainer,
        inject: @escaping (String) -> Void,
        copyToClipboard: @escaping (String) -> Void
    ) {
        self.init(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 600),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView, .closable],
            backing: .buffered,
            defer: false
        )

        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        hidesOnDeactivate = false

        let rootView = RootTabView()
            .modelContainer(modelContainer)
            .environment(\.injectText, inject)
            .environment(\.copyToClipboard, copyToClipboard)
            .environmentObject(ThemeStore.shared)
            .environmentObject(TabSelectionStore.shared)
        contentView = NSHostingView(rootView: rootView)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Auto-hide when focus moves elsewhere (another app, the desktop, or the
    /// menu bar) — the panel is the app's only window, so losing key status
    /// normally means the user clicked outside it. The exception is a
    /// SwiftUI `.sheet()` (e.g. the Snippets add/edit sheet): that's a child
    /// window of this panel becoming key, not a click outside, so hiding here
    /// would rip the panel out from under its own sheet and corrupt the
    /// modal session (symptom: a grayed-out, unresponsive panel next time
    /// it's shown).
    override func resignKey() {
        super.resignKey()
        hideUnlessPresentingSheet()
    }

    /// Used for every path that hides the whole panel (auto-hide, toggling
    /// off, hiding after a copy/inject) so none of them can hide out from
    /// under an open sheet.
    func hideUnlessPresentingSheet() {
        guard sheets.isEmpty else { return }
        orderOut(nil)
    }
}
