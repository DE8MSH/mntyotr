; Phase 39: bank-safe Room $02 decor upload.
; tools/room02_decor.py generates 57 exact 8x8 PCE chars in source type order.

CHR_ROOM02_DECOR = CHR_GAME + 9

.code

room02_upload_decor:
        php
        sei
        tma3
        pha
        tma4
        pha

        lda     #<room02_decor_patterns
        sta     <_bp
        lda     #>room02_decor_patterns
        sta     <_bp+1
        ldy     #BANK(room02_decor_patterns)
        call    map_bp_to_mpr34

        lda     #<(CHR_ROOM02_DECOR*16)
        sta     <_di
        lda     #>(CHR_ROOM02_DECOR*16)
        sta     <_di+1
        call    vdc_di_to_mawr

        ; 57 chars * 32 bytes = 1824 bytes = 7 full pages + 32 bytes.
        ldx     #7
.page:
        cly
.copy_page:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        bne     .copy_page
        inc     <_bp+1
        dex
        bne     .page

        cly
        ldx     #16
.tail:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        dex
        bne     .tail

        pla
        tam4
        pla
        tam3
        plp
        rts
