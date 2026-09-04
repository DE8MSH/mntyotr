; C64 Monty.UpdateMovement_down bottom-edge transition.
; Original semantics: when Monty's C64 Y reaches $DA while moving/falling down,
; increment map_row, resolve the room below, and on success wrap Y to $4C.
; World lookup remains in world_resolve_exit; this helper only emits exit #4.

.code
monty_check_down_room_edge:
        lda     <monty_room_exit
        bne     .done
        lda     <monty_y
        cmp     #$da
        bcc     .done
        lda     #4
        sta     <monty_room_exit
        lda     #$4c
        sta     <monty_y
.done:
        rts
