; Render one authentic 24x21 C64 special item with the same PCE 16x32
; sprite-group layout used by Monty and the enemy bridge.  A converted frame is
; stored in VRAM as TL,TR,BL,BR 16x16 cells.  The VDC's 16x32 mode fetches the
; matching top+bottom cells automatically, so only TWO SAT entries are needed:
; left at the group base and right at +$40 bytes.  The old four-entry renderer
; also placed explicit bottom sprites at Y+16; because those entries were still
; configured as 16x32 it drew the item twice vertically (very visible on the
; Room $0A cupcake) and made it appear embedded in the wall.
SPECIAL_ITEM_SAT_LEFT  = SAT_ADDR+64
SPECIAL_ITEM_SAT_RIGHT = SAT_ADDR+68

.code
.proc special_item_update_satb
        lda special_item_active
        bne .show
        jmp .hide
.show:
        lda #<SPECIAL_ITEM_SAT_LEFT
        sta <_di
        lda #>SPECIAL_ITEM_SAT_LEFT
        sta <_di+1
        call vdc_di_to_mawr

        ; Left 16x32 half. C64 VIC coordinates use the same bridge as enemies:
        ; PCE SAT X = VIC_X + 8, SAT Y = VIC_Y + 14.
        lda special_item_y
        clc
        adc #14
        sta VDC_DL
        stz VDC_DH
        lda special_item_x
        clc
        adc #8
        sta VDC_DL
        stz VDC_DH
        lda #<(SPECIAL_ITEM_VRAM>>5)
        sta VDC_DL
        lda #>(SPECIAL_ITEM_VRAM>>5)
        sta VDC_DH
        lda #$85
        sta VDC_DL
        lda #$10
        sta VDC_DH

        ; Right 16x32 half. +$40 selects TR while 16x32 hardware also fetches BR.
        lda special_item_y
        clc
        adc #14
        sta VDC_DL
        stz VDC_DH
        lda special_item_x
        clc
        adc #24
        sta VDC_DL
        stz VDC_DH
        lda #<((SPECIAL_ITEM_VRAM+$40)>>5)
        sta VDC_DL
        lda #>((SPECIAL_ITEM_VRAM+$40)>>5)
        sta VDC_DH
        lda #$85
        sta VDC_DL
        lda #$10
        sta VDC_DH
        jmp .dma

.hide:
        lda #<SPECIAL_ITEM_SAT_LEFT
        sta <_di
        lda #>SPECIAL_ITEM_SAT_LEFT
        sta <_di+1
        call vdc_di_to_mawr
        ldx #2
.hide_one:
        stz VDC_DL
        lda #1
        sta VDC_DH
        stz VDC_DL
        stz VDC_DH
        stz VDC_DL
        stz VDC_DH
        stz VDC_DL
        stz VDC_DH
        dex
        bne .hide_one
.dma:
        st0 #$13
        st1 #<SAT_ADDR
        st2 #>SAT_ADDR
        leave
.endp
