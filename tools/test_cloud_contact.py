#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    main = (ROOT/'src/main.asm').read_text()
    contact = (ROOT/'src/rising_cloud_contact.asm').read_text()
    cloud = (ROOT/'src/rising_cloud.asm').read_text()

    assert 'include "rising_cloud_contact.asm"' in main
    c = main.index('call    rising_cloud_contact_update')
    u = main.index('call    rising_cloud_update')
    assert c < u

    # Landing is event-only and stateless: only fall/descent snaps to cloud_y-$10.
    assert 'sbc     #$10' in contact
    assert 'sta     <rising_cloud_contact_y' in contact
    assert 'cmp     #1' in contact
    assert 'cmp     #2' in contact
    assert 'lda     <monty_falling' in contact
    assert 'cmp     #4' in contact
    assert 'cmp     #$fe' in contact
    assert 'rising_cloud_riding' not in contact

    # No persistent rider state anywhere. Support is recomputed from exact current
    # geometry, so normal horizontal input and jump state can release immediately.
    assert 'rising_cloud_riding' not in cloud
    assert 'rising_cloud_detect_push:' in cloud
    assert 'lda     <monty_jump_phase' in cloud
    assert 'lda     <monty_falling' in cloud
    assert 'cmp     #$36' in cloud and 'cmp     #$49' in cloud
    assert 'sbc     #$10' in cloud
    assert 'cmp     <monty_y' in cloud
    detect = cloud[cloud.index('rising_cloud_detect_push:'):cloud.index('rising_cloud_refresh_row:')]
    assert 'monty_tile_state' not in detect

    # Cloud moves every odd tick. A supported Monty moves only after an upward
    # collision probe; a ceiling blocks Monty while the cloud itself continues.
    assert 'dec     <rising_cloud_y' in cloud
    assert 'call    monty_check_tile_above' in cloud
    assert 'bcs     .refresh' in cloud
    assert 'dec     <monty_y' in cloud

    print('OK: Room01 cloud uses stateless support; walk/jump release immediately; ceiling blocks upward push')


if __name__ == '__main__':
    main()
