# Phase 2 review: autonomous decisions

Phase 2 (Text mode, parent #25) was built while the maintainer was away, with the instruction to decide
everything that is not irreversible and to record each choice that goes beyond the spec. This page lists
those choices so they can be checked in one place. Each one is a row in `docs/decision-log.md` marked
**Autonomous default** and is noted on its issue.

Every PR was reviewed against its acceptance criteria by the coordinator before being marked ready.

## Look at these first

1. **#61 — the Text pane keeps your text as typed after Save, but the file is pretty-printed.** After
   Save, the pane and the file on disk differ in layout until the file is reopened. This keeps the caret,
   scroll and undo history in place. If you prefer the pane to reformat on Save (as an undoable edit),
   change `MainWindow._writeTo`.
2. **#68 — closing the only window quits the app.** Many macOS editors stay running with no window.
   Staying open needs a way to create a window from the Dock or menu, which does not exist yet.
3. **#79 — performance trade-offs.** The "— Edited" mark stays on if typing happens to restore the
   saved text (undo clears it); key suggestions may miss a key added in the last 2 seconds.
4. **#65 — no auto-closing quotes and brackets.** Turned off because typing `"x": 1` produced
   `"x": 1""` in the real app.

## All autonomous decisions

| # | What was decided | Why | Where | How to change |
|---|---|---|---|---|
| 60 | Text pane built on `re_editor` 0.10.0 (MIT; adds `re_highlight`, `isolate_manager`). | Only option that meets the 5 MB target: a plain `TextField` took 1.4 s to show 5.9 MB and over 1 s per keystroke; `flutter_code_editor` is TextField-based with 14 dependencies. | #26, PR #47, `docs/editor-component.md` | Replace the widget in `lib/ui/text_pane.dart`; the document model does not depend on it. |
| 61 | Save writes pretty-printed JSON but the pane keeps the typed text. | Caret, scroll and undo are not disturbed. | #27, PR #48 | `MainWindow._writeTo`: replace the controller text after a successful write. |
| 62 | Keep re_editor's extra macOS shortcuts (Cmd+L, Cmd+D, Opt+Up/Down); remove Cmd+S, find/replace and comment toggles from the editor. Its auto-closing part is superseded by #65. | Normal code-editor behaviour; the app owns Save and Find; JSON has no comments. | #27, PR #48 | `_TextPaneShortcuts` in `lib/ui/text_pane.dart`. |
| 63 | New gives "Untitled" holding `{}`; Cmd+O opens a file from the keyboard. | `{}` is the ticket's wording; Cmd+O is the standard shortcut. | #28, PR #49 | `MainWindow._newDocument`; the shortcut map in `MainWindow.build`. |
| 64 | The Text pane takes keyboard focus after New and Open. | In the real app, typing after Cmd+N went nowhere. | #30, PR #51 | `TextPaneState.initState`. |
| 65 | Auto-closing of quotes and brackets is off. | Typing a closing quote was not skipped, giving `""`. | #30, PR #51 | `autocompleteSymbols` on `CodeEditor`. |
| 66 | Edited mark "name — Edited" plus the close-button dot; prompt "Do you want to save the changes made to “name”?" with Don't Save / Cancel / Save (default); Esc = Cancel; undo back to the saved text clears the mark. | macOS wording and behaviour. | #30, PR #51 | `lib/l10n/app_en.arb`; `MainWindow._confirmDiscard`. |
| 67 | File menu added in Swift (`AppDelegate.addFileMenu`), not Flutter's `PlatformMenuBar`. | `PlatformMenuBar` replaces the whole menu bar, including the Edit menu. | #31, PR #52 | `AppDelegate.addFileMenu`. |
| 68 | Closing the only window quits the app. | One document per window; no way to reopen a window yet. | #31, PR #52 | `applicationShouldTerminateAfterLastWindowClosed` → false, plus window creation on reopen. |
| 69 | `.json` handler with `LSHandlerRank` Default; several files from Finder → the last one opens; a launch file waits for Dart. | Listed in Open With without taking over `.json` on install; one document per window. | #32, PR #53 | `CFBundleDocumentTypes` in `Info.plist`; `AppDelegate.application(_:open:)`. |
| 70 | Own JSON grammar and basic colours (key purple, string green, number blue, boolean orange, null red, punctuation muted); highlighting on up to 64 MB. | re_highlight's grammar colours booleans and null alike and stops at invalid text; String green / Number blue match the Node pane. | #33, PR #55 | `jsonMode`, `jsonHighlightTheme` in `lib/ui/json_highlight.dart`. One Light / One Dark replace the colours in Phase 4. |
| 71 | Bracket/quote matching: inside a string → its quotes; else the bracket before the caret (then after); unbalanced or unclosed → nothing; boxes painted over the text. | re_editor has no per-character style hook. | #35, PR #57 | `lib/document/bracket_match.dart`; `_PairPainter`. |
| 72 | A folded block is one line (the closing-bracket line is folded too); folds are view state and never edits. | Matches the ticket ("folds to one line"). | #36, PR #58 | `_JsonChunkAnalyzer` in `lib/ui/text_pane.dart`. |
| 73 | The template Edit menu (Undo, Redo, Cut, Copy, Paste, Select All, later Find) is routed to the Text pane. | Those items were greyed out in the real app. | #38, PR #60 | `AppDelegate.retargetEditMenu`; `MainWindow._edit`. |
| 74 | View › Word Wrap at the top of the View menu with a checkmark; Opt+Z also handled in Dart; not remembered between launches. | Opt+Z typed "Ω" before the menu saw it. Persistence belongs to Settings (Phase 4). | #39, PR #61 | `AppDelegate.addWordWrapItem`; `MainWindow._toggleWordWrap`. |
| 75 | Key suggestions: shown after a quote in an object (not in arrays); every key in the document incl. folded parts; case-sensitive prefix; A–Z; accept adds the closing quote but not the colon; Esc closes. | Ticket rules plus the simplest predictable list. | #40, PR #62 | `JsonKeyPrompts`, `KeySuggestions` in `lib/ui/key_autocomplete.dart`. |
| 76 | Search field above the Text pane; case-insensitive plain text; searches keys, string contents, numbers, `true`, `false`, `null`; re-searches on each keystroke; opening a search unfolds folded blocks. | Ticket rules; unfolding so matches inside folds are found and shown. | #41, PR #63 | `searchJson` in `lib/document/json_search.dart`; `JsonSearchBar`. |
| 77 | Undo granularity is re_editor's (a typing run = one step; cut, paste, indent = one step each). | Built in. | #43, PR #65 | A custom history would wrap `CodeLineEditingController`. |
| 78 | Undo/redo skip caret-only and fold steps. | Review: Cmd+Z should only undo text changes. | #43, PR #65 | `undoTextChange` / `redoTextChange` in `lib/ui/text_pane.dart`. |
| 79 | Performance trade-offs: edited-mark shortcut, 2 s key cache, own fold analyser; capacity about 30 MB. | Meet decision #59 at 5 MB (open 2.1 s → 0.5 s). | #44, PR #68, `docs/performance.md` | `_OpenFile.edited`; `JsonKeyPrompts._documentKeys`. |

## Bugs found by checking the real app (all fixed in Phase 2)

- Quit hung after Close → Don't Save (#31).
- Edit menu items greyed out (#38); Opt+Z typed "Ω" (#39).
- Menu shortcuts acted on the document behind a dialog, and Return did not press OK; a file opened from
  Finder during a dialog now opens after it closes (#54).
- Quadratic line loops made a 5 MB file take 2.1 s to open and fold markers never appear (#44).

## Open issues and decisions for you

- **#67 — a long jump to the top of a large file freezes** (2.7 s at 5 MB). re_editor lays out every
  line between the old and new position when scrolling up. Fixing it needs a patched re_editor (a
  vendored copy or a fork), which is a dependency decision. Also in #67: the first key suggestion in a
  session takes 0.3 s at 5 MB. Kept outside Phase 2.
- **Merging.** The Claude Code safety check on this Mac refused `gh pr merge`, so PRs #46–#68 are
  approved by the coordinator but **not merged**. They form one chain (each branch builds on the previous
  one); merging in order #46, #47, … #68 works without conflicts. Allowing `gh pr merge` in
  `~/.claude/settings.json` would let the agent do it.
- Search and undo cover the Text pane only; Node mode and the shared history are Phase 3 (decision #53).

## Evidence

Real-app screenshots for each ticket are in `docs/screenshots/` (Release or real macOS engine). The
Phase 2 done check: `docs/screenshots/45-phase2-done.jpg` — highlighting, line numbers, fold markers,
search "2 of 2" and the edited mark in the Release app.
