; Exact original enemy setup for Rooms $10-$1F.
; Reuses the shared four-slot movement/SAT/collision runtime.

.bss
enemy_room10_1f_last_room: ds 1

.code

.proc enemy_room10_1f_palette_init
        lda #26
        sta <_al
        lda #1
        sta <_ah
        lda #<enemy_palette_light_green
        sta <_bp
        lda #>enemy_palette_light_green
        sta <_bp+1
        ldy #BANK(enemy_palette_light_green)
        call load_palettes
        lda #27
        sta <_al
        lda #1
        sta <_ah
        lda #<enemy_palette_medium_grey
        sta <_bp
        lda #>enemy_palette_medium_grey
        sta <_bp+1
        ldy #BANK(enemy_palette_medium_grey)
        call load_palettes
        lda #28
        sta <_al
        lda #1
        sta <_ah
        lda #<enemy_palette_light_grey
        sta <_bp
        lda #>enemy_palette_light_grey
        sta <_bp+1
        ldy #BANK(enemy_palette_light_grey)
        call load_palettes
        lda #29
        sta <_al
        lda #1
        sta <_ah
        lda #<enemy_palette_light_red
        sta <_bp
        lda #>enemy_palette_light_red
        sta <_bp+1
        ldy #BANK(enemy_palette_light_red)
        call load_palettes
        lda #30
        sta <_al
        lda #1
        sta <_ah
        lda #<enemy_palette_orange
        sta <_bp
        lda #>enemy_palette_orange
        sta <_bp+1
        ldy #BANK(enemy_palette_orange)
        call load_palettes
        call xfer_palettes
        lda #$ff
        sta enemy_room10_1f_last_room
        leave
.endp

.proc enemy_room10_1f_room_sync
        lda <monty_room
        cmp #$10
        bcc .outside
        cmp #$20
        bcs .outside
        cmp enemy_room10_1f_last_room
        bne .changed
        leave
.outside:
        lda #$ff
        sta enemy_room10_1f_last_room
        leave
.changed:
        sta enemy_room10_1f_last_room
        jsr .clear_slots
        lda <monty_room
        sec
        sbc #$10
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
        beq .decode_done
        jmp .decode_next
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
        db <enemy_room10_records,<enemy_room11_records,<enemy_room12_records,<enemy_room13_records,<enemy_room14_records,<enemy_room15_records,<enemy_room16_records,<enemy_room17_records,<enemy_room18_records,<enemy_room19_records,<enemy_room1a_records,<enemy_room1b_records,<enemy_room1c_records,<enemy_room1d_records,<enemy_room1e_records,<enemy_room1f_records
.room_ptr_hi:
        db >enemy_room10_records,>enemy_room11_records,>enemy_room12_records,>enemy_room13_records,>enemy_room14_records,>enemy_room15_records,>enemy_room16_records,>enemy_room17_records,>enemy_room18_records,>enemy_room19_records,>enemy_room1a_records,>enemy_room1b_records,>enemy_room1c_records,>enemy_room1d_records,>enemy_room1e_records,>enemy_room1f_records

.asset_lo:
        db <enemy_type08_patterns,<enemy_type09_patterns,<enemy_type0a_patterns,<enemy_type0b_patterns,<enemy_type0c_patterns,<enemy_type0c_patterns,<enemy_type0e_patterns,<enemy_type0f_patterns,<enemy_type10_patterns,<enemy_type11_patterns,<enemy_type12_patterns,<enemy_type13_patterns,<enemy_type14_patterns,<enemy_type15_patterns,<enemy_type16_patterns,<enemy_type17_patterns,<enemy_type18_patterns,<enemy_type19_patterns,<enemy_type1a_patterns,<enemy_type1b_patterns,<enemy_type1c_patterns,<enemy_type1d_patterns
.asset_hi:
        db >enemy_type08_patterns,>enemy_type09_patterns,>enemy_type0a_patterns,>enemy_type0b_patterns,>enemy_type0c_patterns,>enemy_type0c_patterns,>enemy_type0e_patterns,>enemy_type0f_patterns,>enemy_type10_patterns,>enemy_type11_patterns,>enemy_type12_patterns,>enemy_type13_patterns,>enemy_type14_patterns,>enemy_type15_patterns,>enemy_type16_patterns,>enemy_type17_patterns,>enemy_type18_patterns,>enemy_type19_patterns,>enemy_type1a_patterns,>enemy_type1b_patterns,>enemy_type1c_patterns,>enemy_type1d_patterns
.asset_bank:
        db BANK(enemy_type08_patterns),BANK(enemy_type09_patterns),BANK(enemy_type0a_patterns),BANK(enemy_type0b_patterns),BANK(enemy_type0c_patterns),BANK(enemy_type0c_patterns),BANK(enemy_type0e_patterns),BANK(enemy_type0f_patterns),BANK(enemy_type10_patterns),BANK(enemy_type11_patterns),BANK(enemy_type12_patterns),BANK(enemy_type13_patterns),BANK(enemy_type14_patterns),BANK(enemy_type15_patterns),BANK(enemy_type16_patterns),BANK(enemy_type17_patterns),BANK(enemy_type18_patterns),BANK(enemy_type19_patterns),BANK(enemy_type1a_patterns),BANK(enemy_type1b_patterns),BANK(enemy_type1c_patterns),BANK(enemy_type1d_patterns)

