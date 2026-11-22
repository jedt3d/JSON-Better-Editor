#!/usr/bin/env bash
# Screenshot of the app's window only (not the whole screen).
# Usage: scripts/shot.sh <out.png> [process-name-substring]
set -euo pipefail
id=$(swift "$(dirname "$0")/window_id.swift" "${2:-JSON Better Editor}")
[ -n "$id" ] || { echo "no window found" >&2; exit 1; }
screencapture -x -o -l "$id" "$1"
