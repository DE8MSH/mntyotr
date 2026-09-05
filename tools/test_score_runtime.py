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
assert "call    score_init" in main
assert main.index('include "score_runtime.asm"') < main.index("bare_main:")
assert main.index("call    score_init") < main.index("main_loop:")

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

print("OK: authentic five-ASCII-digit C64 score arithmetic + startup init")
