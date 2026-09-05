#!/usr/bin/env python3
from pathlib import Path
from room_rle import decode_room
from room01 import ROOM01_RLE, ROOM01_PROPERTIES

ROOT = Path(__file__).resolve().parents[1]


def prop_for_code(code: int) -> int:
    if code == 0 or code >= 9:
        return 0
    return ROOM01_PROPERTIES[code - 1]


def room01_prop_at_screen(screen_x: int, screen_y: int) -> int:
    if screen_y < 3 or screen_y >= 23:
        return 0
    if screen_x < 2 or screen_x >= 38:
        return 0
    if screen_x < 4:
        screen_x = 4
    elif screen_x >= 36:
        screen_x = 35
    logical_x = screen_x - 4
    logical_y = screen_y - 3
    cells = decode_room(ROOM01_RLE)
    return prop_for_code(cells[logical_y * 32 + logical_x])


def prospective_push_blocked(monty_x: int, monty_y: int) -> bool:
    probe_y = ((monty_y - 1 - 0x32) & 0xFF) >> 3
    xraw = (monty_x - 0x0C) & 0xFF
    probe_x = xraw >> 2
    cols = 2 if (xraw & 3) == 0 else 3
    for sy in range(probe_y, probe_y + 3):
        for sx in range(probe_x, probe_x + cols):
            if room01_prop_at_screen(sx, sy) == 1:
                return True
    return False


def cloud_room_boundary_allows_push(monty_y: int) -> bool:
    # Runtime rule: $4D->$4C is the last legal cloud-supported pixel.
    # At $4C, another push would make $4B and therefore create an UP exit.
    return monty_y >= 0x4D


def main():
    main = (ROOT/'src/main.asm').read_text()
    physics = (ROOT/'src/monty_physics.asm').read_text()
    contact = (ROOT/'src/rising_cloud_contact.asm').read_text()
    cloud = (ROOT/'src/rising_cloud.asm').read_text()

    assert 'include "rising_cloud_contact.asm"' in main
    c = main.index('call    rising_cloud_contact_update')
    u = main.index('call    rising_cloud_update')
    assert c < u

    assert 'sbc     #$10' in contact
    assert 'sta     <rising_cloud_contact_y' in contact
    assert 'cmp     #1' in contact
    assert 'cmp     #2' in contact
    assert 'lda     <monty_falling' in contact
    assert 'cmp     #4' in contact
    assert 'cmp     #$fe' in contact
    assert 'rising_cloud_riding' not in contact

    assert 'rising_cloud_support:    ds 1' in cloud
    assert 'rising_cloud_support_update:' in cloud
    assert 'stz     <monty_tile_state' in cloud
    input_code = physics[physics.index('monty_update_input:'):physics.index('monty_jump_step:')]
    assert 'call rising_cloud_support_update' in input_code
    assert 'lda <rising_cloud_support' in input_code
    assert input_code.index('lda <rising_cloud_support') < input_code.index('lda <monty_tile_state')
    assert 'call monty_jump_start' in input_code
    assert 'lda joynow\n        and #$80' in input_code
    assert 'lda joynow\n        and #$20' in input_code

    assert 'rising_cloud_riding' not in cloud
    assert 'rising_cloud_detect_push:' in cloud
    assert 'lda     <monty_jump_phase' in cloud
    assert 'lda     <monty_falling' in cloud
    assert 'cmp     #$36' in cloud and 'cmp     #$49' in cloud
    assert 'cmp     <monty_y' in cloud

    # Hard topology guard: moving cloud support may never itself create an UP exit.
    move = cloud[cloud.index('.move_tick:'):cloud.index('rising_cloud_detect_push:')]
    assert 'lda     <monty_y' in move
    assert 'cmp     #$4d' in move
    assert 'bcc     .refresh' in move
    assert move.index('cmp     #$4d') < move.index('dec     <monty_y')
    assert cloud_room_boundary_allows_push(0x4D)
    assert not cloud_room_boundary_allows_push(0x4C)

    assert 'rising_cloud_can_push_up:' in cloud
    guard = cloud[cloud.index('rising_cloud_can_push_up:'):cloud.index('rising_cloud_refresh_row:')]
    assert 'call    room00_get_property_xy' in guard
    assert 'cmp     #$01' in guard
    assert 'rising_cloud_probe_rows' in guard
    assert 'rising_cloud_probe_cols' in guard
    assert 'call    monty_check_tile_above' not in guard
    assert 'dec     <rising_cloud_y' in cloud
    assert 'dec     <monty_y' in cloud

    assert room01_prop_at_screen(12, 4) == 0
    assert room01_prop_at_screen(12, 3) == 1
    assert not prospective_push_blocked(0x3C, 0x53)
    assert prospective_push_blocked(0x3C, 0x52)

    print('OK: Room01 cloud walk/jump free; ceiling footprint + hard $4C top-exit guard prevent cloud room transition')


if __name__ == '__main__':
    main()
