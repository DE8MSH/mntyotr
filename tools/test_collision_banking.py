#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    main_asm = (ROOT / 'src/main.asm').read_text()
    bank = (ROOT / 'src/collision_banking.asm').read_text()
    physics = (ROOT / 'src/monty_physics.asm').read_text()
    loader = (ROOT / 'src/room_loader.asm').read_text()
    tail2 = (ROOT / 'src/room02_assets_tail.asm').read_text()
    tail3 = (ROOT / 'src/room03_assets_tail.asm').read_text()

    enter = main_asm.index('call    collision_bank_enter')
    update = main_asm.index('call    monty_update_input')
    jump = main_asm.index('call    monty_jump_step')
    leave = main_asm.index('call    collision_bank_exit')
    world = main_asm.index('call    world_resolve_exit')
    assert enter < update < jump < leave < world

    assert 'BANK(room00_collision_map)' in bank
    assert 'BANK(room01_collision_map)' in bank
    assert 'call    map_bp_to_mpr34' in bank

    # Tail rooms share one proven 648-byte RAM cache.
    assert 'room02_collision_map:   ds 640' in bank
    assert 'room02_tile_properties: ds 8' in bank
    assert 'collision_actual_room:  ds 1' in bank
    assert 'cmp     #3' in bank
    assert 'sta     <collision_actual_room' in bank
    assert 'lda     #2' in bank and 'sta     <monty_room' in bank
    assert 'lda     <collision_actual_room' in bank
    assert 'BANK(room02_collision_map)' not in bank

    assert 'call    room02_cache_collision' in loader
    assert 'call    room03_cache_collision' in loader
    assert 'BANK(room02_collision_map_rom)' in loader
    assert 'BANK(room03_collision_map_rom)' in loader
    assert '#<room02_collision_map' in loader
    assert 'room02_collision_map_rom:' in tail2
    assert 'room03_collision_map_rom:' in tail3

    assert 'tma3' in bank and 'tma4' in bank
    assert 'tam3' in bank and 'tam4' in bank
    assert 'sei' in bank and 'cli' in bank

    # The sensitive physics file remains direct-pointer based and unchanged in
    # structure: Room03 is adapted outside it through the shared Room02 cache.
    assert 'lda     [collision_ptr],y' in physics
    assert '#<room00_collision_map' in physics
    assert '#<room01_collision_map' in physics
    assert '#<room02_collision_map' in physics
    assert 'room02_tile_properties,x' in physics
    assert 'room03_collision_map' not in physics

    print('OK: Room00/01 ROM banking + shared Room02/03 RAM collision cache')


if __name__ == '__main__':
    main()
