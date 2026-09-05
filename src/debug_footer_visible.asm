; Runtime copy of the port signature on the first BAT row below the 20-row
; C64 playfield. The previous row-27 placement can be cropped by emulator/video
; overscan even though the top diagnostics remain visible.

DEBUG_FOOTER_VISIBLE_BAT = 23*BAT_LINE

.code

debug_footer_visible_draw:
        lda     #<DEBUG_FOOTER_VISIBLE_BAT
        sta     <_di
        lda     #>DEBUG_FOOTER_VISIBLE_BAT
        sta     <_di+1
        call    vdc_di_to_mawr
        ldx     #0
.loop:
        lda     debug_footer_tiles,x
        clc
        adc     #DEBUG_HEX_CHR
        sta     VDC_DL
        lda     #$70
        sta     VDC_DH
        inx
        cpx     #18
        bne     .loop
        rts
