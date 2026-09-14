; Source-derived four-room teleporter network.
; Mechanisms.Data.teleporter_cfg_tbl gives source room/column/row/height;
; dest_tbl gives exact destination Monty X/Y and destination world grid cell.

.bss
teleporter_last_room: ds 1
teleporter_active: ds 1
teleporter_index: ds 1
teleporter_col: ds 1
teleporter_row: ds 1
teleporter_height: ds 1
teleporter_player_col: ds 1
teleporter_player_row: ds 1
teleporter_transition_pending: ds 1

.code
teleporter_init:
        lda #$ff
        sta teleporter_last_room
        stz teleporter_active
        stz teleporter_transition_pending
        rts

teleporter_room_sync:
        lda <monty_room
        cmp teleporter_last_room
        bne .changed
        rts
.changed:
        sta teleporter_last_room
        stz teleporter_active
        stz teleporter_transition_pending
        cmp #$08
        beq .r08
        cmp #$14
        beq .r14
        cmp #$1c
        beq .r1c
        cmp #$2a
        beq .r2a
        rts
.r08:
        stz teleporter_index
        lda #$0e
        sta teleporter_col
        lda #$08
        sta teleporter_row
        lda #6
        sta teleporter_height
        bra .enable
.r14:
        lda #1
        sta teleporter_index
        lda #$1c
        sta teleporter_col
        lda #$0d
        sta teleporter_row
        lda #6
        sta teleporter_height
        bra .enable
.r1c:
        lda #2
        sta teleporter_index
        lda #$1d
        sta teleporter_col
        lda #$05
        sta teleporter_row
        lda #10
        sta teleporter_height
        bra .enable
.r2a:
        lda #3
        sta teleporter_index
        lda #$1d
        sta teleporter_col
        lda #$04
        sta teleporter_row
        lda #8
        sta teleporter_height
.enable:
        lda #1
        sta teleporter_active
        rts

; Original contact scans Monty's surrounding tiles for the teleporter chars.
; The PCE rooms keep the same C64 logical grid, so use the exact source column/
; row/height rectangle rather than guessing from screen pixels.
teleporter_update:
        lda teleporter_active
        bne .active
        rts
.active:
        lda teleporter_transition_pending
        beq .coords
        rts
.coords:
        lda <monty_x
        sec
        sbc #$0c
        lsr a
        lsr a
        sta teleporter_player_col
        lda <monty_y
        sec
        sbc #$32
        lsr a
        lsr a
        lsr a
        sta teleporter_player_row

        ; Column art is 3 chars wide at its cap and one centre column below it.
        lda teleporter_player_col
        clc
        adc #1
        cmp teleporter_col
        bcc .done
        lda teleporter_col
        clc
        adc #2
        cmp teleporter_player_col
        bcc .done

        lda teleporter_player_row
        clc
        adc #2
        cmp teleporter_row
        bcc .done
        lda teleporter_row
        clc
        adc teleporter_height
        inc a
        cmp teleporter_player_row
        bcc .done

        ldx teleporter_index
        lda teleporter_dest_room,x
        sta <world_pending_room
        sta <monty_room
        lda teleporter_dest_x,x
        sta <monty_x
        lda teleporter_dest_y,x
        sta <monty_y
        lda teleporter_dest_col,x
        sta <world_exit_col
        lda teleporter_dest_row,x
        sta <world_map_row
        stz <monty_room_exit
        stz <monty_jump_phase
        stz <monty_jump_index
        stz <monty_falling
        stz <monty_saved_left
        stz <monty_saved_right
        lda #1
        sta teleporter_transition_pending
.done:
        rts

.data
teleporter_dest_room:
        db $06,$13,$1b,$29
teleporter_dest_x:
        db $34,$60,$28,$17
teleporter_dest_y:
        db $72,$a2,$6a,$a2
teleporter_dest_col:
        db $11,$10,$0c,$03
teleporter_dest_row:
        db $01,$05,$03,$03
