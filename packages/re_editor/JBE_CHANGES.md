# JSON Better Editor changes to re_editor

This folder is a fork of [re_editor](https://pub.dev/packages/re_editor) kept inside the JSON Better
Editor repository (decision #81, issue #70). The app depends on it by path (`pubspec.yaml`). This file
lists every change we make, apart from the app's own docs, so the fork can be rebuilt on a newer
upstream version.

## Upstream base

- Package: `re_editor` **0.10.0** by Reqable, MIT licence (`LICENSE`, unchanged).
- Source: `https://pub.dev/api/archives/re_editor-0.10.0.tar.gz`, SHA-256
  `66671c4774a6b4c5254c9a53ab35a083e7e7da9ae371c519bcf491c70a2a4e56`
  (upstream repository: https://github.com/reqable/re-editor).
- Copied on 2026-11-22. `lib/`, `test/`, `pubspec.yaml`, `analysis_options.yaml`, `LICENSE`, `README*` and
  `CHANGELOG.md` are as published; the `arts/` (screenshots) and `example/` folders were left out (9 MB,
  not needed to build).

## Updating to a newer upstream

1. Download the new archive (`https://pub.dev/api/archives/re_editor-<version>.tar.gz`) into an empty
   folder and record its SHA-256 above.
2. Replace `lib/`, `test/` and the top-level files here with the new ones (still leaving out `arts/` and
   `example/`).
3. Re-apply each patch below, in order, using its "how to re-apply" notes. Check first whether upstream
   already fixed the problem; if so, drop the patch and say so here.
4. Run `scripts/check.sh` and `scripts/perf.sh 5` from the repository root and compare with
   `docs/performance.md`.

## Patches

Each patch: number, files and functions, why, how to re-apply. Every changed line in `lib/` is marked
with a `// JBE:` comment naming the patch.

### Patch 1 — jump up without laying out every line (#71, 2026-11-22)

- **File / function:** `lib/src/_code_field.dart`, `_CodeFieldRender._updateDisplayRenderParagraphs`,
  the `else` part that handles a scroll target above the first laid-out line
  (`target < _displayParagraphs.first.top`).
- **Why:** upstream lays out every line between the current first line and the target, to add up the
  heights of wrapped lines. A jump from the end to the top of a 5 MB file (259,506 lines) took 2.2 s in a
  profile build and about 3 s in the Release app (#67). Without word wrap every line has the same height.
- **Change:** a new first branch, taken only when word wrap is off (`_horizontalViewport != null`),
  computes the start line from the target offset (`target / _preferredLineHeight`), the same way the
  downward branch already does, and lays out only the visible lines. With word wrap on, the upstream
  branch runs unchanged.
- **Result:** 5 MB end → top: longest scroll frame 9.4 ms (was 2,742 ms); Release app shows the top
  within the first capture (~0.1 s) instead of ~3 s.
- **How to re-apply:** in the new upstream `_updateDisplayRenderParagraphs`, find the branch for
  `target < _displayParagraphs.first.top`. If it still walks lines one by one, add the `// JBE: patch 1`
  branch from this repository's history (`git log -p packages/re_editor/lib/src/_code_field.dart`) in
  front of it. Check: `test/ui/jump_up_test.dart` and `scripts/perf.sh 5` (`scroll_frame_max_ms`).

### Patch 2 — type over a closing quote (#91, 2026-11-23)

- **File / function:** `lib/src/_code_input.dart`, `_SmartTextEditingDelta._smartInsertion` (the quote
  loop) and a new `_shouldSkipQuote`.
- **Why:** with auto-closing on, upstream skips over a typed `}` or `]` but not a typed quote, so typing
  `"x"` gave `"x""` (decision #65 had turned auto-closing off for this).
- **Change:** before the auto-quote check, if the next character is the same quote and the caret is
  inside a quoted string (an odd number of unescaped quotes before it on the line), the typed quote
  only moves the caret past the existing one.
- **How to re-apply:** in the new upstream `_smartInsertion`, add the `// JBE: patch 2` check at the top
  of the quote loop and copy `_shouldSkipQuote`. Check: `test/ui/auto_close_test.dart`.

### Patch 3 — fold or unfold many blocks at once (#103, 2026-11-23)

- **File / function:** `lib/src/code_chunk.dart`, new `CodeChunkController.collapseAll` and
  `CodeChunkController.expandAll`.
- **Why:** upstream folds one block per call, and each call copies every line. Fold All on a 23 MB file
  folds about 100,000 blocks, which would take hours that way.
- **Change:** `collapseAll(indexes)` builds the folded lines, the shifted fold markers and the moved
  caret in one pass (one editing value, like `collapse`); `expandAll()` opens every fold, nested ones
  too, in one pass. Upstream methods are unchanged.
- **Result:** 23 MB, 1.57 M lines, Release app: Fold All 2.6 s, Unfold All 2.1 s.
- **How to re-apply:** copy both `// JBE: patch 3` methods into the new upstream `CodeChunkController`;
  check that `collapse` / `expand` still use the same `CodeChunk` and `copyWith(chunks:)` model. Check:
  `test/ui/fold_all_test.dart`.
