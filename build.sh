#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$ROOT/build"
PCEAS="${PCEAS:-$(command -v pceas || true)}"
if [ -z "$PCEAS" ]; then
  echo "pceas not found. Run ./install.sh first." >&2
  exit 1
fi
cd "$ROOT"
"$PCEAS" -raw src/main.asm build/monty.pce
printf '\nBuilt: %s/build/monty.pce\n' "$ROOT"
ls -lh build/monty.pce
