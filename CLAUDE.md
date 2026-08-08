# KeyClip

## Overview

KeyClip is a macOS menu-bar keyboard/clipboard utility. It lives in the menu
bar (no Dock icon) and is summoned via a global hotkey into a floating panel
overlaid on top of whatever app is frontmost — think Raycast/Alfred/Maccy.
The panel hosts a tab bar (Clipboard, Snippets, Symbols, Developer, Keyboard,
Settings); clicking content in any tab types/inserts it into the app the user
was just in. Full product spec, fixed constraints, and the milestone roadmap
live in `docs/SPEC.md` — read that before assuming a feature is missing or
before re-deriving scope in conversation.

**Current status: Milestone 1 (Foundation + Clipboard) is complete.**
Snippets/Symbols/Developer/Keyboard are wired-in placeholder tabs — see
`docs/SPEC.md`'s milestone checklist for what's next.

## Architecture

- **App shell**: `NSApplicationDelegateAdaptor`-based `AppDelegate`
  (`KeyClip/App/AppDelegate.swift`), not a SwiftUI `WindowGroup`. Sets
  `NSApp.setActivationPolicy(.accessory)` and owns an `NSStatusItem`.
- **Panel**: `KeyClip/App/FloatingPanel.swift` is a custom `NSPanel` subclass
  (`.nonactivatingPanel`, `canBecomeKey = true`, `canBecomeMain = false`,
  `level = .floating`) hosting a SwiftUI `NSHostingView`. **Deliberately not**
  SwiftUI's `MenuBarExtra` — that scene type has no supported way to be shown
  imperatively from a global-hotkey handler, only from clicking its own status
  item.
- **Global hotkeys**: `KeyClip/Services/HotKeyManager.swift` wraps Carbon's
  `RegisterEventHotKey`/`InstallEventHandler`. Chosen over a `CGEventTap`
  specifically because a tap needs Accessibility trust just to register —
  chicken-and-egg for an app that isn't trusted yet. `HotKeyBinding` is
  `Codable`/`RawRepresentable` (JSON-string-backed) so it works directly as an
  `@AppStorage` value.
- **Text injection**: `KeyClip/Services/TextInjector.swift` reactivates the
  previously-frontmost app (captured by `AppDelegate` before the panel is
  shown) and posts `CGEvent`s built via `keyboardSetUnicodeString`, chunked
  into ~20 UTF-16 units per event pair (the API silently truncates longer
  strings). No-ops if Accessibility isn't trusted
  (`KeyClip/Services/AccessibilityPermission.swift` gates this). This service
  is shared by every tab that inserts content — not Clipboard-specific.
- **Persistence**:
  - `ClipboardItem` (`KeyClip/Models/ClipboardItem.swift`) is a SwiftData
    `@Model`. Favorites/pinned are flags on the same row (not a separate
    entity) to avoid duplicate-content rows; pruning explicitly skips
    pinned/favorite rows.
  - The `ModelContainer` is built once in `AppDelegate` and injected via
    `.modelContainer(container)` on the view passed into `NSHostingView` —
    there's no SwiftUI `Scene` hosting the UI, so the `.modelContainer(for:)`
    scene modifier isn't available.
  - `ClipboardMonitor` polls `NSPasteboard.general.changeCount` every 0.5s
    (macOS has no push-based clipboard-change API), dedups by bumping
    `createdAt` on identical content, and prunes non-pinned/non-favorite
    history beyond 200 items.
  - Settings (tab visibility, hotkey binding) live directly in
    `@AppStorage` — no separate settings object; `RootTabView` reads the
    visibility flags reactively to filter the tab bar live.
- **Tabs**: `FeatureTab` (`KeyClip/Features/TabBar/FeatureTab.swift`) is the
  single source of truth for tab identity/icon/visibility key. `Settings` is
  the only case that's always visible. `RootTabView` filters+switches on it;
  adding a real view for a currently-placeholder tab is a one-line swap in
  that switch statement.

## Conventions

- File layout: `App/` (app lifecycle/shell), `Services/` (hotkeys,
  accessibility, injection, clipboard monitor — stateless-ish singletons/
  services), `Models/` (SwiftData models), `Features/<Tab>/` (per-tab views),
  `Features/Shared/` (cross-tab views/environment plumbing).
- `KeyClip/` is a `PBXFileSystemSynchronizedRootGroup` in the Xcode project —
  any `.swift` file added anywhere under `KeyClip/` on disk is automatically
  picked up by the target. No manual `project.pbxproj` group editing needed
  for new source files (only build-setting changes need pbxproj edits).
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is set project-wide; most types
  don't need explicit `@MainActor` annotations.
- Not sandboxed (`ENABLE_APP_SANDBOX = NO`) and `INFOPLIST_KEY_LSUIElement =
  YES` — both are build settings directly in `project.pbxproj` (the project
  uses Xcode's synthesized Info.plist/entitlements, so there's no physical
  `Info.plist` or `.entitlements` file to edit).

## Build & run

1. Open `KeyClip.xcodeproj` in Xcode.
2. Signing & Capabilities → set **Team** to your personal Apple ID (Personal
   Team). Keep `CODE_SIGN_STYLE = Automatic`. A stable signing identity
   matters here: TCC ties the Accessibility grant to the app's signature, so
   an unstable/no-team identity can make the grant appear to reset on every
   rebuild.
3. Build & Run. Confirm no Dock icon appears and no window auto-opens — a
   menu bar icon should appear instead.
4. Press ⌘⇧V (default) to summon the panel. In Settings, grant Accessibility
   access via the "Open System Settings" button, enable KeyClip, come back.
5. To run it like a normal app instead of from Xcode: Product → Show Build
   Folder in Finder → `Build/Products/Release/KeyClip.app` (Release build) →
   copy to `/Applications`. First launch will show Gatekeeper's "unidentified
   developer" warning (expected, not notarized) — right-click → Open once.

## Verifying changes

There's no test target yet (M1 scope didn't call for one). Verify manually:
build & run, confirm the hotkey/menu-bar icon work, copy text elsewhere and
confirm it lands in the Clipboard tab, click it and confirm it's typed into
the app you copied it from.
