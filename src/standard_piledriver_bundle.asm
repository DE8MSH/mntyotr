        include "standard_piledriver.asm"

; Standard piledrivers are original-style dynamic BG charset tiles, not sprites.
; They reuse the already-loaded C64 grey BG palette slots 6/5/4, so no extra
; palette or sprite asset upload is required.
.code
piledriver_palette_init:
        rts
