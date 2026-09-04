#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$ROOT/build"
PCEAS="${PCEAS:-$(command -v pceas || true)}"
if [ -z "$PCEAS" ]; then
  echo "pceas not found. Run ./install.sh first." >&2
  exit 1
fi

# pceas writes <input>.pce beside the source; assemble from a staging copy
# so generated files never pollute src/.
cp "$ROOT/src/main.asm" "$ROOT/build/monty.asm"
cd "$ROOT/build"
"$PCEAS" -S -l 3 monty.asm
rm -f monty.asm

test -s monty.pce || { echo "ERROR: build/monty.pce was not generated" >&2; exit 1; }
printf '\nBuilt: %s/build/monty.pce\n' "$ROOT"
ls -lh monty.pce
