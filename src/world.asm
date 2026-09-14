; C64 world navigation port.
; Exact 6x23 room destination grid from Room.Data.room_exit_dest_tbl.
; $ff means no transition. Room $30 is completion-only and not in this grid.

.zp
world_map_row:          ds 1
world_exit_col:         ds 1
world_pending_room:     ds 1
world_transition_ready: ds 1
world_lookup_index:     ds 1

.code

; Startup-only world state does not need to occupy fixed HOME. Keep it banked
; with --newproc so Bank 0 remains available for reset/vectors and call thunks.
.proc world_init
        lda     #$02
        sta     <world_map_row
        lda     #$15
        sta     <world_exit_col
        stz     <monty_room            ; room $00 at row 2, col $15
        stz     <world_pending_room
        stz     <world_transition_ready
        leave
.endp

; X=world column 0..22, Y=world row 0..5.
; Returns A=room id or $ff for a wall/outside cell.
world_get_room_xy:
        cpx     #23
        bcs     .wall
        cpy     #6
        bcs     .wall
        stx     <world_lookup_index
        tya
        tax
        lda     world_row_offsets,x
        clc
        adc     <world_lookup_index
        tax
        lda     world_room_grid,x
        rts
.wall:
        lda     #$ff
        rts

; A=room id. C=1 if this room currently has a real loader.
; Rooms $00-$33 are now a contiguous supported block; $30 remains off-grid and
; is reached by the original completion path rather than normal edge traversal.
world_room_supported:
        cmp     #$34
        bcc     .yes
        clc
        rts
.yes:
        sec
        rts

; Relocate the large edge dispatcher into a normal code bank. The generated
; HOME thunk is much smaller than this body and leaves fixed Bank 0 available
; for reset/vectors and the other --newproc thunks.
.proc world_resolve_exit
        stz     <world_transition_ready
        lda     <monty_room_exit
        bne     .have_exit
        jmp     .none
.have_exit:
        cmp     #1
        beq     .left
        cmp     #2
        beq     .right
        cmp     #3
        beq     .up
        cmp     #4
        beq     .down
        jmp     .blocked
.left:
        lda     <world_exit_col
        bne     .left_have_col
        jmp     .blocked_left
.left_have_col:
        sec
        sbc     #1
        tax
        ldy     <world_map_row
        jsr     world_get_room_xy
        cmp     #$ff
        bne     .left_have_room
        jmp     .blocked_left
.left_have_room:
        jsr     world_room_supported
        bcs     .left_valid
        jmp     .blocked_left
.left_valid:
        dec     <world_exit_col
        jmp     .valid
.right:
        lda     <world_exit_col
        clc
        adc     #1
        tax
        ldy     <world_map_row
        jsr     world_get_room_xy
        cmp     #$ff
        bne     .right_have_room
        jmp     .blocked_right
.right_have_room:
        jsr     world_room_supported
        bcs     .right_valid
        jmp     .blocked_right
.right_valid:
        inc     <world_exit_col
        jmp     .valid
.up:
        lda     <world_map_row
        bne     .up_have_row
        jmp     .blocked_up
.up_have_row:
        sec
        sbc     #1
        tay
        ldx     <world_exit_col
        jsr     world_get_room_xy
        cmp     #$ff
        bne     .up_have_room
        jmp     .blocked_up
.up_have_room:
        jsr     world_room_supported
        bcs     .up_valid
        jmp     .blocked_up
.up_valid:
        dec     <world_map_row
        jmp     .valid
.down:
        lda     <world_map_row
        clc
        adc     #1
        tay
        ldx     <world_exit_col
        jsr     world_get_room_xy
        cmp     #$ff
        bne     .down_have_room
        jmp     .blocked_down
.down_have_room:
        jsr     world_room_supported
        bcs     .down_valid
        jmp     .blocked_down
.down_valid:
        inc     <world_map_row
.valid:
        ; Commit the destination before touching A again. Then install the exact
        ; opposite-edge entry coordinate from the exit direction. The movement
        ; code also clamps at the edge, but doing it here makes the transition
        ; atomic and prevents a freshly loaded room from inheriting a stale edge
        ; coordinate and immediately bouncing back to the previous room.
        sta     <world_pending_room
        lda     <monty_room_exit
        cmp     #1
        bne     .entry_not_left
        lda     #$9b
        sta     <monty_x
        bra     .entry_done
.entry_not_left:
        cmp     #2
        bne     .entry_not_right
        lda     #$15
        sta     <monty_x
        bra     .entry_done
.entry_not_right:
        cmp     #3
        bne     .entry_down
        lda     #$da
        sta     <monty_y
        bra     .entry_done
.entry_down:
        lda     #$4c
        sta     <monty_y
.entry_done:
        stz     <monty_is_moving
        lda     #1
        sta     <world_transition_ready
        stz     <monty_room_exit
        sec
        leave

.blocked_left:
        lda     #$15
        sta     <monty_x
        bra     .blocked
.blocked_right:
        lda     #$9b
        sta     <monty_x
        bra     .blocked
.blocked_up:
        lda     #$4c
        sta     <monty_y
        bra     .blocked
.blocked_down:
        lda     #$d9
        sta     <monty_y
.blocked:
        stz     <monty_room_exit
.none:
        clc
        leave
.endp

.data
world_row_offsets:
        db $00,$17,$2e,$45,$5c,$73

world_room_grid:
        db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$23,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        db $ff,$2f,$2e,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$22,$ff,$ff,$ff,$ff,$ff,$ff,$06,$07,$08,$09,$ff,$ff
        db $2d,$2c,$27,$26,$33,$32,$31,$25,$24,$20,$21,$ff,$ff,$ff,$ff,$ff,$05,$04,$03,$02,$01,$00,$ff
        db $2b,$2a,$28,$29,$ff,$ff,$ff,$ff,$ff,$1f,$ff,$ff,$1b,$ff,$ff,$0f,$0c,$0d,$0e,$0b,$0a,$ff,$ff
        db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$1e,$ff,$1a,$19,$18,$ff,$10,$11,$ff,$ff,$ff,$ff,$ff,$ff
        db $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$1d,$1c,$17,$16,$15,$14,$12,$13,$ff,$ff,$ff,$ff,$ff,$ff
