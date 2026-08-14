//
//  InjectionEnvironment.swift
//  KeyClip
//

import SwiftUI

/// Lets any tab (later Snippets/Symbols/Developer/Keyboard) request text be
/// typed directly into the previously-frontmost app via `TextInjector`,
/// without needing a reference to the panel or `AppDelegate`.
private struct InjectTextKey: EnvironmentKey {
    static let defaultValue: (String) -> Void = { _ in }
}

/// Lets a tab (Clipboard) put text on the system pasteboard and hand focus
/// back to the previously-frontmost app, so the user can paste it themselves
/// (⌘V) rather than having it typed out via simulated keystrokes.
private struct CopyToClipboardKey: EnvironmentKey {
    static let defaultValue: (String) -> Void = { _ in }
}

/// Lets a view (Now Playing's artwork tap) explicitly hide the panel before
/// activating another app, rather than relying on `FloatingPanel.resignKey()`
/// firing as a side effect of that activation — which is the same
/// hide-then-activate order `AppDelegate.copyAndHide`/`injectAndHide` already
/// use, just exposed directly since jumping to the Now Playing source app
/// doesn't go through either of those (it doesn't put anything on the
/// pasteboard or inject text).
private struct HidePanelKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var injectText: (String) -> Void {
        get { self[InjectTextKey.self] }
        set { self[InjectTextKey.self] = newValue }
    }

    var copyToClipboard: (String) -> Void {
        get { self[CopyToClipboardKey.self] }
        set { self[CopyToClipboardKey.self] = newValue }
    }

    var hidePanel: () -> Void {
        get { self[HidePanelKey.self] }
        set { self[HidePanelKey.self] = newValue }
    }
}
