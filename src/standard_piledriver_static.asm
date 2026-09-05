; Safe original-style C64 standard Piledriver for rooms $01/$02/$0B.
;
; The C64 mechanism is NOT a sprite. DrawShaft installs a 3-char-wide shaft and
; MoveDown/MoveUp shifts the 8-byte head bitmap through three 48-byte charset
; columns. This implementation preserves that visible/state behaviour but avoids
; mutable 144-byte pointer walks: each animation tick regenerates the selected
; 18-tile PCE charset directly from the exact C64 state.
;
; IMPORTANT original MoveDown detail: it copies byte N to N+1 but never clears
; byte 0. Therefore the first bitmap row is replicated above the descending head,
; producing the visible piledriver body. The previous PCE formula incorrectly
; zeroed that region and showed only the moving head.
;
; Original configs:
;   room $01: col $07,row $05,height 4,char $10
;             col $1f,row $0c,height 6,char $22
;   room $02: col $15,row $05,height 4,char $10
;   room $0b: col $13,row $11,height 4,char $10
;
; Room $02 decor occupies CHR_GAME+9..+65. Keep both dynamic piledriver charsets
; above all currently generated decor so animation can never overwrite a pot/
; flower/decor tile.
PILE_STATIC_CHR0 = CHR_GAME + 96
PILE_STATIC_CHR1 = PILE_STATIC_CHR0 + 18

.zp
pile_static_last_room: ds 1
pile_static_count:     ds 1
pile_static_state:     ds 1          ; 0 idle, 1 down, 2 up
pile_static_delay:     ds 1
pile_static_index:     ds 1          ; $ff idle, 0/1 selected
pile_static_position:  ds 1          ; original position, starts at 5
pile_static_shift:     ds 1          ; position-5, exact bitmap displacement
pile_static_limit0:    ds 1
pile_static_limit1:    ds 1
pile_static_col:       ds 1
pile_static_row:       ds 1
pile_static_height:    ds 1
pile_static_base_lo:   ds 1
pile_static_i:         ds 1
pile_static_tile:      ds 1
pile_static_seed_sel:  ds 1
pile_static_global:    ds 1

.code

piledriver_static_init:
        lda     #$ff
        sta     <pile_static_last_room
        sta     <pile_static_index
        stz     <pile_static_count
        stz     <pile_static_state
        stz     <pile_static_shift
        lda     #1
        sta     <pile_static_delay
        call    piledriver_static_upload_set0
        jmp     piledriver_static_upload_set1

piledriver_static_room_sync:
        lda     <monty_room
        cmp     <pile_static_last_room
        bne     .changed
        rts
.changed:
        sta     <pile_static_last_room
        stz     <pile_static_count
        stz     <pile_static_state
        stz     <pile_static_shift
        lda     #$ff
        sta     <pile_static_index
        lda     #1
        sta     <pile_static_delay
        call    piledriver_static_upload_set0
        call    piledriver_static_upload_set1

        lda     <monty_room
        cmp     #$01
        beq     .room01
        cmp     #$02
        beq     .room02
        cmp     #$0b
        beq     .room0b
        rts
.room01:
        lda     #2
        sta     <pile_static_count
        lda     #$1f
        sta     <pile_static_limit0
        lda     #$2f
        sta     <pile_static_limit1

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
        lda     #1
        sta     <pile_static_count
        lda     #$1f
        sta     <pile_static_limit0
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
        lda     #1
        sta     <pile_static_count
        lda     #$1f
        sta     <pile_static_limit0
        lda     #$13
        sta     <pile_static_col
        lda     #$11
        sta     <pile_static_row
        lda     #4
        sta     <pile_static_height
        lda     #<PILE_STATIC_CHR0
        sta     <pile_static_base_lo
        jmp     piledriver_static_draw

; Exact source state sequence, with game_tick_counter supplying the original
; random $14..$53 delay range and the choice between two Room-$01 drivers.
; Collision is deliberately not enabled yet; this stage proves animation only.
piledriver_static_update:
        lda     <pile_static_count
        bne     .active_room
        rts
