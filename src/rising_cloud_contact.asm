; Phase 50: explicit moving-platform contact for the Room $01 rising cloud.
;
; The C64 cloud moves at pixel precision but exposes support through three
; character cells. The generic PCE ground probe only evaluates at an 8-pixel
; alignment, so a moving cloud can pass between probe phases. This contact pass
; closes that gap without changing normal room collision: only while Monty is
; FALLING or in jump DESCENT, when his feet reach the cloud top and horizontally
; overlap it, snap to cloud_y-$10, end the descent, and mark property-3 support.
;
; IMPORTANT: once landed, this routine must not snap again every tick. Normal
; input must remain live so Monty can walk across/off the cloud or jump away.
; rising_cloud_update independently carries a standing rider upward by the same
; 1px as the cloud while the overlap/support conditions remain true.

.zp
rising_cloud_contact_y: ds 1

.code

rising_cloud_contact_update:
        lda     <monty_room
        cmp     #1
        beq     .room01
        rts
.room01:
        lda     <rising_cloud_y
        cmp     #$da
        bcs     .done
        cmp     #$52
        bcc     .done

        ; Cloud spans C64 screen columns $0c-$0e. In Monty's half-X gameplay
        ; coordinates the useful overlap window is centred on x=$3c.
        lda     <monty_x
        cmp     #$36
        bcc     .done
        cmp     #$49
        bcs     .done

        ; Landing is one-way and event-driven. Never re-snap a rider who is
        ; already standing on the cloud: doing so would clear fresh walk/jump
        ; input every tick and make Monty appear glued to the platform.
        lda     <monty_jump_phase
        cmp     #1
        beq     .done                 ; ascent: pass upward through platform
        cmp     #2
        beq     .descending
        lda     <monty_falling
        beq     .done                 ; standing/walking: leave controls alone
.descending:

        ; Standing position is exactly 16 C64 pixels above sprite1_y_buffer.
        lda     <rising_cloud_y
        sec
        sbc     #$10
        sta     <rising_cloud_contact_y

        ; Accept a small swept-crossing window. Normal fall is 1px/tick; jump
        ; descent can advance 2px in one logical tick. Reject positions already
        ; substantially below the platform so it remains one-way from above.
        lda     <monty_y
        sec
        sbc     <rising_cloud_contact_y
        bcc     .above
        cmp     #4
        bcs     .done
        bra     .land
.above:
        ; A = wrapped negative difference. Only -1/-2 are close enough to snap;
        ; anything farther above should continue falling naturally.
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
