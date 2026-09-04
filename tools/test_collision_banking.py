#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    main_asm = (ROOT / 'src/main.asm').read_text()
    bank = (ROOT / 'src/collision_banking.asm').read_text()
    physics = (ROOT / 'src/monty_physics.asm').read_text()

    assert 'include "collision_banking.asm"' in main_asm
    enter = main_asm.index('call    collision_bank_enter')
    update = main_asm.index('call    monty_update_input')
    jump = main_asm.index('call    monty_jump_step')
    leave = main_asm.index('call    collision_bank_exit')
    world = main_asm.index('call    world_resolve_exit')
    assert enter < update < jump < leave < world

    assert 'BANK(room00_collision_map)' in bank
    assert 'BANK(room01_collision_map)' in bank
    assert 'BANK(room02_collision_map)' in bank
    assert 'call    map_bp_to_mpr34' in bank
    assert 'tma3' in bank and 'tma4' in bank
    assert 'tam3' in bank and 'tam4' in bank
    assert 'collision_saved_bp_lo' in bank and 'collision_saved_bp_hi' in bank
    assert 'sei' in bank and 'cli' in bank

    assert 'room_collision_map_ram' not in physics
    assert 'lda     [collision_ptr],y' in physics
    assert '#<room00_collision_map' in physics
    assert '#<room01_collision_map' in physics
    assert '#<room02_collision_map' in physics

    print('OK: active Room 00/01/02 collision bank is mapped around physics')


if __name__ == '__main__':
    main()
