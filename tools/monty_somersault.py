#!/usr/bin/env python3
"""Convert Monty's exact 12+12 C64 somersault frames to PCE sprite data."""
import re
from pathlib import Path
from monty_sprite import BITMAP_BYTES, VIC_FRAME_BYTES, convert_frame

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'tools' / 'monty_somersault_source.asm'


def _parse_block(text: str, label: str, next_label: str | None) -> bytes:
    part = text.split(label + ':', 1)[1]
    if next_label:
        part = part.split(next_label + ':', 1)[0]
    vals = []
    for line in part.splitlines():
        line = line.split(';', 1)[0]
        if '.byte' not in line:
            continue
        vals.extend(int(x, 16) for x in re.findall(r'\$([0-9a-fA-F]{2})', line))
    return bytes(vals)


def load_raw_frames():
    text = SOURCE.read_text()
    left = _parse_block(text, 'sault_l_spr', 'sault_r_spr')
    right = _parse_block(text, 'sault_r_spr', None)
    expected = 12 * VIC_FRAME_BYTES
    assert len(left) == expected, f'somersault-left raw bytes: {len(left)} != {expected}'
    assert len(right) == expected, f'somersault-right raw bytes: {len(right)} != {expected}'
    return left, right


def visible_frames(raw: bytes) -> bytes:
    assert len(raw) % VIC_FRAME_BYTES == 0
    return b''.join(raw[i:i+BITMAP_BYTES] for i in range(0, len(raw), VIC_FRAME_BYTES))


def build(raw: bytes) -> bytes:
    visible = visible_frames(raw)
    return b''.join(convert_frame(visible[i:i+BITMAP_BYTES])
                    for i in range(0, len(visible), BITMAP_BYTES))


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('--left', type=Path)
    ap.add_argument('--right', type=Path)
    a = ap.parse_args()
    left_raw, right_raw = load_raw_frames()
    left, right = build(left_raw), build(right_raw)
    if a.left:
        a.left.write_bytes(left)
    if a.right:
        a.right.write_bytes(right)
    print(f'Monty somersault: 24 exact C64 VIC frames -> {len(left)+len(right)} bytes PCE SPR')


if __name__ == '__main__':
    main()
