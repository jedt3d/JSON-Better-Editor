# Text-mode editor component (#26)

Chosen: **`re_editor` 0.10.0** (MIT, by Reqable). Decision #60.

## Options

| Need (requirements) | `re_editor` | `flutter_code_editor` | Own editor on `EditableText` |
|---|---|---|---|
| §1.1 highlighting | Yes, `re_highlight` JSON grammar, runs in an isolate | Yes, `highlight` package | Must build |
| §1.1 line numbers | `DefaultCodeLineNumber` | Yes | Must build |
| §1.1 bracket matching | Not built in; add on top (caret + controller) | Partial | Must build |
| §1.1 folding | `DefaultCodeChunkIndicator` + chunk analyser | Yes | Must build |
| §1.3 autocomplete, Enter only | `CodeAutocomplete` with our own prompts builder | Yes, but suggestions are its own | Must build |
| §1.4 Tab / Shift+Tab | Built in (indent/outdent); indent size set on the controller | Yes | Must build |
| §1.4 clipboard | Built in | TextField | TextField |
| §1.5 word wrap | `wordWrap` flag | No soft wrap toggle | TextField wraps only |
| §3.3 search | `CodeFindController` | Partial | Must build |
| §3.5 undo/redo | Built in on the controller | TextField undo | TextField undo |
| 5 MB target (decision #59) | **5.9 MB: first frame 0.38 s; 50 typed chars in 0.59 s (about 12 ms each); build p50 0.9 ms** | TextField-based (whole text is one paragraph), same limit as the next column | **5.9 MB `TextField`: first frame 1.37 s; each edit about 1.15 s** |
| Dependencies added | 2 (`re_highlight`, `isolate_manager`) | 14, incl. `http`, `url_launcher`, `mocktail` at runtime | 0 |
| Licence, upkeep | MIT; last release 2026-07 | Apache-2.0/MIT; last release 2025-09 | ours |
| Flutter 3.50.1 + `material_ui`, macOS 14 | Builds and runs (spike). It reads `Theme.of` from `package:flutter/material.dart`, so we pass every colour through `CodeEditorStyle` | not tried | n/a |

The own-editor column is the "zero dependencies" option the global rules prefer. It loses because the
standard `EditableText` lays out the whole text as one paragraph: at 5 MB one keystroke takes over a
second, so meeting decision #59 means writing a virtualised line editor, which is what `re_editor`
already is. `flutter_code_editor` is built on `TextField` too and pulls in 14 packages.

## Spike numbers (throwaway, profile build, this Mac)

Generated pretty-printed JSON, opened in `CodeEditor` with line numbers, fold indicators and JSON
highlighting (highlight size limit raised from the 4 MB default to 64 MB).

| File | Lines | Controller built | First frame | 50 edits | Frame build p50 / max |
|---|---|---|---|---|---|
| 1.2 MB | 78,647 | 74–122 ms | 85–150 ms | 480–642 ms | 0.8 / 1.8 ms |
| 5.9 MB | 393,227 | 364 ms | 374 ms | 592 ms | 0.9 / 3.4 ms |
| 5.9 MB, plain `TextField` | — | — | 1,368 ms | 5 edits in 5,762 ms | — |

These measure showing text already in memory; file reading and our own parse are measured in #44.

## Known gaps to cover in later tickets

- Bracket and quote matching (#35) are built on top of the controller.
- `re_highlight`'s JSON grammar does not separate keys from string values the way §1.1 asks; #33
  decides whether to use it or our own tokenizer.
- Highlighting turns itself off above `CodeHighlightThemeMode.maxSize` (4 MB by default); we raise it
  and check the cost in #44.
