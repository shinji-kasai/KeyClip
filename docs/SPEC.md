# KeyClip — Full Feature Spec

Source of truth for what KeyClip is meant to become. Originally specified by the
user in Japanese; translated and organized here. Read this before assuming a
feature doesn't exist or before re-deriving scope from scratch — check the
milestone checklist at the bottom first.

## 1. Overall shape

A macOS keyboard/clipboard utility. Main UI is a tab bar:

```
[ Clip ] [ Snippets ] [ Symbols ] [ Settings ]
```

(Originally specified with two more tabs, Developer and Keyboard — both were
built in Milestones 4–5 and then **removed entirely** per explicit user
request; see the "Removed scope" note before the milestone checklist. The
rest of this section's "any feature can be hidden" behavior still applies to
the three remaining optional tabs.)

Each tab is a fully separate feature. In Settings, the user can turn any
feature OFF except Settings itself, and that tab disappears entirely from the
bar — unused features are never left cluttering the UI.

## 2. Clipboard (the core feature)

- Captures every copy made anywhere on the Mac into a searchable history list.
- Clicking an entry types/inserts it into whatever app was frontmost before
  the panel was summoned.
- Beyond raw history, supports Favorites/Pinned/Frequently-Used items saved
  separately (e.g. canned replies like "Thank you for your help.").

## 3. Snippets

- Text-expansion templates, kept separate from Clipboard history.
- Organized into user-defined categories, e.g.:
  ```
  General
  ├─ Email
  ├─ Address
  ├─ Work
  └─ Personal
  Developer
  ├─ Python
  ├─ JavaScript
  ├─ SQL
  └─ Git
  ```
- Typing a trigger like `;email` anywhere expands it to canned text (e.g.
  "Thank you for your email. I will get back to you shortly.").
- Users can register their own triggers/expansions.

## 4. Symbols

- Browsable/searchable palette of characters that are hard to type on a
  normal keyboard: arrows (← → ↑ ↓ ↔ ↕ ⇐ ⇒), check/star marks (✓ ✕ ★ ☆),
  copyright/trademark (© ® ™), math (± × ÷ ≠ ≤ ≥ ∞ √ ∑ ∏ ∫ ≈ ≡ ∝), science
  (α β γ δ, μ Ω π, ℃ ℉, Å), Greek letters, and a Unicode search (e.g.
  searching "arrow" surfaces all arrow variants).
- Click an entry to insert it, same mechanism as Clipboard.

## 5. Recently Used Symbols

- A "Recently Used" section sits above the full Symbols list, visually
  separated by a divider.
- Recently-used symbols are ranked by frequency of use over time — a symbol
  used repeatedly rises to the top of that section (not just most-recent).

## 6. Developer — REMOVED

~~A palette of code-oriented symbols and keywords: brackets, operators, SQL/
Python/JavaScript keywords, click to insert.~~ Built in Milestone 4, then
removed in full per explicit user request. Do not rebuild without the user
asking again.

## 7. Keyboard — REMOVED

~~An on-screen input-assistance keyboard.~~ Built in Milestone 5 (first as a
virtual keyboard, then reworked into a width-conversion control panel after
user feedback), then removed in full per explicit user request. Do not
rebuild without the user asking again.

## 8. Japanese input width settings — REMOVED

~~Per category — Numbers, Katakana, Alphabet, Symbols, Space — full-width/
half-width enable + choice.~~ This lived entirely inside the Keyboard tab
(§7) and was removed along with it.

## 9. Japanese width-conversion example — REMOVED (reference only)

Kept here only so the exact worked example isn't lost if this is ever
rebuilt. Given input `１２３ＡＢＣ　カタカナ` and settings:
- Numbers → Half-width, Alphabet → Half-width, Katakana → Half-width,
  Space → Half-width
  → Result: `123ABC ｶﾀｶﾅ`
- Numbers → Full-width, Katakana → Full-width, Alphabet → Half-width
  → Result: `１２３ABC カタカナ`

The `WidthConverter` implementation (run-based, per-category, careful about
voiced/semi-voiced katakana combining marks) was verified against both of
these before it was deleted — if rebuilt, re-derive from git history
(`Services/WidthConverter.swift`, removed alongside the Keyboard tab) rather
than from scratch.

## 10. Global shortcuts

- Default example: ⌘⇧V opens the panel; ⌘⇧C jumps straight to Clipboard;
  ⌘⇧S jumps straight to Symbols.
