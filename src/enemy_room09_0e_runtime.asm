; Exact original enemy setup for legacy Rooms $09/$0A/$0C/$0D/$0E.
; Reuses the shared four-slot movement/SAT/collision engine and the same sprite
; payload/palette layout used by the later room-table runtimes.

.bss
enemy_room09_0e_last_room: ds 1

.code

.proc enemy_room09_0e_room_sync
        lda <monty_room
        cmp enemy_room09_0e_last_room
        bne .changed
        leave
.changed:
        sta enemy_room09_0e_last_room
        cmp #$09
        beq .r09
        cmp #$0a
        beq .r0a
        cmp #$0c
        beq .r0c
        cmp #$0d
        beq .r0d
        cmp #$0e
        beq .r0e
        leave
.r09:
        lda #<enemy_room09_records
        sta <_bp
        lda #>enemy_room09_records
        bra .seed
.r0a:
        lda #<enemy_room0a_records
        sta <_bp
        lda #>enemy_room0a_records
        bra .seed
.r0c:
        lda #<enemy_room0c_records
        sta <_bp
        lda #>enemy_room0c_records
        bra .seed
.r0d:
        lda #<enemy_room0d_records
        sta <_bp
        lda #>enemy_room0d_records
        bra .seed
.r0e:
        lda #<enemy_room0e_records
        sta <_bp
        lda #>enemy_room0e_records
.seed:
        sta <_bp+1
        jsr .clear_slots
        jsr .decode_records
        jsr .upload_slots
        leave

.clear_slots:
        ldx #31
        lda #$ff
.clear_state:
        sta enemy_state_tbl,x
        dex
        bpl .clear_state
        ldx #3
        cla
.clear_aux:
        sta enemy_xmsb_tbl,x
        sta enemy_anim_timer_tbl,x
        sta enemy_palette_tbl,x
        dex
        bpl .clear_aux
        rts

.decode_records:
        stz enemy_tmp_slot
        stz enemy_tmp_state
        cly
.decode_next:
        lda [_bp],y
        cmp #$ff
        beq .decode_done
        sty enemy_tmp_record_y
        tax
        lda .colour_tbl,x
        sta enemy_tmp_color
        ldx enemy_tmp_state
        sta enemy_state_tbl+2,x
        ldy enemy_tmp_slot
        jsr .palette_for_colour
        sta enemy_palette_tbl,y
        ldy enemy_tmp_record_y
        iny
        lda [_bp],y
        lsr a
        clc
        adc #$1c
        ldx enemy_tmp_state
        sta enemy_state_tbl,x
        iny
        lda [_bp],y
        sta enemy_tmp_color
        lda #$f9
        sec
        sbc enemy_tmp_color
        sta enemy_state_tbl+1,x
        iny
        lda [_bp],y
        phy
        tay
        lda .dir_flags,y
        ldx enemy_tmp_state
        sta enemy_state_tbl+4,x
        ply
        iny
        lda [_bp],y
        sta enemy_state_tbl+3,x
        iny
        lda [_bp],y
        sta enemy_state_tbl+7,x
        iny
        lda [_bp],y
        sta enemy_state_tbl+5,x
        lda enemy_state_tbl+4,x
        bmi .reverse_start
        stz enemy_state_tbl+6,x
        bra .decoded_slot
.reverse_start:
        lda enemy_state_tbl+5,x
        sta enemy_state_tbl+6,x
.decoded_slot:
        iny
        inc enemy_tmp_slot
        lda enemy_tmp_state
        clc
        adc #8
        sta enemy_tmp_state
        lda enemy_tmp_slot
        cmp #4
        bne .decode_next
.decode_done:
        rts

.palette_for_colour:
        lda enemy_tmp_color
        cmp #$03
        bne .pc4
        lda #3
        rts
.pc4:
        cmp #$04
        bne .pc1
        lda #4
        rts
.pc1:
        cmp #$01
        bne .pc7
        lda #5
        rts
.pc7:
        cmp #$07
        bne .pc2
        lda #6
        rts
.pc2:
        cmp #$02
        bne .pc5
        lda #7
        rts
.pc5:
        cmp #$05
        bne .pce
        lda #8
        rts
.pce:
        cmp #$0e
        bne .pcd
        lda #9
        rts
.pcd:
        cmp #$0d
        bne .pcc
        lda #10
        rts
.pcc:
        cmp #$0c
        bne .pcf
        lda #11
        rts
.pcf:
        cmp #$0f
        bne .pca
        lda #12
        rts
.pca:
        cmp #$0a
        bne .pc8
        lda #13
        rts
.pc8:
        lda #14
        rts

.upload_slots:
        stz enemy_tmp_slot
        stz enemy_tmp_state
.upload_next:
        ldx enemy_tmp_state
        lda enemy_state_tbl,x
        cmp #$ff
        beq .upload_advance
        lda enemy_state_tbl+3,x
        sec
        sbc #$08
        tax
        lda .asset_lo,x
        sta <_bp
        lda .asset_hi,x
        sta <_bp+1
        ldy .asset_bank,x
        stz <_di
        lda enemy_tmp_slot
        asl a
        asl a
        asl a
        clc
        adc #$38
        sta <_di+1
        jsr .upload_4k
