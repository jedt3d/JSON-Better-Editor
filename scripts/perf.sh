#!/usr/bin/env bash
# Performance check (#44, decision #59): builds tool/perf/perf_main.dart as a
# macOS profile build and runs it once per file size in MB.
# Usage: scripts/perf.sh [size ...]   (default: 1 5 10 20 50)
set -euo pipefail
cd "$(dirname "$0")/.."
flutter build macos --profile -t tool/perf/perf_main.dart >/dev/null
app="build/macos/Build/Products/Profile/JSON Better Editor.app/Contents/MacOS/JSON Better Editor"
for mb in "${@:-1 5 10 20 50}"; do
  for size in $mb; do
    echo "== ${size} MB"
    PERF_MB="$size" "$app" 2>/dev/null | grep '^PERF ' | sed 's/^PERF /  /'
  done
done
