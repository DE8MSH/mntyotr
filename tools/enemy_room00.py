#!/usr/bin/env python3
"""Convert the authentic C64 enemy sprite blocks needed by rooms $00-$02.

C64 UnpackSpriteGraphics deinterleaves 32-byte source chunks into one 64-byte
VIC sprite frame. Types with enemy_copy_flag set provide four unique frames;
the original copies frames 0..3 to 4..7. Eight-frame types keep both direction
groups intact. Every generated PCE file therefore contains exactly eight
512-byte 24x21->two-16x32 frames (4096 bytes).
"""
from pathlib import Path
from monty_sprite import convert_frame

SKATE = bytes.fromhex(
"0003070f0f2f2f3700c0e0f0f0f4f4ec3b3c7f78c10a5000dc3cfe0e432805"
"0003070c3a3f0f253bc0e0f0f0f0f4ecdc3c7f7ff005a800003cfefe0f502500"
"000003070d090f2d3600c0e0d090f0b46c3b3c7fff00550000dc3cfeff005500"
"00000003070f0f0f2f0000c02050fcfcf0273b7c7ff005a800acdc3efe0f502500")
CLOCK = bytes.fromhex(
"00fc330e19362f6f003fcc70186c74765e566d37190e0300ea7af66c9a76c400"
"c07c330e19362f6f033ecc70186c74765e566d37190e0300ea7af66c9a76c400"
"00fc330e19362f6f003fcc70186c74765e566d37190e0300ea7af66c9a76c400"
"001c73ce19362f6f0038ce73186c74765e566d37190e0300ea7af66c9a76c400")
BIG_NOSE = bytes.fromhex(
"00000001073e7fff18649616acdc7c7cfef8700000050b0b78f834e8140cbcfc"
"000000010f7effff18648616acdc7c7cfe7000000001020278f834ea1646eef8"
"00000000033f7f7f0c324383d66ebebe7f3e000002050500bc7c1a748adefe"
"0000000000031f3f7f0c324383c66ebebe7f7c3800000a17173c7c18740c1478f8"
"18266968353b3e3e00000080e07cfeff1e1f2c1728303d3f7f1f0e0000a0d0d0"
"18266168353b3e3e00000080f07effff1e1f2c576862771f7f0e000000804040"
"304cc2c16b767d7d00000000c0fcfefe3d3e582e517b7f00fe7c000040a0a0"
"00304cc2c163767d7d00000000c0f8fcfe3c3e182e30281e1ffe3e1c000050e8e8")
WASP = bytes.fromhex(
"0c060602020202013060604040404080040b150b57cf83a120d0a8d0eaf3c185"
"0000701c0c06020100000e3830604080040b150b57cf83a120d0a8d0eaf3c185"
"0000000070fc0601000000000e3f6080040b150b57cf83a120d0a8d0eaf3c185"
"0000701c0c06020100000e3830604080040b150b57cf83a120d0a8d0eaf3c185")
KETTLE = bytes.fromhex(
"08a101000107c0df00c04080c0b003af5f1f1f1f0f070007d5b4d4b4f8b000d0"
"40a141804107c0df00c04080c0b003af5f1f1f1f0f070007d5b4d4b4f8b000d0"
"c82911200107c0df00c04080c0b003af5f1f1f1f0f070007d5b4d4b4f8b000d0"
"a419a1000107c0df00c04080c0b003af5f1f1f1f0f070007d5b4d4b4f8b000d0"
"00030201030dc0f51085800080e003fbab2d2b2d1f0d000bfaf8f8f8f0e000e0"
"00030201030dc0f50285820182e003fbab2d2b2d1f0d000bfaf8f8f8f0e000e0"
"00030201030dc0f51394880480e003fbab2d2b2d1f0d000bfaf8f8f8f0e000e0"
"00030201030dc0f52598850080e003fbab2d2b2d1f0d000bfaf8f8f8f0e000e0")
SMILEY = bytes.fromhex(
"01070c1b383a7ccfc0f0986c0e4f1ff1b3acce4666223c07cb1ae6c4cc9830e0"
"01070c18383a7ccfc0f0980c0e4f1ff1b3acce66381f0703cb1ae6c41cf8f0c0"
"01070c1838387ccfc0f0980c0e0f1ff1f3fcff7f3f1f0703cf1efefcfcf8f0c0"
"01070c18383a7ccfc0f0980c0e4f1ff1b3acce66381f0703cb1ae6c41cf8f0c0")


def deinterleave(src: bytes) -> bytes:
    assert len(src) == 32
    out = bytearray(64)
    y = 0
    for x in range(8):
        out[y] = src[x]
        out[y+1] = src[8+x]
        y += 3
    for x in range(8):
        out[y] = src[16+x]
        out[y+1] = src[24+x]
        y += 3
    return bytes(out)


def build8(blob: bytes) -> bytes:
    assert len(blob) in (128, 256)
    frames = [deinterleave(blob[i:i+32]) for i in range(0, len(blob), 32)]
    if len(frames) == 4:
        frames = frames + frames
    assert len(frames) == 8
    out = b''.join(convert_frame(f) for f in frames)
    assert len(out) == 4096
    return out


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('--skate', type=Path, required=True)
    ap.add_argument('--clock', type=Path, required=True)
    ap.add_argument('--big-nose', type=Path, required=True)
    ap.add_argument('--wasp', type=Path, required=True)
    ap.add_argument('--kettle', type=Path, required=True)
    ap.add_argument('--smiley', type=Path, required=True)
    a = ap.parse_args()
    payloads = {
        a.skate: build8(SKATE),
        a.clock: build8(CLOCK),
        a.big_nose: build8(BIG_NOSE),
        a.wasp: build8(WASP),
        a.kettle: build8(KETTLE),
        a.smiley: build8(SMILEY),
    }
    for path, data in payloads.items():
        path.write_bytes(data)
    print('Rooms00-02 enemies: 6 authentic C64 types -> 6 x 8 PCE frames')


if __name__ == '__main__':
    main()
