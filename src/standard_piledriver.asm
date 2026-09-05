; Standard C64 piledriver mechanism for currently ported rooms $01/$02/$0B.
; Config records are copied from Mechanisms.Data.config_tbl.
; State machine matches the source: idle delay $14..$53, position starts at 5,
; descend +2 until height*8-1, retract -2 until position<6.

PILE_SPR_VRAM = $3700
PILE_SAT0_L   = SAT_ADDR+32
PILE_SAT0_R   = SAT_ADDR+36
PILE_SAT1_L   = SAT_ADDR+40
PILE_SAT1_R   = SAT_ADDR+44

.zp
piledriver_last_room: ds 1
piledriver_count:     ds 1
piledriver_state:     ds 1
piledriver_delay:     ds 1
piledriver_index:     ds 1
piledriver_position:  ds 1
piledriver_col0:      ds 1
piledriver_row0:      ds 1
piledriver_limit0:    ds 1
piledriver_y0:        ds 1
piledriver_col1:      ds 1
piledriver_row1:      ds 1
piledriver_limit1:    ds 1
piledriver_y1:        ds 1
piledriver_tmp_x:     ds 1
piledriver_tmp_y:     ds 1

.code

piledriver_init:
        lda #$ff
        sta <piledriver_last_room
        sta <piledriver_index
        stz <piledriver_count
        stz <piledriver_state
        lda #1
        sta <piledriver_delay
        jmp piledriver_upload_patterns

piledriver_room_sync:
        lda <monty_room
        cmp <piledriver_last_room
        bne .changed
        rts
.changed:
        sta <piledriver_last_room
        stz <piledriver_count
        stz <piledriver_state
        lda #1
        sta <piledriver_delay
        lda #$ff
        sta <piledriver_index
        lda <monty_room
        cmp #$01
        beq .room01
        cmp #$02
        beq .room02
        cmp #$0b
        beq .room0b
        rts
.room01:
        lda #2
        sta <piledriver_count
        lda #$07
        sta <piledriver_col0
        lda #$05
        sta <piledriver_row0
        lda #$1f
        sta <piledriver_limit0
        lda #$5c
        sta <piledriver_y0
        lda #$1f
        sta <piledriver_col1
        lda #$0c
        sta <piledriver_row1
        lda #$2f
        sta <piledriver_limit1
        lda #$94
        sta <piledriver_y1
        rts
.room02:
        lda #1
        sta <piledriver_count
        lda #$15
        sta <piledriver_col0
        lda #$05
        sta <piledriver_row0
        lda #$1f
        sta <piledriver_limit0
        lda #$5c
        sta <piledriver_y0
        rts
.room0b:
        lda #1
        sta <piledriver_count
        lda #$13
        sta <piledriver_col0
        lda #$11
        sta <piledriver_row0
        lda #$1f
        sta <piledriver_limit0
        lda #$bc
        sta <piledriver_y0
        rts

piledriver_update:
        lda <piledriver_count
        bne .active_room
        rts
.active_room:
        lda <piledriver_state
        bne .step
        lda #$ff
        sta <piledriver_index
        dec <piledriver_delay
        beq .activate
        rts
.activate:
        lda game_tick_counter
        and #$3f
        clc
        adc #$14
        sta <piledriver_delay
        ldx #0
        lda <piledriver_count
        cmp #2
        bne .picked
        lda game_tick_counter
        and #1
        tax
.picked:
        stx <piledriver_index
        lda #1
        sta <piledriver_state
        lda #5
        sta <piledriver_position
        rts
.step:
        cmp #2
        beq .retract
        inc <piledriver_position
        inc <piledriver_position
        ldx <piledriver_index
        lda <piledriver_position
        cpx #0
        bne .desc1
        cmp <piledriver_limit0
        bra .desc_cmp
.desc1:
        cmp <piledriver_limit1
.desc_cmp:
        bcc .check_hit
        inc <piledriver_state
        rts
.check_hit:
        jmp piledriver_check_hit
.retract:
        dec <piledriver_position
        dec <piledriver_position
        lda <piledriver_position
        cmp #6
        bcs .done
        stz <piledriver_state
        lda #$ff
        sta <piledriver_index
.done:
        rts

; Source CheckTiles compares active driver top+position against Monty's Y and
; dispatches piledriver death. The PCE port uses the same action_counter=4 path.
piledriver_check_hit:
        ldx <piledriver_index
        cpx #0
        bne .driver1
        lda <piledriver_col0
        sta <piledriver_tmp_x
        lda <piledriver_y0
        bra .have
.driver1:
        lda <piledriver_col1
        sta <piledriver_tmp_x
        lda <piledriver_y1
