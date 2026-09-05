#!/usr/bin/env python3
"""Convert original C64 Room $00 Skate/Smiley enemy graphics to PCE sprites.

The source enemy blocks are four 32-byte interleaved records. The C64
DeinterleaveSpriteRow routine expands each record to one 64-byte VIC sprite
slot. Both Skate ($09) and Smiley ($19) have enemy_copy_flag set, so these four
unique frames are duplicated for the opposite direction in C64 RAM; PCE only
needs the four unique frames.
"""
from pathlib import Path
from monty_sprite import convert_frame

SKATE = bytes.fromhex(
"0003070f0f2f2f3700c0e0f0f0f4f4ec3b3c7f78c10a5000dc3cfe0e432805"
"0003070c3a3f0f253bc0e0f0f0f0f4ecdc3c7f7ff005a800003cfefe0f502500"
"000003070d090f2d3600c0e0d090f0b46c3b3c7fff00550000dc3cfeff005500"
"00000003070f0f0f2f0000c02050fcfcf0273b7c7ff005a800acdc3efe0f502500")
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


def build(blob: bytes) -> bytes:
    assert len(blob) == 128
    frames = [deinterleave(blob[i:i+32]) for i in range(0,128,32)]
    return b''.join(convert_frame(f) for f in frames)


def main():
    import argparse
    ap=argparse.ArgumentParser()
    ap.add_argument('--skate', type=Path, required=True)
    ap.add_argument('--smiley', type=Path, required=True)
    a=ap.parse_args()
    skate,smiley=build(SKATE),build(SMILEY)
    a.skate.write_bytes(skate)
    a.smiley.write_bytes(smiley)
    assert len(skate)==len(smiley)==2048
    print('Room00 enemies: authentic Skate+Smiley 4-frame C64 art -> 4096 bytes PCE SPR')

if __name__=='__main__':
    main()
