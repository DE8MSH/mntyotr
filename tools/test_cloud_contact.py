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

    assert 'sbc     #$10' in contact
    assert 'sta     <rising_cloud_contact_y' in contact
    assert 'cmp     #1' in contact               # reject jump ascent
    assert 'cmp     #4' in contact               # swept landing window 0..3 px
    assert 'cmp     #$fe' in contact             # allow -1/-2 px from above
    assert 'stz     <monty_jump_phase' in contact
    assert 'stz     <monty_falling' in contact
    assert 'sta     <monty_tile_state' in contact

    # Existing cloud carry must still move both cloud and rider upward by one.
    assert 'call    rising_cloud_detect_carry' in cloud
    assert 'dec     <rising_cloud_y' in cloud
    assert 'dec     <monty_y' in cloud

    print('OK: Room01 cloud moving-platform contact snaps at cloud_y-$10 and carries rider')


if __name__ == '__main__':
    main()
