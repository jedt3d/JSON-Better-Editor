#!/usr/bin/env bash
# Local build-and-test check for macOS. Stops at the first failing step.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

count=0
run() {
  echo "==> $*"
  if ! "$@"; then
    echo "FAIL: $*"
    exit 1
  fi
  count=$((count + 1))
}

run flutter pub get
run flutter analyze
run flutter test
run flutter build macos --debug
run flutter test integration_test -d macos

echo "PASS: all $count steps"
