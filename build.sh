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

HUC_HOME="${HUC_HOME:-$HOME/.local/opt/huc}"
ELMER_INC="$HUC_HOME/examples/asm/elmer/include"
HUCC_INC="$HUC_HOME/include/hucc"
for f in "$ELMER_INC/bare-startup.asm" "$HUCC_INC/common.asm" "$HUCC_INC/vdc.asm" "$HUCC_INC/font.asm" "$HUCC_INC/joypad.asm"; do
  test -f "$f" || { echo "ERROR: missing CORE include: $f" >&2; exit 1; }
done
export PCE_INCLUDE="$ELMER_INC:$HUCC_INC"

PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_port.py"

cp "$ROOT"/src/*.asm "$ROOT"/src/*.inc "$BUILD"/
cp "$ROOT"/src/*.dat "$BUILD"/ 2>/dev/null || true

python3 "$ROOT/tools/room_rle.py" --write "$BUILD/room00-map.dat" --bat "$BUILD/room00-bat.dat" >/dev/null
python3 "$ROOT/tools/monty_sprite.py" --write "$BUILD/monty-walk-l.dat" >/dev/null

cd "$BUILD"
"$PCEAS" -S -gA -l 3 main.asm

if [ -s main.pce ]; then mv -f main.pce monty.pce; fi
if [ -s main.sym ]; then mv -f main.sym monty.sym; fi
if [ -s main.lst ]; then mv -f main.lst monty.lst; fi

test -s monty.pce || { echo "ERROR: build/monty.pce was not generated" >&2; exit 1; }
printf '\nBuilt: %s/monty.pce\n' "$BUILD"
ls -lh monty.pce
