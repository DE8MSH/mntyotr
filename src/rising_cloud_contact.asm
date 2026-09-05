; Phase 50: explicit one-way landing contact for the Room $01 rising cloud.
;
; The cloud itself moves at pixel precision, while the room collision map is
; character based. This pass catches the crossing event when Monty descends onto
; the cloud top. It also enforces the exact original Room01 ceiling immediately
; above the cloud route: C64 CheckTileAbove blocks Monty at Y=$52 because logical
; row 0 / cloud columns are property-1. If the PCE edge path has already produced
; an UP room exit, cancel it and restore the same original blocked Y=$52 result.

.zp
rising_cloud_contact_y: ds 1

.code

rising_cloud_contact_update:
        lda     <monty_room
        cmp     #1
        beq     .room01
        rts
.room01:
        ; Exact Room01 ceiling above the cloud route. The original C64 upward
        ; loop checks CheckTileAbove before every pixel and is blocked at Y=$52.
        ; Guard both raw penetration and a room-exit already generated this tick.
        lda     <monty_x
        cmp     #$36
        bcc     .landing_check
        cmp     #$49
        bcs     .landing_check
        lda     <monty_room_exit
        cmp     #3
        beq     .block_ceiling
        lda     <monty_y
        cmp     #$52
        bcc     .block_ceiling
        bra     .landing_check

.block_ceiling:
        lda     #$52
        sta     <monty_y
        stz     <monty_room_exit
        stz     <monty_climbing
        lda     <monty_jump_phase
        cmp     #1
        bne     .done
        lda     #2
        sta     <monty_jump_phase
        stz     <monty_jump_index
        rts

.landing_check:
        lda     <rising_cloud_y
        cmp     #$da
        bcs     .done
        cmp     #$52
        bcc     .done

        lda     <monty_x
        cmp     #$36
        bcc     .done
        cmp     #$49
        bcs     .done

        ; One-way platform: only falling or jump descent may land.
        lda     <monty_jump_phase
        cmp     #1
        beq     .done
        cmp     #2
        beq     .descending
        lda     <monty_falling
        beq     .done
.descending:

        lda     <rising_cloud_y
        sec
        sbc     #$10
        sta     <rising_cloud_contact_y

        ; Accept a tiny swept crossing window around the top. This catches the
        ; 1..2 px descent steps without allowing contact from well below.
        lda     <monty_y
        sec
        sbc     <rising_cloud_contact_y
        bcc     .above
        cmp     #4
        bcs     .done
        bra     .land
.above:
        cmp     #$fe
        bcc     .done

.land:
        lda     <rising_cloud_contact_y
        sta     <monty_y
        stz     <monty_jump_phase
        stz     <monty_jump_index
        stz     <monty_falling
        stz     <monty_saved_left
        stz     <monty_saved_right
        lda     #1
        sta     <monty_tile_state
        sta     <monty_is_moving
.done:
        rts
