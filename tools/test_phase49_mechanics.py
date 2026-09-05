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
    pile_fix = (ROOT/'src/standard_piledriver_bat_fix.asm').read_text()
    bundle = (ROOT/'src/standard_piledriver_bundle.asm').read_text()
    footer = (ROOT/'src/debug_footer_visible.asm').read_text()
    life = (ROOT/'src/game_life.asm').read_text()

    assert 'call    monty_jump_step_swept' in main_asm
    assert '.up_pixel:' in sweep and '.down_pixel:' in sweep
    assert 'call    monty_check_tile_above' in sweep
    assert 'call    monty_check_tile_below' in sweep
    assert 'dec     <monty_y' in sweep and 'inc     <monty_y' in sweep

    assert 'include "rising_cloud.asm"' in main_asm
    assert 'call    rising_cloud_update' in main_asm
    assert 'CLOUD_VIS_COL       = 12' in cloud
    assert 'CLOUD_CODE          = 8' in cloud
    assert 'dec     <rising_cloud_y' in cloud

    base0c = decode_room(ROOM0C_RLE)
    assert len(base0c) == ROOM_CELLS == 640
    assert ROOM0C_BOLLARD_HEAD == (12, 23)
    assert base0c[12*32+23] == 0
    assert ROOM0C_BOLLARD_CODE == 5
    assert ROOM0C_PROPERTIES[ROOM0C_BOLLARD_CODE-1] == 3
    assert apply_bollard_head(base0c)[12*32+23] == 5

    assert 'include "rising_bollard.asm"' in main_asm
    assert 'call    rising_bollard_update' in main_asm
    assert 'include "standard_piledriver_bundle.asm"' in bollard
    assert 'call    piledriver_update' in bollard
    assert 'call    piledriver_room_sync' in bollard
    assert 'jmp     piledriver_fix_bat_hi' in bollard

    # Original config_tbl for the currently ported rooms.
    assert '; $01,$07,$05,$04,$10 and $01,$1f,$0c,$06,$22' in pile
    assert '; $02,$15,$05,$04,$10' in pile
    assert '; $0b,$13,$11,$04,$10' in pile
    assert 'lda     #$2f\n        sta     <piledriver_limit1' in pile

    # Original visual model: two independent 18-char dynamic BG buffers, NOT SAT.
    assert 'piledriver_buf0: ds 144' in pile
    assert 'piledriver_buf1: ds 144' in pile
    assert 'PILE_CHR0 = CHR_GAME + 64' in pile
    assert 'PILE_CHR1 = PILE_CHR0 + 18' in pile
    assert 'piledriver_draw_shaft:' in pile
    assert 'piledriver_shift_down:' in pile
    assert 'piledriver_shift_up:' in pile
    assert 'piledriver_upload_selected:' in pile
    assert 'piledriver_update_satb:\n        rts' in pile
    assert 'SAT_ADDR' not in pile

    # Exact normal seed glyphs from mechanisms_data.asm.
    assert 'db $0f,$0f,$00,$ff,$ff,$ff,$7f,$00' in pile
    assert 'db $ff,$ff,$00,$ff,$ff,$ff,$ff,$00' in pile
    assert 'db $f0,$f0,$00,$ff,$ff,$ff,$fe,$00' in pile

    # DrawShaft uses the original three C64 greys and the second shaft in Room01.
    assert 'PILE_PAL_LEFT  = 6' in pile
    assert 'PILE_PAL_MID   = 5' in pile
    assert 'PILE_PAL_RIGHT = 4' in pile
    assert 'lda     #$1f\n        sta     <piledriver_col1' in pile
    assert 'lda     #$0c\n        sta     <piledriver_row1' in pile
    assert 'lda     #6\n        sta     <piledriver_tmp_h' in pile

    # PCE dynamic tile ids exceed $ff; BAT high bytes must include tile bit 8.
    assert 'include "standard_piledriver_bat_fix.asm"' in bundle
    assert 'lda     #$61' in pile_fix
    assert 'lda     #$51' in pile_fix
    assert 'lda     #$41' in pile_fix

    # Old sprite prototype is no longer driven by the footer.
    assert 'piledriver_update_satb' not in footer
    assert 'piledriver_sprite_palette' not in bundle

    assert 'and     #$3f' in pile and 'adc     #$14' in pile
    assert pile.count('inc     <piledriver_position') >= 2
    assert pile.count('dec     <piledriver_position') >= 2
    assert 'lda     #4\n        sta     <monty_action_counter' in pile

    cells0d = decode_room(ROOM0D_RLE)
    assert len(cells0d) == 640
    assert ROOM0D_RLE[30:39] == bytes.fromhex('01 f0 f0 f0 f0 f0 f0 22 20')

    assert 'include "game_life.asm"' in main_asm
    assert 'call    game_life_check' in main_asm
    for event in ('#2','#3','#4','#5','#7'):
        assert f'cmp     {event}' in life

    print('OK: cloud/bollard + original dynamic-BG Piledriver shafts $01/$02/$0B + life/respawn')


if __name__ == '__main__':
    main()