- All shortcuts are user-remappable in Settings via a hotkey recorder per
  action.

## 11. Settings

Kept as simple as possible:
- **Visible Tabs** — checkbox per feature (Clipboard/Snippets/Symbols);
  Settings itself has no checkbox.
- **Shortcuts** — one hotkey-recorder row per action (Open Panel, etc.).

## 12. Tab visibility behavior

Turning a feature off in Settings removes its tab from the main UI
immediately and completely — never leave a disabled feature's tab visible
but empty/greyed-out.

## 13. Overall structure

```
                Mac Keyboard Utility
                         │
        ┌────────────────┼────────────────┐
        │                │                │
   Clipboard         Snippets          Symbols
   Copy History       Templates       Special Characters
   Favorites          Shortcuts       Unicode / Math / Science / Greek / Arrows
   Recent             Categories
                         │
                      Settings
```

(Developer and Keyboard branches removed — see §6/§7.)

## 14. Now Playing

A compact strip shown above the tab bar (`Features/Shared/NowPlayingBar.swift`)
showing whatever's currently playing system-wide (Music, Spotify, a browser
tab, etc.) — artwork, title, artist — with previous/play-pause/next controls.
Collapses to nothing when no app is reporting a now-playing session, rather
than showing an empty/disabled row. Has its own hide (×) button on the bar
itself, backed by the same `NowPlayingBar.enabledDefaultsKey` `@AppStorage`
flag as a "Now Playing" toggle in Settings → Visible Tabs — dismissing it
from the bar and re-enabling it from Settings are the same switch.

When the player reports a `duration`, the bar also shows a draggable
progress scrubber with elapsed/total time labels, backed by the adapter's
`seek POSITION` command (microseconds). The adapter only pushes an update
when something actually changes, not once a second, so the live position
between updates is extrapolated locally in `NowPlayingBar.currentElapsed`
from the last known `elapsedTime` plus wall-clock time elapsed since it was
received (via `TimelineView(.periodic(...))`), rather than polling `get`
continuously.

Backed by `Services/NowPlayingMonitor.swift`, which needs Apple's private
`MediaRemote` framework — there is no public API for reading *another* app's
now-playing state. Since macOS 15.4, `mediaremoted` denies MediaRemote
access to any process whose bundle identifier doesn't start with
`com.apple.`, so calling the framework directly (even via `dlopen`) from a
regular app now returns nothing. `KeyClip/Vendor/MediaRemoteAdapter/`
(BSD-3-Clause, vendored from github.com/ungive/mediaremote-adapter) works
around this by shelling out to `/usr/bin/perl`, which macOS itself reports
with bundle identifier `com.apple.perl5` and is therefore still entitled —
the perl script dynamically loads the bundled helper framework (bundled
with the app but never linked against) and streams now-playing JSON to
stdout, which `NowPlayingMonitor` parses via `Process`/`Pipe`. Controls
(`send <command-id>`) go through the same script. This is a documented,
actively-maintained community workaround for a real platform regression,
and it exposes only the same info the system's own Control Center "Now
Playing" widget already shows — see the vendored `LICENSE` for attribution.

---

## Fixed constraints (decided with the user — do not re-litigate)

- **App shell**: menu bar utility, no Dock icon (`LSUIElement`/accessory
  activation policy). Summoned via global hotkey into a floating,
  non-activating panel overlaid on the frontmost app (Raycast/Alfred/Maccy
  style) — not a normal windowed Dock app.
- **Scope**: Developer and Keyboard tabs were removed in full after being
  built (Milestones 4–5) — see §6/§7. The app is Clipboard + Snippets +
  Symbols + Settings only unless the user asks to rebuild one of those.
- **Distribution**: personal use, direct/local distribution — not the Mac App
  Store, not sandboxed. Signed to run locally under the user's personal Apple
  ID team so it behaves like a normal double-clickable app (see root
  `CLAUDE.md` for build/install steps).
- **Version control**: git is initialized locally with a proper `.gitignore`.
  No GitHub remote is created or pushed by Claude — the user does that
  themselves when ready.

---

## Milestone checklist

### Milestone 1 — Foundation + Clipboard ✅
- [x] Accessory (menu-bar-only) app shell, no Dock icon
- [x] `NSStatusItem` + custom non-activating `NSPanel` floating panel
- [x] Global hotkey (default ⌘⇧V) opens/closes the panel, user-remappable
- [x] Accessibility-permission check + system-settings deep link
- [x] `TextInjector` service (CGEvent-based, chunked Unicode injection) shared
      by all tabs
