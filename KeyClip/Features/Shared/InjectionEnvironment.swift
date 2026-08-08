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

extension EnvironmentValues {
    var injectText: (String) -> Void {
        get { self[InjectTextKey.self] }
        set { self[InjectTextKey.self] = newValue }
    }

    var copyToClipboard: (String) -> Void {
        get { self[CopyToClipboardKey.self] }
        set { self[CopyToClipboardKey.self] = newValue }
    }
}
