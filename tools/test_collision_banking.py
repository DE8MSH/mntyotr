#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    main_asm = (ROOT / 'src/main.asm').read_text()
    bank = (ROOT / 'src/collision_banking.asm').read_text()
    physics = (ROOT / 'src/monty_physics.asm').read_text()
    sweep = (ROOT / 'src/jump_collision_sweep.asm').read_text()
    cloud = (ROOT / 'src/rising_cloud.asm').read_text()
    room01_native = (ROOT / 'src/room01_native.asm').read_text()
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
    jump = main_asm.index('call    monty_jump_step_swept')
    leave = main_asm.index('call    collision_bank_exit')
    cloud_update = main_asm.index('call    rising_cloud_update')
    world = main_asm.index('call    world_resolve_exit')
    assert enter < update < jump < leave < cloud_update < world
    assert 'call    monty_check_tile_below' in sweep
    assert 'call    monty_check_tile_above' in sweep

    assert 'BANK(room00_collision_map)' in bank
    # Room01 is deliberately RAM-backed now; mapping it as ROM would make the
    # moving cloud unable to update collision cells.
    assert 'BANK(room01_collision_map)' not in bank
    assert 'cmp     #1' in bank and 'beq     .ram_ready' in bank
    assert '.bss' in room01_native
    assert 'room01_collision_map:' in room01_native and 'ds 640' in room01_native
    assert 'room01_collision_map_rom:' in room01_native
    assert 'BANK(room01_collision_map_rom)' in cloud
    assert '#<room01_collision_map' in cloud and '#>room01_collision_map' in cloud

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

    assert 'lda     [collision_ptr],y' in physics
    assert '#<room00_collision_map' in physics
    assert '#<room01_collision_map' in physics
    assert '#<room02_collision_map' in physics
    assert 'room02_tile_properties,x' in physics
    for room in ('05','09','0a','0b','0c','0d','0e'):
        assert f'room{room}_collision_map' not in physics

    print('OK: Room01 mutable cloud collision + shared tail RAM banking + pixelwise jump sweep')


if __name__ == '__main__':
    main()
