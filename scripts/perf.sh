#!/usr/bin/env bash
# Performance check (#44, decision #59): builds tool/perf/perf_main.dart as a
# macOS profile build and runs it once per file size in MB.
# Usage: scripts/perf.sh [--release] [size ...]   (default: 1 5 10 20 50)
# --release measures a Release build instead of a profile build (it replaces
# the Release app in build/ with the harness).
set -euo pipefail
cd "$(dirname "$0")/.."
mode=profile
if [ "${1:-}" = "--release" ]; then mode=release; shift; fi
flutter build macos --$mode -t tool/perf/perf_main.dart >/dev/null
dir=$([ $mode = release ] && echo Release || echo Profile)
app="build/macos/Build/Products/$dir/JSON Better Editor.app/Contents/MacOS/JSON Better Editor"
for mb in "${@:-1 5 10 20 50}"; do
  for size in $mb; do
    echo "== ${size} MB"
    PERF_MB="$size" "$app" 2>/dev/null | grep '^PERF ' | sed 's/^PERF /  /'
  done
done
