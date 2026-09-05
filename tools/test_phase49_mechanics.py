#!/usr/bin/env python3
from pathlib import Path

from room_rle import decode_room, ROOM_CELLS
from room0c import ROOM0C_RLE, ROOM0C_PROPERTIES, ROOM0C_BOLLARD_HEAD, ROOM0C_BOLLARD_CODE, apply_bollard_head
from room0d import ROOM0D_RLE

ROOT = Path(__file__).resolve().parents[1]


def main():
    main_asm = (ROOT/'src/main.asm').read_text()
    sweep = (ROOT/'src/jump_collision_sweep.asm').read_text()
    cloud = (ROOT/'src/rising_cloud.asm').read_text()
    bollard = (ROOT/'src/rising_bollard.asm').read_text()
    static = (ROOT/'src/standard_piledriver_static.asm').read_text()
    exact = (ROOT/'src/standard_piledriver_exact_runtime.asm').read_text()
    bundle = (ROOT/'src/standard_piledriver_bundle.asm').read_text()
    life = (ROOT/'src/game_life.asm').read_text()

    assert 'call    monty_jump_step_swept' in main_asm
    assert 'call    monty_check_tile_above' in sweep
    assert 'call    monty_check_tile_below' in sweep

    assert 'include "rising_cloud.asm"' in main_asm
    assert 'call    rising_cloud_update' in main_asm
    assert 'dec     <rising_cloud_y' in cloud

    base0c = decode_room(ROOM0C_RLE)
    assert len(base0c) == ROOM_CELLS == 640
    assert ROOM0C_BOLLARD_HEAD == (12, 23)
    assert ROOM0C_PROPERTIES[ROOM0C_BOLLARD_CODE-1] == 3
    assert apply_bollard_head(base0c)[12*32+23] == ROOM0C_BOLLARD_CODE

    assert 'include "standard_piledriver_static.asm"' in bundle
    assert 'include "standard_piledriver_exact_runtime.asm"' in bundle
    assert 'call    piledriver_exact_init' in bollard
    assert 'call    piledriver_exact_update' in bollard
    assert 'call    piledriver_static_update' not in bollard
    assert 'call    piledriver_update' not in bollard

    # Exact C64 configs currently active.
    assert 'room $01: col $07,row $05,height 4,char $10' in static
    assert 'col $1f,row $0c,height 6,char $22' in static
    assert 'room $02: col $15,row $05,height 4,char $10' in static
    assert 'room $0b: col $13,row $11,height 4,char $10' in static

    # Dynamic chars live above Room02 decor (+65), preventing flowerpot corruption.
    assert 'PILE_STATIC_CHR0 = CHR_GAME + 96' in static
    assert 'PILE_STATIC_CHR1 = PILE_STATIC_CHR0 + 18' in static

    # MoveDown body replication from the original charset shift.
    assert '.body_row:' in static
    assert 'cmp     <pile_static_shift' in static
    assert 'cly                             ; seed row 0 is replicated by MoveDown' in static

    # Exact source seed glyphs / shaft greys.
    assert 'db $0f,$0f,$00,$ff,$ff,$ff,$7f,$00' in static
    assert 'db $ff,$ff,$00,$ff,$ff,$ff,$ff,$00' in static
    assert 'db $f0,$f0,$00,$ff,$ff,$ff,$fe,$00' in static
    assert 'lda     #$61' in static and 'lda     #$51' in static and 'lda     #$41' in static

    # C64 Animate uses TWO independent random calls: first delay, then driver index.
    assert exact.count('call    piledriver_exact_random') >= 2
    assert 'and     #$3f' in exact and 'adc     #$14' in exact
    assert 'and     #1' in exact
    assert 'lda     #5\n        sta     <pile_static_position' in exact
    assert exact.count('inc     <pile_static_position') == 2
    assert exact.count('dec     <pile_static_position') == 2

    # Exact CheckTiles semantics, translated geometrically for the PCE BAT model.
    assert 'piledriver_exact_check_tiles:' in exact
    assert 'cmp     #2\n        beq     .done' in exact  # retracting cannot kill
    assert 'sbc     #$0c' in exact and exact.count('lsr     a') >= 5
    assert 'adc     <pile_static_position' in exact
    assert 'cmp     <monty_y' in exact
    assert 'lda     #4\n        sta     <monty_action_counter' in exact

    cells0d = decode_room(ROOM0D_RLE)
    assert len(cells0d) == 640
    assert ROOM0D_RLE[30:39] == bytes.fromhex('01 f0 f0 f0 f0 f0 f0 22 20')

    assert 'include "game_life.asm"' in main_asm
    assert 'call    game_life_check' in main_asm
    for event in ('#2','#3','#4','#5','#7'):
        assert f'cmp     {event}' in life

    print('OK: exact Piledriver RNG selection + 2px state machine + CheckTiles death + safe VRAM/body')


if __name__ == '__main__':
    main()
