#!/usr/bin/env python3
from pathlib import Path
import re
import enemy_room00 as art

ROOT = Path(__file__).resolve().parents[1]
src = (ROOT / "src/enemy_smiley_runtime.asm").read_text()
collision = (ROOT / "src/enemy_room00_collision.asm").read_text()
assets = (ROOT / "src/enemy_room00_assets_tail.asm").read_text()
build = (ROOT / "build.sh").read_text()
life = (ROOT / "src/game_life.asm").read_text()

# The port now mirrors the original four 8-byte enemy slots and aux arrays.
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

# Exact C64 spawn streams for rooms 00, 01 and 02.
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
):
    assert needle in src, needle

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
    "ina",
    "sta     enemy_anim_timer_tbl,y",
):
    assert needle in src, needle
assert "inc     enemy_anim_timer_tbl,y" not in src

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

# Collision now iterates all four slots and selects the same current 0..7 type frame.
for needle in (
    ".proc enemy_room00_collision_update",
    "enemy_state_tbl+24",
    "inc     enemy_col_slot",
    "jsr     .select_enemy_source",
    "enemy_type09_patterns",
    "enemy_type0e_patterns",
    "enemy_type0f_patterns",
    "enemy_type14_patterns",
    "enemy_type18_patterns",
    "enemy_type19_patterns",
    "jsr     .opaque_overlap",
    "sta     <monty_action_counter",
):
    assert needle in collision, needle

# Six authentic types are generated as eight PCE frames. Four-frame C64 types
# duplicate direction groups exactly; true 8-frame types retain distinct halves.
for blob in (art.SKATE, art.CLOCK, art.WASP, art.SMILEY):
    out = art.build8(blob)
    assert len(out) == 4096
    assert out[:2048] == out[2048:]
for blob in (art.BIG_NOSE, art.KETTLE):
    out = art.build8(blob)
    assert len(out) == 4096
    assert out[:2048] != out[2048:]

for needle in (
    'incbin "enemy-type09-skate.dat"',
    'incbin "enemy-type0e-clock.dat"',
    'incbin "enemy-type0f-big-nose.dat"',
    'incbin "enemy-type14-wasp.dat"',
    'incbin "enemy-type18-kettle.dat"',
    'incbin "enemy-type19-smiley.dat"',
    "enemy_palette_white:",
    "enemy_palette_yellow:",
):
    assert needle in assets, needle

for arg in ("--skate", "--clock", "--big-nose", "--wasp", "--kettle", "--smiley"):
    assert arg in build, arg

# Any death reload reruns the C64 SetupRoom enemy pass, not only enemy deaths.
assert "sta     enemy_smiley_last_room" in life

print("OK: exact four-slot C64 enemies for Rooms00-02 + H/V tick + 8-frame art/collision")
