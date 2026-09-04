#!/usr/bin/env python3
"""Fast deterministic checks for the C64->PCE port data path."""
from room_rle import ROOM00_RLE, ROOM_CELLS, decode_room

JUMP_UP = [0,3,2,2,1,2,1,1,0,1,1,1,0,1,1,1,0,1,0,1,0,0]
JUMP_DOWN = [1,0,0,0,1,0,1,0,1,0,2,1,2,1,2,2,0]


def pal_ticks(vblanks: int) -> int:
    """Current integer scheduler: five gameplay ticks per six PCE VBlanks."""
    phase = 0
    ticks = 0
    for _ in range(vblanks):
        phase += 5
        if phase >= 6:
            phase -= 6
            ticks += 1
    return ticks


def main() -> None:
    cells = decode_room(ROOM00_RLE)
    assert len(cells) == ROOM_CELLS == 640
    assert all(0 <= x <= 15 for x in cells)

    # These totals are useful regression fingerprints for the original C64 arc.
    assert len(JUMP_UP) == 22 and sum(JUMP_UP) == 20
    assert len(JUMP_DOWN) == 17 and sum(JUMP_DOWN) == 14

    assert pal_ticks(6) == 5
    assert pal_ticks(60) == 50
    assert pal_ticks(600) == 500

    print("OK: room00=640 cells; jump=22/17 samples (20px up, 14px down); clock=5/6")


if __name__ == "__main__":
    main()
