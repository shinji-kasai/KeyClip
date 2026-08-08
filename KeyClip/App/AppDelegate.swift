//
//  AppDelegate.swift
//  KeyClip
//

import AppKit
import SwiftData

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panel: FloatingPanel?
    private var clipboardMonitor: ClipboardMonitor?
    private var previouslyFrontmostApp: NSRunningApplication?

    let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: ClipboardItem.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPanel()
        setupClipboardMonitor()
        setupHotKey()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "KeyClip")
        item.button?.action = #selector(togglePanel)
        item.button?.target = self
        statusItem = item
    }

    private func setupPanel() {
        panel = FloatingPanel(modelContainer: modelContainer, inject: { [weak self] text in
            self?.injectAndHide(text)
        })
    }

    private func setupClipboardMonitor() {
        let monitor = ClipboardMonitor(modelContext: modelContainer.mainContext)
        monitor.start()
        clipboardMonitor = monitor
    }

    private func setupHotKey() {
        HotKeyManager.shared.setHandler { [weak self] in
            self?.togglePanel()
        }
        let stored = UserDefaults.standard.string(forKey: HotKeyBinding.openPanelDefaultsKey)
        let binding = stored.flatMap(HotKeyBinding.init(rawValue:)) ?? .defaultOpenPanel
        HotKeyManager.shared.updateBinding(binding)
    }

    @objc private func togglePanel() {
        guard let panel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            previouslyFrontmostApp = NSWorkspace.shared.frontmostApplication
            positionPanelNearStatusItem(panel)
            panel.makeKeyAndOrderFront(nil)
        }
    }

    private func injectAndHide(_ text: String) {
        let target = previouslyFrontmostApp
        panel?.orderOut(nil)
        TextInjector.inject(text, into: target)
    }

    private func positionPanelNearStatusItem(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - panel.frame.width / 2
        let y = screenFrame.maxY - panel.frame.height - 8
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
