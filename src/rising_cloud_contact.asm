; Phase 50: explicit moving-platform contact for the Room $01 rising cloud.
;
; The C64 cloud moves at pixel precision but exposes support through three
; character cells. The generic PCE ground probe only evaluates at an 8-pixel
; alignment, so a moving cloud can pass between probe phases. This contact pass
; closes that gap without changing normal room collision: when Monty's feet
; reach the cloud top while horizontally overlapping it, snap to cloud_y-$10,
; end falling/descent, and mark the property-3 support state. rising_cloud_update
; then carries Monty upward by the same 1px as the cloud.

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

        ; Never attach while still rising through the cloud.
        lda     <monty_jump_phase
        cmp     #1
        beq     .done

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
