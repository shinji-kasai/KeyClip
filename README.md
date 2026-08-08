# KeyClip

A macOS menu-bar keyboard/clipboard utility. It lives in the menu bar (no
Dock icon) and is summoned via a global hotkey into a floating panel
overlaid on top of whatever app you're using — think Raycast/Alfred/Maccy.

## Features

- **Clipboard** — automatic copy history, search, favorites, click-to-copy
  (writes to the system pasteboard and hands focus back to the app you were
  in, ready for ⌘V)
- **Snippets** — text-expansion: type a trigger like `;email` anywhere and
  it expands to canned text, plus a browsable/searchable snippet library
  organized by category
- **Symbols** — a categorized palette of special characters (arrows, math,
  science, Greek) with favorites and a usage-frequency-ranked "Recently
  Used" section
- **Theming** — 9 built-in presets (including a Matrix mode) plus fully
  custom colors for background, text, hover, and selection
- **Two ways to summon the panel** — the default hotkey (⌘⇧V, remappable)
  or by double-tapping ⌘
- **Update checking** — Settings → Updates, or right-click the menu bar
  icon, checks GitHub for a newer release

## Installing

1. Download the latest release from the
   [Releases page](https://github.com/shinji-kasai/KeyClip/releases)
2. Unzip it and drag `KeyClip.app` to `/Applications`
3. **Right-click → Open** the first time — this build isn't notarized (no
   paid Apple Developer account), so Gatekeeper will otherwise block it as
   "unidentified developer"; right-click Open bypasses that one-time warning
4. Grant **Accessibility** and **Input Monitoring** access when prompted
   (Settings tab in the app) — needed for pasting and for snippet
   typing-triggers to work

## Building from source

1. Open `KeyClip.xcodeproj` in Xcode
2. Signing & Capabilities → set **Team** to your own Apple ID
3. Build & Run — you should see a menu bar icon appear, no Dock icon and no
   window
4. Press ⌘⇧V (or double-tap ⌘) to summon the panel

## Releasing

Push a tag matching `v*` (e.g. `git tag v1.0.1 && git push origin v1.0.1`)
and a GitHub Actions workflow (`.github/workflows/release.yml`) builds a
universal binary (Apple Silicon + Intel), ad-hoc signs it, zips it, and
publishes a GitHub Release automatically.

## Architecture (brief)

- Accessory app (`NSApplicationDelegateAdaptor`), no `WindowGroup` — the UI
  is a custom non-activating `NSPanel` hosting SwiftUI content, summoned
  from a global hotkey (Carbon `RegisterEventHotKey`) and a double-⌘-tap
  detector (`NSEvent` global monitor).
- Clipboard/Snippets/Symbols data is SwiftData, stored at an explicit,
  app-scoped path under `~/Library/Application Support/KeyClip/`.
- Snippet typing-triggers are detected via a listen-only `CGEventTap`
  (Input Monitoring permission); clicking content to use it writes to the
  system pasteboard (`NSPasteboard`) rather than simulating keystrokes.
- Not sandboxed, not App Store distributed — a personal-use build signed to
  run locally.

## Not currently included

Two tabs (Developer keyword palette, and a Keyboard/Japanese width
conversion panel) were built and then removed by request. They may return
in a future version.
