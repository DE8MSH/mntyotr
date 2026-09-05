; Runtime copy of the port signature on the first BAT row below the 20-row
; C64 playfield. The legacy debug_room writer still targets row 27; clear that
; row after every debug_room_draw so only ONE footer remains visible.
;
; Both footer text and commit nibbles live in banked .data. Always map their
; banks before reading them; direct absolute LDA produced the observed repeated
; 0000/1111 garbage once runtime/data growth moved them out of the active bank.

DEBUG_FOOTER_VISIBLE_BAT = 23*BAT_LINE
DEBUG_FOOTER_LEGACY_BAT  = 27*BAT_LINE

.code

debug_footer_visible_draw:
        lda     #<DEBUG_FOOTER_LEGACY_BAT
        sta     <_di
        lda     #>DEBUG_FOOTER_LEGACY_BAT
        sta     <_di+1
        call    vdc_di_to_mawr
        ldx     #18
.clear_legacy:
        lda     #<(DEBUG_HEX_CHR+$10)
        sta     VDC_DL
        lda     #$70
        sta     VDC_DH
        dex
        bne     .clear_legacy

        php
        sei
        tma3
        pha
        tma4
        pha

        lda     #<debug_footer_tiles
        sta     <_bp
        lda     #>debug_footer_tiles
        sta     <_bp+1
        ldy     #BANK(debug_footer_tiles)
        call    map_bp_to_mpr34

        lda     #<DEBUG_FOOTER_VISIBLE_BAT
        sta     <_di
        lda     #>DEBUG_FOOTER_VISIBLE_BAT
        sta     <_di+1
        call    vdc_di_to_mawr

        cly
.footer_loop:
        lda     [_bp],y
        clc
        adc     #DEBUG_HEX_CHR
        sta     VDC_DL
        lda     #$70
        sta     VDC_DH
        iny
        cpy     #18
        bne     .footer_loop

        pla
        tam4
        pla
        tam3
        plp

        jmp     debug_commit_bank_safe_draw

debug_commit_bank_safe_draw:
        php
        sei
        tma3
        pha
        tma4
        pha

        lda     #<build_commit_nibbles
        sta     <_bp
        lda     #>build_commit_nibbles
        sta     <_bp+1
        ldy     #BANK(build_commit_nibbles)
        call    map_bp_to_mpr34

        lda     #<DEBUG_COMMIT_BAT
        sta     <_di
        lda     #>DEBUG_COMMIT_BAT
        sta     <_di+1
        call    vdc_di_to_mawr

        cly
.commit_loop:
        lda     [_bp],y
        clc
        adc     #DEBUG_HEX_CHR
        sta     VDC_DL
        lda     #$70
        sta     VDC_DH
        iny
        cpy     #7
        bne     .commit_loop

        pla
        tam4
        pla
        tam3
        plp

        ; Standard piledrivers occupy SAT entries 8..11. This diagnostic pass
        ; already runs every logical tick after mechanism updates, so it is a
        ; stable place to refresh those entries without growing main.asm again.
        jmp     piledriver_update_satb
