#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
src = (ROOT / "src/score_runtime.asm").read_text()
main = (ROOT / "src/main.asm").read_text()

for needle in (
    "score_digits:           ds 5",
    "score_lsb:              ds 1",
    "score_init:",
    "lda     #$30",
    "score_increase:",
    "cmp     #$20",
    "cmp     #$3a",
    "sbc     #$0a",
    "dey\n        bpl     score_increase",
    "score_decrement:",
    "ldy     #$04",
    "cmp     #$2f",
    "lda     #$39",
    "score_zero:",
):
    assert needle in src, needle

assert 'include "score_runtime.asm"' in main
assert main.index('include "score_runtime.asm"') < main.index("bare_main:")

# Startup is now deliberately tiny in HOME: bare_main calls a relocatable init
# procedure before entering main_loop. Guard the semantic ordering rather than
# the old source-text ordering of score_init versus main_loop.
assert "bare_main:\n        call    main_game_init\nmain_loop:" in main
init_start = main.index(".proc main_game_init")
init_end = main.index(".endp", init_start)
init_body = main[init_start:init_end]
assert "call    score_init" in init_body

# Score integration must not delete the local video timing helper used by startup.
assert "call    init_c64_video" in init_body
assert ".proc init_c64_video" in main
video_start = main.index(".proc init_c64_video")
video_end = main.index(".endp", video_start)
video_body = main[video_start:video_end]
for needle in (
    "st0     #$0a",
    "st1     #<VDC_HSR_320",
    "st2     #>VDC_HSR_320",
    "st0     #$0b",
    "st1     #<VDC_HDR_320",
    "st2     #>VDC_HDR_320",
):
    assert needle in video_body, needle

# Five display-ready ASCII digits, exactly as original $0294-$0298.
digits = [0x30] * 5

def increase(amount, y):
    while True:
        d = digits[y]
        if d == 0x20:
            d = 0x30
        d += amount
        if d < 0x3A:
            digits[y] = d
            return
        digits[y] = d - 10
        amount = 1
        y -= 1
        if y < 0:
            return

increase(5, 3)          # +50
assert bytes(digits) == b"00050"
increase(2, 2)          # +200
assert bytes(digits) == b"00250"
increase(8, 3)          # +80 -> 00330
assert bytes(digits) == b"00330"

print("OK: authentic five-ASCII-digit C64 score arithmetic + relocated startup/video init")
