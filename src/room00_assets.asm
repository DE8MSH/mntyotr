; Converted C64 room-$00 graphics assets.
; Base room chars 0..8 follow Room.SetupTileGraphics/PopulateColourRam.
; Phase 31 uploads the complete room-$00 decor bitmap set used by the room:
; types 0..6 plus type $43 sad_flowers, for 41 generated 8x8 characters total.
; Base room and decor share a compact BG palette map so all C64 per-character
; colours fit in the PCE's 16 background palettes.

CHR_ROOM00_DECOR = CHR_GAME + 9

.code
upload_room00_patterns:
        lda #<(CHR_GAME*16)
        sta <_di+0
        lda #>(CHR_GAME*16)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_patterns,VDC_DL,288

        lda #<(CHR_ROOM00_DECOR*16)
        sta <_di+0
        lda #>(CHR_ROOM00_DECOR*16)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_decor_patterns,VDC_DL,1312
        rts

.data
room00_patterns:
        ; C64 character code 0: blank.
        ds 32,0
        ; char 1 / room slot 0 <- C64 tile library $0A
        db $ee,$00,$44,$00,$11,$00,$bb,$00,$bb,$00,$11,$00,$c4,$00,$ef,$00
        ds 16,0
        ; char 2 / slot 1 <- library $0B
        db $00,$00,$00,$00,$00,$00,$80,$00,$a0,$00,$10,$00,$c0,$00,$ec,$00
        ds 16,0
        ; char 3 / slot 2 <- library $01
        db $00,$00,$fe,$00,$fe,$00,$fe,$00,$00,$00,$ef,$00,$ef,$00,$ef,$00
        ds 16,0
        ; char 4 / slot 3 <- library $3A
        db $ff,$00,$55,$00,$aa,$00,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00
        ds 16,0
        ; char 5 / slot 4 <- library $15
        db $44,$00,$38,$00,$83,$00,$c6,$00,$44,$00,$6c,$00,$38,$00,$83,$00
        ds 16,0
        ; chars 6..8 / slots 5..7 <- library $00
        db $30,$00,$ff,$00,$03,$00,$ff,$00,$30,$00,$ff,$00,$03,$00,$ff,$00
        ds 16,0
        db $30,$00,$ff,$00,$03,$00,$ff,$00,$30,$00,$ff,$00,$03,$00,$ff,$00
        ds 16,0
        db $30,$00,$ff,$00,$03,$00,$ff,$00,$30,$00,$ff,$00,$03,$00,$ff,$00
        ds 16,0

room00_decor_patterns:
        incbin "room00-decor-patterns.dat"

; Compact BG palette allocation used by room_rle.py and room00_decor.py.
; Each palette is 1bpp-style: entry 0 black, entry 1 the C64 foreground colour.
; Slots 0..4 preserve the confirmed room-$00 colours. Slots 5..12 cover every
; additional C64 colour used by the complete room-$00 decor set.
room00_bg_palettes:
        ; 0 background black
        dw $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; 1 C64 brown $09
        dw $000,$090,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; 2 C64 red $02
        dw $000,$099,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; 3 C64 cyan $03
        dw $000,$15d,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; 4 C64 dark grey $0b
        dw $000,$092,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; 5 C64 medium grey $0c
        dw $000,$124,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; 6 C64 light grey $0f
        dw $000,$16d,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; 7 C64 white $01
        dw $000,$1ff,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; 8 C64 yellow $07
        dw $000,$0df,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; 9 C64 light green $0d
        dw $000,$06d,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; 10 C64 light red $0a
        dw $000,$0bb,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; 11 C64 orange $08
        dw $000,$0b0,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; 12 C64 green $05
        dw $000,$048,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
