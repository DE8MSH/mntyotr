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

    # Core platform bug: authentic jump deltas are preserved, but each 1..3 px
    # delta is now swept one pixel at a time with collision before every pixel.
    assert 'call    monty_jump_step_swept' in main_asm
    assert '.up_pixel:' in sweep and '.down_pixel:' in sweep
    assert 'call    monty_check_tile_above' in sweep
    assert 'call    monty_check_tile_below' in sweep
    assert 'dec     <monty_y' in sweep and 'inc     <monty_y' in sweep
    assert 'call    monty_check_down_room_edge' in sweep
    assert 'lda     monty_jump_arc_up,x' in sweep
    assert 'lda     monty_jump_arc_down,x' in sweep

    # First genuine moving Room01 mechanism: odd-tick, 1px rising cloud using
    # exact screen columns $0C-$0E and code 8/property 3 collision.
    assert 'include "rising_cloud.asm"' in main_asm
    assert 'call    rising_cloud_update' in main_asm
    assert 'CLOUD_VIS_COL       = 12' in cloud
    assert 'CLOUD_CODE          = 8' in cloud
    assert 'CLOUD_BAT_WORD      = $c000+CHR_GAME+CLOUD_CODE' in cloud
    assert 'inc     <rising_cloud_tick' in cloud and 'and     #1' in cloud
    assert 'dec     <rising_cloud_y' in cloud

    # Room0C exact source stays 640 cells. InitState's raw C64 $62 head is
    # represented at the exact logical equivalent (row12,col23) by local code5,
    # which has the same property-3 semantics.
    base0c = decode_room(ROOM0C_RLE)
    assert len(base0c) == ROOM_CELLS == 640
    assert ROOM0C_BOLLARD_HEAD == (12, 23)
    assert base0c[12*32+23] == 0
    assert ROOM0C_BOLLARD_CODE == 5
    assert ROOM0C_PROPERTIES[ROOM0C_BOLLARD_CODE-1] == 3
    run0c = apply_bollard_head(base0c)
    assert run0c[12*32+23] == 5

    # C64 piledriver dual-use ride semantics: contact snaps X=$75, pulls up 2px,
    # then rides 1px/tick until Monty Y drops below $62. It does NOT transition
    # directly from Room0C into Room05.
    assert 'include "rising_bollard.asm"' in main_asm
    assert 'call    rising_bollard_update' in main_asm
    assert 'cmp     #$0c' in bollard
    assert 'lda     #$75' in bollard and 'sta     <monty_x' in bollard
    assert bollard.count('dec     <monty_y') >= 3
    assert 'cmp     #$62' in bollard
    assert 'rising_bollard_active' in bollard
    assert 'sta     <monty_climbing' in bollard

    # Room0D latent source regression: exact refactored stream has SIX $F0 runs
    # after $01. This must decode to 640, not 624 cells.
    cells0d = decode_room(ROOM0D_RLE)
    assert len(cells0d) == 640
    assert ROOM0D_RLE[30:39] == bytes.fromhex('01 f0 f0 f0 f0 f0 f0 22 20')

    print('OK: Phase49 pixel-swept jump + moving Room01 cloud + Room0C rising bollard + exact Room0D RLE')


if __name__ == '__main__':
    main()
