//
//  InjectionEnvironment.swift
//  KeyClip
//

import SwiftUI

/// Lets any tab (Clipboard now, later Snippets/Symbols/Developer/Keyboard)
/// request text be injected into the previously-frontmost app, without
/// needing a reference to the panel or `AppDelegate`.
private struct InjectTextKey: EnvironmentKey {
    static let defaultValue: (String) -> Void = { _ in }
}

extension EnvironmentValues {
    var injectText: (String) -> Void {
        get { self[InjectTextKey.self] }
        set { self[InjectTextKey.self] = newValue }
    }
}
