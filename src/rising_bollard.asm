; Phase 49: Room $0C rising bollard (Piledriver dual-use mechanism).
;
; Exact C64 behaviour relevant to traversal:
; - Piledriver.InitState plants raw character $62 at screen row $0F,col $1B.
; - CheckContact on that head starts the ride, snaps Monty X to $75 and moves
;   him two pixels upward.
; - UpdateRide then moves Monty upward one pixel per logical tick until Y<$62.
;
; Standard Piledriver now uses the proven static DrawShaft geometry plus a safe
; regenerated-char animation. It follows the original idle/down/up position
; sequence without the crash-prone mutable 144-byte pointer walks.

.zp
rising_bollard_active: ds 1
rising_bollard_last_room: ds 1

.code

rising_bollard_init:
        stz     <rising_bollard_active
        lda     #$ff
        sta     <rising_bollard_last_room
        jmp     piledriver_static_init

rising_bollard_room_sync:
        lda     <monty_room
        cmp     <rising_bollard_last_room
        bne     .changed
        rts
.changed:
        sta     <rising_bollard_last_room
        stz     <rising_bollard_active
        ; Force the safe standard Piledriver RoomInit on actual entry and on
        ; same-room respawn (game_life invalidates rising_bollard_last_room).
        lda     #$ff
        sta     <pile_static_last_room
        jmp     piledriver_static_room_sync

; Run after normal movement with the real room id restored. Animate the standard
; Piledriver first; collision/death remains intentionally disabled at this stage.
rising_bollard_update:
        call    piledriver_static_update
        lda     <monty_room
        cmp     #$0c
        beq     .room0c
        stz     <rising_bollard_active
        rts
.room0c:
        lda     <rising_bollard_active
        bne     .ride

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
        stz     <rising_bollard_active
        rts
.move_up:
        dec     <monty_y
        lda     #1
        sta     <monty_is_moving
        sta     <monty_climbing
.done:
        rts

        include "standard_piledriver_bundle.asm"
