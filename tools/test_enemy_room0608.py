#!/usr/bin/env python3
from pathlib import Path
from patch_enemy_collision_0608 import patch_collision

ROOT = Path(__file__).resolve().parents[1]
runtime = (ROOT / "src/enemy_room0608_runtime.asm").read_text()
collision = (ROOT / "src/enemy_room00_collision.asm").read_text()
game_life = (ROOT / "src/game_life.asm").read_text()
assets = (ROOT / "src/enemy_room00_assets_tail.asm").read_text()

# Exact SetupRoom-transformed C64 states from room_data.asm.
for needle in (
    "db $40,$ca,$07,$1c,$02,$10,$00,$04",  # Room06 Tank
    "db $54,$5a,$03,$19,$01,$26,$00,$03",  # Room06 Smiley
    "db $90,$52,$01,$11,$01,$27,$00,$01",  # Room06 Rubik
    "db $48,$ca,$07,$0a,$02,$27,$00,$02",  # Room08 Lamp
    "db $70,$ca,$03,$13,$81,$27,$27,$02",  # Room08 Pi/Pie reverse vertical
    "db $34,$6a,$01,$13,$01,$1d,$00,$03",  # Room08 Pi/Pie
    "db $70,$5a,$03,$15,$82,$80,$80,$02",  # Room08 Bubble reverse horizontal
):
    assert needle in runtime, needle

for needle in (
    "enemy_type11_patterns",
    "enemy_type13_patterns",
    "enemy_type1c_patterns",
):
    assert needle in runtime, needle
    assert needle in assets, needle

# The build-copy collision patch must select the authentic ROM frame for all
# three newly encountered types rather than falling through to Jellyfish $1D.
patched = patch_collision(collision)
for type_id in (0x11, 0x13, 0x1C):
    needle = f"enemy_type{type_id:02x}_patterns"
    assert needle in patched, needle
assert "cmp     #$11" in patched
assert "cmp     #$13" in patched
assert "cmp     #$1c" in patched

# Room-entry/death reload path must reseed the exact records.
assert 'include "enemy_room0608_runtime.asm"' in game_life
assert "call    enemy_room0608_room_sync" in game_life

print("OK: exact Room06/08 enemy state, art and pixel-collision selector")
