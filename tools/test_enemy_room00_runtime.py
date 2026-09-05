#!/usr/bin/env python3
from pathlib import Path
import re
import enemy_room00 as art

ROOT = Path(__file__).resolve().parents[1]
src = (ROOT / "src/enemy_smiley_runtime.asm").read_text()
room07 = (ROOT / "src/enemy_room07_runtime.asm").read_text()
collision = (ROOT / "src/enemy_room00_collision.asm").read_text()
assets = (ROOT / "src/enemy_room00_assets_tail.asm").read_text()
build = (ROOT / "build.sh").read_text()
life = (ROOT / "src/game_life.asm").read_text()

# The port mirrors the original four 8-byte enemy slots and aux arrays.
for needle in (
    "enemy_state_tbl:          ds 32",
    "enemy_xmsb_tbl:           ds 4",
    "enemy_anim_timer_tbl:     ds 4",
    "ENEMY_SLOT0_VRAM = $3800",
    "ENEMY_SLOT1_VRAM = $4000",
    "ENEMY_SLOT2_VRAM = $4800",
    "ENEMY_SLOT3_VRAM = $5000",
    "ENEMY_SAT_BASE   = SAT_ADDR+32",
    ".dir_flags:\n        db $00,$82,$02,$81,$01",
):
    assert needle in src, needle

# Exact C64 spawn streams active in the generic selector for rooms 00..05.
for needle in (
    "db $05,$b8,$8f,$04,$19,$02,$25",
    "db $03,$78,$37,$03,$09,$03,$13",
    "db $06,$28,$27,$02,$0f,$02,$2c",
    "db $07,$28,$77,$04,$09,$04,$11",
    "db $05,$58,$57,$02,$18,$01,$2d",
    "db $05,$b0,$a7,$04,$0e,$03,$27",
    "db $07,$68,$27,$03,$14,$02,$3c",
    "db $06,$a8,$57,$02,$09,$01,$1f",
    "db $05,$28,$67,$03,$19,$04,$0e",
    "db $07,$70,$2f,$03,$1b,$02,$1a",
    "db $06,$58,$2f,$01,$0a,$01,$20",
    "db $05,$60,$97,$02,$0e,$02,$48",
    "db $03,$30,$a7,$04,$1d,$01,$20",
    "db $05,$48,$47,$02,$18,$03,$20",
    "db $0e,$88,$9f,$04,$0e,$04,$16",
    "db $06,$ff,$5f,$04,$0b,$02,$17",
    "db $04,$70,$77,$01,$15,$01,$30",
    "db $05,$70,$67,$02,$18,$02,$24",
    "db $07,$40,$2f,$03,$14,$03,$20",
    "db $02,$3e,$97,$01,$1d,$01,$20",
    "db $06,$c8,$2f,$03,$16,$02,$20",
):
    assert needle in src, needle
for room in range(6):
    assert f"cmp     #${room:02x}" in src
    assert f"#<.room{room:02x}_records" in src

# Room07 is already exact because all four original enemies are Bubble type $15,
# which the generic upload, SAT animation and pixel-collision paths support.
for needle in (
    ".proc enemy_room07_room_sync",
    "cmp     #$07",
    "call    map_bp_to_mpr34",
    "#<enemy_type15_patterns",
    "BANK(enemy_type15_patterns)",
    "db $30,$ca,$02,$15,$81,$17,$17,$02",
    "db $6c,$5a,$03,$15,$01,$1a,$00,$03",
    "db $3c,$5a,$04,$15,$01,$27,$00,$01",
    "db $94,$52,$05,$15,$01,$24,$00,$02",
    "db $07,$03,$04,$08",
):
    assert needle in room07, needle
assert 'include "enemy_room07_runtime.asm"' in life
assert "call    enemy_room07_room_sync" in life
room07_procs = re.findall(r"(?ms)^\.proc\s+([^\n]+)\n(.*?)^\.endp\s*$", room07)
assert len(room07_procs) == 1
assert re.search(r"(?m)^\s*leave(?:\s|$)", room07_procs[0][1])

# Seven exact C64 single-colour sprite palettes also cover Rooms06-08.
for needle in (
    "enemy_palette_cyan", "enemy_palette_purple", "enemy_palette_white",
    "enemy_palette_yellow", "enemy_palette_red", "enemy_palette_green",
    "enemy_palette_light_blue",
    "cmp     #$02", "cmp     #$05", "lda     #9",
):
    assert needle in src or needle in assets, needle
for value in ("$19d", "$0a4", "$1ff", "$1fb", "$062", "$152", "$0de"):
    assert value in assets, value

# SetupRoom transforms and reverse-direction initial step=range.
for needle in (
    "lsr     a\n        clc\n        adc     #$1c",
    "lda     #$f9",
    "sbc     enemy_tmp_color",
    "sta     enemy_state_tbl+6,x",
    "lda     enemy_state_tbl+5,x",
):
    assert needle in src, needle

