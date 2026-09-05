        include "standard_piledriver.asm"
        include "standard_piledriver_bat_fix.asm"
        include "standard_piledriver_static.asm"

; Standard piledrivers are original-style dynamic BG charset tiles, not sprites.
; The safe runtime stage currently uses only static SeedGlyphs + DrawShaft; the
; crash-prone MoveDown/MoveUp buffer path remains gated until static geometry is
; confirmed in the emulator.
.code
piledriver_palette_init:
        rts
