# KeyClip

## Overview

KeyClip is a macOS menu-bar keyboard/clipboard utility. It lives in the menu
bar (no Dock icon) and is summoned via a global hotkey into a floating panel
overlaid on top of whatever app is frontmost — think Raycast/Alfred/Maccy.
The panel hosts a tab bar (Clipboard, Snippets, Symbols, Settings); clicking
content in Clipboard/Snippets/Symbols copies it to the system pasteboard and
hands focus back to the app you were in, ready for ⌘V. Full product spec,
fixed constraints, and the milestone roadmap live in `docs/SPEC.md` — read
that before assuming a feature is missing or before re-deriving scope in
conversation.

**Current status: Milestones 1–3 are complete and in the app** (Foundation +
Clipboard, Snippets, Symbols). **Milestones 4 (Developer) and 5 (Keyboard +
width conversion) were built in full and then removed entirely per explicit
user request** — do not reintroduce a Developer or Keyboard tab, or a
`WidthConverter`/`InputSourceMonitor`/`DeveloperCatalog`/`FlowLayout` file,
unless the user asks again; see `docs/SPEC.md`'s §6/§7 and Milestone 4/5
entries for what they were and why they're gone (recoverable from git
history if ever needed). Remaining open scope (per-tab jump hotkeys, polish)
is Milestone 6 in `docs/SPEC.md`'s checklist.

Repo: https://github.com/shinji-kasai/KeyClip (public).

## Architecture

- **App shell**: `NSApplicationDelegateAdaptor`-based `AppDelegate`
  (`KeyClip/App/AppDelegate.swift`), not a SwiftUI `WindowGroup`. Sets
  `NSApp.setActivationPolicy(.accessory)` and owns an `NSStatusItem`.
- **Panel**: `KeyClip/App/FloatingPanel.swift` is a custom `NSPanel` subclass
  (`.nonactivatingPanel`, `canBecomeKey = true`, `canBecomeMain = false`,
  `level = .floating`) hosting a SwiftUI `NSHostingView`. **Deliberately not**
  SwiftUI's `MenuBarExtra` — that scene type has no supported way to be shown
  imperatively from a global-hotkey handler, only from clicking its own status
  item. Overrides `resignKey()` to auto-hide (`orderOut`) whenever it loses
  key status — since it's the app's only window, losing key status always
  means the user clicked another app, the desktop, or the menu bar.
- **Status item**: right-click shows a "Quit KeyClip" menu (left-click still
  toggles the panel) — an accessory app has no Dock icon/app menu, so this is
  the only quit path. A stale instance left running from a prior Xcode Run
  can lock the built binary and cause `CodeSign` failures on the next build;
  quit it from here (or Activity Monitor) if that happens.
- **Global hotkeys**: `KeyClip/Services/HotKeyManager.swift` wraps Carbon's
  `RegisterEventHotKey`/`InstallEventHandler`. Chosen over a `CGEventTap`
  specifically because a tap needs Accessibility trust just to register —
  chicken-and-egg for an app that isn't trusted yet. `HotKeyBinding` is
  `Codable`/`RawRepresentable` (JSON-string-backed) so it works directly as an
  `@AppStorage` value.
