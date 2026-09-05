        include "standard_piledriver.asm"
        include "standard_piledriver_bat_fix.asm"
        include "standard_piledriver_static.asm"
        include "standard_piledriver_exact_runtime.asm"

; Standard piledrivers use original-style dynamic BG charset tiles, not sprites.
; The safe renderer regenerates VRAM directly; exact_runtime restores the C64
; independent RNG draws and CheckTiles death semantics without the old mutable
; 144-byte pointer walk that crashed Room $01.
.code
piledriver_palette_init:
        rts