- [x] SwiftData `ClipboardItem` model + `ClipboardMonitor` (pasteboard
      polling, dedup, 200-item prune, pin/favorite exempt from pruning)
- [x] Clipboard tab: search, history list, favorites section, click-to-copy
      (writes to the system pasteboard and reactivates the app you were in,
      ready for ⌘V — changed from an earlier auto-typed-injection approach
      for reliability; see `copyToClipboard` in `InjectionEnvironment.swift`)
- [x] Settings tab: tab-visibility toggles, hotkey recorder, accessibility
      status banner
- [x] Snippets/Symbols/Developer/Keyboard wired in as placeholder tabs
      (fully plugged into the visibility-toggle system, no real content yet
      — Developer/Keyboard were later built in M4/M5 then removed entirely,
      see below)
- [x] Local git repo + `.gitignore` + `CLAUDE.md`/`docs/SPEC.md`

### Milestone 2 — Snippets ✅
- [x] Snippet data model (`trigger`, `content`, flat `category` string rather
      than a fully editable nested tree — kept simple; see Settings tab CRUD)
- [x] Typing-trigger expansion engine (`SnippetExpansionEngine`): a
      listen-only `CGEventTap` (gated by the separate **Input Monitoring**
      TCC category, not Accessibility) watches typed characters system-wide,
      matches a rolling buffer against registered triggers, then deletes the
      typed trigger and types the expansion via `TextInjector`. Synthetic
      events are tagged (`TextInjector.syntheticEventMarker`) so the engine
      ignores its own output instead of feeding it back into the buffer.
- [x] Snippets tab UI: grouped-by-category list, search, click-to-copy
      (same pasteboard mechanism as Clipboard), add/edit/delete via a sheet,
      duplicate-trigger guard
- [x] Settings: Input Monitoring permission status row + grant button

### Milestone 3 — Symbols + Recently Used ✅
- [x] Built-in symbol catalog (`SymbolCatalog.swift`) grouped into categories
      (Marks, Arrows, Math, Science, Greek) — reference data, not user
      content, so it isn't a SwiftData model
- [x] Per-symbol favorite/usage state (`SymbolUsage` model, keyed by the
      character itself, created lazily on first favorite/use)
- [x] Favorites section + Recently Used section (ranked by usage frequency,
      ties broken by recency — not just most-recent) above the category list
- [x] Categories are collapsible/expandable (chevron-toggled disclosure);
      search matches by name (e.g. "arrow") or the literal character and
      auto-expands matches regardless of collapsed state
- [x] Click-to-copy via the same `copyToClipboard` pasteboard mechanism as
      Clipboard/Snippets, hover highlighting, right-click to favorite

### Milestone 4 — Developer ❌ REMOVED
Was built in full (built-in token catalog grouped into Brackets/Operators/
SQL/Python/JavaScript, collapsible categories, a reusable `FlowLayout` for
wrapping variable-width chips, click-to-copy). **Removed entirely per
explicit user request** — the tab, `DeveloperView.swift`,
`Models/DeveloperCatalog.swift`, and `Features/Shared/FlowLayout.swift` were
all deleted. Recoverable from git history if the user asks for it again; do
not proactively rebuild.

### Milestone 5 — Keyboard + Japanese width conversion ❌ REMOVED
Was built in full, in two iterations: first an on-screen QWERTY keyboard +
compose box, then reworked (per user feedback) into a width-conversion
control panel — per-category enable/disable + Full/Half-width picker,
gated on the Mac's active input source actually being Japanese (via
`TISCreateInputSourceList`/`kTISPropertyInputSourceIsSelected`, after an
earlier `TISCopyCurrentKeyboardInputSource`-based version was confirmed
wrong — see git history for why that API is unreliable for a non-activating
background panel). **Removed entirely per explicit user request** — the tab,
`KeyboardView.swift`, `Services/WidthConverter.swift`, and
`Services/InputSourceMonitor.swift` were all deleted. The worked conversion
examples are preserved in §9 in case this is rebuilt. Recoverable from git
history if the user asks for it again; do not proactively rebuild.

### Milestone 6 — Remaining shortcuts + polish (in progress)
- [x] Now Playing bar above the tab bar (`Services/NowPlayingMonitor.swift`,
      `Features/Shared/NowPlayingBar.swift`) — see §14.
