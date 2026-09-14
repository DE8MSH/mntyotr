#!/usr/bin/env python3
"""Pack/unpack 16-bit PCE BAT streams with a tiny PackBits-style RLE.

Packet format is deliberately trivial for HuC6280 decoding:
- control bit7=1: run packet, count=(control&$7f)+1, followed by one LE word
- control bit7=0: literal packet, count=control+1, followed by count LE words

The codec is used for the 36x20 room BATs ($10-$33): source truth remains the
uncompressed generated BAT, while only the compact stream is incbin'd into ROM.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path

MAX_PACKET = 128


def words_from_bytes(data: bytes) -> list[int]:
    if len(data) & 1:
        raise ValueError("BAT byte length must be even")
    return list(struct.unpack("<" + "H" * (len(data) // 2), data))


def encode(data: bytes) -> bytes:
    words = words_from_bytes(data)
    out = bytearray()
    i = 0
    n = len(words)
    while i < n:
        run = 1
        while i + run < n and run < MAX_PACKET and words[i + run] == words[i]:
            run += 1
        if run >= 2:
            out.append(0x80 | (run - 1))
            out += struct.pack("<H", words[i])
            i += run
            continue

        start = i
        i += 1
        while i < n and i - start < MAX_PACKET:
            run = 1
            while i + run < n and run < MAX_PACKET and words[i + run] == words[i]:
                run += 1
            if run >= 2:
                break
            i += 1
        count = i - start
        out.append(count - 1)
        out += struct.pack("<" + "H" * count, *words[start:i])
    return bytes(out)


def decode(packed: bytes, expected_words: int | None = None) -> bytes:
    out: list[int] = []
    i = 0
    while i < len(packed):
        ctrl = packed[i]
        i += 1
        count = (ctrl & 0x7F) + 1
        if ctrl & 0x80:
            if i + 2 > len(packed):
                raise ValueError("truncated run packet")
            word = packed[i] | (packed[i + 1] << 8)
            i += 2
            out.extend([word] * count)
        else:
            size = count * 2
            if i + size > len(packed):
                raise ValueError("truncated literal packet")
            out.extend(words_from_bytes(packed[i:i + size]))
            i += size
    if expected_words is not None and len(out) != expected_words:
        raise ValueError(f"decoded {len(out)} words, expected {expected_words}")
    return struct.pack("<" + "H" * len(out), *out)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("input", type=Path)
    ap.add_argument("output", type=Path)
    ap.add_argument("--verify-words", type=int, default=36 * 20)
    args = ap.parse_args()
    raw = args.input.read_bytes()
    packed = encode(raw)
    assert decode(packed, args.verify_words) == raw
    args.output.write_bytes(packed)
    print(f"{args.input.name}: {len(raw)} -> {len(packed)} bytes ({100*len(packed)/len(raw):.1f}%)")


if __name__ == "__main__":
    main()
