//
//  KeyClipApp.swift
//  KeyClip
//

import SwiftUI

@main
struct KeyClipApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
