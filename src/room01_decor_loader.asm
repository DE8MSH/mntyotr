; Phase 34: bank-safe Room $01 decor upload kept separate from the proven
; gameplay/physics path. 25 exact C64 decor chars = 800 bytes at CHR_GAME+9.
;
; Keeping this routine outside room_loader.asm avoids growing the room-transition
; routine around its relative branches. The caller uses CALL, so this routine
; may live in another HuCard bank without changing gameplay code placement.

.zp
room01_decor_pages: ds 1

.code

room01_upload_decor:
        php
        sei
        tma3
        pha
        tma4
        pha

        lda     #<room01_decor_patterns
        sta     <_bp
        lda     #>room01_decor_patterns
        sta     <_bp+1
        ldy     #BANK(room01_decor_patterns)
        call    map_bp_to_mpr34

        lda     #<((CHR_GAME+9)*16)
        sta     <_di
        lda     #>((CHR_GAME+9)*16)
        sta     <_di+1
        call    vdc_di_to_mawr

        ; 800 bytes = 3 complete 256-byte pages + 32-byte tail.
        lda     #3
        sta     <room01_decor_pages
.full_page:
        cly
        ldx     #128
.full_word:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        dex
        bne     .full_word
        inc     <_bp+1
        dec     <room01_decor_pages
        bne     .full_page

        cly
        ldx     #16
.tail_word:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        dex
        bne     .tail_word

        pla
        tam4
        pla
        tam3
        plp
        rts
