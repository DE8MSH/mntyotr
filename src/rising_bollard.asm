; Phase 49: Room $0C rising bollard (Piledriver dual-use mechanism).
;
; Exact C64 behaviour relevant to traversal:
; - Piledriver.InitState plants raw character $62 at screen row $0F,col $1B.
; - CheckContact on that head starts the ride, snaps Monty X to $75 and moves
;   him two pixels upward.
; - UpdateRide then moves Monty upward one pixel per logical tick until Y<$62.
;
; Standard Piledriver uses the proven safe regenerated-char renderer plus an
; exact runtime wrapper for independent random draws and CheckTiles semantics.

.zp
rising_bollard_active: ds 1
rising_bollard_last_room: ds 1
rising_bollard_armed: ds 1

.code

rising_bollard_init:
        stz     <rising_bollard_active
        lda     #1
        sta     <rising_bollard_armed
        lda     #$ff
        sta     <rising_bollard_last_room
        call    piledriver_exact_init
        jmp     piledriver_static_init

rising_bollard_room_sync:
        lda     <monty_room
        cmp     <rising_bollard_last_room
        bne     .changed
        rts
.changed:
        sta     <rising_bollard_last_room
        stz     <rising_bollard_active
        lda     #1
        sta     <rising_bollard_armed
        ; Force safe Piledriver RoomInit on entry and same-room respawn.
        lda     #$ff
        sta     <pile_static_last_room
        jmp     piledriver_static_room_sync

; Run after normal movement with the real room id restored.
rising_bollard_update:
        call    piledriver_exact_update
        lda     <monty_room
        cmp     #$0c
        beq     .room0c
        stz     <rising_bollard_active
        lda     #1
        sta     <rising_bollard_armed
        rts
.room0c:
        lda     <rising_bollard_active
        bne     .ride

        ; After one completed ride, do not immediately retrigger while Monty
        ; falls straight back through the same X range. Re-arm only after he has
        ; actually moved sideways away from the bollard column.
        lda     <rising_bollard_armed
        bne     .can_trigger
        lda     <monty_x
        cmp     #$70
        bcc     .rearm
        cmp     #$7d
        bcs     .rearm
        rts
.rearm:
        lda     #1
        sta     <rising_bollard_armed
        rts

.can_trigger:
        lda     <monty_tile_state
        beq     .done
        lda     <monty_x
        cmp     #$70
        bcc     .done
        cmp     #$7d
        bcs     .done
        lda     <monty_y
        cmp     #$90
        bcc     .done
        cmp     #$aa
        bcs     .done

        lda     #1
        sta     <rising_bollard_active
        lda     #$75
        sta     <monty_x
        stz     <monty_jump_phase
        stz     <monty_jump_index
        stz     <monty_falling
        stz     <monty_saved_left
        stz     <monty_saved_right
        dec     <monty_y
        dec     <monty_y
        lda     #1
        sta     <monty_is_moving
        sta     <monty_climbing
        rts

.ride:
        lda     #$75
        sta     <monty_x
        stz     <monty_jump_phase
        stz     <monty_jump_index
        stz     <monty_falling
        stz     <monty_saved_left
        stz     <monty_saved_right
        lda     <monty_y
        cmp     #$62
        bcs     .move_up

        ; Original UpdateRide clears the ride/game-mode lock here. The PCE port
        ; has no shared game_mode latch, so explicitly release the ride and keep
        ; the trigger disarmed until Monty leaves this X column. This prevents
        ; the upper-R0C lift/fall/lift loop that otherwise traps the player.
        stz     <rising_bollard_active
        stz     <rising_bollard_armed
        stz     <monty_climbing
        stz     <monty_is_moving
        rts
.move_up:
        dec     <monty_y
        lda     #1
        sta     <monty_is_moving
        sta     <monty_climbing
.done:
        rts

        include "standard_piledriver_bundle.asm"
