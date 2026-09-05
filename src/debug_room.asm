; Two-digit hexadecimal room-id overlay at the top-right corner.
; Uses the reserved diagnostic-font VRAM area (CHR_FONT..CHR_FONT+15), so room
; graphics beginning at CHR_GAME never overwrite it. Palette 7 is existing
; white-on-black from room00_bg_palettes.

DEBUG_ROOM_BAT = 38              ; row 0, columns 38..39 of the 64-wide BAT
DEBUG_HEX_CHR  = CHR_FONT

.code

debug_room_init:
        php
        sei
        tma3
        pha
        tma4
        pha

        lda     #<debug_hex_patterns
        sta     <_bp
        lda     #>debug_hex_patterns
        sta     <_bp+1
        ldy     #BANK(debug_hex_patterns)
        call    map_bp_to_mpr34

        lda     #<(DEBUG_HEX_CHR*16)
        sta     <_di
        lda     #>(DEBUG_HEX_CHR*16)
        sta     <_di+1
        call    vdc_di_to_mawr

        ; 16 glyphs * 32 bytes = 512 bytes.
        ldx     #2
        cly
.page:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        bne     .page
        inc     <_bp+1
        dex
        bne     .page

        pla
        tam4
        pla
        tam3
        plp

        jmp     debug_room_draw

; Draw current monty_room as two hexadecimal digits (00, 01, 0A, ...).
; DEBUG_HEX_CHR is currently below 256, so its high BAT tile bits are zero.
debug_room_draw:
        lda     #<DEBUG_ROOM_BAT
        sta     <_di
        lda     #>DEBUG_ROOM_BAT
        sta     <_di+1
        call    vdc_di_to_mawr

        lda     <monty_room
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #DEBUG_HEX_CHR
        sta     VDC_DL
        lda     #$70              ; palette 7, tile high bits 0
        sta     VDC_DH

        lda     <monty_room
        and     #$0f
        clc
        adc     #DEBUG_HEX_CHR
        sta     VDC_DL
        lda     #$70
        sta     VDC_DH
        rts

.data
; 8x8 1bpp hexadecimal glyphs converted to PCE 4bpp tiles:
; each source row is plane 0 followed by zero plane 1; planes 2/3 are zero.
debug_hex_patterns:
        ; 0
        db $3c,$00,$66,$00,$6e,$00,$76,$00,$66,$00,$66,$00,$3c,$00,$00,$00
        ds 16,0
        ; 1
        db $18,$00,$38,$00,$18,$00,$18,$00,$18,$00,$18,$00,$7e,$00,$00,$00
        ds 16,0
        ; 2
        db $3c,$00,$66,$00,$06,$00,$0c,$00,$30,$00,$60,$00,$7e,$00,$00,$00
        ds 16,0
        ; 3
        db $3c,$00,$66,$00,$06,$00,$1c,$00,$06,$00,$66,$00,$3c,$00,$00,$00
        ds 16,0
        ; 4
        db $0c,$00,$1c,$00,$3c,$00,$6c,$00,$7e,$00,$0c,$00,$0c,$00,$00,$00
        ds 16,0
        ; 5
        db $7e,$00,$60,$00,$7c,$00,$06,$00,$06,$00,$66,$00,$3c,$00,$00,$00
        ds 16,0
        ; 6
        db $1c,$00,$30,$00,$60,$00,$7c,$00,$66,$00,$66,$00,$3c,$00,$00,$00
        ds 16,0
        ; 7
        db $7e,$00,$66,$00,$0c,$00,$18,$00,$18,$00,$18,$00,$18,$00,$00,$00
        ds 16,0
        ; 8
        db $3c,$00,$66,$00,$66,$00,$3c,$00,$66,$00,$66,$00,$3c,$00,$00,$00
        ds 16,0
        ; 9
        db $3c,$00,$66,$00,$66,$00,$3e,$00,$06,$00,$0c,$00,$38,$00,$00,$00
        ds 16,0
        ; A
        db $18,$00,$3c,$00,$66,$00,$66,$00,$7e,$00,$66,$00,$66,$00,$00,$00
        ds 16,0
        ; B
        db $7c,$00,$66,$00,$66,$00,$7c,$00,$66,$00,$66,$00,$7c,$00,$00,$00
        ds 16,0
        ; C
        db $3c,$00,$66,$00,$60,$00,$60,$00,$60,$00,$66,$00,$3c,$00,$00,$00
        ds 16,0
        ; D
        db $78,$00,$6c,$00,$66,$00,$66,$00,$66,$00,$6c,$00,$78,$00,$00,$00
        ds 16,0
        ; E
        db $7e,$00,$60,$00,$60,$00,$7c,$00,$60,$00,$60,$00,$7e,$00,$00,$00
        ds 16,0
        ; F
        db $7e,$00,$60,$00,$60,$00,$7c,$00,$60,$00,$60,$00,$60,$00,$00,$00
        ds 16,0
