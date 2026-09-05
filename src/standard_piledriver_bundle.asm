        include "standard_piledriver.asm"
        include "standard_piledriver_assets_tail.asm"

.code
piledriver_palette_init:
        lda     #19
        sta     <_al
        lda     #1
        sta     <_ah
        lda     #<piledriver_sprite_palette
        sta     <_bp
        lda     #>piledriver_sprite_palette
        sta     <_bp+1
        ldy     #BANK(piledriver_sprite_palette)
        call    load_palettes
        jmp     xfer_palettes
