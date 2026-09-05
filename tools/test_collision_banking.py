#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    main_asm = (ROOT / 'src/main.asm').read_text()
    bank = (ROOT / 'src/collision_banking.asm').read_text()
    physics = (ROOT / 'src/monty_physics.asm').read_text()
    loader = (ROOT / 'src/room_loader.asm').read_text()
    ext = (ROOT / 'src/room050c_loader.asm').read_text()
    tails = {
        '02': (ROOT / 'src/room02_assets_tail.asm').read_text(),
        '03': (ROOT / 'src/room03_assets_tail.asm').read_text(),
        '04': (ROOT / 'src/room04_assets_tail.asm').read_text(),
        '05': (ROOT / 'src/room05_assets_tail.asm').read_text(),
        '09': (ROOT / 'src/room09_assets_tail.asm').read_text(),
        '0a': (ROOT / 'src/room0a_assets_tail.asm').read_text(),
        '0b': (ROOT / 'src/room0b_assets_tail.asm').read_text(),
        '0c': (ROOT / 'src/room0c_assets_tail.asm').read_text(),
        '0d': (ROOT / 'src/room0d_assets_tail.asm').read_text(),
        '0e': (ROOT / 'src/room0e_assets_tail.asm').read_text(),
    }

    enter = main_asm.index('call    collision_bank_enter')
    update = main_asm.index('call    monty_update_input')
    jump = main_asm.index('call    monty_jump_step')
    leave = main_asm.index('call    collision_bank_exit')
    world = main_asm.index('call    world_resolve_exit')
    assert enter < update < jump < leave < world

    assert 'BANK(room00_collision_map)' in bank
    assert 'BANK(room01_collision_map)' in bank
    assert 'room02_collision_map:   ds 640' in bank
    assert 'room02_tile_properties: ds 8' in bank
    assert 'collision_actual_room:  ds 1' in bank
    assert 'cmp     #3' in bank and 'bcc     .select_room' in bank
    assert 'lda     #2' in bank and 'sta     <monty_room' in bank
    assert 'BANK(room02_collision_map)' not in bank

    for room in ('02','03','04','0a','0b','0d','0e'):
        assert f'call    room{room}_cache_collision' in loader
        assert f'BANK(room{room}_collision_map_rom)' in loader
        assert f'room{room}_collision_map_rom:' in tails[room]
    for room in ('05','09','0c'):
        assert f'call    room{room}_cache_collision' in ext
        assert f'BANK(room{room}_collision_map_rom)' in ext
        assert f'room{room}_collision_map_rom:' in tails[room]

    assert 'tma3' in bank and 'tma4' in bank
    assert 'tam3' in bank and 'tam4' in bank
    assert 'sei' in bank and 'cli' in bank

    # Sensitive physics remains direct-pointer based and unchanged. All tail
    # rooms above $02 are adapted outside it through the shared Room02 RAM cache.
    assert 'lda     [collision_ptr],y' in physics
    assert '#<room00_collision_map' in physics
    assert '#<room01_collision_map' in physics
    assert '#<room02_collision_map' in physics
    assert 'room02_tile_properties,x' in physics
    for room in ('05','09','0a','0b','0c','0d','0e'):
        assert f'room{room}_collision_map' not in physics

    print('OK: Room00/01 ROM banking + shared tail-room RAM collision cache through 05/09/0A-0E')


if __name__ == '__main__':
    main()
