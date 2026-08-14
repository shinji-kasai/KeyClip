//
//  FloatingPanel.swift
//  KeyClip
//

import AppKit
import SwiftUI
import SwiftData
import Combine

/// A borderless, non-activating panel that overlays the frontmost app without
/// stealing its activation (mirrors Spotlight/Raycast-style summon panels).
final class FloatingPanel: NSPanel {
    private var themeCancellable: AnyCancellable?

    convenience init(
        modelContainer: ModelContainer,
        inject: @escaping (String) -> Void,
        copyToClipboard: @escaping (String) -> Void,
        copyImageToClipboard: @escaping (Data) -> Void,
        hidePanel: @escaping () -> Void,
        captureText: @escaping () -> Void
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
            .environment(\.copyImageToClipboard, copyImageToClipboard)
            .environment(\.hidePanel, hidePanel)
            .environment(\.captureText, captureText)
            .environmentObject(ThemeStore.shared)
            .environmentObject(TabSelectionStore.shared)
        contentView = NSHostingView(rootView: rootView)

        // `RootTabView`'s `.preferredColorScheme()` SwiftUI modifier sets the
        // *environment* color scheme for SwiftUI-rendered content, but
        // doesn't reliably cascade to native AppKit-bridged controls (a
        // `Picker`'s underlying pop-up button, in particular) when applied
        // inside the view hierarchy rather than at the window/scene level —
        // which is exactly how this app is built (a manually-hosted
        // `NSPanel`, not a `WindowGroup` scene). Setting the *window's*
        // `appearance` directly is the authoritative source native chrome
        // actually consults, so a dark custom theme reliably gets a
        // dark-styled Picker/dropdown instead of stale default-appearance
        // (black-on-dark) text. Reacts to `$background`, not `$selectedID`,
        // since a custom theme's background can change via a swatch edit
        // without `selectedID` itself changing (still the same theme's id
        // throughout an editing session).
        themeCancellable = ThemeStore.shared.$background
            .sink { [weak self] _ in
                self?.updateAppearance(colorScheme: ThemeStore.shared.preferredColorScheme)
            }
        updateAppearance(colorScheme: ThemeStore.shared.preferredColorScheme)
    }

    private func updateAppearance(colorScheme: ColorScheme?) {
        switch colorScheme {
        case .light: appearance = NSAppearance(named: .aqua)
        case .dark: appearance = NSAppearance(named: .darkAqua)
        case .none: appearance = nil
        @unknown default: appearance = nil
        }
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
