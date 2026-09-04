#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/build"
rm -rf "$BUILD"; mkdir -p "$BUILD"

HUC_HOME="${HUC_HOME:-$HOME/.local/opt/huc}"
# Do not require the install shell to have refreshed PATH. Prefer an explicit
# PCEAS override, then PATH, then the known locations used by current/older HuC.
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

# The pure-ASM Elmer CORE used by this port lives in examples/asm/elmer/include
# in current pce-devel/huc. Older scripts incorrectly expected font/vdc/joypad
# under include/hucc; that directory is the HuCC compiler runtime, not Elmer.
ELMER_INC="$HUC_HOME/examples/asm/elmer/include"
HUCC_INC="$HUC_HOME/include/hucc"
for f in bare-startup.asm common.asm vdc.asm font.asm joypad.asm; do
  test -f "$ELMER_INC/$f" || {
    echo "ERROR: missing Elmer CORE include: $ELMER_INC/$f" >&2
    echo "HuC checkout may be incomplete or incompatible." >&2
    exit 1
  }
done
export PCE_INCLUDE="$ELMER_INC:$HUCC_INC"

PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_port.py"
cp "$ROOT"/src/*.asm "$ROOT"/src/*.inc "$BUILD"/
cp "$ROOT"/src/*.dat "$BUILD"/ 2>/dev/null || true
python3 "$ROOT/tools/room_rle.py" --write "$BUILD/room00-map.dat" --bat "$BUILD/room00-bat.dat" >/dev/null
python3 "$ROOT/tools/monty_sprite.py" --left "$BUILD/monty-walk-l.dat" --right "$BUILD/monty-walk-r.dat" --climb "$BUILD/monty-climb.dat" >/dev/null
cd "$BUILD"
"$PCEAS" -S -gA -l 3 main.asm
if [ -s main.pce ]; then mv -f main.pce monty.pce; fi
if [ -s main.sym ]; then mv -f main.sym monty.sym; fi
if [ -s main.lst ]; then mv -f main.lst monty.lst; fi
test -s monty.pce || { echo "ERROR: build/monty.pce was not generated" >&2; exit 1; }
printf '\nBuilt: %s/monty.pce\n' "$BUILD"; ls -lh monty.pce
