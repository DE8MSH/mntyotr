#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/build"
rm -rf "$BUILD"; mkdir -p "$BUILD"

HUC_HOME="${HUC_HOME:-$HOME/.local/opt/huc}"
if [ -n "${PCEAS:-}" ] && [ -x "$PCEAS" ]; then
  :
elif command -v pceas >/dev/null 2>&1; then
  PCEAS="$(command -v pceas)"
elif [ -x "$HUC_HOME/src/mkit/as/pceas" ]; then
  PCEAS="$HUC_HOME/src/mkit/as/pceas"
elif [ -x "$HUC_HOME/src/bin/pceas" ]; then
  PCEAS="$HUC_HOME/src/bin/pceas"
elif [ -x "$HUC_HOME/bin/pceas" ]; then
  PCEAS="$HUC_HOME/bin/pceas"
else
  echo "ERROR: pceas not found." >&2
  echo "Checked PATH and HuC under: $HUC_HOME" >&2
  echo "Run ./install.sh, or invoke as: PCEAS=/full/path/to/pceas ./build.sh" >&2
  exit 1
fi
echo "Using pceas: $PCEAS"

ELMER_INC="$HUC_HOME/examples/asm/elmer/include"
HUCC_INC="$HUC_HOME/include/hucc"
for f in \
  "$ELMER_INC/bare-startup.asm" \
  "$ELMER_INC/font.asm" \
  "$HUCC_INC/common.asm" \
  "$HUCC_INC/vdc.asm" \
  "$HUCC_INC/joypad.asm" \
  "$HUCC_INC/pceas.inc" \
  "$HUCC_INC/pcengine.inc"; do
  test -f "$f" || {
    echo "ERROR: missing HuC include: $f" >&2
    echo "HuC checkout may be incomplete or incompatible." >&2
    exit 1
  }
done
export PCE_INCLUDE="$ELMER_INC:$HUCC_INC"
echo "PCE_INCLUDE: $PCE_INCLUDE"

PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_port.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_sprite_banking.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_room00_decor.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_room01.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_jump_edge_guard.py"
cp "$ROOT"/src/*.asm "$ROOT"/src/*.inc "$BUILD"/
cp "$ROOT"/src/*.dat "$BUILD"/ 2>/dev/null || true
python3 "$ROOT/tools/room_rle.py" \
  --write "$BUILD/room00-map.dat" \
  --bat "$BUILD/room00-bat.dat" \
  --screen-bat "$BUILD/room00-screen-bat.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room00_decor.py" \
  --screen-bat "$BUILD/room00-screen-bat.dat" \
  --patterns "$BUILD/room00-decor-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room01.py" \
  --map "$BUILD/room01-map.dat" \
  --screen-bat "$BUILD/room01-screen-bat.dat" \
  --patterns "$BUILD/room01-patterns.dat" >/dev/null
python3 "$ROOT/tools/monty_sprite.py" --left "$BUILD/monty-walk-l.dat" --right "$BUILD/monty-walk-r.dat" --climb "$BUILD/monty-climb.dat" >/dev/null
python3 "$ROOT/tools/monty_somersault.py" --left "$BUILD/monty-sault-l.dat" --right "$BUILD/monty-sault-r.dat" >/dev/null
cd "$BUILD"
"$PCEAS" --newproc --strip -m -l 2 -S -gA --raw main.asm
if [ -s main.pce ]; then mv -f main.pce monty.pce; fi
if [ -s main.sym ]; then mv -f main.sym monty.sym; fi
if [ -s main.lst ]; then mv -f main.lst monty.lst; fi
test -s monty.pce || { echo "ERROR: build/monty.pce was not generated" >&2; exit 1; }
printf '\nBuilt: %s/monty.pce\n' "$BUILD"; ls -lh monty.pce
