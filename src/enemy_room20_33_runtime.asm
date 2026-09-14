; Exact original enemy setup for Rooms $20-$33.
; Reuses the shared four-slot movement/SAT/collision runtime and palettes.
; Flying-banner types $20-$22 in Room $23 are ambient; the build-time collision
; selector explicitly excludes those three types from Monty damage.

.bss
enemy_room20_33_last_room: ds 1

.code

.proc enemy_room20_33_room_sync
        lda <monty_room
        cmp #$20
        bcc .outside
        cmp #$34
        bcs .outside
        cmp enemy_room20_33_last_room
        bne .changed
        leave
.outside:
        lda #$ff
        sta enemy_room20_33_last_room
        leave
.changed:
        sta enemy_room20_33_last_room
        jsr .clear_slots
        lda <monty_room
        sec
        sbc #$20
        tax
        lda .room_ptr_lo,x
        sta <_bp
        lda .room_ptr_hi,x
        sta <_bp+1
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

.room_ptr_lo:
        db <enemy_room20_records,<enemy_room21_records,<enemy_room22_records,<enemy_room23_records
        db <enemy_room24_records,<enemy_room25_records,<enemy_room26_records,<enemy_room27_records
        db <enemy_room28_records,<enemy_room29_records,<enemy_room2a_records,<enemy_room2b_records
        db <enemy_room2c_records,<enemy_room2d_records,<enemy_room2e_records,<enemy_room2f_records
        db <enemy_room30_records,<enemy_room31_records,<enemy_room32_records,<enemy_room33_records
.room_ptr_hi:
        db >enemy_room20_records,>enemy_room21_records,>enemy_room22_records,>enemy_room23_records
        db >enemy_room24_records,>enemy_room25_records,>enemy_room26_records,>enemy_room27_records
        db >enemy_room28_records,>enemy_room29_records,>enemy_room2a_records,>enemy_room2b_records
        db >enemy_room2c_records,>enemy_room2d_records,>enemy_room2e_records,>enemy_room2f_records
        db >enemy_room30_records,>enemy_room31_records,>enemy_room32_records,>enemy_room33_records

; Indexed by type_id-$08. Type $1E (Medusa) has no spawn in $20-$33; its
; otherwise-unused table slot aliases Jelly Fish so every index remains valid.
.asset_lo:
        db <enemy_type08_patterns,<enemy_type09_patterns,<enemy_type0a_patterns,<enemy_type0b_patterns
        db <enemy_type0c_patterns,<enemy_type0d_patterns,<enemy_type0e_patterns,<enemy_type0f_patterns
        db <enemy_type10_patterns,<enemy_type11_patterns,<enemy_type12_patterns,<enemy_type13_patterns
        db <enemy_type14_patterns,<enemy_type15_patterns,<enemy_type16_patterns,<enemy_type17_patterns
        db <enemy_type18_patterns,<enemy_type19_patterns,<enemy_type1a_patterns,<enemy_type1b_patterns
        db <enemy_type1c_patterns,<enemy_type1d_patterns,<enemy_type1d_patterns,<enemy_type1f_patterns
        db <enemy_type20_patterns,<enemy_type21_patterns,<enemy_type22_patterns
.asset_hi:
        db >enemy_type08_patterns,>enemy_type09_patterns,>enemy_type0a_patterns,>enemy_type0b_patterns
        db >enemy_type0c_patterns,>enemy_type0d_patterns,>enemy_type0e_patterns,>enemy_type0f_patterns
        db >enemy_type10_patterns,>enemy_type11_patterns,>enemy_type12_patterns,>enemy_type13_patterns
        db >enemy_type14_patterns,>enemy_type15_patterns,>enemy_type16_patterns,>enemy_type17_patterns
        db >enemy_type18_patterns,>enemy_type19_patterns,>enemy_type1a_patterns,>enemy_type1b_patterns
        db >enemy_type1c_patterns,>enemy_type1d_patterns,>enemy_type1d_patterns,>enemy_type1f_patterns
        db >enemy_type20_patterns,>enemy_type21_patterns,>enemy_type22_patterns
.asset_bank:
        db BANK(enemy_type08_patterns),BANK(enemy_type09_patterns),BANK(enemy_type0a_patterns),BANK(enemy_type0b_patterns)
        db BANK(enemy_type0c_patterns),BANK(enemy_type0d_patterns),BANK(enemy_type0e_patterns),BANK(enemy_type0f_patterns)
        db BANK(enemy_type10_patterns),BANK(enemy_type11_patterns),BANK(enemy_type12_patterns),BANK(enemy_type13_patterns)
        db BANK(enemy_type14_patterns),BANK(enemy_type15_patterns),BANK(enemy_type16_patterns),BANK(enemy_type17_patterns)
        db BANK(enemy_type18_patterns),BANK(enemy_type19_patterns),BANK(enemy_type1a_patterns),BANK(enemy_type1b_patterns)
        db BANK(enemy_type1c_patterns),BANK(enemy_type1d_patterns),BANK(enemy_type1d_patterns),BANK(enemy_type1f_patterns)
        db BANK(enemy_type20_patterns),BANK(enemy_type21_patterns),BANK(enemy_type22_patterns)

