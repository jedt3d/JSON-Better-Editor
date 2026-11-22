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

_None yet._
