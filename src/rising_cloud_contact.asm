; Phase 50: explicit one-way landing contact for the Room $01 rising cloud.
;
; The cloud itself moves at pixel precision, while the room collision map is
; character based. This pass only catches the crossing event when Monty descends
; onto the cloud top. It performs no persistent attachment and never touches
; input state after the landing tick.

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
