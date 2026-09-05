#!/usr/bin/env python3
from pathlib import Path

from room_rle import decode_room, ROOM_CELLS
from room0c import (
    ROOM0C_RLE, ROOM0C_PROPERTIES, ROOM0C_BOLLARD_HEAD,
    ROOM0C_BOLLARD_CODE, apply_bollard_head,
)
from room0d import ROOM0D_RLE

ROOT = Path(__file__).resolve().parents[1]


def main():
    main_asm = (ROOT/'src/main.asm').read_text()
    sweep = (ROOT/'src/jump_collision_sweep.asm').read_text()
    cloud = (ROOT/'src/rising_cloud.asm').read_text()
    bollard = (ROOT/'src/rising_bollard.asm').read_text()
    static = (ROOT/'src/standard_piledriver_static.asm').read_text()
    bundle = (ROOT/'src/standard_piledriver_bundle.asm').read_text()
    life = (ROOT/'src/game_life.asm').read_text()

    assert 'call    monty_jump_step_swept' in main_asm
    assert '.up_pixel:' in sweep and '.down_pixel:' in sweep
    assert 'call    monty_check_tile_above' in sweep
    assert 'call    monty_check_tile_below' in sweep

    assert 'include "rising_cloud.asm"' in main_asm
    assert 'call    rising_cloud_update' in main_asm
    assert 'CLOUD_VIS_COL       = 12' in cloud
    assert 'CLOUD_CODE          = 8' in cloud
    assert 'dec     <rising_cloud_y' in cloud

    base0c = decode_room(ROOM0C_RLE)
    assert len(base0c) == ROOM_CELLS == 640
    assert ROOM0C_BOLLARD_HEAD == (12, 23)
    assert ROOM0C_PROPERTIES[ROOM0C_BOLLARD_CODE-1] == 3
    assert apply_bollard_head(base0c)[12*32+23] == ROOM0C_BOLLARD_CODE

    assert 'include "rising_bollard.asm"' in main_asm
    assert 'call    rising_bollard_update' in main_asm
    assert 'include "standard_piledriver_bundle.asm"' in bollard
    assert 'include "standard_piledriver_static.asm"' in bundle

    # Proven static DrawShaft is retained; only the safe regenerated-char
    # animation is now ticked. Old mutable-buffer runtime remains unused.
    assert 'jmp     piledriver_static_init' in bollard
    assert 'jmp     piledriver_static_room_sync' in bollard
    assert 'call    piledriver_static_update' in bollard
    assert 'call    piledriver_update' not in bollard
    assert 'call    piledriver_room_sync' not in bollard

    # Exact C64 configs for current rooms.
    assert 'room $01: col $07,row $05,height 4,char $10' in static
    assert 'col $1f,row $0c,height 6,char $22' in static
    assert 'room $02: col $15,row $05,height 4,char $10' in static
    assert 'room $0b: col $13,row $11,height 4,char $10' in static
    assert 'lda     #$1f' in static
    assert 'lda     #$2f' in static

    # Original state machine: random delay $14..$53, position starts 5,
    # descends/retracts in 2px steps. Visible shift is exactly position-5.
    assert 'piledriver_static_update:' in static
    assert 'and     #$3f' in static and 'adc     #$14' in static
    assert 'lda     #5\n        sta     <pile_static_position' in static
    assert static.count('inc     <pile_static_position') == 2
    assert static.count('dec     <pile_static_position') == 2
    assert static.count('sbc     #5\n        sta     <pile_static_shift') == 2
    assert 'lda     #2\n        sta     <pile_static_state' in static

    # Safe renderer regenerates the C64 48-byte-column shift directly, avoiding
    # the crash-prone 144-byte RAM pointer walks.
    assert 'piledriver_static_upload_selected:' in static
    assert 'piledriver_static_global' in static
    assert 'sbc     <pile_static_shift' in static
    assert 'piledriver_buf0' not in static
    assert 'piledriver_buf1' not in static

    # Exact source seed glyphs and proven DrawShaft BAT high bytes.
    assert 'db $0f,$0f,$00,$ff,$ff,$ff,$7f,$00' in static
    assert 'db $ff,$ff,$00,$ff,$ff,$ff,$ff,$00' in static
    assert 'db $f0,$f0,$00,$ff,$ff,$ff,$fe,$00' in static
    assert 'piledriver_static_draw:' in static
    assert 'lda     #$61' in static
    assert 'lda     #$51' in static
    assert 'lda     #$41' in static

    # This stage is visuals/state only. Standard Piledriver death collision is
    # deliberately not wired until emulator confirms stable motion.
    update = static[static.index('piledriver_static_update:'):static.index('piledriver_static_upload_selected:')]
    assert 'monty_action_counter' not in update

    cells0d = decode_room(ROOM0D_RLE)
    assert len(cells0d) == 640
    assert ROOM0D_RLE[30:39] == bytes.fromhex('01 f0 f0 f0 f0 f0 f0 22 20')

    assert 'include "game_life.asm"' in main_asm
    assert 'call    game_life_check' in main_asm
    for event in ('#2','#3','#4','#5','#7'):
        assert f'cmp     {event}' in life

    print('OK: Room01 proven DrawShaft + safe original Piledriver 2px down/up animation; collision still gated')


if __name__ == '__main__':
    main()