.active_room:
        lda     <pile_static_state
        bne     .moving

        dec     <pile_static_delay
        beq     .activate
        rts
.activate:
        lda     game_tick_counter
        and     #$3f
        clc
        adc     #$14
        sta     <pile_static_delay
        ldx     #0
        lda     <pile_static_count
        cmp     #2
        bne     .picked
        lda     game_tick_counter
        and     #1
        tax
.picked:
        stx     <pile_static_index
        lda     #1
        sta     <pile_static_state
        lda     #5
        sta     <pile_static_position
        stz     <pile_static_shift
        jmp     piledriver_static_upload_selected

.moving:
        cmp     #2
        beq     .move_up

        inc     <pile_static_position
        inc     <pile_static_position
        ldx     <pile_static_index
        lda     <pile_static_position
        cpx     #0
        bne     .limit1
        cmp     <pile_static_limit0
        bra     .limit_cmp
.limit1:
        cmp     <pile_static_limit1
.limit_cmp:
        bcc     .down_shift
        lda     #2
        sta     <pile_static_state
        rts
.down_shift:
        lda     <pile_static_position
        sec
        sbc     #5
        sta     <pile_static_shift
        jmp     piledriver_static_upload_selected

.move_up:
        dec     <pile_static_position
        dec     <pile_static_position
        lda     <pile_static_position
        cmp     #6
        bcs     .up_shift
        stz     <pile_static_state
        stz     <pile_static_shift
        lda     #$ff
        sta     <pile_static_index
        ; Restore exact SeedGlyphs state after the cycle.
        jmp     piledriver_static_upload_selected
.up_shift:
        sec
        sbc     #5
        sta     <pile_static_shift
        jmp     piledriver_static_upload_selected

piledriver_static_upload_selected:
        lda     <pile_static_index
        beq     piledriver_static_upload_set0
        cmp     #1
        beq     piledriver_static_upload_set1
        ; index=$ff at end of cycle: no selected buffer remains to upload.
        rts

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

; Generate 18 chars = left[6], middle[6], right[6]. Original MoveDown leaves
; byte0 untouched while shifting everything else down. Thus for global offsets
; <= shift the rendered byte is seed[0]; offsets shift+1..shift+7 use the rest
; of the seed. This is the missing visible body from the previous PCE pass.
piledriver_static_upload_common:
        call    vdc_di_to_mawr
        stz     <pile_static_tile
.tile_loop:
        lda     <pile_static_tile
        cmp     #6
        bcc     .left
        cmp     #12
        bcc     .mid
        lda     #2
        sta     <pile_static_seed_sel
        lda     <pile_static_tile
        sec
        sbc     #12
        bra     .tile_in_col
.left:
        stz     <pile_static_seed_sel
        lda     <pile_static_tile
        bra     .tile_in_col
.mid:
        lda     #1
        sta     <pile_static_seed_sel
        lda     <pile_static_tile
        sec
        sbc     #6
.tile_in_col:
        asl     a
        asl     a
        asl     a
        sta     <pile_static_global
        stz     <pile_static_i
.row:
        lda     <pile_static_global
        clc
        adc     <pile_static_i
        cmp     <pile_static_shift
        bcc     .body_row
        beq     .body_row
        sec
        sbc     <pile_static_shift
        cmp     #8
        bcs     .zero_row
        tay
        bra     .seed_row
.body_row:
        cly                             ; seed row 0 is replicated by MoveDown
.seed_row:
        lda     <pile_static_seed_sel
        beq     .get_left
        cmp     #1
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

        lda     <pile_static_base_lo
        clc
        adc     <pile_static_i
        sta     VDC_DL
        lda     #$61                    ; C64 light grey $0f
        sta     VDC_DH

        lda     <pile_static_base_lo
        clc
        adc     #6
        adc     <pile_static_i
        sta     VDC_DL
        lda     #$51                    ; C64 medium grey $0c
        sta     VDC_DH

        lda     <pile_static_base_lo
        clc
        adc     #12
        adc     <pile_static_i
        sta     VDC_DL
        lda     #$41                    ; C64 dark grey $0b
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