enemy_room20_records:
        db $06,$70,$3f,$04,$14,$01,$22
        db $05,$e8,$57,$01,$0a,$03,$30
        db $04,$40,$4f,$03,$0b,$02,$21
        db $07,$80,$67,$03,$18,$01,$1f
        db $ff
enemy_room21_records:
        db $03,$60,$5f,$03,$0e,$02,$1f
        db $06,$50,$af,$01,$15,$01,$37
        db $05,$10,$5f,$02,$15,$02,$2f
        db $0c,$18,$8f,$03,$13,$02,$2f
        db $ff
enemy_room22_records:
        db $07,$50,$3f,$03,$14,$01,$17
        db $05,$80,$5f,$02,$0f,$01,$1f
        db $03,$90,$5f,$03,$0e,$03,$2f
        db $ff
enemy_room23_records:
        db $0e,$00,$80,$02,$20,$01,$d0
        db $0e,$10,$80,$02,$21,$01,$d0
        db $0e,$20,$80,$02,$22,$01,$d0
        db $06,$28,$27,$02,$09,$02,$0f
        db $ff
enemy_room24_records:
        db $05,$40,$7f,$03,$0d,$01,$20
        db $03,$90,$af,$04,$13,$02,$18
        db $ff
enemy_room25_records:
        db $05,$50,$87,$03,$0e,$01,$18
        db $04,$70,$7f,$03,$13,$02,$13
        db $ff
enemy_room26_records:
        db $07,$88,$27,$03,$1b,$03,$21
        db $06,$98,$27,$03,$13,$01,$17
        db $05,$58,$47,$03,$19,$02,$17
        db $04,$40,$47,$03,$0b,$01,$1f
        db $ff
enemy_room27_records:
        db $0e,$78,$8f,$04,$1d,$04,$25
        db $07,$28,$47,$03,$13,$02,$0f
        db $06,$d8,$87,$04,$19,$02,$1f
        db $ff
enemy_room28_records:
        db $01,$c0,$87,$04,$1b,$02,$1b
        db $0d,$18,$a7,$04,$0e,$02,$1f
        db $08,$08,$97,$04,$16,$01,$2f
        db $04,$40,$6f,$02,$12,$02,$1b
        db $ff
enemy_room29_records:
        db $07,$28,$47,$03,$14,$01,$3f
        db $ff
enemy_room2a_records:
        db $07,$f0,$a7,$04,$0b,$02,$2f
        db $04,$20,$4f,$03,$19,$02,$1f
        db $ff
enemy_room2b_records:
        db $07,$d8,$4f,$03,$1b,$03,$15
        db $08,$88,$9f,$02,$0a,$02,$1f
        db $ff
enemy_room2c_records:
        db $06,$48,$47,$03,$15,$03,$1f
        db $07,$38,$5f,$04,$15,$01,$17
        db $05,$d0,$47,$03,$1d,$02,$17
        db $ff
enemy_room2d_records:
        db $07,$e7,$97,$00,$0c,$01,$01
        db $06,$98,$47,$03,$1d,$02,$17
        db $05,$08,$47,$02,$1c,$02,$37
        db $ff
enemy_room2e_records:
        db $05,$58,$67,$04,$19,$02,$2f
        db $07,$88,$5f,$02,$19,$01,$3f
        db $06,$00,$87,$02,$10,$01,$19
        db $02,$90,$77,$00,$1d,$01,$01
        db $ff
enemy_room2f_records:
        db $08,$70,$7f,$02,$1c,$01,$27
        db $07,$a0,$27,$02,$1c,$02,$17
        db $03,$90,$67,$04,$09,$02,$1f
        db $07,$60,$5f,$00,$0d,$01,$01
        db $ff
enemy_room30_records:
        db $06,$00,$24,$02,$1f,$01,$ff
        db $ff
enemy_room31_records:
        db $06,$40,$7f,$03,$12,$01,$28
        db $ff
enemy_room32_records:
        db $02,$00,$a3,$04,$15,$02,$13
        db $ff
enemy_room33_records:
        db $0e,$a8,$af,$04,$1b,$02,$18
        db $05,$00,$7f,$03,$14,$01,$30
        db $ff
.endp
