#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
src = (ROOT / "src/enemy_smiley_runtime.asm").read_text()

# Exact Room $00 state reconstructed from C64 SetupRoom.
for needle in (
    "ENEMY_SMILEY_VRAM  = $3800",
    "ENEMY_SKATE_VRAM   = $3c00",
    "lda     #$78",
    "sta     enemy_smiley_x",
    "lda     #$6a",
    "lda     #$01                    ; dir_idx4 -> vertical/down",
    "cmp     #$25",
    "adc     #2",
    "sbc     #2",
    "lda     #$58",
    "sta     enemy_skate_x",
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

# C64 SetupRoom stores half-X; ProcessSprites ASLs before VIC output.
# PCE bridge must therefore double enemy_x and add +8 for the left half,
# +24 for the right half, preserving the 9th X bit for Smiley-right ($0108).
for needle in (
    "SAT X = 2*enemy_x + 8",
    "lda     enemy_smiley_x",
    "lda     enemy_skate_x",
    "adc     #8",
    "adc     #24",
    "stx     VDC_DH",
    "SAT X = 2*$78+8 = $00F8",
    "SAT X = 2*$78+24 = $0108",
    "SAT X = 2*$58+8 = $00B8",
    "SAT X = 2*$58+24 = $00C8",
    "lda     #$83                    ; sprite palette slot19",
    "lda     #$84                    ; sprite palette slot20",
):
    assert needle in src, needle

assert "lda     #$80                    ; C64 X=$78 + 8" not in src
assert "lda     #$60                    ; C64 X=$58 + 8" not in src

print("OK: Room00 Smiley+Skate exact spawn/speed/range/half-frame tick + doubled C64 enemy X bridge")
