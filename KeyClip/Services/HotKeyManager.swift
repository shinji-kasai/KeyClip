//
//  HotKeyManager.swift
//  KeyClip
//

import Carbon.HIToolbox
import Foundation

/// A user-remappable global shortcut, persisted via `@AppStorage` (RawRepresentable as JSON).
struct HotKeyBinding: Codable, Equatable, RawRepresentable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let openPanelDefaultsKey = "openPanelHotKey"
    static let defaultOpenPanel = HotKeyBinding(keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(cmdKey | shiftKey))

    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(HotKeyBinding.self, from: data) else { return nil }
        self = decoded
    }

    var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let string = String(data: data, encoding: .utf8) else { return "" }
        return string
    }

    var displayString: String {
        var symbols = ""
        if modifiers & UInt32(controlKey) != 0 { symbols += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { symbols += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { symbols += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { symbols += "⌘" }
        return symbols + KeyCodeNames.name(for: keyCode)
    }
}

enum KeyCodeNames {
    private static let names: [UInt32: String] = [
        UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B", UInt32(kVK_ANSI_C): "C", UInt32(kVK_ANSI_D): "D",
        UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F", UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H",
        UInt32(kVK_ANSI_I): "I", UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
        UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N", UInt32(kVK_ANSI_O): "O", UInt32(kVK_ANSI_P): "P",
        UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R", UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T",
        UInt32(kVK_ANSI_U): "U", UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
        UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z", UInt32(kVK_Space): "Space",
    ]

    static func name(for keyCode: UInt32) -> String {
        names[keyCode] ?? "Key\(keyCode)"
    }
}

/// Thin wrapper around the Carbon Event Manager for a single system-wide hotkey.
///
/// Carbon's `RegisterEventHotKey` (not a `CGEventTap`) is used deliberately: a tap
/// would require Accessibility trust just to register the hotkey used to *grant*
/// that trust in the first place.
final class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var handler: (() -> Void)?
    private let signature: FourCharCode = 0x4B79436C // "KyCl"

    private init() {
        installEventHandler()
    }

    func setHandler(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    func updateBinding(_ binding: HotKeyBinding) {
        unregister()
        var newRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        RegisterEventHotKey(binding.keyCode, binding.modifiers, hotKeyID, GetApplicationEventTarget(), 0, &newRef)
        hotKeyRef = newRef
    }

    private func unregister() {
        guard let ref = hotKeyRef else { return }
        UnregisterEventHotKey(ref)
        hotKeyRef = nil
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, eventRef, userData in
            guard let userData, let eventRef else { return noErr }
            var hotKeyID = EventHotKeyID()
            GetEventParameter(eventRef, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            if hotKeyID.id == 1 {
                manager.handler?()
            }
            return noErr
        }, 1, &eventType, selfPointer, &eventHandlerRef)
    }
}
