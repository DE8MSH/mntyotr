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
  exit 1
fi
echo "Using pceas: $PCEAS"

ELMER_INC="$HUC_HOME/examples/asm/elmer/include"
HUCC_INC="$HUC_HOME/include/hucc"
for f in "$ELMER_INC/bare-startup.asm" "$ELMER_INC/font.asm" "$HUCC_INC/common.asm" "$HUCC_INC/vdc.asm" "$HUCC_INC/joypad.asm" "$HUCC_INC/pceas.inc" "$HUCC_INC/pcengine.inc"; do
  test -f "$f" || { echo "ERROR: missing HuC include: $f" >&2; exit 1; }
done
export PCE_INCLUDE="$ELMER_INC:$HUCC_INC"
echo "PCE_INCLUDE: $PCE_INCLUDE"

PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_port.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_debug_room.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_sprite_banking.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_room00_decor.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_room01.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_room01_decor.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_room02.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_room02_decor.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_phase48_traversal.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_phase49_mechanics.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_moving_lift.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_cloud_sprite.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_cloud_contact.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_room03.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_room04.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_room050c.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_room0a0b.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_room0d0e.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_room0f.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_vertical_route.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_jump_edge_guard.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_collision_banking.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_enemy_room00_runtime.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_enemy_room0608.py"
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/test_score_runtime.py"