- [x] Double-⌘ (two quick Command-key taps, nothing else held) as an
      additional way to open the panel, alongside the existing ⌘⇧V hotkey —
      `Services/DoubleCommandTapDetector.swift`. Carbon's `RegisterEventHotKey`
      can't represent a bare-modifier tap (it needs a real virtual key plus
      modifiers), so this uses a global `NSEvent.addGlobalMonitorForEvents`
      on `.flagsChanged` instead — gated by the same Accessibility trust
      `TextInjector` already needs, not a new permission category. Toggle in
      Settings → Shortcuts, default on.
- [x] Theming (`Services/ThemeStore.swift`): 5 built-in presets (System,
      Light, Dark, Ocean, Forest) plus per-element custom colors — Background,
      Text, Hover Highlight, Selected Highlight — via `ColorPicker`s in
      Settings → Appearance. Editing any individual color switches to (and
      persists as) a "custom" theme seeded from whichever preset was active,
      so the other three colors don't reset. Shared app-wide via
      `.environmentObject(ThemeStore.shared)` injected once in
      `FloatingPanel`; applied to the tab bar, panel background, and the
      Clipboard/Snippets/Symbols row text + hover colors, **and now Settings
      itself** (reversed the earlier "keep Settings native" call — the user
      asked for it explicitly; Section headers use themed custom labels,
      Toggles wrap their label in themed `Text`, native chrome like
      `ColorPicker`'s swatch and context menus is left alone since that's
      genuinely not re-stylable).
    - **Fixed a real bug from the first theming pass**: `List` `Section`
      headers (Clipboard's "Favorites"/"History", Snippets' category names)
      used the plain `Section("title")` initializer, which renders with the
      system's default text color — not `theme.text`. On a dark custom
      background this stayed black and was unreadable. Fixed by switching to
      the closure-based `Section { ... } header: { Text(...).foregroundStyle(theme.text.opacity(0.6)) }`
      form everywhere a Section appears. Also themed the search-field icons/
      text and empty-state text in all three tabs, which had the same
      `.secondary`-not-`theme.text` gap.
    - Added 4 more presets: **Orange, Cream, Tiffany Blue, Matrix** (green
      text on black, à la the movie) — 9 presets total.
    - **Fixed a second readability bug + added a 5th customizable color**:
      the tab bar's selected-tab text used plain `theme.text` regardless of
      what `theme.selected` (the highlight behind it) was — on Matrix
      (bright green text, green-tinted-black highlight) this read as
      low-contrast. Added `selectedText` as its own field on `ThemePreset`/
      `ThemeStore` (with its own `ColorPicker` in Settings → Appearance, so
      it's manually adjustable regardless of preset), applied only when a
      tab is selected. Each of the 9 presets got a `selectedText` chosen for
      contrast against its own `selected` highlight (mostly white or black,
      not necessarily matching the base `text` color).
    - **Also reverted theming `Picker`/`ColorPicker` label text** in
      Settings → Appearance. Those are native controls that draw their own
      box/swatch chrome independent of `.scrollContentBackground(.hidden)`
      — forcing `theme.text` onto their labels fought that native chrome
      and was reported as hard to read. Plain `Toggle`/`Text` rows (which
      really do sit on `theme.background` with no competing native box)
      keep their theming.
- [x] **Update checking** (`Services/UpdateChecker.swift`): manual/on-demand
      only, not an auto-updater — queries GitHub's Releases API
      (`/repos/shinji-kasai/KeyClip/releases/latest`), compares `tag_name`
      against `CFBundleShortVersionString` via simple numeric
      dot-component comparison, and if newer surfaces a link to the release
      page. Chosen deliberately over full Sparkle-based auto-update: no
      private signing key to manage as a CI secret, no appcast feed to
      generate per release, no new dependency — at the cost of the user
      having to manually download and drag-replace the app themselves.
      Two entry points sharing the same service: **Settings → Updates**
      (inline status: Check for Updates / Up to date / vX.Y.Z available with
      a View Release button / Check failed with Retry) and **right-click the
      menu bar icon → Check for Updates…** (same check, result shown via
      `NSAlert` instead of inline state, since the status-bar menu has no
      persistent view to show it in).
- [ ] Per-tab jump hotkeys (Open Clipboard, Open Symbols, etc.) — the
      `HotKeyManager`/`HotKeyBinding` design already generalizes to this
- [ ] Any remaining settings/UX polish
