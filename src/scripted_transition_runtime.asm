; Scripted non-grid room transitions from the original C64 game.
; - R2F treasure at ($40,$9A), enabled by Jerry Can item #8, enters R30.
; - R33 C5 return at exact Monty position ($14,$CA) returns to R26 at ($9C,$5C).
;
; Keep both entry points as procedures.  With --newproc pceas can relocate these
; helpers instead of letting late-game code consume/wrap the fixed HOME window.

.bss
scripted_transition_pending: ds 1
scripted_transition_tmp: ds 1

.code
.proc scripted_transition_init
        stz scripted_transition_pending
        leave
.endp

.proc scripted_transition_update
        stz scripted_transition_pending
        lda <monty_room
        cmp #$2f
        beq .room2f
        cmp #$33
        beq .room33
        leave

.room2f:
        ; Original Enemies.PlaceTreasure only enables the treasure after Jerry
        ; Can (SI #8, R23) has been collected.
        lda special_item_collected+8
        beq .done
        ; Same 24x21 sprite overlap used for normal special items, treasure at
        ; original C64 sprite coordinate X=$40,Y=$9A.
        lda <monty_x
        asl a
        sta scripted_transition_tmp
        sec
        sbc #$40
        cmp #24
        bcc .r2f_x_ok
        lda #$40
        sec
        sbc scripted_transition_tmp
        cmp #24
        bcs .done
.r2f_x_ok:
        lda <monty_y
        clc
        adc #1
        sec
        sbc #$9a
        cmp #21
        bcc .complete
        lda #$9a
        sec
        sbc <monty_y
        cmp #22
        bcs .done
.complete:
        lda #$30
        sta <world_pending_room
        sta <monty_room
        stz <monty_room_exit
        stz <monty_jump_phase
        stz <monty_jump_index
        lda #1
        sta scripted_transition_pending
        leave

.room33:
        ; Exact C5CheckReturnTeleport trigger and destination.
        lda <monty_x
        cmp #$14
        bne .done
        lda <monty_y
        cmp #$ca
        bne .done
        lda #$26
        sta <world_pending_room
        sta <monty_room
        lda #$9c
        sta <monty_x
        lda #$5c
        sta <monty_y
        lda #$03
        sta <world_exit_col
        lda #$02
        sta <world_map_row
        stz <monty_room_exit
        stz <monty_jump_phase
        stz <monty_jump_index
        stz <monty_falling
        lda #1
        sta scripted_transition_pending
.done:
        leave
.endp