enemy_room10_records:
        db $0d,$d8,$37,$03,$19,$02,$1e
        db $05,$48,$67,$01,$18,$01,$26
        db $06,$28,$2f,$02,$18,$02,$4f
        db $ff
enemy_room11_records:
        db $0c,$78,$6f,$03,$15,$02,$1b
        db $06,$a8,$8e,$01,$13,$02,$4e
        db $07,$30,$37,$03,$1b,$01,$27
        db $05,$c0,$2f,$01,$1d,$01,$27
        db $ff
enemy_room12_records:
        db $05,$f2,$57,$04,$09,$01,$27
        db $0f,$60,$9f,$01,$15,$01,$3f
        db $ff
enemy_room13_records:
        db $06,$00,$67,$04,$1a,$02,$1d
        db $03,$60,$2f,$01,$0f,$02,$27
        db $07,$90,$7f,$03,$0b,$01,$1f
        db $ff
enemy_room14_records:
        db $0a,$08,$97,$04,$0b,$05,$14
        db $06,$90,$97,$04,$1d,$02,$33
        db $08,$80,$2f,$03,$11,$03,$22
        db $ff
enemy_room15_records:
        db $06,$40,$67,$02,$0a,$01,$1d
        db $05,$70,$77,$04,$15,$01,$1f
        db $04,$58,$2f,$02,$15,$02,$21
        db $0d,$30,$2f,$03,$15,$04,$14
        db $ff
enemy_room16_records:
        db $0e,$40,$2f,$01,$0f,$02,$1f
        db $0e,$a0,$2f,$02,$0f,$02,$1f
        db $07,$b8,$87,$01,$10,$02,$1f
        db $06,$a0,$5f,$02,$1c,$02,$2f
        db $ff
enemy_room17_records:
        db $07,$80,$37,$03,$19,$03,$12
        db $03,$90,$34,$01,$08,$02,$2b
        db $05,$10,$8f,$04,$15,$02,$1f
        db $0c,$d8,$6f,$04,$09,$04,$0e
        db $ff
enemy_room18_records:
        db $06,$70,$a7,$04,$12,$03,$2d
        db $05,$a0,$a7,$01,$12,$02,$3f
        db $07,$e0,$5f,$01,$09,$03,$41
        db $03,$c0,$27,$01,$1d,$02,$37
        db $ff
enemy_room19_records:
        db $06,$88,$6f,$02,$1c,$02,$24
        db $03,$70,$47,$03,$19,$02,$1f
        db $07,$38,$4f,$03,$0c,$03,$12
        db $06,$70,$9f,$00,$14,$01,$01
        db $ff
enemy_room1a_records:
        db $03,$50,$6f,$04,$1b,$03,$24
        db $07,$68,$6c,$02,$08,$01,$27
        db $06,$c8,$5f,$03,$19,$02,$1f
        db $0d,$d8,$9f,$04,$0b,$03,$16
        db $ff
enemy_room1b_records:
        db $07,$60,$2f,$02,$18,$04,$1e
        db $05,$70,$2f,$03,$15,$02,$27
        db $06,$98,$4f,$03,$16,$01,$2f
        db $03,$08,$57,$02,$0e,$01,$47
        db $ff
enemy_room1c_records:
        db $05,$98,$a7,$01,$0a,$06,$0e
        db $04,$c0,$4f,$03,$0c,$02,$1f
        db $02,$60,$47,$03,$16,$01,$27
        db $ff
enemy_room1d_records:
        db $02,$c0,$27,$01,$0f,$02,$2a
        db $06,$40,$97,$02,$0a,$02,$43
        db $05,$d0,$6f,$04,$15,$02,$19
        db $ff
enemy_room1e_records:
        db $03,$60,$67,$02,$0e,$01,$1f
        db $05,$98,$47,$02,$0c,$02,$1f
        db $04,$18,$8f,$02,$0c,$03,$2d
        db $06,$b0,$87,$04,$0c,$02,$13
        db $ff
enemy_room1f_records:
        db $07,$80,$5f,$02,$17,$02,$31
        db $06,$50,$6f,$03,$1b,$02,$35
        db $04,$28,$77,$03,$1d,$01,$2e
        db $05,$a8,$97,$01,$0c,$02,$22
        db $ff
.endp

.data
enemy_palette_light_green:
        dw $000,$1ec,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
enemy_palette_medium_grey:
        dw $000,$0db,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
enemy_palette_light_grey:
        dw $000,$16d,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
enemy_palette_light_red:
        dw $000,$0eb,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
enemy_palette_orange:
        dw $000,$0a1,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000