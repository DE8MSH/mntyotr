; Runtime port signature and build id below the 20-row C64 playfield.
; Row 23: fixed footer text. Row 24: 7-digit build commit directly underneath.
; The old row-27 writer was removed earlier, so no per-frame legacy clear is
; needed anymore. This also returns enough main-bank bytes for the live HUD.
;
; Both footer text and commit nibbles live in banked .data. Always map their
; banks before reading them; direct absolute LDA produced repeated garbage once
; runtime/data growth moved them out of the active bank.

DEBUG_FOOTER_VISIBLE_BAT = 23*BAT_LINE

.code

debug_footer_visible_draw:
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
        rts
