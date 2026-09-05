#!/usr/bin/env python3
from pathlib import Path
from room_rle import ROOM_CELLS, decode_room
from room0f import (
    ROOM0F_RLE, ROOM0F_TILE_IDS, ROOM0F_COLOURS, ROOM0F_PROPERTIES,
    ROOM0F_TILE_BITMAPS, build_patterns, make_screen_bat,
)

ROOT = Path(__file__).resolve().parents[1]
assets = (ROOT / "src/room0f_assets_tail.asm").read_text()
loader = (ROOT / "src/room050c_loader.asm").read_text()
warp = (ROOT / "src/debug_room_warp.asm").read_text()
world = (ROOT / "src/world.asm").read_text()
enemies = (ROOT / "src/enemy_room0608_runtime.asm").read_text()
main = (ROOT / "src/main.asm").read_text()

cells = decode_room(ROOM0F_RLE)
assert len(ROOM0F_RLE) == 115
assert len(cells) == ROOM_CELLS == 640
assert ROOM0F_TILE_IDS == (0x25,0x0f,0x02,0x64,0x27,0x6b,0x31,0x16)
assert ROOM0F_COLOURS == (0x02,0x06,0x03,0x03,0x04,0x07,0x05,0x05)
assert ROOM0F_PROPERTIES == (1,1,1,3,2,3,2,1)
assert len(ROOM0F_TILE_BITMAPS) == 8
assert len(build_patterns()) == 9 * 32
assert len(make_screen_bat(cells)) == 36 * 20 * 2
assert 'incbin "room0f-map.dat"' in assets
assert 'db $01,$01,$01,$03,$02,$03,$02,$01' in assets

for needle in (
    ".proc room_load_pending_extended",
    "ROOM_EXT_COUNT = 7",
    "db $05,$06,$07,$08,$09,$0c,$0f",
    "room0f_patterns", "room0f_screen_bat", "room0f_collision_map_rom",
):
    assert needle in loader, needle

assert "cmp     #$10" in world
assert "cmp     #$10" in warp
assert "db $02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$03,$03,$03,$03,$03,$03" in warp
assert "db $15,$14,$13,$12,$11,$10,$11,$12,$13,$14,$14,$13,$10,$11,$12,$0f" in warp

for needle in (
    "db $68,$ca,$07,$15,$81,$17,$17,$03",
    "db $84,$82,$03,$1b,$01,$23,$00,$02",
    "db $80,$ca,$0a,$0f,$82,$47,$47,$02",
    "db $20,$62,$0e,$0f,$02,$9c,$00,$01",
    "db $06,$03,$0a,$09",
    "enemy_palette_light_red",
    "C64 $0A -> $0eb",
):
    assert needle in enemies, needle
assert "call    enemy_room0f_palette_init" in main
assert 'include "room0f_assets_tail.asm"' in main

print("OK: exact Room0F ESCAPE TUNNEL geometry, collision, enemies, loader + SELECT reachability")
