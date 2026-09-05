; Phase 49: execute C64 jump deltas one pixel at a time.
;
; The C64 jump table stores per-frame deltas of 0..3 pixels, but UpdateMovement
; consumes jump_up_steps/jump_dn_steps in a loop and calls CheckTileAbove/Below
; before EVERY single pixel.  Applying a whole delta at once lets the PCE port
; skip an 8-pixel platform boundary and tunnel through floors/ceilings.
;
; Keep the existing authentic arc tables and collision routines; only replace
; the multi-pixel application with this swept version.

.code

monty_jump_step_swept:
        lda     <monty_jump_phase
        beq     .done
        cmp     #1
        bne     .descent

        ; C64 StepJumpArc increments the ascent index before reading it, so the
        ; first real delta is $03 (table entry 1); table entry 0 is never moved.
        inc     <monty_jump_index
        ldx     <monty_jump_index
        lda     monty_jump_arc_up,x
        cmp     #$ff
        beq     .switch_down
        sta     <jump_delta

.up_pixel:
        lda     <jump_delta
        beq     .done
        call    monty_check_tile_above
        bcs     .switch_down
        dec     <monty_y
        lda     #1
        sta     <monty_is_moving
        dec     <jump_delta
        call    monty_check_room_edges
        lda     <monty_room_exit
        bne     .done
        bra     .up_pixel

.switch_down:
        lda     #2
        sta     <monty_jump_phase
        stz     <monty_jump_index
        rts

.descent:
        ldx     <monty_jump_index
        lda     monty_jump_arc_down,x
        cmp     #$ff
        beq     .finish_arc
        sta     <jump_delta
        inc     <monty_jump_index

.down_pixel:
        lda     <jump_delta
        beq     .done
        call    monty_check_tile_below
        bcs     .land
        inc     <monty_y
        lda     #1
        sta     <monty_is_moving
        dec     <jump_delta

        ; Original UpdateMovement_down tests the room edge inside the same
        ; per-pixel loop. Do that here too, so a two-pixel descent cannot step
        ; past $DA before world navigation sees the transition.
        call    monty_check_down_room_edge
        lda     <monty_room_exit
        bne     .done
        bra     .down_pixel

.land:
        stz     <monty_jump_phase
        stz     <monty_jump_index
        stz     <monty_falling
        stz     <monty_saved_left
        stz     <monty_saved_right
        rts

.finish_arc:
        ; The C64 descent table ends before gravity necessarily reaches ground.
        ; Clearing the jump action lets the normal unsupported-fall path finish
        ; the drop one pixel at a time on following logical ticks.
        stz     <monty_jump_phase
        stz     <monty_jump_index
        stz     <monty_saved_left
        stz     <monty_saved_right
.done:
        rts
