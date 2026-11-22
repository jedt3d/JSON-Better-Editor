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

## Results (2026-11-22, this Mac, Flutter 3.50.1, re_editor 0.10.0)

| | 1 MB | 5 MB | 10 MB | 20 MB | 30 MB | 50 MB |
|---|---|---|---|---|---|---|
| Lines | 51,910 | 259,506 | 519,010 | 1,038,002 | 1,556,994 | 2,594,977 |
| **Open and show** | 148 ms | **495 ms** | 890 ms | 1.68 s | **2.52 s** | 4.18 s |
| Longest frame while opening | 12 ms | 27 ms | 45 ms | 88 ms | 140 ms | 232 ms |
| Fold markers ready after open | at once | 1.3 s | 6.2 s | 25 s | 58 s | > 60 s |
| Typing: time per key (wall) | 8.6 ms | 19 ms | 38 ms | 70 ms | 116 ms | 75 ms |
| Typing: longest frame | 3.7 ms | **8.0 ms** | 19 ms | 21 ms | 61 ms | 9 ms |
| Scrolling in steps: frame p50 | 2.3 ms | **5.3 ms** | 9.4 ms | 18 ms | 27 ms | 6.9 ms |
| Jump from end to top: one frame | 427 ms | **2.7 s** | 7.2 s | 22 s | 42 s | 92 s |
| Search, word not present | 3 ms | **13 ms** | 27 ms | 83 ms | 120 ms | 132 ms |
| Search, very common word | 9 ms | 51 ms | 104 ms | 208 ms | 270 ms | 423 ms |
| Bracket pair from the root `[` | 2 ms | 13 ms | 22 ms | 45 ms | 80 ms | 104 ms |
| Key suggestions: first / later | 53 / 0 ms | 305 / 0 ms | 632 / 0 ms | 1.3 s / 0 | 2.0 s / 0 | 2.8 s / 0 |
| Fold the root block (incl. edited check) | 5 ms | 15 ms | 40 ms | 85 ms | 265 ms | 3 ms |

Typing wall time includes re_editor sending the text to its highlighting and folding isolates. The 50 MB
column is lower than 30 MB for typing because its fold analysis never finished, so less work ran.

## Against the targets at 5 MB

- Open and show: **met** (0.5 s ≤ 2 s).
- Typing: **met** (longest frame 8 ms).
- Scrolling in steps: **met** (p50 5 ms). A single jump from the end to the top is **not met** (2.7 s): follow-up #67.
- Search: **met** for normal queries (13 ms); a word with 15,888 hits takes 51 ms: in #67.
- First key suggestion in a session: 305 ms: in #67.

**Current capacity: about 30 MB** (opens and shows in 2.5 s). Files up to 5 MB meet the targets apart from
#67; between 10 and 30 MB the file opens but typing and fold markers lag.

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
