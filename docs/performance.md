# Text-mode performance (#44)

Targets (decision #59): a 5 MB file opens and is shown in 2 s or less; typing, scrolling and search show
no visible lag (frame time 16 ms or less in a profile build). Also find the largest file that still opens
within 2–3 s.

## How to measure

```bash
scripts/perf.sh 1 5 10 20 30 50
```

It builds `tool/perf/perf_main.dart` as a macOS **profile** build and runs it once per size. The harness
generates pretty-printed JSON of that size (records with nested objects, arrays and every value type),
writes it to a temp file, opens it the way Finder does (the `openPath` request), then types, scrolls,
searches, matches brackets, collects keys for suggestions and folds the root block, printing one
`PERF name=value` line per measurement. Frame times are build + raster from Flutter's `FrameTiming`.

## Results (2026-11-22, this Mac, Flutter 3.50.1, re_editor 0.10.0 fork with patch 1)

Re-measured after the fork patch (#71). Earlier numbers from #44 are in git history.

| | 1 MB | 5 MB | 10 MB | 20 MB | 30 MB | 50 MB |
|---|---|---|---|---|---|---|
| Lines | 51,910 | 259,506 | 519,010 | 1,038,002 | 1,556,994 | 2,594,977 |
| **Open and show** | 164 ms | **485 ms** | 859 ms | 1.64 s | **2.47 s** | 4.16 s |
| Fold markers ready after open | at once | 1.3 s | 6.1 s | 25 s | 57 s | > 60 s |
| Typing: longest frame | 4.4 ms | **8.1 ms** | 15 ms | 28 ms | 32 ms | 9 ms |
| Scrolling, 60 jumps across the file incl. end → top: frame p50 / longest | 2.6 / 3.7 ms | **5.4 / 9.7 ms** | 9.1 / 18 ms | 17 / 78 ms | 26 / 169 ms | 6.1 / 9.8 ms |
| Search, word not present | 4 ms | **19 ms** | 25 ms | 54 ms | 67 ms | 124 ms |
| Key suggestions: first in a session / later | 48 / 0 ms | 295 / 0 ms | 666 / 0 ms | 1.4 s / 0 | 2.2 s / 0 | 2.8 s / 0 |

Before the fork patch, one jump from the end to the top took 427 ms (1 MB), 2.7 s (5 MB), 7.2 s (10 MB)
and 92 s (50 MB) in a single frame. The 50 MB column is lower than 30 MB for typing and scrolling because
its fold analysis never finished, so less work ran.

## Against the targets at 5 MB

- Open and show: **met** (0.5 s ≤ 2 s).
- Typing: **met** (longest frame 8 ms).
- Scrolling, including a jump from the end to the top: **met** (longest frame 9.7 ms; fork patch 1, #71).
- Search: **met** (19 ms; a word with 15,888 hits takes about 50 ms).
- First key suggestion in a session: 0.3 s, still open in #67.

**Current capacity: about 30 MB** (opens and shows in 2.5 s). Files up to 5 MB meet the targets apart from
the first key suggestion; between 10 and 30 MB the file opens but typing and fold markers lag.

## What #44 fixed

The first run at 5 MB opened in 2.1 s with a 1.6 s frame, typing took 33–83 ms per key, search 0.9 s, and
fold markers never appeared. Causes and fixes:

- `CodeLines[i]` and `CodeLines.length` walk all segments on every call, so line-by-line loops were
  quadratic. `lineList` (`lib/ui/line_list.dart`) builds a plain list once per `CodeLines` object; bracket
  matching, search, key suggestions and folding use it.
- re_editor's default fold analyser has the same quadratic indexing; the app's own analyser
  (`multiLineBlocks`) reads the lines once.
- Bracket scanning reads each line's characters once instead of looking up string ranges per character.
- The edited check (#30, #36) compared every line on every keystroke; it now compares only when the
  document was unedited (a fold, or the first edit).
- Search joins the lines and runs one regular expression, splitting into tokens only the lines with a hit.
- Key suggestions reuse the collected keys for 2 s (decision #79).

## What #71 fixed (fork patch 1)

re_editor laid out every line between the first visible line and the target when scrolling up, to add
up wrapped heights. Without word wrap all lines have the same height, so the patched fork jumps straight
to the target line. See `packages/re_editor/JBE_CHANGES.md`.
