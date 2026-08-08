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
    convenience init(modelContainer: ModelContainer, inject: @escaping (String) -> Void) {
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
        contentView = NSHostingView(rootView: rootView)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
