#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
src = (ROOT / "src/enemy_smiley_runtime.asm").read_text()

# Exact Room $00 state reconstructed from C64 SetupRoom.
for needle in (
    "ENEMY_SMILEY_VRAM  = $3800",
    "ENEMY_SKATE_VRAM   = $3c00",
    "lda     #$6a",
    "lda     #$01                    ; dir_idx4 -> vertical/down",
    "cmp     #$25",
    "adc     #2",
    "sbc     #2",
    "lda     #$c2",
    "lda     #$81                    ; dir_idx3 -> vertical/up",
    "lda     #$13                    ; negative flags preserve range as count",
    "cmp     #$13",
    "adc     #3",
    "sbc     #3",
    "lda     <game_tick_counter",
    "and     #$01",
):
    assert needle in src, needle

# --newproc thunks JMP into MPR6. Every exit must use LEAVE so MPR6 is restored.
procs = re.findall(r"(?ms)^\.proc\s+([^\n]+)\n(.*?)^\.endp\s*$", src)
assert len(procs) == 4, [name for name, _ in procs]
for name, body in procs:
    assert not re.search(r"(?m)^\s*rts(?:\s|$)", body), f"raw RTS inside relocated proc {name}"
    assert re.search(r"(?m)^\s*leave(?:\s|$)", body), f"no LEAVE in relocated proc {name}"

# Exact VIC->PCE SAT bridge and fixed Room00 X positions.
for needle in (
    "adc     #14",
    "lda     #$80                    ; C64 X=$78 + 8",
    "lda     #$60                    ; C64 X=$58 + 8",
    "lda     #$83                    ; sprite palette slot19",
    "lda     #$84                    ; sprite palette slot20",
):
    assert needle in src, needle

print("OK: Room00 Smiley+Skate exact spawn/speed/range/half-frame tick + newproc LEAVE")
