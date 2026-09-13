; Render one 24x21 special item using SAT entries 16..19.
SPECIAL_ITEM_SAT_TL = SAT_ADDR+64
SPECIAL_ITEM_SAT_TR = SAT_ADDR+68
SPECIAL_ITEM_SAT_BL = SAT_ADDR+72
SPECIAL_ITEM_SAT_BR = SAT_ADDR+76

.code
.proc special_item_update_satb
        lda special_item_active
        bne .show
        jmp .hide
.show:
        lda #<SPECIAL_ITEM_SAT_TL
        sta <_di
        lda #>SPECIAL_ITEM_SAT_TL
        sta <_di+1
        call vdc_di_to_mawr

        ; top-left
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

        ; top-right
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

        ; bottom-left
        lda special_item_y
        clc
        adc #30
        sta VDC_DL
        stz VDC_DH
        lda special_item_x
        clc
        adc #8
        sta VDC_DL
        stz VDC_DH
        lda #<((SPECIAL_ITEM_VRAM+$80)>>5)
        sta VDC_DL
        lda #>((SPECIAL_ITEM_VRAM+$80)>>5)
        sta VDC_DH
        lda #$85
        sta VDC_DL
        lda #$10
        sta VDC_DH

        ; bottom-right
        lda special_item_y
        clc
        adc #30
        sta VDC_DL
        stz VDC_DH
        lda special_item_x
        clc
        adc #24
        sta VDC_DL
        stz VDC_DH
        lda #<((SPECIAL_ITEM_VRAM+$c0)>>5)
        sta VDC_DL
        lda #>((SPECIAL_ITEM_VRAM+$c0)>>5)
        sta VDC_DH
        lda #$85
        sta VDC_DL
        lda #$10
        sta VDC_DH
        jmp .dma

.hide:
        lda #<SPECIAL_ITEM_SAT_TL
        sta <_di
        lda #>SPECIAL_ITEM_SAT_TL
        sta <_di+1
        call vdc_di_to_mawr
        ldx #4
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
