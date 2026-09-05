; Safe static stage for the original C64 standard Piledriver.
; No RAM glyph buffers, no animation and no collision. This mirrors only
; RoomInit SeedGlyphs + DrawShaft so Room $01 geometry/art can be verified
; before enabling MoveDown/MoveUp.
;
; Original configs currently used:
;   room $01: col $07,row $05,height 4,char $10
;             col $1f,row $0c,height 6,char $22
;   room $02: col $15,row $05,height 4,char $10
;   room $0b: col $13,row $11,height 4,char $10
;
; SeedGlyphs writes the 8-byte frame only into the first character of each
; 48-byte left/middle/right column. The remaining five chars in each column are
; initially zero. Therefore static VRAM needs only tiles 0,6,12 populated.

PILE_STATIC_CHR0 = CHR_GAME + 64
PILE_STATIC_CHR1 = PILE_STATIC_CHR0 + 18
PILE_STATIC_PAL_LEFT  = 6
PILE_STATIC_PAL_MID   = 5
PILE_STATIC_PAL_RIGHT = 4

.zp
pile_static_col:      ds 1
pile_static_row:      ds 1
pile_static_height:   ds 1
pile_static_base_lo:  ds 1
pile_static_i:        ds 1
pile_static_tile:     ds 1
pile_static_seed_sel: ds 1
pile_static_tmp:      ds 1

.code

piledriver_static_init:
        call    piledriver_static_upload_set0
        jmp     piledriver_static_upload_set1

piledriver_static_room_sync:
        lda     <monty_room
        cmp     #$01
        beq     .room01
        cmp     #$02
        beq     .room02
        cmp     #$0b
        beq     .room0b
        rts
.room01:
        lda     #$07
        sta     <pile_static_col
        lda     #$05
        sta     <pile_static_row
        lda     #4
        sta     <pile_static_height
        lda     #<PILE_STATIC_CHR0
        sta     <pile_static_base_lo
        call    piledriver_static_draw

        lda     #$1f
        sta     <pile_static_col
        lda     #$0c
        sta     <pile_static_row
        lda     #6
        sta     <pile_static_height
        lda     #<PILE_STATIC_CHR1
        sta     <pile_static_base_lo
        jmp     piledriver_static_draw
.room02:
        lda     #$15
        sta     <pile_static_col
        lda     #$05
        sta     <pile_static_row
        lda     #4
        sta     <pile_static_height
        lda     #<PILE_STATIC_CHR0
        sta     <pile_static_base_lo
        jmp     piledriver_static_draw
.room0b:
        lda     #$13
        sta     <pile_static_col
        lda     #$11
        sta     <pile_static_row
        lda     #4
        sta     <pile_static_height
        lda     #<PILE_STATIC_CHR0
        sta     <pile_static_base_lo
        jmp     piledriver_static_draw

; Upload two identical 18-tile initial charset blocks. Each PCE tile is 16 VDC
; words. Plane 0 carries the C64 1bpp bitmap, all other planes are zero.
piledriver_static_upload_set0:
        lda     #<(PILE_STATIC_CHR0*16)
        sta     <_di
        lda     #>(PILE_STATIC_CHR0*16)
        sta     <_di+1
        bra     piledriver_static_upload_common
piledriver_static_upload_set1:
        lda     #<(PILE_STATIC_CHR1*16)
        sta     <_di
        lda     #>(PILE_STATIC_CHR1*16)
        sta     <_di+1
piledriver_static_upload_common:
        call    vdc_di_to_mawr
        stz     <pile_static_tile
.tile_loop:
        lda     <pile_static_tile
        cmp     #0
        beq     .left
        cmp     #6
        beq     .mid
        cmp     #12
        beq     .right
        lda     #$ff
        sta     <pile_static_seed_sel
        bra     .write
.left:
        stz     <pile_static_seed_sel
        bra     .write
.mid:
        lda     #1
        sta     <pile_static_seed_sel
        bra     .write
.right:
        lda     #2
        sta     <pile_static_seed_sel
.write:
        stz     <pile_static_i
.row:
        lda     <pile_static_seed_sel
        cmp     #$ff
        beq     .zero_row
        tax
        lda     <pile_static_i
        tay
        cpx     #0
        beq     .get_left
        cpx     #1
        beq     .get_mid
        lda     piledriver_static_seed_right,y
        bra     .put_row
.get_left:
        lda     piledriver_static_seed_left,y
        bra     .put_row
.get_mid:
        lda     piledriver_static_seed_mid,y
        bra     .put_row
.zero_row:
        cla
.put_row:
        sta     VDC_DL
        stz     VDC_DH
        inc     <pile_static_i
        lda     <pile_static_i
        cmp     #8
        bne     .row

        ldx     #8
.blank_planes:
        stz     VDC_DL
        stz     VDC_DH
        dex
        bne     .blank_planes

        inc     <pile_static_tile
        lda     <pile_static_tile
        cmp     #18
        bne     .tile_loop
        rts

; Fixed DrawShaft. Uses only ZP counters across VDC helper calls; no X/Y state is
; assumed to survive. BAT coordinate is the original absolute C64 screen col,row.
piledriver_static_draw:
        stz     <pile_static_i
.row_loop:
        lda     <pile_static_row
        clc
        adc     <pile_static_i
        tay
        lda     piledriver_static_bat_lo,y
        clc
        adc     <pile_static_col
        sta     <_di
        lda     piledriver_static_bat_hi,y
        adc     #0
        sta     <_di+1
        call    vdc_di_to_mawr

        ; left tile = base + row, palette 6. Tile ids are >$ff so bit 8 is set.
        lda     <pile_static_base_lo
        clc
        adc     <pile_static_i
        sta     VDC_DL
        lda     #$60+>((PILE_STATIC_CHR0)&$100)
        sta     VDC_DH

        ; middle tile = base + 6 + row, palette 5.
        lda     <pile_static_base_lo
        clc
        adc     #6
        adc     <pile_static_i
        sta     VDC_DL
        lda     #$50+>((PILE_STATIC_CHR0)&$100)
        sta     VDC_DH

        ; right tile = base + 12 + row, palette 4.
        lda     <pile_static_base_lo
        clc
        adc     #12
        adc     <pile_static_i
        sta     VDC_DL
        lda     #$40+>((PILE_STATIC_CHR0)&$100)
        sta     VDC_DH

        inc     <pile_static_i
        lda     <pile_static_i
        cmp     <pile_static_height
        bne     .row_loop
        rts

.data
piledriver_static_seed_left:
        db $0f,$0f,$00,$ff,$ff,$ff,$7f,$00
piledriver_static_seed_mid:
        db $ff,$ff,$00,$ff,$ff,$ff,$ff,$00
piledriver_static_seed_right:
        db $f0,$f0,$00,$ff,$ff,$ff,$fe,$00

piledriver_static_bat_lo:
        db $00,$40,$80,$c0,$00,$40,$80,$c0,$00,$40,$80,$c0,$00,$40,$80,$c0
        db $00,$40,$80,$c0,$00,$40,$80,$c0,$00,$40,$80,$c0
piledriver_static_bat_hi:
        db $00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$03
        db $04,$04,$04,$04,$05,$05,$05,$05,$06,$06,$06,$06
