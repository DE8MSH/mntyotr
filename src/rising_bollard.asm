; Phase 49: Room $0C rising bollard (Piledriver dual-use mechanism).
;
; Exact C64 behaviour relevant to traversal:
; - Piledriver.InitState plants raw character $62 at screen row $0F,col $1B.
; - CheckContact on that head starts the ride, snaps Monty X to $75 and moves
;   him two pixels upward.
; - UpdateRide then moves Monty upward one pixel per logical tick until Y<$62.
;
; Standard piledrivers share this mechanism family. Their runtime is included
; below and is advanced from the same lifecycle hooks so main.asm stays stable.

.zp
rising_bollard_active: ds 1
rising_bollard_last_room: ds 1

.code

rising_bollard_init:
        stz     <rising_bollard_active
        lda     #$ff
        sta     <rising_bollard_last_room
        call    piledriver_palette_init
        jmp     piledriver_init

rising_bollard_room_sync:
        lda     <monty_room
        cmp     <rising_bollard_last_room
        bne     .changed
        jmp     piledriver_room_sync
.changed:
        sta     <rising_bollard_last_room
        stz     <rising_bollard_active
        ; A forced same-room reload (death/respawn) invalidates this family via
        ; rising_bollard_last_room=$ff. Force the standard Piledriver to re-run
        ; RoomInit too, matching the C64 room-entry reset.
        lda     #$ff
        sta     <piledriver_last_room
        jmp     piledriver_room_sync

; Run after normal movement with the real room id restored. Standard piledriver
; animation/collision advances first, then the special Room0C bollard behaviour.
rising_bollard_update:
        call    piledriver_update
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