cp "$ROOT"/src/*.asm "$ROOT"/src/*.inc "$BUILD"/
cp "$ROOT"/src/*.dat "$BUILD"/ 2>/dev/null || true
python3 "$ROOT/tools/patch_enemy_collision_0608.py" "$BUILD/enemy_room00_collision.asm"

COMMIT_HEX="$(git -C "$ROOT" rev-parse --short=7 HEAD 2>/dev/null || printf '0000000')"
COMMIT_HEX="$(printf '%s' "$COMMIT_HEX" | tr '[:lower:]' '[:upper:]')"
case "$COMMIT_HEX" in
  ???????) ;;
  *) COMMIT_HEX="0000000" ;;
esac
python3 - "$COMMIT_HEX" "$BUILD/build-commit.dat" <<'PY'
import sys
from pathlib import Path
text = sys.argv[1]
out = Path(sys.argv[2])
try:
    data = bytes(int(ch, 16) for ch in text)
except ValueError:
    text = '0000000'
    data = bytes(7)
assert len(data) == 7
out.write_bytes(data)
print(f'ROM commit overlay: {text}')
PY

python3 "$ROOT/tools/room_rle.py" --write "$BUILD/room00-map.dat" --bat "$BUILD/room00-bat.dat" --screen-bat "$BUILD/room00-screen-bat.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room00_decor.py" --screen-bat "$BUILD/room00-screen-bat.dat" --patterns "$BUILD/room00-decor-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room01.py" --map "$BUILD/room01-map.dat" --screen-bat "$BUILD/room01-screen-bat.dat" --patterns "$BUILD/room01-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room01_decor.py" --screen-bat "$BUILD/room01-screen-bat.dat" --patterns "$BUILD/room01-decor-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room02.py" --map "$BUILD/room02-map.dat" --screen-bat "$BUILD/room02-screen-bat.dat" --patterns "$BUILD/room02-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room02_decor.py" --screen-bat "$BUILD/room02-screen-bat.dat" --patterns "$BUILD/room02-decor-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room03.py" --map "$BUILD/room03-map.dat" --screen-bat "$BUILD/room03-screen-bat.dat" --patterns "$BUILD/room03-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room04.py" --map "$BUILD/room04-map.dat" --screen-bat "$BUILD/room04-screen-bat.dat" --patterns "$BUILD/room04-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room05.py" --map "$BUILD/room05-map.dat" --screen-bat "$BUILD/room05-screen-bat.dat" --patterns "$BUILD/room05-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room06.py" --map "$BUILD/room06-map.dat" --screen-bat "$BUILD/room06-screen-bat.dat" --patterns "$BUILD/room06-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room07.py" --map "$BUILD/room07-map.dat" --screen-bat "$BUILD/room07-screen-bat.dat" --patterns "$BUILD/room07-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room08.py" --map "$BUILD/room08-map.dat" --screen-bat "$BUILD/room08-screen-bat.dat" --patterns "$BUILD/room08-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room09.py" --map "$BUILD/room09-map.dat" --screen-bat "$BUILD/room09-screen-bat.dat" --patterns "$BUILD/room09-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room0a.py" --map "$BUILD/room0a-map.dat" --screen-bat "$BUILD/room0a-screen-bat.dat" --patterns "$BUILD/room0a-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room0b.py" --map "$BUILD/room0b-map.dat" --screen-bat "$BUILD/room0b-screen-bat.dat" --patterns "$BUILD/room0b-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room0c.py" --map "$BUILD/room0c-map.dat" --screen-bat "$BUILD/room0c-screen-bat.dat" --patterns "$BUILD/room0c-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room0d.py" --map "$BUILD/room0d-map.dat" --screen-bat "$BUILD/room0d-screen-bat.dat" --patterns "$BUILD/room0d-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room0e.py" --map "$BUILD/room0e-map.dat" --screen-bat "$BUILD/room0e-screen-bat.dat" --patterns "$BUILD/room0e-patterns.dat" >/dev/null
PYTHONPATH="$ROOT/tools" python3 "$ROOT/tools/room0f.py" --map "$BUILD/room0f-map.dat" --screen-bat "$BUILD/room0f-screen-bat.dat" --patterns "$BUILD/room0f-patterns.dat" >/dev/null
python3 "$ROOT/tools/monty_sprite.py" --left "$BUILD/monty-walk-l.dat" --right "$BUILD/monty-walk-r.dat" --climb "$BUILD/monty-climb.dat" >/dev/null
python3 "$ROOT/tools/monty_somersault.py" --left "$BUILD/monty-sault-l.dat" --right "$BUILD/monty-sault-r.dat" >/dev/null
python3 "$ROOT/tools/lift_sprite.py" --write "$BUILD/lift-sprites.dat" >/dev/null
python3 "$ROOT/tools/cloud_sprite.py" --write "$BUILD/cloud-sprites.dat" >/dev/null
python3 "$ROOT/tools/enemy_room00.py" \
  --skate "$BUILD/enemy-type09-skate.dat" \
  --lamp "$BUILD/enemy-type0a-lamp.dat" \
  --knight "$BUILD/enemy-type0b-knight.dat" \
  --clock "$BUILD/enemy-type0e-clock.dat" \
  --big-nose "$BUILD/enemy-type0f-big-nose.dat" \
  --rubik "$BUILD/enemy-type11-rubik.dat" \
  --pi-pie "$BUILD/enemy-type13-pi-pie.dat" \
  --wasp "$BUILD/enemy-type14-wasp.dat" \
  --bubble "$BUILD/enemy-type15-bubble.dat" \
  --sad-ghost "$BUILD/enemy-type16-sad-ghost.dat" \
  --kettle "$BUILD/enemy-type18-kettle.dat" \
  --smiley "$BUILD/enemy-type19-smiley.dat" \
  --hand "$BUILD/enemy-type1b-hand.dat" \
  --tank "$BUILD/enemy-type1c-tank.dat" \
  --jelly-fish "$BUILD/enemy-type1d-jelly-fish.dat" >/dev/null
cd "$BUILD"
"$PCEAS" --newproc --strip -m -l 2 -S -gA --raw main.asm
if [ -s main.pce ]; then mv -f main.pce monty.pce; fi
if [ -s main.sym ]; then mv -f main.sym monty.sym; fi
if [ -s main.lst ]; then mv -f main.lst monty.lst; fi
test -s monty.pce || { echo "ERROR: build/monty.pce was not generated" >&2; exit 1; }
printf '\nBuilt: %s/monty.pce\n' "$BUILD"; ls -lh monty.pce
