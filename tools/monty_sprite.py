#!/usr/bin/env python3
"""Convert authentic C64 Monty frames to native PCE sprite data."""
from pathlib import Path

WALK_L = bytes.fromhex(
"02 00 00 1d c0 00 7d c0 00 7f a0 00 1e 70 00 21 b8 00 76 b8 00 76 2c 00 6f ec 00 1f 6c 00 1f 98 00 0f bc 00 6f 7c 00 3e 38 00 1c f0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"02 00 00 1d c0 00 7d c0 00 7f a0 00 1e 70 00 01 b8 00 16 b8 00 16 3c 00 2d fc 00 2d bc 00 1e 7c 00 0f f8 00 03 f0 00 01 e8 00 0f d8 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"02 00 00 1d c0 00 7d c0 00 7f a0 00 1e 70 00 01 b8 00 06 b8 00 04 7c 00 0b fc 00 1b 7c 00 1c f8 00 0e fc 00 6f 7c 00 3e 38 00 1c f0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"02 00 00 1d c0 00 7d c0 00 7f a0 00 1e 70 00 01 b8 00 16 b8 00 36 3c 00 2d fc 00 2d bc 00 1e 7c 00 0f f8 00 03 f0 00 01 e0 00 0f c0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
WALK_R = bytes.fromhex(
"00 40 00 03 f8 00 03 fe 00 05 fe 00 0e 78 00 1d 84 00 1d 6e 00 34 6e 00 37 f6 00 36 f8 00 19 f8 00 3d f0 00 3e f6 00 1c 7c 00 0f 38 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"00 40 00 03 f8 00 03 fe 00 05 fe 00 0e 78 00 1d 80 00 1d 68 00 3c 68 00 3f b4 00 3d b4 00 3e 78 00 1f f0 00 0f c0 00 17 80 00 1b f0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"00 40 00 03 f8 00 03 fe 00 05 fe 00 0e 78 00 1d 80 00 1d 60 00 3e 20 00 3f d0 00 3e d8 00 1f 38 00 3f 70 00 3e f6 00 1c 7c 00 0f 38 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"00 40 00 03 f8 00 03 fe 00 05 fe 00 0e 78 00 1d 80 00 1d 68 00 3c 6c 00 3f b4 00 3d b4 00 3e 78 00 1f f0 00 0f c0 00 07 80 00 03 f0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
CLIMB = bytes.fromhex(
"07 80 00 0f c0 00 07 80 00 1f e0 00 3f f0 00 7f f8 00 5f e8 00 3f f0 00 7f f8 00 7f f8 00 7f f8 00 3f f0 00 3c f0 00 18 60 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"07 80 00 0f c0 00 07 80 00 1f e0 00 3f e0 00 7f f0 00 7f b8 00 3f b8 00 7f c8 00 7f f0 00 4f f0 00 37 e0 00 7b c0 00 71 e0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"07 80 00 0f c0 00 07 80 00 1f e0 00 3f f0 00 7f f8 00 5f e8 00 3f f0 00 7f f8 00 7f f8 00 7f f8 00 3f f0 00 3c f0 00 18 60 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"07 80 00 0f c0 00 07 80 00 1f e0 00 1f f0 00 3f f8 00 77 f8 00 77 f0 00 4f f8 00 3f f8 00 3f c8 00 1f b0 00 0f 78 00 1e 38 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
FRAME_BYTES=64

def c64_frame_pixels(frame):
    assert len(frame)==64
    rows=[]
    for y in range(21):
        v=(frame[y*3]<<16)|(frame[y*3+1]<<8)|frame[y*3+2]
        rows.append([(v>>(23-x))&1 for x in range(24)])
    return rows

def pce_16x16(tile):
    out=bytearray()
    for plane in range(4):
        for y in range(16):
            word=sum((tile[y][x] if plane==0 else 0)<<(15-x) for x in range(16))
            out += bytes((word & 0xff, word >> 8))
    return out

def convert_frame(frame):
    pix=c64_frame_pixels(frame); chunks=[]
    for x0 in (0,16):
        for y0 in (0,16):
            tile=[[0]*16 for _ in range(16)]
            for y in range(16):
                for x in range(16):
                    sy,sx=y0+y,x0+x
                    if sy<21 and sx<24: tile[y][x]=pix[sy][sx]
            chunks.append(pce_16x16(tile))
    return b''.join(chunks)

def build(frames):
    assert len(frames)%FRAME_BYTES==0
    return b''.join(convert_frame(frames[i:i+FRAME_BYTES]) for i in range(0,len(frames),FRAME_BYTES))

def main():
    import argparse
    ap=argparse.ArgumentParser(); ap.add_argument('--left',type=Path); ap.add_argument('--right',type=Path); ap.add_argument('--climb',type=Path); a=ap.parse_args()
    left,right,climb=build(WALK_L),build(WALK_R),build(CLIMB)
    if a.left: a.left.write_bytes(left)
    if a.right: a.right.write_bytes(right)
    if a.climb: a.climb.write_bytes(climb)
    print(f'Monty walk/climb: 12 authentic C64 frames -> {len(left)+len(right)+len(climb)} bytes PCE SPR')
if __name__=='__main__': main()
