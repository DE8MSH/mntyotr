#!/usr/bin/env python3
"""Convert authentic C64 Monty frames to native PCE sprite data.

Primary gameplay/art reference: Dave-Agent/monty-on-the-run refactored/src.
The reference sprite labels are aligned to four 64-byte VIC slots. Each VIC
sprite uses 63 visible bitmap bytes plus one unused byte.

The text transcription below omits runs of trailing zero bytes at some frame
ends. Therefore its total byte count is shorter than 4*63. Frame boundaries are
recovered from the authentic repeated frame prefixes visible at $5400/$5440/
$5480/$54c0 etc., and only the omitted trailing zero bytes of each individual
frame are restored. Prefix bytes may also occur inside a bitmap (notably climb),
so only candidates separated by a plausible frame-length interval are accepted.

PCE layout note: Monty's 24x21 image is carried by two 16x32 SAT sprites. The
VDC treats 16x32 as a half of an aligned 32x32 pattern group, so the four 16x16
cells in VRAM must be row-major: TL, TR, BL, BR. The previous x-major order
TL, BL, TR, BR made tall-sprite hardware fetch the wrong cells, which became
very obvious during the 12-frame somersault animation.
"""
from pathlib import Path

WALK_L = bytes.fromhex(
"02 00 00 1d c0 00 7d c0 00 7f a0 00 1e 70 00 21 b8 00 76 b8 00 76 2c 00 6f ec 00 1f 6c 00 1f 98 00 0f bc 00 6f 7c 00 3e 38 00 1c f0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"02 00 00 1d c0 00 7d c0 00 7f a0 00 1e 70 00 01 b8 00 16 b8 00 16 3c 00 2d fc 00 2d bc 00 1e 7c 00 0f f8 00 03 f0 00 01 e8 00 0f d8 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"02 00 00 1d c0 00 7d c0 00 7f a0 00 1e 70 00 01 b8 00 06 b8 00 04 7c 00 0b fc 00 1b 7c 00 1c f8 00 0e fc 00 6f 7c 00 3e 38 00 1c f0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"02 00 00 1d c0 00 7d c0 00 7f a0 00 1e 70 00 01 b8 00 16 b8 00 36 3c 00 2d fc 00 2d bc 00 1e 7c 00 0f f8 00 03 f0 00 01 e0 00 0f c0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
WALK_R = bytes.fromhex(
"00 40 00 03 f8 00 03 fe 00 05 fe 00 0e 78 00 1d 84 00 1d 6e 00 34 6e 00 37 f6 00 36 f8 00 19 f8 00 3d f0 00 3e f6 00 1c 7c 00 0f 38 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"00 40 00 03 f8 00 03 fe 00 05 fe 00 0e 78 00 1d 80 00 1d 68 00 3c 68 00 3f b4 00 3d b4 00 3e 78 00 1f f0 00 0f c0 00 17 80 00 1b f0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"00 40 00 03 f8 00 03 fe 00 05 fe 00 0e 78 00 1d 80 00 1d 60 00 3e 20 00 3f d0 00 3e d8 00 1f 38 00 3f 70 00 3e f6 00 1c 7c 00 0f 38 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"00 40 00 03 f8 00 03 fe 00 05 fe 00 0e 78 00 1d 80 00 1d 68 00 3c 6c 00 3f b4 00 3d b4 00 3e 78 00 1f f0 00 0f c0 00 07 80 00 03 f0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
CLIMB = bytes.fromhex(
"07 80 00 0f c0 00 07 80 00 1f e0 00 3f f0 00 7f f8 00 5f e8 00 3f f0 00 7f f8 00 7f f8 00 7f f8 00 3f f0 00 3c f0 00 18 60 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"07 80 00 0f c0 00 07 80 00 1f e0 00 3f e0 00 7f f0 00 7f b8 00 3f b8 00 7f c8 00 7f f0 00 4f f0 00 37 e0 00 7b c0 00 71 e0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"07 80 00 0f c0 00 07 80 00 1f e0 00 3f f0 00 7f f8 00 5f e8 00 3f f0 00 7f f8 00 7f f8 00 7f f8 00 3f f0 00 3c f0 00 18 60 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
"07 80 00 0f c0 00 07 80 00 1f e0 00 1f f0 00 3f f8 00 77 f8 00 77 f0 00 4f f8 00 3f f8 00 3f c8 00 1f b0 00 0f 78 00 1e 38 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")

BITMAP_BYTES = 63
VIC_FRAME_BYTES = 64
FRAME_BYTES = BITMAP_BYTES


def _recover_frames(blob: bytes, prefix: bytes, count: int = 4) -> bytes:
    candidates=[]
    pos=0
    while True:
        i=blob.find(prefix,pos)
        if i < 0:
            break
        candidates.append(i)
        pos=i+1
    if not candidates or candidates[0] != 0:
        raise AssertionError(f'missing first frame prefix {prefix.hex()}: {candidates}')
    starts=[0]
    for i in candidates[1:]:
        if i - starts[-1] >= 48:
            starts.append(i)
            if len(starts) == count:
                break
    if len(starts) != count:
        raise AssertionError(f'could not recover {count} frame starts for {prefix.hex()}: candidates={candidates}, selected={starts}')
    out=[]
    for n,start in enumerate(starts):
        end=starts[n+1] if n+1<count else len(blob)
        frame=blob[start:end]
        if not 48 <= len(frame) <= BITMAP_BYTES:
            raise AssertionError(f'frame {n} implausible length: {len(frame)}; starts={starts}')
        frame += bytes(BITMAP_BYTES-len(frame))
        out.append(frame)
    return b''.join(out)

WALK_L = _recover_frames(WALK_L, bytes.fromhex('02 00 00'))
WALK_R = _recover_frames(WALK_R, bytes.fromhex('00 40 00'))
CLIMB  = _recover_frames(CLIMB,  bytes.fromhex('07 80 00'))


def c64_frame_pixels(frame):
    assert len(frame) in (BITMAP_BYTES,VIC_FRAME_BYTES)
    frame=frame[:BITMAP_BYTES]
    rows=[]
    for y in range(21):
        v=(frame[y*3]<<16)|(frame[y*3+1]<<8)|frame[y*3+2]
        rows.append([(v>>(23-x))&1 for x in range(24)])
    return rows


def _plane_word(tile,plane,y):
    return sum((((tile[y][x]>>plane)&1)<<(15-x)) for x in range(16))


def pce_16x16(tile):
    out=bytearray()
    for plane in range(4):
        for y in range(16):
            word=_plane_word(tile,plane,y)
            out += bytes((word & 0xff, word >> 8))
    assert len(out)==128
    return out


def convert_frame(frame):
    pix=c64_frame_pixels(frame)
    chunks=[]
    # PCE 32x32 sprite-group order is row-major. A 16x32 SAT entry selects
    # one half of this aligned group, so hardware fetches TL+BL or TR+BR.
    # Keep the group as TL,TR,BL,BR in VRAM rather than TL,BL,TR,BR.
    for y0 in (0,16):
        for x0 in (0,16):
            tile=[[0]*16 for _ in range(16)]
            for y in range(16):
                for x in range(16):
                    sy,sx=y0+y,x0+x
                    if sy<21 and sx<24:
                        tile[y][x]=pix[sy][sx]
            chunks.append(pce_16x16(tile))
    return b''.join(chunks)


def build(frames):
    assert len(frames)%BITMAP_BYTES==0
    return b''.join(convert_frame(frames[i:i+BITMAP_BYTES]) for i in range(0,len(frames),BITMAP_BYTES))


def main():
    import argparse
    ap=argparse.ArgumentParser()
    ap.add_argument('--left',type=Path)
    ap.add_argument('--right',type=Path)
    ap.add_argument('--climb',type=Path)
    a=ap.parse_args()
    left,right,climb=build(WALK_L),build(WALK_R),build(CLIMB)
    if a.left: a.left.write_bytes(left)
    if a.right: a.right.write_bytes(right)
    if a.climb: a.climb.write_bytes(climb)
    print(f'Monty walk/climb: 12 authentic C64 frames -> {len(left)+len(right)+len(climb)} bytes PCE SPR')

if __name__=='__main__':
    main()