# Exact odd-frame Enemies.Tick plus vertical and horizontal movement semantics.
for needle in (
    "lda     <game_tick_counter",
    "and     #$01",
    "ldy     #3",
    "jsr     .move_vertical",
    "jsr     .move_horizontal",
    "inc     enemy_state_tbl+6,x",
    "dec     enemy_state_tbl+6,x",
    "lda     enemy_xmsb_tbl,y",
    "and     #1",
    "inc     enemy_state_tbl,x",
    "dec     enemy_state_tbl,x",
    "lda     enemy_anim_timer_tbl,y",
    "clc\n        adc     #1",
    "sta     enemy_anim_timer_tbl,y",
):
    assert needle in src, needle
assert "inc     enemy_anim_timer_tbl,y" not in src
assert not re.search(r"(?m)^\s*ina\s*(?:;.*)?$", src), "raw INA instruction remains"

# --newproc externally returns with LEAVE; internal helper RTS is intentional.
procs = re.findall(r"(?ms)^\.proc\s+([^\n]+)\n(.*?)^\.endp\s*$", src)
assert len(procs) == 4, [name for name, _ in procs]
for name, body in procs:
    assert re.search(r"(?m)^\s*leave(?:\s|$)", body), f"no LEAVE in relocated proc {name}"

# Rendering uses original direction group (forward +4, reverse +0), doubled X,
# four slot-specific 8-frame VRAM blocks, and two SAT entries per C64 sprite.
for needle in (
    "C64 frame = ((anim_timer & 6)>>1) + (direction forward ? 4 : 0)",
    "lda     #4",
    "and     #$06",
    "adc     enemy_tmp_frame",
    "adc     #$c0",
    "adc     #8",
    "adc     #24",
    "ora     #$80",
):
    assert needle in src, needle

# Every type currently active through Room07 selects its own upload and exact
# collision frame. Room06/08-only types are generated below, then wired next.
for type_id in (0x09,0x0a,0x0b,0x0e,0x0f,0x14,0x15,0x16,0x18,0x19,0x1b,0x1d):
    needle = f"enemy_type{type_id:02x}_patterns"
    assert needle in src, needle
    assert needle in collision, needle

# Collision still iterates all four slots and rejects by coordinates before masks.
for needle in (
    ".proc enemy_room00_collision_update",
    ".scan_slot:",
    ".prepare_masks:",
    ".precise_scan:",
    "cmp     #4",
    "inc     enemy_col_slot",
    "jsr     .coarse_overlap",
    "jsr     .select_enemy_source",
    "jsr     .opaque_overlap",
    "sta     <monty_action_counter",
):
    assert needle in collision, needle

proc_body = re.search(
    r"(?ms)^\.proc\s+enemy_room00_collision_update\n(.*?)^\.endp\s*$",
    collision,
).group(1)
assert proc_body.index("jsr     .coarse_overlap") < proc_body.index("php")
assert proc_body.index("jsr     .coarse_overlap") < proc_body.index("jsr     .convert_monty_mask")
assert ".done_unmapped:\n        leave" in proc_body

# Authentic C64 sprite blocks prepared for Rooms00-08. Four-frame C64 types are
# duplicated into direction groups; true eight-frame types keep distinct halves.
for blob in (
    art.SKATE, art.CLOCK, art.RUBIK, art.PI_PIE, art.WASP, art.BUBBLE,
    art.SAD_GHOST, art.SMILEY, art.JELLY_FISH,
):
    out = art.build8(blob)
    assert len(out) == 4096
    assert out[:2048] == out[2048:]
for blob in (art.LAMP, art.KNIGHT, art.BIG_NOSE, art.KETTLE, art.HAND, art.TANK):
    out = art.build8(blob)
    assert len(out) == 4096
    assert out[:2048] != out[2048:]

for needle in (
    'incbin "enemy-type09-skate.dat"',
    'incbin "enemy-type0a-lamp.dat"',
    'incbin "enemy-type0b-knight.dat"',
    'incbin "enemy-type0e-clock.dat"',
    'incbin "enemy-type0f-big-nose.dat"',
    'incbin "enemy-type11-rubik.dat"',
    'incbin "enemy-type13-pi-pie.dat"',
    'incbin "enemy-type14-wasp.dat"',
    'incbin "enemy-type15-bubble.dat"',
    'incbin "enemy-type16-sad-ghost.dat"',
    'incbin "enemy-type18-kettle.dat"',
    'incbin "enemy-type19-smiley.dat"',
    'incbin "enemy-type1b-hand.dat"',
    'incbin "enemy-type1c-tank.dat"',
    'incbin "enemy-type1d-jelly-fish.dat"',
):
    assert needle in assets, needle

for arg in (
    "--skate", "--lamp", "--knight", "--clock", "--big-nose", "--rubik",
    "--pi-pie", "--wasp", "--bubble", "--sad-ghost", "--kettle", "--smiley",
    "--hand", "--tank", "--jelly-fish",
):
    assert arg in build, arg

# Any death reload reruns the C64 SetupRoom enemy pass, not only enemy deaths.
assert "sta     enemy_smiley_last_room" in life

print("OK: exact four-slot C64 enemies active through Room07; Room06/08 art prepared")
