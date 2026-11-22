# Keyboard shortcuts

Every keyboard shortcut active in the app (macOS), what it does and where it is defined (#96). This is
the base for reviewing the whole scheme later; we own the re_editor fork, so any of these can change.

**Keep this file current:** when you add, remove or change a shortcut (in `MainWindow`, the Swift menus
or re_editor), update this table in the same PR.

Sources:

- **App**: Dart `CallbackShortcuts` in `lib/ui/` (file named in the table).
- **Menu**: macOS menu item key equivalents, from the template `macos/Runner/Base.lproj/MainMenu.xib`
  or added in `macos/Runner/AppDelegate.swift`.
- **Editor**: re_editor's macOS defaults (`packages/re_editor/lib/src/code_shortcuts.dart`,
  `_kDefaultMacCodeShortcutsActivators`), minus the ones the app removes in `_TextPaneShortcuts`
  (`lib/ui/text_pane.dart`).

Several shortcuts are defined in two places (a menu item and an App or Editor binding) that run the same
action; both are listed. ⌘ Command, ⇧ Shift, ⌥ Option, ⌃ Control.

## File

| Shortcut | Action | Source |
|---|---|---|
| ⌘N | New document | Menu (AppDelegate `addFileMenu`) + App (`main_window.dart`) |
| ⌘O | Open… | Menu (AppDelegate) + App (`main_window.dart`) |
| ⌘W | Close (asks about unsaved changes; the app keeps running, #93) | Menu (AppDelegate) |
| ⌘S | Save | Menu (AppDelegate) + App (`main_window.dart`) |
| ⇧⌘S | Save As… | Menu (AppDelegate) + App (`main_window.dart`) |
| — | Open Recent ›, Clear Menu | Menu (AppDelegate), no shortcut |

## Edit

| Shortcut | Action | Source |
|---|---|---|
| ⌘Z | Undo (text changes only, decision #78) | Menu (xib, re-targeted in `retargetEditMenu`) + Editor `undo` (overridden in `text_pane.dart`) |
| ⇧⌘Z | Redo | Menu (xib, re-targeted) + Editor `redo` (overridden) |
| ⌘X / ⌘C / ⌘V | Cut / Copy / Paste as plain text | Menu (xib, re-targeted) + Editor |
| ⌘A | Select All | Menu (xib, re-targeted) + Editor |
| — | Validate JSON, Format, Minify, Go to Line… | Menu (AppDelegate `addValidateItem`), no shortcuts (maintainer, #90) |
| ⌘F | Find… (open the search field, or put the keyboard back in it) | Menu (xib Find › Find…, re-targeted) + App (`main_window.dart`) |
| ⌘G | Find Next | Menu (xib, re-targeted) + App (`main_window.dart`) |
| ⇧⌘G | Find Previous | Menu (xib, re-targeted) + App (`main_window.dart`) |

## View and window

| Shortcut | Action | Source |
|---|---|---|
| ⌥Z | Word Wrap on/off | Menu (AppDelegate `addWordWrapItem`) + App (`main_window.dart`, so it does not type "Ω", decision #74) |
| ⌘/ | Hide / Show Status Bar (#98) | Menu (AppDelegate) + App (`main_window.dart`) |
| ⌃⌘F | Enter Full Screen | Menu (xib) |
| ⌘M | Minimize | Menu (xib) |
| ⌘H / ⌥⌘H | Hide the app / Hide Others | Menu (xib) |
| ⌘Q | Quit (asks about unsaved changes) | Menu (xib) |

## Search field (while it has the keyboard)

| Shortcut | Action | Source |
|---|---|---|
| Return | Next match | App (`search_bar.dart`) |
| ⇧Return | Previous match | App (`search_bar.dart`) |
| Esc | Close the field, keep the selection | App (`search_bar.dart`) |

## Text pane (editor)

| Shortcut | Action | Source |
|---|---|---|
| Arrows | Move the caret | Editor |
| ⇧ + arrows | Extend the selection | Editor |
| ⌘Left / ⌘Right, Home / End | Line start / end | Editor |
| ⇧⌘Left / ⇧⌘Right, ⇧Home / ⇧End | Select to line start / end | Editor |
| ⌘Up / ⌘Down, ⌃Home / ⌃End | Document start / end | Editor |
| ⇧⌘Up / ⇧⌘Down, ⇧⌘Home / ⇧⌘End | Select to document start / end | Editor |
| ⌥Left / ⌥Right | Word left / right | Editor |
| ⇧⌥Left / ⇧⌥Right | Select a word left / right | Editor |
| Delete (⌫), ⇧⌫ | Delete backward; right after an empty pair `[]` `{}` `""` it deletes both (#91) | Editor |
| Forward Delete, ⇧Forward Delete | Delete forward | Editor |
| ⌥⌫ / ⇧⌘⌫ | Delete the word before the caret | Editor |
| ⌥Forward Delete / ⇧⌘Forward Delete | Delete the word after the caret | Editor |
| ⌘⌫ / ⌘Forward Delete | Delete to line start / end | Editor |
| ⌘L | Select the line | Editor (decision #62) |
| ⌘D | Delete the line | Editor (decision #62) |
| ⌥Up / ⌥Down | Move the line up / down | Editor (decision #62) |
| ⌃T | Transpose characters | Editor |
| Tab / ⇧Tab | Indent / de-indent by 2 spaces (decision #57) | Editor |
| Return (and ⇧ / ⌘ / numpad variants) | New line with indent; with key suggestions open: accept the suggestion (#40) | Editor |
| Up / Down with key suggestions open | Move in the list | Editor (`CodeAutocomplete`) |
| Esc | Close key suggestions (#40) | App (`text_pane.dart`); also Editor `esc` (clears a selection) |
| `{` `[` `"` | Insert the pair; typing the closer moves past it (#91) | Editor (fork patch 2) |

## Removed from re_editor

Turned off in `_TextPaneShortcuts` (`lib/ui/text_pane.dart`, decision #62):

| re_editor shortcut | Why removed |
|---|---|
| ⌘S (`save`) | Save belongs to the window (File › Save), not the editor. |
| ⌘F (`find`), ⌥⌘C / ⌥⌘R (`findToggleMatchCase` / `findToggleRegex`), ⌥⌘F (`replace`) | The app has its own search (#41, #42); find options and replace are not built. |
| ⌘/ and ⇧⌘/ (`singleLineComment`, `multiLineComment`) | JSON has no comments. |

## Template menu items with a shortcut that do nothing yet

From the template `MainMenu.xib`; their AppKit actions reach nothing in a Flutter window. Checked in the
Release app on 2026-11-23:

- Greyed out: Find and Replace… (⌥⌘F), Use Selection for Find (⌘E), Paste and Match Style (⌥⇧⌘V),
  Settings… (⌘,; Settings come in Phase 4).
- Enabled by AppKit, effect in the Text pane not checked: Jump to Selection (⌘J).
- Not checked: Edit › Spelling and Grammar › Show Spelling and Grammar (⌘:) and Check Document Now (⌘;).
