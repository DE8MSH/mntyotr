#!/usr/bin/env python3
"""Generate authentic C64 enemy art first needed by Rooms $10-$1F."""
from pathlib import Path
import argparse
from enemy_room00 import build8

RAW = {
'boot':'''03 03 03 03 03 01 3e 67 f9 f9 f9 fb fb fa fa 7a cf df ff 00 ff 00 00 00 f9 f0 ed 1d f5 00 00 00
03 03 03 01 1e 33 67 6f f9 f9 f9 fb fb 7a ba ba 3f 43 7c 30 4f 00 00 00 f9 f0 6d 1d f5 00 00 00
03 00 0f 19 33 37 1f 07 f9 f9 79 bb bb da da fa 39 e0 de b0 67 00 00 00 f9 f0 6d 1d f5 00 00 00
03 03 03 01 1e 33 67 6f f9 f9 f9 fb fb 7a ba ba 3f 03 6c 50 37 00 00 00 f9 f0 6d 1d f5 00 00 00
9f 9f 9f df df 5f 5f 5e c0 c0 c0 c0 c0 80 7c e6 9f 0f b7 b8 af 00 00 00 f3 fb ff 00 ff 00 00 00
9f 9f 9f df df 5e 5d 5d c0 c0 c0 80 78 cc e6 f6 9f 0f b6 b8 af 00 00 00 fc c2 3e 0c f2 00 00 00
9f 9f 9e dd dd 5b 5b 5f c0 00 f0 98 cc ec f8 e0 9f 0f b6 b8 af 00 00 00 9c 07 7b 0d e6 00 00 00
9f 9f 9f df df 5e 5d 5d c0 c0 c0 80 78 cc e6 f6 9f 0f b6 b8 af 00 00 00 fc c0 36 0a ec 00 00 00''',
'ufo':'''07 18 20 40 40 80 80 80 e0 18 04 22 12 19 09 01 ff bb 3f 03 03 07 07 0f ff bb fc 40 40 20 a0 90
07 18 20 40 40 80 80 80 e0 18 04 22 12 19 09 01 ff 77 3f 03 03 07 07 0f ff 77 fc 40 40 20 a0 90
07 18 20 40 40 80 80 80 e0 18 04 22 12 19 09 01 ff ee 3f 03 03 07 07 0f ff ee fc 40 40 20 a0 90
07 18 20 40 40 80 80 80 e0 18 04 22 12 19 09 01 ff dd 3f 03 03 07 07 0f ff dd fc 40 40 20 a0 90''',
'king':'''41 e2 a5 45 48 4b 40 49 00 80 c0 c0 20 e0 00 c0 43 46 40 40 47 65 25 56 a0 50 a0 50 f8 f8 f8 f8
40 e1 a2 45 45 48 4b 40 00 00 80 c0 c0 20 e0 00 49 43 46 40 47 45 65 56 c0 90 20 50 f8 f8 f8 f8
40 e1 a2 45 45 48 4b 40 00 00 80 c0 c0 20 e0 00 49 43 46 40 47 65 25 56 c0 90 20 50 f8 f8 f8 f8
41 e2 a5 45 48 4b 40 49 00 80 c0 c0 20 e0 00 c0 43 46 40 40 47 45 65 56 a0 50 a0 50 f8 f8 f8 f8
00 01 03 03 04 07 00 03 82 47 a5 a2 12 d2 02 92 05 0a 05 0a 1f 1f 1f 1f c2 62 02 02 e2 a6 a4 6a
00 00 01 03 03 04 07 00 02 87 45 a2 a2 12 d2 02 03 09 04 0a 1f 1f 1f 1f 92 c2 62 02 e2 a2 a6 6a
00 00 01 03 03 04 07 00 02 87 45 a2 a2 12 d2 02 03 09 04 0a 1f 1f 1f 1f 92 c2 62 02 e2 a6 a4 6a
00 01 03 03 04 07 00 03 82 47 a5 a2 12 d2 02 92 05 0a 05 0a 1f 1f 1f 1f c2 62 02 02 e2 a2 a6 6a''',
'sad_mug':'''0f 0d 2a 6e ed cb cb ca ff fb 65 07 9b 9d 19 95 ca cc ef 6f 2f 0c 0d 07 11 63 ff ff 83 39 ff fe
0f 0d 2a 6e ed c8 cb ca ff fb 65 97 9b 01 19 95 ca cc ef 6f 2f 0c 0f 07 11 63 ff ff 83 01 ff fe
0f 0d 2a 6e ed cb cb c8 ff fb 65 97 9b 9d 9d 01 ca cc ef 6f 2e 0c 0c 07 11 63 ff ff 03 01 e3 fe
0f 0d 2a 6e ec cb cb ca ff fb 65 97 03 9d 19 95 ca cc ef 6f 2e 0c 0d 07 11 63 ff ff 03 31 ff fe''',
'alien':'''01 02 05 0c 09 19 1c 3f c0 60 b0 b0 50 58 38 f8 ff 3e 0c 18 30 00 00 00 fc ee e6 60 60 40 c0 00
01 02 04 0c 09 19 1c 3f c0 60 30 b0 50 58 38 f8 7f 7e 4c 0c 0c 08 00 00 fc ec e6 60 60 70 10 00
01 02 05 0c 09 19 1c 3f c0 60 b0 b0 50 58 38 f8 3f 7e 3c 18 18 0c 00 00 fc ee e0 70 38 0c 00 00
01 02 04 0c 09 19 1c 3f c0 60 30 b0 50 58 38 f8 7f 7e 4c 0c 0c 08 00 00 fc ec e6 60 60 70 10 00''',
'cone':'''03 04 04 08 08 08 10 10 00 80 80 40 40 40 20 20 0f 00 1e 3f 7f 00 ff ff c0 00 60 30 38 00 9c 9c
03 06 06 0e 0e 0e 1e 1e 00 80 80 40 40 40 20 20 0f 00 1e 3f 7f 00 ff ff c0 00 60 30 38 00 9c 9c
03 07 07 0f 0f 0f 1f 1f 00 80 80 c0 c0 c0 e0 e0 0f 00 1e 3f 7f 00 ff ff c0 00 60 30 38 00 9c 9c
03 05 05 09 09 09 11 11 00 80 80 c0 c0 c0 e0 e0 0f 00 1e 3f 7f 00 ff ff c0 00 60 30 38 00 9c 9c'''
}

OUTPUTS = {
    'boot': 'enemy-type08-boot.dat',
    'ufo': 'enemy-type0c-ufo.dat',
    'king': 'enemy-type10-king.dat',
    'sad_mug': 'enemy-type12-sad-mug.dat',
    'alien': 'enemy-type17-alien.dat',
    'cone': 'enemy-type1a-cone.dat',
}

def write_all(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, filename in OUTPUTS.items():
        raw = bytes.fromhex(RAW[name])
        (out_dir / filename).write_bytes(build8(raw))

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--out-dir', type=Path, required=True)
    args = ap.parse_args()
    write_all(args.out_dir)
    print('enemy Room10-1F art: 6 authentic types generated')

if __name__ == '__main__':
    main()
