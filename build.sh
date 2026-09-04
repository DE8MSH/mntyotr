#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/build"
rm -rf "$BUILD"
mkdir -p "$BUILD"
PCEAS="${PCEAS:-$(command -v pceas || true)}"
if [ -z "$PCEAS" ]; then
  echo "pceas not found. Run ./install.sh first." >&2
  exit 1
fi

# Stage the complete assembly unit. CORE files such as bare-startup.asm,
# common.asm, vdc.asm, font.asm and joypad.asm are resolved through PCE_INCLUDE.
cp "$ROOT"/src/*.asm "$ROOT"/src/*.inc "$BUILD"/
cp "$ROOT"/src/*.dat "$BUILD"/ 2>/dev/null || true

# Generate exact logical/collision map plus native PCE BAT words from the
# checked-in C64 room-$00 RLE stream. This prevents renderer and collision data
# from silently diverging.
python3 "$ROOT/tools/room_rle.py" \
  --write "$BUILD/room00-map.dat" \
  --bat "$BUILD/room00-bat.dat" >/dev/null

cd "$BUILD"
"$PCEAS" -S -l 3 main.asm

# pceas names output after its input.
if [ -s main.pce ]; then
  mv -f main.pce monty.pce
fi
test -s monty.pce || { echo "ERROR: build/monty.pce was not generated" >&2; exit 1; }
printf '\nBuilt: %s/monty.pce\n' "$BUILD"
ls -lh monty.pce