.upload_advance:
        inc enemy_tmp_slot
        lda enemy_tmp_state
        clc
        adc #8
        sta enemy_tmp_state
        lda enemy_tmp_slot
        cmp #4
        bne .upload_next
        rts

.upload_4k:
        php
        sei
        tma3
        pha
        tma4
        pha
        call map_bp_to_mpr34
        call vdc_di_to_mawr
        ldx #16
        cly
.upload_page:
        lda [_bp],y
        sta VDC_DL
        iny
        lda [_bp],y
        sta VDC_DH
        iny
        bne .upload_page
        inc <_bp+1
        dex
        bne .upload_page
        pla
        tam4
        pla
        tam3
        plp
        rts

.dir_flags:
        db $00,$82,$02,$81,$01
.colour_tbl:
        db $00,$06,$02,$04,$05,$03,$07,$01,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f

.asset_lo:
        db <enemy_type08_patterns,<enemy_type09_patterns,<enemy_type0a_patterns,<enemy_type0b_patterns
        db <enemy_type0c_patterns,<enemy_type0d_patterns,<enemy_type0e_patterns,<enemy_type0f_patterns
        db <enemy_type10_patterns,<enemy_type11_patterns,<enemy_type12_patterns,<enemy_type13_patterns
        db <enemy_type14_patterns,<enemy_type15_patterns,<enemy_type16_patterns,<enemy_type17_patterns
        db <enemy_type18_patterns,<enemy_type19_patterns,<enemy_type1a_patterns,<enemy_type1b_patterns
        db <enemy_type1c_patterns,<enemy_type1d_patterns,<enemy_type1e_patterns,<enemy_type1f_patterns
        db <enemy_type20_patterns,<enemy_type21_patterns,<enemy_type22_patterns
.asset_hi:
        db >enemy_type08_patterns,>enemy_type09_patterns,>enemy_type0a_patterns,>enemy_type0b_patterns
        db >enemy_type0c_patterns,>enemy_type0d_patterns,>enemy_type0e_patterns,>enemy_type0f_patterns
        db >enemy_type10_patterns,>enemy_type11_patterns,>enemy_type12_patterns,>enemy_type13_patterns
        db >enemy_type14_patterns,>enemy_type15_patterns,>enemy_type16_patterns,>enemy_type17_patterns
        db >enemy_type18_patterns,>enemy_type19_patterns,>enemy_type1a_patterns,>enemy_type1b_patterns
        db >enemy_type1c_patterns,>enemy_type1d_patterns,>enemy_type1e_patterns,>enemy_type1f_patterns
        db >enemy_type20_patterns,>enemy_type21_patterns,>enemy_type22_patterns
.asset_bank:
        db BANK(enemy_type08_patterns),BANK(enemy_type09_patterns),BANK(enemy_type0a_patterns),BANK(enemy_type0b_patterns)
        db BANK(enemy_type0c_patterns),BANK(enemy_type0d_patterns),BANK(enemy_type0e_patterns),BANK(enemy_type0f_patterns)
        db BANK(enemy_type10_patterns),BANK(enemy_type11_patterns),BANK(enemy_type12_patterns),BANK(enemy_type13_patterns)
        db BANK(enemy_type14_patterns),BANK(enemy_type15_patterns),BANK(enemy_type16_patterns),BANK(enemy_type17_patterns)
        db BANK(enemy_type18_patterns),BANK(enemy_type19_patterns),BANK(enemy_type1a_patterns),BANK(enemy_type1b_patterns)
        db BANK(enemy_type1c_patterns),BANK(enemy_type1d_patterns),BANK(enemy_type1e_patterns),BANK(enemy_type1f_patterns)
        db BANK(enemy_type20_patterns),BANK(enemy_type21_patterns),BANK(enemy_type22_patterns)

enemy_room09_records:
        db $07,$60,$97,$02,$12,$01,$78
        db $05,$50,$2f,$03,$16,$02,$23
        db $03,$60,$2b,$01,$08,$03,$23
        db $ff
enemy_room0a_records:
        db $05,$88,$9f,$04,$14,$01,$3f
        db $06,$d0,$5f,$01,$0f,$02,$2c
        db $04,$40,$9f,$04,$19,$03,$15
        db $07,$50,$5f,$03,$12,$02,$20
        db $ff
enemy_room0c_records:
        db $05,$70,$38,$03,$1b,$03,$17
        db $03,$50,$2c,$01,$08,$02,$23
        db $06,$e0,$57,$03,$1d,$01,$1f
        db $08,$80,$6f,$02,$1e,$02,$24
        db $ff
enemy_room0d_records:
        db $05,$20,$47,$03,$15,$01,$2f
        db $06,$88,$77,$04,$14,$02,$1b
        db $ff
enemy_room0e_records:
        db $06,$80,$27,$01,$1e,$04,$21
        db $0f,$b0,$8f,$01,$0a,$02,$3a
        db $04,$58,$77,$04,$1b,$02,$27
        db $ff
.endp
