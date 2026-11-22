#!/usr/bin/env bash
# Local build-and-test check for macOS. Stops at the first failing step.
set -uo pipefail
cd "$(dirname "$0")/.."

steps=(
  "flutter pub get"
  "flutter analyze"
  "flutter test"
  "flutter build macos --debug"
  "flutter test integration_test -d macos"
)

for step in "${steps[@]}"; do
  echo "==> $step"
  if ! $step; then
    echo "FAIL: $step"
    exit 1
  fi
done

echo "PASS: all ${#steps[@]} steps"
