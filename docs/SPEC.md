# KeyClip — Full Feature Spec

Source of truth for what KeyClip is meant to become. Originally specified by the
user in Japanese; translated and organized here. Read this before assuming a
feature doesn't exist or before re-deriving scope from scratch — check the
milestone checklist at the bottom first.

## 1. Overall shape

A macOS keyboard/clipboard utility. Main UI is a tab bar:

```
[ Clipboard ] [ Snippets ] [ Symbols ] [ Developer ] [ Keyboard ] [ Settings ]
```

Each tab is a fully separate feature. In Settings, the user can turn any
feature OFF except Settings itself, and that tab disappears entirely from the
bar — unused features are never left cluttering the UI. Example: turning off
Developer changes the bar from
`Clipboard | Snippets | Symbols | Developer | Keyboard` to
`Clipboard | Snippets | Symbols | Keyboard`.

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

## 6. Developer

- A palette of code-oriented symbols and keywords: brackets (`{ } [ ] ( ) < >`),
  operators (`=> -> == === != !== && || ++ -- += -=`), SQL keywords (SELECT,
  FROM, WHERE, JOIN, GROUP BY, ORDER BY), Python keywords (def, class, self,
  None, True, False), JavaScript keywords (const, let, async, await, Promise).
- Click to insert, same mechanism as Clipboard/Symbols.

## 7. Keyboard

- An on-screen input-assistance keyboard (not a plain QWERTY replica) — the
  layout itself should eventually be user-configurable.

## 8. Japanese input width settings

- Per category — Numbers, Katakana, Alphabet, Symbols, Space — the user picks
  Full-width or Half-width as a per-category checkbox/toggle, e.g.:
  ```
  ☑ Numbers     ☑ Katakana     ☐ Alphabet     ☑ Symbols
  ```

## 9. Japanese width-conversion example

Given input `１２３ＡＢＣ　カタカナ` and settings:
- Numbers → Half-width, Alphabet → Half-width, Katakana → Half-width,
  Space → Half-width
  → Result: `123ABC ｶﾀｶﾅ`
- Numbers → Full-width, Katakana → Full-width, Alphabet → Half-width
  → Result: `１２３ABC カタカナ`

This conversion applies to text typed via the Keyboard tab before it's
inserted into the target app.

## 10. Global shortcuts

- Default example: ⌘⇧V opens the Keyboard/panel; ⌘⇧C jumps straight to
  Clipboard; ⌘⇧S jumps straight to Symbols.
- All shortcuts are user-remappable in Settings via a hotkey recorder per
  action.

## 11. Settings

Kept as simple as possible:
- **Visible Tabs** — checkbox per feature (Clipboard/Snippets/Symbols/
  Developer/Keyboard); Settings itself has no checkbox.
- **Input Conversion** — a Full-width/Half-width dropdown per category
  (Numbers, Katakana, Alphabet, Symbols, Space).
- **Shortcuts** — one hotkey-recorder row per action (Open Keyboard, Open
  Clipboard, etc.).

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
                    Developer
                    Code Symbols, SQL, Python, JavaScript
                         │
                      Keyboard
                 Japanese Input, Full/Half Width, Custom Layout
                         │
                      Settings
```

---

## Fixed constraints (decided with the user — do not re-litigate)

- **App shell**: menu bar utility, no Dock icon (`LSUIElement`/accessory
  activation policy). Summoned via global hotkey into a floating,
  non-activating panel overlaid on the frontmost app (Raycast/Alfred/Maccy
  style) — not a normal windowed Dock app.
- **Keyboard tab**: an in-app virtual keyboard whose keystrokes go through the
  same simulated-keystroke injection mechanism as every other tab. **Not** a
  real macOS Input Method Kit extension — that was explicitly ruled out as
  disproportionate effort for this project.
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
      (fully plugged into the visibility-toggle system, no real content yet)
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

### Milestone 4 — Developer ✅
- [x] Built-in token catalog (`DeveloperCatalog.swift`) grouped into
      categories (Brackets, Operators, SQL, Python, JavaScript) — reference
      data, no persistence needed (no favorites/recently-used for this tab,
      unlike Symbols — not called for in the original spec)
- [x] Collapsible categories (same chevron-toggle pattern as Symbols)
- [x] New `FlowLayout` (`Features/Shared/FlowLayout.swift`) wraps
      variable-width token chips onto new rows — chosen over `LazyVGrid`
      because tokens vary a lot in length ("if" vs. "GROUP BY") and a fixed
      grid would waste space or clip long tokens
- [x] Click-to-copy via the same `copyToClipboard` mechanism, hover
      highlighting on each chip

### Milestone 5 — Keyboard + Japanese width conversion ✅
**Revised after initial delivery**: the Keyboard tab is a **width-conversion
control panel**, not an on-screen keyboard — an earlier version included a
clickable QWERTY grid, which was removed once the user clarified this tab's
job is to *control* conversion, not provide an alternate way to type.

- [x] `KeyboardView.swift`: per-category (Numbers/Katakana/Alphabet/Symbols/
      Space) **enable/disable toggle** + Full/Half-width picker (both, not
      just the width choice — matches the original spec's checkbox +
      radio-button illustration more closely than the first pass did).
      Alphabet defaults OFF, the other four default ON, matching the spec's
      own example checklist.
- [x] Gated on the Mac's **active keyboard input source actually being
      Japanese** — `InputSourceMonitor`/`InputSourceObserver`
      (`Services/InputSourceMonitor.swift`) reads `TISCopyCurrentKeyboardInputSource`
      and listens for `kTISNotifySelectedKeyboardInputSourceChanged` so the
      tab live-enables/disables itself (with a notice) as the user switches
      input sources — not just a one-time check.
- [x] A plain editable `TextField` (not a virtual keyboard) is where the
      conversion is actually used — type with your real keyboard or paste
      existing text (e.g. the spec's own "１２３ＡＢＣ　カタカナ" example)
      to see the converted result and copy it.
- [x] `WidthConverter` (`Services/WidthConverter.swift`): groups the input
      into contiguous same-category runs and transforms each run as a whole
      via `String.applyingTransform(.fullwidthToHalfwidth, reverse:)` — a
      character-at-a-time approach was tried first and is specifically wrong
      for voiced/semi-voiced katakana (ｶﾞ ⇄ ガ), since a half-width kana base
      + its sound mark is one `Character` with 2 Unicode scalars; classify by
      the base scalar, not `scalars.count == 1`, or the mark gets silently
      skipped. A disabled category is simply omitted from the settings dict
      passed to `convert`, which already passes unconfigured categories
      through unchanged — no separate on/off branch needed there. Verified
      against both of the spec's own worked examples plus a voiced-katakana
      round trip before shipping.
- [x] This only affects text typed/pasted into KeyClip's own Keyboard tab
      field, not real-time system-wide typing (that would need a CGEventTap-
      based engine like Snippets' expansion engine — out of scope here).

### Milestone 6 — Remaining shortcuts + polish (not started)
- [ ] Per-tab jump hotkeys (Open Clipboard, Open Symbols, etc.) — the
      `HotKeyManager`/`HotKeyBinding` design already generalizes to this
- [ ] Any remaining settings/UX polish
