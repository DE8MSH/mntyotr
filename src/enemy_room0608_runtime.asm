; Exact C64 Room $06 and $08 enemy activation.
; The generic four-slot movement/SAT engine is already correct; these two rooms
; only need their original SetupRoom state and the three newly converted enemy
; assets (Rubik $11, Pi/Pie $13, Tank $1C) uploaded to the slot VRAM blocks.
;
; Source records are copied from the byte-identical C64 reconstruction.

.code
.proc enemy_room0608_room_sync
        lda     <monty_room
        cmp     #$06
        beq     .room06
        cmp     #$08
        beq     .room08
        leave

.room06:
        ; enemy_smiley_room_sync clears unsupported legacy slots once on entry.
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
.done:
        leave

; Upload each active slot's authentic eight-frame PCE payload to the same four
; private VRAM ranges used by the generic Room00-07 renderer.
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
        bne     .type1c
        lda     #<enemy_type19_patterns
        sta     <_bp
        lda     #>enemy_type19_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type19_patterns)
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
; SetupRoom: X=(x_grid>>1)+$1c, Y=$f9-y_grid, flags 00/82/02/81/01.
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
.endp
