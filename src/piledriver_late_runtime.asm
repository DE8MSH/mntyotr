; Remaining authentic standard Piledriver configs from Mechanisms.Data.config_tbl.
; Early runtime already owns R01/R02/R0B. This helper activates R06/R13/R19/R1B/R28
; using the same dynamic VRAM renderer/state machine and adds exact CheckTiles
; collision for those rooms.

.bss
late_pile_last_room: ds 1
late_pile_col0: ds 1
late_pile_row0: ds 1
late_pile_h0: ds 1
late_pile_col1: ds 1
late_pile_row1: ds 1
late_pile_h1: ds 1
late_pile_pd_y: ds 1
late_pile_base_col: ds 1
late_pile_base_row: ds 1

.code

piledriver_late_init:
        lda #$ff
        sta late_pile_last_room
        rts

piledriver_late_room_sync:
        lda <monty_room
        cmp late_pile_last_room
        bne .changed
        rts
.changed:
        sta late_pile_last_room
        cmp #$06
        beq .r06
        cmp #$13
        beq .r13
        cmp #$19
        beq .r19
        cmp #$1b
        beq .r1b
        cmp #$28
        beq .r28
        rts

.reset:
        stz <pile_static_state
        stz <pile_static_shift
        lda #$ff
        sta <pile_static_index
        lda #1
        sta <pile_static_delay
        rts

.single_draw:
        lda #1
        sta <pile_static_count
        lda late_pile_h0
        asl a
        asl a
        asl a
        dec a
        sta <pile_static_limit0
        lda late_pile_col0
        sta <pile_static_col
        lda late_pile_row0
        sta <pile_static_row
        lda late_pile_h0
        sta <pile_static_height
        lda #<PILE_STATIC_CHR0
        sta <pile_static_base_lo
        call piledriver_static_draw
        jmp .reset

.r06:
        lda #$0d
        sta late_pile_col0
        lda #$06
        sta late_pile_row0
        lda #4
        sta late_pile_h0
        jmp .single_draw
.r13:
        lda #$18
        sta late_pile_col0
        lda #$0d
        sta late_pile_row0
        lda #3
        sta late_pile_h0
        jmp .single_draw
.r19:
        lda #$1a
        sta late_pile_col0
        lda #$04
        sta late_pile_row0
        lda #3
        sta late_pile_h0
        jmp .single_draw
.r28:
        lda #$15
        sta late_pile_col0
        lda #$0b
        sta late_pile_row0
        lda #6
        sta late_pile_h0
        jmp .single_draw
.r1b:
        lda #2
        sta <pile_static_count
        lda #$1f
        sta <pile_static_limit0
        sta <pile_static_limit1

        lda #$0f
        sta late_pile_col0
        sta <pile_static_col
        lda #$04
        sta late_pile_row0
        sta <pile_static_row
        lda #4
        sta late_pile_h0
        sta <pile_static_height
        lda #<PILE_STATIC_CHR0
        sta <pile_static_base_lo
        call piledriver_static_draw

        lda #$15
        sta late_pile_col1
        sta <pile_static_col
        lda #$04
        sta late_pile_row1
        sta <pile_static_row
        lda #4
        sta late_pile_h1
        sta <pile_static_height
        lda #<PILE_STATIC_CHR1
        sta <pile_static_base_lo
        call piledriver_static_draw
        jmp .reset

; Exact late-room equivalent of Piledriver.CheckTiles. Only descending state can
; kill; Monty's upper 2x2 character footprint must overlap the selected shaft,
; then pd_sprite_y + position must reach Monty's Y.
piledriver_late_collision_update:
        lda <monty_room
        cmp #$06
        beq .late_room
        cmp #$13
        beq .late_room
        cmp #$19
        beq .late_room
        cmp #$1b
        beq .late_room
        cmp #$28
        beq .late_room
        rts
.late_room:
        lda <pile_static_index
        cmp #$ff
        beq .done
        lda <pile_static_state
        cmp #1
        bne .done

        lda <monty_x
        sec
        sbc #$0c
        lsr a
        lsr a
        sta late_pile_base_col
        lda <monty_y
        sec
        sbc #$32
        lsr a
        lsr a
        lsr a
        sta late_pile_base_row

        lda <pile_static_index
        beq .driver0
        lda late_pile_col1
        sta <pile_static_col
        lda late_pile_row1
        sta <pile_static_row
        lda late_pile_h1
        sta <pile_static_height
        bra .cfg_ready
.driver0:
        lda late_pile_col0
        sta <pile_static_col
        lda late_pile_row0
        sta <pile_static_row
        lda late_pile_h0
        sta <pile_static_height
.cfg_ready:
        ; horizontal: Monty [base,base+1], shaft [col,col+2]
        lda late_pile_base_col
        clc
        adc #1
        cmp <pile_static_col
        bcc .done
        lda <pile_static_col
        clc
        adc #2
        cmp late_pile_base_col
        bcc .done

        ; vertical intersection with shaft rows
        lda late_pile_base_row
        clc
        adc #1
        cmp <pile_static_row
        bcc .done
        lda <pile_static_row
        clc
        adc <pile_static_height
        dec a
        cmp late_pile_base_row
        bcc .done

        ; pd_sprite_y = row*8 + $34
        lda <pile_static_row
        asl a
        asl a
        asl a
        clc
        adc #$34
        sta late_pile_pd_y
        clc
        adc <pile_static_position
        cmp <monty_y
        bcc .done
        lda #4
        sta <monty_action_counter
.done:
        rts
