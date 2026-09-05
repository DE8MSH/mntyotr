; Phase 50: explicit moving-platform contact for the Room $01 rising cloud.
;
; This routine only detects the landing event. Once landed it sets the dedicated
; rising_cloud_riding flag. rising_cloud.asm then validates exact top geometry,
; horizontal overlap and jump/fall state every tick before carrying Monty.

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

        lda     <monty_x
        cmp     #$36
        bcc     .done
        cmp     #$49
        bcs     .done

        ; Landing is one-way and event-driven. Never re-snap a rider who is
        ; already standing/walking on the cloud.
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
        sta     <rising_cloud_riding
.done:
        rts
