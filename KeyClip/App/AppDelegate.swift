//
//  AppDelegate.swift
//  KeyClip
//

import AppKit
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panel: FloatingPanel?
    private var clipboardMonitor: ClipboardMonitor?
    private var previouslyFrontmostApp: NSRunningApplication?

    /// KeyClip is unsandboxed, so — unlike a sandboxed app, which gets its own
    /// isolated Application Support directory for free — `Application Support`
    /// here is shared with every other unsandboxed app on the machine. An
    /// unnamed `ModelContainer(for:)` defaults to a generic `default.store`
    /// filename with no app-specific scoping, so it can collide with any other
    /// unsandboxed SwiftData app's default store. Must use an explicit,
    /// app-scoped store location instead.
    let modelContainer: ModelContainer = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = appSupport.appendingPathComponent("KeyClip", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let storeURL = directory.appendingPathComponent("KeyClip.store")
        let configuration = ModelConfiguration(url: storeURL)
        do {
            return try ModelContainer(for: ClipboardItem.self, Snippet.self, SymbolUsage.self, configurations: configuration)
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
        setupDoubleCommandTap()
        SnippetExpansionEngine.shared.start(modelContext: modelContainer.mainContext)
        NowPlayingMonitor.shared.start()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "paperclip", accessibilityDescription: "KeyClip")
        item.button?.action = #selector(statusItemClicked)
        item.button?.target = self
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem = item
    }

    private func setupPanel() {
        panel = FloatingPanel(
            modelContainer: modelContainer,
            inject: { [weak self] text in
                self?.injectAndHide(text)
            },
            copyToClipboard: { [weak self] text in
                self?.copyAndHide(text)
            }
        )
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
        let binding = stored.flatMap { HotKeyBinding(rawValue: $0) } ?? .defaultOpenPanel
        HotKeyManager.shared.updateBinding(binding)
    }

    private func setupDoubleCommandTap() {
        DoubleCommandTapDetector.shared.setHandler { [weak self] in
            self?.togglePanel()
        }
        let enabled = UserDefaults.standard.object(forKey: DoubleCommandTapDetector.enabledDefaultsKey) as? Bool ?? true
        if enabled {
            DoubleCommandTapDetector.shared.start()
        }
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent, event.type == .rightMouseUp else {
            togglePanel()
            return
        }
        showStatusMenu()
    }

    private func showStatusMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Check for Updates…", action: #selector(checkForUpdatesFromMenu), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit KeyClip", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        // Clear the menu afterward so a plain left-click goes back to togglePanel
        // instead of re-showing this menu (NSStatusItem can't have both an
        // action and a menu active on the button at the same time).
        statusItem?.menu = nil
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    @objc private func checkForUpdatesFromMenu() {
        Task { @MainActor in
            let result = await UpdateChecker.checkForUpdate()
            let alert = NSAlert()
            switch result {
            case .upToDate:
                alert.messageText = "You're up to date"
                alert.informativeText = "KeyClip \(UpdateChecker.currentVersion()) is the latest version."
                alert.addButton(withTitle: "OK")
                alert.runModal()
            case .updateAvailable(let info):
                alert.messageText = "Update Available"
                alert.informativeText = "KeyClip \(info.version) is available. You're on \(UpdateChecker.currentVersion())."
                alert.addButton(withTitle: "View Release")
                alert.addButton(withTitle: "Later")
                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(info.url)
                }
            case .failed:
                alert.messageText = "Couldn't Check for Updates"
                alert.informativeText = "Check your internet connection and try again."
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }

    private func togglePanel() {
        guard let panel else { return }
        if panel.isVisible {
            panel.hideUnlessPresentingSheet()
        } else {
            previouslyFrontmostApp = NSWorkspace.shared.frontmostApplication
            TabSelectionStore.shared.resetToDefault()
            positionPanelNearStatusItem(panel)
            panel.makeKeyAndOrderFront(nil)
        }
    }

    private func injectAndHide(_ text: String) {
        let target = previouslyFrontmostApp
        panel?.hideUnlessPresentingSheet()
        TextInjector.inject(text, into: target)
    }

    /// Puts `text` on the system pasteboard, hands focus back to whatever
    /// app was frontmost before the panel opened, and — as long as Settings
    /// → Startup & Behavior's "Auto-Paste on Select" is on (the default) and
    /// Accessibility trust is granted — posts a synthetic ⌘V so it lands
    /// there immediately, no manual ⌘V needed. Still copy+paste under the
    /// hood rather than typing the text out via simulated keystrokes, so
    /// long/unicode-heavy content isn't at risk of mangling; only the
    /// trailing paste keystroke is synthetic. With auto-paste off, or
    /// without Accessibility trust, this still reactivates the target app
    /// and leaves the content on the pasteboard for a manual ⌘V.
    private func copyAndHide(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        let target = previouslyFrontmostApp
        panel?.hideUnlessPresentingSheet()
        let autoPasteEnabled = UserDefaults.standard.object(forKey: TextInjector.autoPasteDefaultsKey) as? Bool ?? true
        if autoPasteEnabled {
            TextInjector.pasteFromClipboard(into: target)
        } else {
            target?.activate(options: [])
        }
    }

    private func positionPanelNearStatusItem(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - panel.frame.width / 2
        let y = screenFrame.maxY - panel.frame.height - 8
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
