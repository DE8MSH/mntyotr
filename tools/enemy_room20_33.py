#!/usr/bin/env python3
"""Generate authentic enemy art first needed by Rooms $20-$33."""
from pathlib import Path
import argparse
from enemy_room00 import build8

RAW = {
'queen_liz': '''
06 05 1a 21 04 27 49 29 c0 50 28 18 e4 f4 90 96 5f 5d 1e 57 1b 0c 0f 03 f2 b0 7a fa d0 30 e0 c0
06 05 1a 21 04 27 4f 29 c0 50 28 18 e4 f4 f0 96 5f 5d 1e 57 18 0c 0f 03 f2 b0 7a fa 10 30 e0 c0
06 05 1a 21 04 27 4f 2f c0 50 28 18 e4 f4 f0 f6 5f 5d 1e 53 18 08 0e 03 f2 b0 7a fa 10 30 60 c0
06 05 1a 21 04 27 4f 29 c0 50 28 18 e4 f4 f0 96 5f 5d 1e 57 18 0c 0f 03 f2 b0 7a fa 10 30 e0 c0''',
'fish': '''
00 00 1e 3f 63 d3 db e7 00 00 0f 1e 9e fc fe fe ff f1 0f ff 7f 1e 00 00 ff ff f3 c1 81 00 00 00
00 00 0f 1f 31 69 65 73 00 00 06 8e ce fe fc ff 7f 60 01 0f 7f 1f 00 00 ff ff fb e1 c1 00 00 00
00 1e 3f 7f e3 db cb e7 00 00 10 98 f8 f8 f0 f8 ff 01 03 07 1f 3e 00 00 f8 fc fc cc 86 04 00 00
00 00 0f 1f 31 69 65 73 00 00 06 8e ce fe fc ff 7f 60 01 0f 7f 1f 00 00 ff ff fb e1 c1 00 00 00
00 f0 78 79 3f 7f 7f 00 00 78 fc c6 cb db e7 ff ff cf 83 81 00 00 00 ff 8f f0 ff fe 78 00 00 00
00 60 71 73 7f 3f ff 00 00 f0 f8 8c 96 a6 ce ff ff df 87 83 00 00 00 fe 06 80 f0 fe f8 00 00 00
00 08 19 1f 1f 0f 1f 00 78 fc fe c7 db d3 e7 1f 3f 3f 33 61 20 00 00 ff 80 c0 e0 f8 7c 00 00 00
00 60 71 73 7f 3f ff 00 00 f0 f8 8c 96 a6 ce ff ff df 87 83 00 00 00 fe 06 80 f0 fe f8 00 00 00''',
'flying_banner_1': '''
00 00 07 08 90 bf df b8 00 00 02 87 85 ef fd 3f b7 1b 01 00 00 00 00 00 de cc e0 f0 00 00 00 00
00 00 07 08 10 bf df b8 00 00 02 87 85 ef fd 3f 37 1b 01 00 00 00 00 00 de cc e0 f0 00 00 00 00
00 00 07 08 10 3f df 38 00 00 02 87 85 ef fd 3f 37 1b 01 00 00 00 00 00 de cc e0 f0 00 00 00 00
00 00 07 08 10 bf 5f b8 00 00 02 87 85 ef fd 3f 37 1b 01 00 00 00 00 00 de cc e0 f0 00 00 00 00
00 ff 40 21 12 12 22 21 00 ff 00 c0 06 49 29 c6 40 42 42 82 82 43 40 ff 00 00 09 09 09 e6 00 ff
00 ff 40 41 42 42 42 81 00 ff 00 c0 06 49 29 c6 80 82 42 22 22 43 40 ff 00 00 09 09 09 e6 00 ff
00 ff 40 21 22 22 42 21 00 ff 00 c0 06 49 29 c6 20 22 42 82 82 83 40 ff 00 00 09 09 09 e6 00 ff
00 3f 40 21 12 12 62 81 00 ff 00 c0 06 49 29 c6 80 82 42 82 82 83 40 ff 00 00 09 09 09 e6 00 ff''',
'flying_banner_2': '''
00 7f 40 58 58 5c 5f 5b 00 ff 00 67 66 e6 e6 66 d8 58 58 58 58 58 40 7f 67 66 66 66 66 66 00 ff
00 7f 40 58 58 5c 5f 5b 00 ff 00 67 66 e6 e6 66 d8 58 58 58 58 58 40 7f 67 66 66 66 66 66 00 ff
00 7f 40 58 58 5c 5f 5b 00 ff 00 67 66 e6 e6 66 d8 58 58 58 58 58 40 7f 67 66 66 66 66 66 00 ff
00 7f 40 58 58 5c 5f 5b 00 ff 00 67 66 e6 e6 66 d8 58 58 58 58 58 40 7f 67 66 66 66 66 66 00 ff
00 ff 00 00 33 4a 4a 33 00 fe 02 02 8a 4a 4a 8a 00 00 3a 43 43 3a 00 ff 0a 0b 8a 0a 02 8a 02 fe
00 ff 00 00 33 4a 4a 33 00 fe 02 02 8a 4a 4a 8a 00 00 3a 43 43 3a 00 ff 0a 0b 8a 0a 02 8a 02 fe
00 ff 00 00 33 4a 4a 33 00 fe 02 02 8a 4a 4a 8a 00 00 3a 43 43 3a 00 ff 0a 0b 8a 0a 02 8a 02 fe
00 ff 00 00 33 4a 4a 33 00 fe 02 02 8a 4a 4a 8a 00 00 3a 43 43 3a 00 ff 0a 0b 8a 0a 02 8a 02 fe''',
'flying_banner_3': '''
00 ff 00 f1 19 19 19 19 00 ff 02 84 88 88 84 84 f1 01 01 01 01 01 00 ff 82 82 82 81 f9 fa 02 fe
00 ff 00 f1 19 19 19 19 00 ff 02 84 82 82 84 84 f1 01 01 01 01 01 00 ff 82 81 82 81 f9 f9 02 fc
00 ff 00 f1 19 19 19 19 00 fe 04 88 84 84 84 84 f1 01 01 01 01 01 00 ff 88 88 84 82 fa fa 02 fc
00 ff 00 f1 19 19 19 19 00 fc 04 88 84 84 84 84 f1 01 01 01 01 01 00 ff 82 83 81 81 fa fa 01 ff
00 00 40 e1 a1 f7 bf fc 00 00 e0 10 09 fd fb 1d 7b 33 07 0f 00 00 00 00 ed d8 80 00 00 00 00 00
00 00 40 e1 a1 f7 bf fc 00 00 e0 10 08 fd fb 1d 7b 33 07 0f 00 00 00 00 ec d8 80 00 00 00 00 00
00 00 40 e1 a1 f7 bf fc 00 00 e0 10 08 fc fb 1c 7b 33 07 0f 00 00 00 00 ec d8 80 00 00 00 00 00
00 00 40 e1 a1 f7 bf fc 00 00 e0 10 08 fd fa 1d 7b 33 07 0f 00 00 00 00 ec d8 80 00 00 00 00 00''',
}

OUTPUTS = {
    'queen_liz': 'enemy-type0d-queen-liz.dat',
    'fish': 'enemy-type1f-fish.dat',
    'flying_banner_1': 'enemy-type20-flying-banner-1.dat',
    'flying_banner_2': 'enemy-type21-flying-banner-2.dat',
    'flying_banner_3': 'enemy-type22-flying-banner-3.dat',
}

def write_all(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, filename in OUTPUTS.items():
        raw = bytes.fromhex(RAW[name])
        assert len(raw) in (128, 256), (name, len(raw))
        payload = build8(raw)
        assert len(payload) == 4096
        (out_dir / filename).write_bytes(payload)

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--out-dir', type=Path, required=True)
    args = ap.parse_args()
    write_all(args.out_dir)
    print('enemy Room20-33 art: queen, fish and three flying banners generated')

if __name__ == '__main__':
    main()
