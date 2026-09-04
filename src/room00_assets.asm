; Converted C64 room-$00 graphics assets.
; C64 screen code 0 is blank; room tile slots 0..7 are installed as character
; codes 1..8 exactly like Room.SetupTileGraphics in the refactored source.
; Each C64 1bpp character becomes one PCE 4bpp tile using pixel indices 0/1.

.code
upload_room00_patterns:
        lda #<(CHR_GAME*16)
        sta <_di+0
        lda #>(CHR_GAME*16)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_patterns,VDC_DL,288
        rts

.data
room00_patterns:
        ; C64 character code 0: blank (SetupTileGraphics leaves it untouched).
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

; BAT palette number follows the C64 screen character code. Code 0 is blank;
; code N (1..8) uses room_colour_tbl[N-1], matching PopulateColourRam.
room00_palettes:
        ; code 0: blank/background
        dw $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; code 1: C64 brown $9 -> VCE $090
        dw $000,$090,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; code 2: brown $9
        dw $000,$090,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; code 3: red $2 -> $099
        dw $000,$099,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; code 4: cyan $3 -> $15D
        dw $000,$15d,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; code 5: dark grey $B -> $092
        dw $000,$092,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; codes 6..8: black for room $00
        dw $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        dw $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        dw $000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
