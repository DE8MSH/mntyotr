#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    physics = (ROOT / 'src/monty_physics.asm').read_text()
    loader = (ROOT / 'src/room_loader.asm').read_text()
    main_asm = (ROOT / 'src/main.asm').read_text()

    assert 'room_collision_map_ram' in physics
    assert 'room_tile_properties_ram,x' in physics
    assert '#<room00_collision_map' not in physics
    assert '#<room01_collision_map' not in physics
    assert 'room_collision_map_ram:  ds 640' in loader
    assert 'room_tile_properties_ram: ds 8' in loader
    assert 'room_collision_copy640' in loader
    assert 'BANK(room00_collision_map)' in loader
    assert 'BANK(room01_collision_map)' in loader
    assert 'call    room_collision_load_pending' in main_asm
    assert loader.count('room_collision_load_pending') >= 3

    print('OK: active collision map/properties are bank-safe RAM cached')


if __name__ == '__main__':
    main()
