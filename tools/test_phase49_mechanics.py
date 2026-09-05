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
    pile = (ROOT/'src/standard_piledriver.asm').read_text()
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

    # Crash containment: keep the original-data Piledriver source in-tree but do
    # not execute its first dynamic-BG pass until static DrawShaft is proven safe.
    assert 'dynamic-BG renderer is temporarily' in bollard
    assert 'call    piledriver_update' not in bollard
    assert 'call    piledriver_room_sync' not in bollard
    assert 'jmp     piledriver_init' not in bollard

    # Original configs/visual model remain the source for the rebuild.
    assert '; $01,$07,$05,$04,$10 and $01,$1f,$0c,$06,$22' in pile
    assert '; $02,$15,$05,$04,$10' in pile
    assert '; $0b,$13,$11,$04,$10' in pile
    assert 'piledriver_buf0: ds 144' in pile
    assert 'piledriver_buf1: ds 144' in pile
    assert 'piledriver_draw_shaft:' in pile
    assert 'piledriver_shift_down:' in pile
    assert 'piledriver_shift_up:' in pile
    assert 'db $0f,$0f,$00,$ff,$ff,$ff,$7f,$00' in pile
    assert 'db $ff,$ff,$00,$ff,$ff,$ff,$ff,$00' in pile
    assert 'db $f0,$f0,$00,$ff,$ff,$ff,$fe,$00' in pile

    cells0d = decode_room(ROOM0D_RLE)
    assert len(cells0d) == 640
    assert ROOM0D_RLE[30:39] == bytes.fromhex('01 f0 f0 f0 f0 f0 f0 22 20')

    assert 'include "game_life.asm"' in main_asm
    assert 'call    game_life_check' in main_asm
    for event in ('#2','#3','#4','#5','#7'):
        assert f'cmp     {event}' in life

    print('OK: stable Room01 cloud/bollard path; crash-prone Piledriver runtime gated for static DrawShaft rebuild')


if __name__ == '__main__':
    main()
