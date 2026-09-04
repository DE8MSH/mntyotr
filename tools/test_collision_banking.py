#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    main_asm = (ROOT / 'src/main.asm').read_text()
    bank = (ROOT / 'src/collision_banking.asm').read_text()
    physics = (ROOT / 'src/monty_physics.asm').read_text()
    loader = (ROOT / 'src/room_loader.asm').read_text()
    tail = (ROOT / 'src/room02_assets_tail.asm').read_text()

    assert 'include "collision_banking.asm"' in main_asm
    enter = main_asm.index('call    collision_bank_enter')
    update = main_asm.index('call    monty_update_input')
    jump = main_asm.index('call    monty_jump_step')
    leave = main_asm.index('call    collision_bank_exit')
    world = main_asm.index('call    world_resolve_exit')
    assert enter < update < jump < leave < world

    # Rooms 00/01 keep the proven ROM mapping path.
    assert 'BANK(room00_collision_map)' in bank
    assert 'BANK(room01_collision_map)' in bank
    assert 'call    map_bp_to_mpr34' in bank

    # Room 02 is different: its tail ROM payload is cached in RAM on entry and
    # the physics slice must not remap MPR3/MPR4 to that far asset bank.
    assert 'room02_collision_map:   ds 640' in bank
    assert 'room02_tile_properties: ds 8' in bank
    assert 'cmp     #2' in bank and 'beq     .room02_ram' in bank
    assert 'BANK(room02_collision_map)' not in bank
    assert 'call    room02_cache_collision' in loader
    assert 'BANK(room02_collision_map_rom)' in loader
    assert '#<room02_collision_map' in loader
    assert 'room02_collision_map_rom:' in tail
    assert 'room02_tile_properties_rom:' in tail

    assert 'tma3' in bank and 'tma4' in bank
    assert 'tam3' in bank and 'tam4' in bank
    assert 'collision_saved_bp_lo' in bank and 'collision_saved_bp_hi' in bank
    assert 'sei' in bank and 'cli' in bank

    # Physics semantics remain direct-pointer based; Room02 labels now resolve
    # to the RAM cache without changing the collision routines themselves.
    assert 'room_collision_map_ram' not in physics
    assert 'lda     [collision_ptr],y' in physics
    assert '#<room00_collision_map' in physics
    assert '#<room01_collision_map' in physics
    assert '#<room02_collision_map' in physics
    assert 'room02_tile_properties,x' in physics

    print('OK: Room 00/01 ROM banking + Room 02 RAM collision cache keep runtime code mapped')


if __name__ == '__main__':
    main()
