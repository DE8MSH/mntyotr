; Exact C64 enemy activation for Rooms $06, $08 and $0F.
; The generic four-slot movement/SAT/collision engine is reused; this shim seeds
; exact SetupRoom state and uploads the authentic already-converted sprite sets.

.code
.proc enemy_room0f_palette_init
        ; Room $0F introduces C64 colour $0A (light red). Sprite palette 26 maps
        ; to SAT palette index 10 and uses the same unified C64->PCE quantization.
        lda     #26
        sta     <_al
        lda     #1
        sta     <_ah
        lda     #<enemy_palette_light_red
        sta     <_bp
        lda     #>enemy_palette_light_red
        sta     <_bp+1
        ldy     #BANK(enemy_palette_light_red)
        call    load_palettes
        call    xfer_palettes
        leave
.endp

.proc enemy_room0608_room_sync
        lda     <monty_room
        cmp     #$06
        beq     .room06
        cmp     #$08
        beq     .room08
        cmp     #$0f
        beq     .room0f
        leave

.room06:
        lda     enemy_state_tbl
        cmp     #$ff
        bne     .done
        ldx     #31
.copy06:
        lda     .room06_state,x
        sta     enemy_state_tbl,x
        dex
        bpl     .copy06
        ldx     #3
.pal06:
        stz     enemy_xmsb_tbl,x
        stz     enemy_anim_timer_tbl,x
        lda     .room06_palettes,x
        sta     enemy_palette_tbl,x
        dex
        bpl     .pal06
        jsr     .upload_slots
        leave

.room08:
        lda     enemy_state_tbl
        cmp     #$ff
        bne     .done
        ldx     #31
.copy08:
        lda     .room08_state,x
        sta     enemy_state_tbl,x
        dex
        bpl     .copy08
        ldx     #3
.pal08:
        stz     enemy_xmsb_tbl,x
        stz     enemy_anim_timer_tbl,x
        lda     .room08_palettes,x
        sta     enemy_palette_tbl,x
        dex
        bpl     .pal08
        jsr     .upload_slots
        leave

.room0f:
        lda     enemy_state_tbl
        cmp     #$ff
        bne     .done
        ldx     #31
.copy0f:
        lda     .room0f_state,x
        sta     enemy_state_tbl,x
        dex
        bpl     .copy0f
        ldx     #3
.pal0f:
        stz     enemy_xmsb_tbl,x
        stz     enemy_anim_timer_tbl,x
        lda     .room0f_palettes,x
        sta     enemy_palette_tbl,x
        dex
        bpl     .pal0f
        jsr     .upload_slots
.done:
        leave

.upload_slots:
        php
        sei
        tma3
        pha
        tma4
        pha

        stz     enemy_tmp_slot
        stz     enemy_tmp_state
.upload_next:
        ldx     enemy_tmp_state
        lda     enemy_state_tbl,x
        cmp     #$ff
        beq     .upload_advance
        jsr     .select_asset
        call    map_bp_to_mpr34

        stz     <_di
        lda     enemy_tmp_slot
        asl     a
        asl     a
        asl     a
        clc
        adc     #$38
        sta     <_di+1
        call    vdc_di_to_mawr

        ldx     #16
        cly
.upload_page:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        bne     .upload_page
        inc     <_bp+1
        dex
        bne     .upload_page

.upload_advance:
        inc     enemy_tmp_slot
        lda     enemy_tmp_state
        clc
        adc     #8
        sta     enemy_tmp_state
        lda     enemy_tmp_slot
        cmp     #4
        bne     .upload_next

        pla
        tam4
        pla
        tam3
        plp
        rts

.select_asset:
        ldx     enemy_tmp_state
        lda     enemy_state_tbl+3,x
        cmp     #$0a
        bne     .not0a
        lda     #<enemy_type0a_patterns
        sta     <_bp
        lda     #>enemy_type0a_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type0a_patterns)
        rts
.not0a:
        cmp     #$0f
        bne     .not0f
        lda     #<enemy_type0f_patterns
        sta     <_bp
        lda     #>enemy_type0f_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type0f_patterns)
        rts
.not0f:
        cmp     #$11
        bne     .not11
        lda     #<enemy_type11_patterns
        sta     <_bp
        lda     #>enemy_type11_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type11_patterns)
        rts
.not11:
        cmp     #$13
        bne     .not13
        lda     #<enemy_type13_patterns
        sta     <_bp
        lda     #>enemy_type13_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type13_patterns)
        rts
.not13:
        cmp     #$15
        bne     .not15
        lda     #<enemy_type15_patterns
        sta     <_bp
        lda     #>enemy_type15_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type15_patterns)
        rts
.not15:
        cmp     #$19
        bne     .not19
        lda     #<enemy_type19_patterns
        sta     <_bp
        lda     #>enemy_type19_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type19_patterns)
        rts
.not19:
        cmp     #$1b
        bne     .type1c
        lda     #<enemy_type1b_patterns
        sta     <_bp
        lda     #>enemy_type1b_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type1b_patterns)
        rts
.type1c:
        lda     #<enemy_type1c_patterns
        sta     <_bp
        lda     #>enemy_type1c_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type1c_patterns)
        rts

; Room $06 source records:
;   $06,$48,$2f,$02,$1c,$04,$10  Tank
;   $05,$70,$9f,$04,$19,$03,$26  Smiley
;   $07,$e8,$a7,$04,$11,$01,$27  Rubik
.room06_state:
        db $40,$ca,$07,$1c,$02,$10,$00,$04
        db $54,$5a,$03,$19,$01,$26,$00,$03
        db $90,$52,$01,$11,$01,$27,$00,$01
        db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
.room06_palettes:
        db $06,$03,$05,$00

; Room $08 source records:
;   $06,$58,$2f,$02,$0a,$02,$27  Lamp
;   $05,$a8,$2f,$03,$13,$02,$27  Pi/Pie (reverse vertical)
;   $07,$30,$8f,$04,$13,$03,$1d  Pi/Pie
;   $05,$a8,$9f,$01,$15,$02,$80  Bubble (reverse horizontal)
.room08_state:
        db $48,$ca,$07,$0a,$02,$27,$00,$02
        db $70,$ca,$03,$13,$81,$27,$27,$02
        db $34,$6a,$01,$13,$01,$1d,$00,$03
        db $70,$5a,$03,$15,$82,$80,$80,$02
.room08_palettes:
        db $06,$03,$05,$03

; Room $0F source records:
;   $06,$98,$2f,$03,$15,$03,$17  Bubble, reverse vertical
;   $05,$d0,$77,$04,$1b,$02,$23  Hand
;   $0a,$c8,$2f,$01,$0f,$02,$47  Big Nose, reverse horizontal, light red
;   $0e,$08,$97,$02,$0f,$01,$9c  Big Nose
.room0f_state:
        db $68,$ca,$07,$15,$81,$17,$17,$03
        db $84,$82,$03,$1b,$01,$23,$00,$02
        db $80,$ca,$0a,$0f,$82,$47,$47,$02
        db $20,$62,$0e,$0f,$02,$9c,$00,$01
.room0f_palettes:
        db $06,$03,$0a,$09
.endp

.data
enemy_palette_light_red:             ; C64 $0A -> $0eb
        dw $000,$0eb,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
