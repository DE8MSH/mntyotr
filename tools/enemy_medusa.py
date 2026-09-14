#!/usr/bin/env python3
"""Generate authentic C64 Medusa (enemy type $1E) as eight PCE frames."""
from pathlib import Path
import argparse
from enemy_room00 import build8

RAW = bytes.fromhex('''
60 30 19 1f 0f 0f 1f 3a 60 c3 ce f8 f8 f8 fc ee 37 0f 0d 1c 3f 3b 02 01 1e ae d0 ea d4 6a f4 e8
38 18 19 0f 0f 0f 1f 3a 78 c0 c3 ff fe f8 fc ee 37 0f 0d 1c 3f 3b 00 01 1e ae d0 ea d4 6a 74 e8
06 06 06 07 0f 0f 1f 3a 00 e0 ce fc fc f8 fc ee 37 0f 0d 1c 3f 38 00 01 1e ae d0 ea d4 6a 74 e8
00 39 1d 0d 0f 0f 1f 3a 0e 9c d8 d8 f8 f8 fc ee 37 0f 0d 1c 3f 3b 00 01 1e ae d0 ea d4 6a 74 e8
06 c3 73 1f 1f 1f 3f 77 06 0c 98 f8 f0 f0 f8 5c 78 75 0b 57 2b 56 2f 17 ec f0 b0 38 fc dc 40 80
1e 03 c3 ff 7f 1f 3f 77 1c 18 98 f0 f0 f0 f8 5c 78 75 0b 57 2b 56 2e 17 ec f0 b0 38 fc dc 00 80
00 07 73 3f 3f 1f 3f 77 60 60 60 e0 f0 f0 f8 5c 78 75 0b 57 2b 56 2e 17 ec f0 b0 38 fc 1c 00 80
70 39 1b 1b 1f 1f 3f 77 00 9c b8 b0 f0 f0 f8 5c 78 75 0b 57 2b 56 2e 17 ec f0 b0 38 fc dc 00 80
''')


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--write', type=Path, required=True)
    args = ap.parse_args()
    assert len(RAW) == 256, len(RAW)
    payload = build8(RAW)
    assert len(payload) == 4096
    args.write.write_bytes(payload)
    print('enemy type $1E Medusa generated')


if __name__ == '__main__':
    main()
