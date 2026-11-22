# JSON Better Editor — Decision Log

> Append-only. Add new decisions as new rows at the bottom; do not edit or delete past rows. If a decision is reversed, add a new row that says which row it replaces.
> Requirements live in [`requirements-checklist.md`](requirements-checklist.md).

| # | Date | Topic | Decision |
|---|------|-------|----------|
| 1 | 2026-11-22 | Platform | macOS only. Windows dropped. |
| 2 | 2026-11-22 | Null type | Added everywhere a type list appears, gray `?` icon. |
| 3 | 2026-11-22 | Mode layout | Side by side 50/50 with splitter; toolbar toggles Text only / Node only / Split. |
| 4 | 2026-11-22 | Drag and drop | Node mode only, one node at a time. |
| 5 | 2026-11-22 | Copy/cut/paste | One node at a time. Text mode = normal text editor. Node mode = node-aware paste shortcuts. |
| 6 | 2026-11-22 | Tab key | Indent only (text in Text mode, node in Node mode). Not used to accept autocomplete. |
| 7 | 2026-11-22 | Node indent / de-indent | Tab = become last child of previous sibling; Shift+Tab = become sibling of parent. |
| 8 | 2026-11-22 | Invalid JSON while editing | Node pane shows a blank node; ≤250 ms sync delay OK. Invalid file on open = error dialog, not opened. |
| 9 | 2026-11-22 | Expand/collapse | Expand all, collapse all, expand to depth, collapse siblings. |
| 10 | 2026-11-22 | Child count | `{n}` objects, `[n]` arrays. |
| 11 | 2026-11-22 | Click behavior | Single-click selects and toggles single/multi-line; double-click edits key or value. |
| 12 | 2026-11-22 | Multi-line | Fixed 10 lines. Setting = document default; click toggles per node. |
| 13 | 2026-11-22 | Type change | No automatic conversion; popup with current value for manual edit. |
| 14 | 2026-11-22 | Delete | Confirmation dialog, default Cancel. Undo/redo required. |
| 15 | 2026-11-22 | HTML/Markdown | Syntax-highlighted text editor only, no render, never run scripts. |
| 16 | 2026-11-22 | Base64 images | `data:image/...;base64,` only; 64×64 center-crop thumbnail. |
| 17 | 2026-11-22 | Fonts | System monospace font replaces Plex Mono in both places; fonts not bundled. |
| 18 | 2026-11-22 | Theme | Atom One Light / One Dark; follows OS by default. |
| 19 | 2026-11-22 | Toolbar | Star, Menu and New-dropdown removed. New, Open, Search on left; Language, Theme, Settings on right. |
| 20 | 2026-11-22 | Search | Keys and values, first match, Next/Previous. |
| 21 | 2026-11-22 | Files | Standard File menu; single document per window; multiple instances allowed; test with <5 MB. |
| 22 | 2026-11-22 | Language | Switch button on toolbar, right side. |
| 23 | 2026-11-22 | Word wrap | Text mode lines and long String/Number values in Node mode. |
| 24 | 2026-11-22 | OS integration | Appear in "Open With" and settable as default is enough. |
| 25 | 2026-11-22 | Cmd+V in Node mode | With a node selected (not editing a field), Cmd+V pastes as child. |
| 26 | 2026-11-22 | Undo/redo scope | One shared history across Text and Node panes. |
| 27 | 2026-11-22 | Layout toggle position | Right group of the toolbar, before the Language switch. |
| 28 | 2026-11-22 | Save formatting | Save reformats (pretty-prints) the JSON. |
| 29 | 2026-11-22 | Missing fonts | Fall back to the macOS default monospace font. |
| 30 | 2026-11-22 | Default UI language | Always English on first launch. |
| 31 | 2026-11-22 | Node-mode paste shortcuts (final) | Cmd+V = paste as child; Cmd+Shift+V = paste sibling after; Cmd+Opt+V = paste sibling before. Cmd+Opt+Shift+V removed. Supersedes the shortcut parts of #5 and #25. |
| 32 | 2026-11-22 | Development phases | Four phases: 1 Bootstrap (app runs on macOS + very basic features), 2 Text mode complete ("tech base"), 3 Node Visualization, 4 Settings. Details in `development-phases.md`. |
| 33 | 2026-11-22 | Split view and sync placement | Split view and Text/Node sync belong to Phase 3, because that is where Node Visualization is introduced. |
| 34 | 2026-11-22 | Build and test | Compile and test locally on macOS (`scripts/check.sh`). No GitHub Actions unless truly necessary. Replaces the "CI build" item in Phase 1 of `development-phases.md`. |
| 35 | 2026-11-22 | Work tracking | Feature-branch workflow, one branch and PR per ticket. Phase 1 tickets are GitHub sub-issues of the phase issue #2; blockers are listed as `Blocked by:` lines in each ticket. |
| 36 | 2026-11-22 | Minimum macOS | macOS 14.0 is the minimum supported version (`MACOSX_DEPLOYMENT_TARGET = 14.0`). Xcode 27 cannot build below 12.0. |
| 37 | 2026-11-22 | Merging PRs | The maintainer never merges. The main agent chat reviews each PR against its acceptance criteria and merges it when they pass; failing tests are fixed until green. A conflict between acceptance criteria, feature intent and a bug goes to the maintainer. Each ticket branches from `main` after the previous PR is merged. |
| 38 | 2026-11-22 | Minimum window size | The main window cannot be resized below 640×400, so the toolbar row always fits. |
| 39 | 2026-11-22 | JSON parser | Own small parser in `lib/document/` instead of `dart:convert` `jsonDecode`: numbers keep their original text, duplicate keys are kept, errors carry line and column (characters). |
| 40 | 2026-11-22 | Nesting limit | JSON nested deeper than 512 levels is rejected with a parse error instead of risking a stack overflow. |
| 41 | 2026-11-22 | Native file dialogs | Open/Save panels are shown by the app's own Swift code over the `json_better_editor/window` method channel, not a plugin (no new dependency). The sandbox grants `files.user-selected.read-write` (Save needs write). |
