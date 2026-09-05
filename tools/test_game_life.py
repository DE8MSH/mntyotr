#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    main = (ROOT/'src/main.asm').read_text()
    life = (ROOT/'src/game_life.asm').read_text()
    build_sh = (ROOT/'build.sh').read_text()

    assert 'include "game_life.asm"' in main
    assert 'call    game_life_init' in main
    assert 'call    game_life_check' in main
    assert 'call    game_life_reload' in main
    assert 'call    game_life_room_sync' in main

    assert 'lda     #5' in life and 'sta     <game_lives' in life
    for event in ('#2','#3','#4','#5','#7'):
        assert f'cmp     {event}' in life
    assert 'cmp     #6' not in life       # completion is not a death event
    assert 'dec     <game_lives' in life
    assert 'game_checkpoint_x' in life and 'game_checkpoint_y' in life
    assert 'sta     <world_pending_room' in life
    assert 'call    room_load_pending_extended' in life
    assert 'sta     <rising_cloud_last_room' in life
    assert 'sta     <rising_bollard_last_room' in life
    assert 'sta     <moving_lift_last_room' in life

    assert 'tools/test_game_life.py' in build_sh
    print('OK: shared C64-style life loss + same-room checkpoint respawn foundation')


if __name__ == '__main__':
    main()