.have:
        clc
        adc <piledriver_position
        cmp <monty_y
        bcc .done
        ; config screen col -> Monty gameplay X: col*4 + $0c, width 3 chars.
        lda <piledriver_tmp_x
        asl a
        asl a
        clc
        adc #$0c
        sta <piledriver_tmp_x
        lda <monty_x
        cmp <piledriver_tmp_x
        bcc .done
        lda <piledriver_tmp_x
        clc
        adc #12
        cmp <monty_x
        bcc .done
        lda #4
        sta <monty_action_counter
.done:
        rts

piledriver_upload_patterns:
        php
        sei
        tma3
        pha
        tma4
        pha
        lda #<piledriver_patterns
        sta <_bp
        lda #>piledriver_patterns
        sta <_bp+1
        ldy #BANK(piledriver_patterns)
        call map_bp_to_mpr34
        lda #<PILE_SPR_VRAM
        sta <_di
        lda #>PILE_SPR_VRAM
        sta <_di+1
        call vdc_di_to_mawr
        ldx #1
        cly
.page:
        lda [_bp],y
        sta VDC_DL
        iny
        lda [_bp],y
        sta VDC_DH
        iny
        bne .page
        pla
        tam4
        pla
        tam3
        plp
        rts

; Render both configured heads. The selected driver receives the live position
; offset; idle/unselected heads remain at source position 5.
piledriver_update_satb:
        lda <piledriver_count
        bne .show0
        jmp piledriver_hide_satb
.show0:
        ldx #0
        call piledriver_draw_one
        lda <piledriver_count
        cmp #2
        bne .hide1
        ldx #1
        call piledriver_draw_one
        jmp piledriver_sat_dma
.hide1:
        lda #<PILE_SAT1_L
        sta <_di
        lda #>PILE_SAT1_L
        sta <_di+1
        call vdc_di_to_mawr
        ldx #2
        jmp piledriver_hide_entries

piledriver_draw_one:
        cpx #0
        bne .d1
        lda <piledriver_col0
        sta <piledriver_tmp_x
        lda <piledriver_y0
        bra .base
.d1:
        lda <piledriver_col1
        sta <piledriver_tmp_x
        lda <piledriver_y1
.base:
        sta <piledriver_tmp_y
        txa
        cmp <piledriver_index
        bne .idlepos
        lda <piledriver_state
        beq .idlepos
        lda <piledriver_position
        bra .addpos
.idlepos:
        lda #5
.addpos:
        clc
        adc <piledriver_tmp_y
        clc
        adc #15
        sta <piledriver_tmp_y
        cpx #0
        bne .addr1
        lda #<PILE_SAT0_L
        sta <_di
        lda #>PILE_SAT0_L
        bra .addr
.addr1:
        lda #<PILE_SAT1_L
        sta <_di
        lda #>PILE_SAT1_L
.addr:
        sta <_di+1
        call vdc_di_to_mawr
        ; left sprite
        lda <piledriver_tmp_y
        sta VDC_DL
        stz VDC_DH
        lda <piledriver_tmp_x
        asl a
        asl a
        asl a
        clc
        adc #32
        sta VDC_DL
        stz VDC_DH
        lda #<(PILE_SPR_VRAM>>5)
        sta VDC_DL
        lda #>(PILE_SPR_VRAM>>5)
        sta VDC_DH
        lda #$83
        sta VDC_DL
        lda #$10
        sta VDC_DH
        ; right sprite
        lda <piledriver_tmp_y
        sta VDC_DL
        stz VDC_DH
        lda <piledriver_tmp_x
        asl a
        asl a
        asl a
        clc
        adc #48
        sta VDC_DL
        stz VDC_DH
        lda #<((PILE_SPR_VRAM+64)>>5)
        sta VDC_DL
        lda #>((PILE_SPR_VRAM+64)>>5)
        sta VDC_DH
        lda #$83
        sta VDC_DL
        lda #$10
        sta VDC_DH
        rts

piledriver_hide_satb:
        lda #<PILE_SAT0_L
        sta <_di
        lda #>PILE_SAT0_L
        sta <_di+1
        call vdc_di_to_mawr
        ldx #4
piledriver_hide_entries:
        cla
        sta VDC_DL
        lda #1
        sta VDC_DH
        cla
        sta VDC_DL
        sta VDC_DH
        sta VDC_DL
        sta VDC_DH
        sta VDC_DL
        sta VDC_DH
        dex
        bne piledriver_hide_entries
piledriver_sat_dma:
        st0 #$13
        st1 #<SAT_ADDR
        st2 #>SAT_ADDR
        rts
