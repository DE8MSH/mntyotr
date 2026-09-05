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
    pile_assets = (ROOT/'src/standard_piledriver_assets_tail.asm').read_text()
    footer = (ROOT/'src/debug_footer_visible.asm').read_text()
    life = (ROOT/'src/game_life.asm').read_text()

    assert 'call    monty_jump_step_swept' in main_asm
    assert '.up_pixel:' in sweep and '.down_pixel:' in sweep
    assert 'call    monty_check_tile_above' in sweep
    assert 'call    monty_check_tile_below' in sweep
    assert 'dec     <monty_y' in sweep and 'inc     <monty_y' in sweep
    assert 'call    monty_check_down_room_edge' in sweep
    assert 'lda     monty_jump_arc_up,x' in sweep
    assert 'lda     monty_jump_arc_down,x' in sweep

    assert 'include "rising_cloud.asm"' in main_asm
    assert 'call    rising_cloud_update' in main_asm
    assert 'CLOUD_VIS_COL       = 12' in cloud
    assert 'CLOUD_CODE          = 8' in cloud
    assert 'CLOUD_BAT_WORD      = $c000+CHR_GAME+CLOUD_CODE' in cloud
    assert 'inc     <rising_cloud_tick' in cloud and 'and     #1' in cloud
    assert 'dec     <rising_cloud_y' in cloud

    base0c = decode_room(ROOM0C_RLE)
    assert len(base0c) == ROOM_CELLS == 640
    assert ROOM0C_BOLLARD_HEAD == (12, 23)
    assert base0c[12*32+23] == 0
    assert ROOM0C_BOLLARD_CODE == 5
    assert ROOM0C_PROPERTIES[ROOM0C_BOLLARD_CODE-1] == 3
    run0c = apply_bollard_head(base0c)
    assert run0c[12*32+23] == 5

    assert 'include "rising_bollard.asm"' in main_asm
    assert 'call    rising_bollard_update' in main_asm
    assert 'cmp     #$0c' in bollard
    assert 'lda     #$75' in bollard and 'sta     <monty_x' in bollard
    assert bollard.count('dec     <monty_y') >= 3
    assert 'cmp     #$62' in bollard
    assert 'rising_bollard_active' in bollard
    assert 'sta     <monty_climbing' in bollard

    # Standard Piledriver configs copied from original mechanisms_data.asm.
    assert 'include "standard_piledriver_bundle.asm"' in bollard
    assert 'call    piledriver_palette_init' in bollard
    assert 'jmp     piledriver_init' in bollard
    assert 'call    piledriver_room_sync' in bollard
    assert 'call    piledriver_update' in bollard
    for needle in ('lda #$07','lda #$1f','lda #$15','lda #$13'):
        assert needle in pile
    assert 'lda #$1f\n        sta <piledriver_limit0' in pile
    assert 'lda #$2f\n        sta <piledriver_limit1' in pile
    assert pile.count('inc <piledriver_position') >= 2
    assert pile.count('dec <piledriver_position') >= 2
    assert 'adc #$14' in pile and 'and #$3f' in pile
    assert 'lda #4\n        sta <monty_action_counter' in pile
    assert 'PILE_SAT0_L   = SAT_ADDR+32' in pile
    assert 'PILE_SAT1_R   = SAT_ADDR+44' in pile
    assert 'jmp     piledriver_update_satb' in footer
    assert 'piledriver_patterns:' in pile_assets
    assert 'db $0f,$ff,$0f,$ff' in pile_assets

    cells0d = decode_room(ROOM0D_RLE)
    assert len(cells0d) == 640
    assert ROOM0D_RLE[30:39] == bytes.fromhex('01 f0 f0 f0 f0 f0 f0 22 20')

    assert 'include "game_life.asm"' in main_asm
    assert 'call    game_life_init' in main_asm
    assert 'call    game_life_check' in main_asm
    assert 'call    game_life_reload' in main_asm
    assert 'call    game_life_room_sync' in main_asm
    assert 'lda     #5' in life and 'sta     <game_lives' in life
    for event in ('#2','#3','#4','#5','#7'):
        assert f'cmp     {event}' in life
    assert 'cmp     #6' not in life
    assert 'dec     <game_lives' in life
    assert 'sta     <world_pending_room' in life
    assert 'call    room_load_pending_extended' in life

    print('OK: swept collision + cloud/bollard + standard Piledriver $01/$02/$0B + life/respawn')


if __name__ == '__main__':
    main()