- **Text injection vs. keystroke listening** — two distinct mechanisms, two
  distinct TCC permission categories:
  - `KeyClip/Services/TextInjector.swift` *posts* synthetic `CGEvent`s (gated
    by **Accessibility** trust, `AccessibilityPermission.swift`). `inject(_:into:)`
    reactivates a specific app first (used by the panel's direct-insert flows,
    not currently wired to any tab — see below); `typeText`/`deleteBackward`
    post directly with no reactivation step (used by the snippet expansion
    engine, where focus is already correct). All posted events are tagged
    with `TextInjector.syntheticEventMarker` via the `eventSourceUserData`
    field so listeners can recognize and ignore KeyClip's own output.
  - `KeyClip/Services/SnippetExpansionEngine.swift` *listens* system-wide via
    a listen-only `CGEventTap` (gated by the separate **Input Monitoring**
    category, `InputMonitoringPermission.swift` — `IOHIDCheckAccess`/
    `IOHIDRequestAccess`, not `AXIsProcessTrustedWithOptions`). It keeps a
    ~40-character rolling buffer of typed text, checks it against registered
    snippet triggers on every keystroke, and on a match deletes the trigger
    and types the expansion via `TextInjector`. It skips any event tagged
    with `syntheticEventMarker` so its own output doesn't feed back into the
    buffer or re-trigger.
  - **Clipboard/Snippets/Symbols click-to-use their content via
    `copyToClipboard`**, not `TextInjector` — the environment closure
    (`Features/Shared/InjectionEnvironment.swift`) writes to
    `NSPasteboard.general` and reactivates the previously-frontmost app so
    the user presses ⌘V themselves. This replaced an earlier
    auto-typed-injection approach: copy+paste is faster, doesn't mangle long
    or unicode-heavy text, and needs no Accessibility permission for that
    path. `injectText`/`TextInjector.inject` is still wired into the
    environment but currently unused by any tab — kept for a future direct-
    insert use case, not dead code to remove reflexively.
- **Persistence**:
  - `ClipboardItem` and `Snippet` (`KeyClip/Models/`) are SwiftData `@Model`s.
    Clipboard favorites/pinned are flags on the same row (not a separate
    entity) to avoid duplicate-content rows; pruning explicitly skips
    pinned/favorite rows. `Snippet.category` is a flat string (not a fully
    editable nested tree) — the Snippets tab groups rows by this value.
  - The `ModelContainer` is built once in `AppDelegate` with an **explicit**
    store URL (`~/Library/Application Support/KeyClip/KeyClip.store`) and
    injected via `.modelContainer(container)` on the view passed into
    `NSHostingView`. Do not switch this back to an unnamed
    `ModelContainer(for:)` — KeyClip is unsandboxed, so `Application Support`
    is shared with every other unsandboxed app on the machine, and the
    unnamed default resolves to a generic `default.store` filename with no
    per-app scoping. That caused a real data-loss bug (a favorited item got
    reset) from a collision with another unsandboxed SwiftData app on the
    same machine.
  - `ClipboardMonitor` polls `NSPasteboard.general.changeCount` every 0.5s
    (macOS has no push-based clipboard-change API), dedups by bumping
    `createdAt` on identical content, and prunes non-pinned/non-favorite
    history beyond 200 items.
  - Settings (tab visibility, hotkey binding) live directly in
    `@AppStorage` — no separate settings object; `RootTabView` reads the
    visibility flags reactively to filter the tab bar live.
- **Tabs**: `FeatureTab` (`KeyClip/Features/TabBar/FeatureTab.swift`) is the
  single source of truth for tab identity/icon/visibility key (`title` is the
  short label shown in the tab bar — e.g. "Clip" — not necessarily the full
  feature name). Current cases: `clipboard, snippets, symbols, settings`.
  `Settings` is the only case that's always visible. `RootTabView`
  filters+switches on it and shows a header ("KeyClip vX.Y") above the tab
  bar.

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
   access via the "Open System Settings" button (needed for future
   direct-insert tabs and for snippet expansion's substitution step) and
   Input Monitoring access via "Grant Access" (needed for snippet
   typing-triggers to be observed at all).
5. To run it like a normal app instead of from Xcode: Product → Show Build
   Folder in Finder → `Build/Products/Release/KeyClip.app` (Release build) →
   copy to `/Applications`. First launch will show Gatekeeper's "unidentified
   developer" warning (expected, not notarized) — right-click → Open once.

## Verifying changes

There's no test target yet (M1 scope didn't call for one). Verify manually:
build & run, confirm the hotkey/menu-bar icon work, copy text elsewhere and
confirm it lands in the Clipboard tab, click it and confirm it's typed into
the app you copied it from.
