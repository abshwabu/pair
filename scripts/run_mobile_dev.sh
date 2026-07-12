#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFINES_FILE="$ROOT/mobile/dart_defines.local.json"
EXAMPLE_FILE="$ROOT/mobile/dart_defines.local.json.example"

if [[ ! -f "$DEFINES_FILE" ]]; then
  echo "Missing $DEFINES_FILE"
  echo "Copy the example and set your machine's LAN IP:"
  echo "  cp mobile/dart_defines.local.json.example mobile/dart_defines.local.json"
  exit 1
fi

cd "$ROOT/mobile"
exec flutter run --dart-define-from-file=dart_defines.local.json "$@"
