#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    text = (ROOT / 'src/main.asm').read_text()
    sweep = (ROOT / 'src/jump_collision_sweep.asm').read_text()
    assert 'main_jump_x_before_step:   ds 1' in text
    assert 'main_exit_before_jump:     ds 1' in text
    assert 'sta     <main_exit_before_jump' in text
    assert 'include "jump_collision_sweep.asm"' in text
    assert 'call    monty_jump_step_swept' in text
    assert 'call    monty_jump_step\n' not in text
    assert 'lda     <main_exit_before_jump' in text
    assert 'sta     <monty_room_exit' in text
    assert '.guard_jump_generated_exit:' in text
    assert 'lda     <monty_jump_phase' in text
    assert 'lda     <collision_actual_room' in text
    assert 'lda     #$9b' in text
    assert text.count('stz     <monty_room_exit') >= 2
    assert 'lda     <monty_is_moving' in text
    assert 'lda     <main_jump_x_before_step' in text
    assert 'call    init_c64_video' in text
    assert 'bsr     init_c64_video' not in text

    # C64 UpdateMovement consumes every jump delta one pixel at a time and checks
    # collision before each pixel. This prevents floors/ceilings being tunneled
    # through by the $02/$03 arc deltas.
    assert 'monty_jump_step_swept:' in sweep
    assert 'inc     <monty_jump_index' in sweep
    assert '.up_pixel:' in sweep and '.down_pixel:' in sweep
    assert sweep.count('call    monty_check_tile_above') == 1
    assert sweep.count('call    monty_check_tile_below') == 1
    assert 'dec     <monty_y' in sweep
    assert 'inc     <monty_y' in sweep
    assert 'dec     <jump_delta' in sweep
    assert 'call    monty_check_down_room_edge' in sweep
    assert 'lda     monty_jump_arc_up,x' in sweep
    assert 'lda     monty_jump_arc_down,x' in sweep

    # Only the true outer edge at Room $00 right is special-cased before world.
    guard = text.split('call    monty_update_input', 1)[1]
    guard = guard.split('.after_unsupported_jump_edge:', 1)[0]
    assert 'cmp     #4' not in guard
    assert 'cmp     #2' in guard
    assert 'bne     .after_unsupported_jump_edge' in guard

    print('OK: pixelwise C64 jump collision sweep; supported exits open; only Room00 outer-right pre-guarded')


if __name__ == '__main__':
    main()
