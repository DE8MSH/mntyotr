; Pixel-accurate enemy collision for the four authentic C64 enemy slots.
; C64 latches VIC sprite/sprite collisions in $D01E. Monty is sprite 3 and
; enemies are sprites 4..7, so a hit only exists where opaque 24x21 pixels
; overlap. A cheap C64-coordinate broadphase now runs before any bank mapping
; or mask reconstruction; exact opaque-pixel collision is unchanged.
;
; --newproc note: top-level exit uses LEAVE. Internal JSR helpers use RTS.

.bss
enemy_col_monty_mask:   ds 63
enemy_col_enemy_mask:   ds 63
enemy_col_hit:          ds 1
enemy_col_tmp:          ds 1
enemy_col_enemy_x:      ds 1
enemy_col_enemy_y:      ds 1
enemy_col_shift:        ds 1
enemy_col_shift_work:   ds 1
enemy_col_shift_side:   ds 1
enemy_col_rows:         ds 1
enemy_col_mrow:         ds 1
enemy_col_erow:         ds 1
enemy_col_delta:        ds 1
enemy_col_m0:           ds 1
enemy_col_m1:           ds 1
enemy_col_m2:           ds 1
enemy_col_e0:           ds 1
enemy_col_e1:           ds 1
enemy_col_e2:           ds 1
enemy_col_slot:         ds 1
enemy_col_state:        ds 1
enemy_col_frame:        ds 1

.code
.proc enemy_room00_collision_update
        ; First pass is state-only. If no active enemy is within the 24x21 VIC
        ; sprite rectangle, do no ROM mapping and build no 63-byte masks.
        stz     enemy_col_hit
        stz     enemy_col_slot
        stz     enemy_col_state

.scan_slot:
        ldx     enemy_col_state
        lda     enemy_state_tbl,x
        cmp     #$ff
        beq     .scan_next
        sta     enemy_col_enemy_x
        lda     enemy_state_tbl+1,x
        sta     enemy_col_enemy_y
        jsr     .coarse_overlap
        bcs     .prepare_masks

.scan_next:
        inc     enemy_col_slot
        lda     enemy_col_state
        clc
        adc     #8
        sta     enemy_col_state
        lda     enemy_col_slot
        cmp     #4
        bne     .scan_more
        jmp     .done_unmapped
.scan_more:
        jmp     .scan_slot

.prepare_masks:
        ; Only a real broadphase candidate pays for bank switching and Monty's
        ; current-frame mask. The current slot/state already names candidate #1.
        php
        sei
        tma3
        pha
        tma4
        pha

        jsr     .select_monty_source
        call    map_bp_to_mpr34
        jsr     .convert_monty_mask

.precise_slot:
        jsr     .select_enemy_source
        call    map_bp_to_mpr34
        jsr     .convert_enemy_mask
        jsr     .opaque_overlap
        bcc     .precise_next

        lda     #1
        sta     enemy_col_hit
        jmp     .restore_maps

.precise_next:
        inc     enemy_col_slot
        lda     enemy_col_state
        clc
        adc     #8
        sta     enemy_col_state
        lda     enemy_col_slot
        cmp     #4
        beq     .restore_maps

.precise_scan:
        ldx     enemy_col_state
        lda     enemy_state_tbl,x
        cmp     #$ff
        beq     .precise_advance
        sta     enemy_col_enemy_x
        lda     enemy_state_tbl+1,x
        sta     enemy_col_enemy_y
        jsr     .coarse_overlap
        bcs     .precise_slot

.precise_advance:
        inc     enemy_col_slot
        lda     enemy_col_state
        clc
        adc     #8
        sta     enemy_col_state
        lda     enemy_col_slot
        cmp     #4
        beq     .restore_maps
        jmp     .precise_scan

.restore_maps:
        pla
        tam4
        pla
        tam3
        plp

        lda     enemy_col_hit
        beq     .done

        lda     #2
        sta     <monty_action_counter

        lda     #$ff
        sta     enemy_smiley_last_room
.done:
        leave

.done_unmapped:
        leave

; Fast rectangle reject before doing banked frame conversion.
.coarse_overlap:
        lda     enemy_col_enemy_x
        cmp     <monty_x
        bcc     .coarse_enemy_left
        sec
        sbc     <monty_x
        cmp     #12
        bcc     .coarse_vertical
        clc
        rts
.coarse_enemy_left:
        lda     <monty_x
        sec
        sbc     enemy_col_enemy_x
        cmp     #12
        bcc     .coarse_vertical
        clc
        rts
.coarse_vertical:
        lda     <monty_y
        clc
        adc     #1
        sta     enemy_col_tmp
        lda     enemy_col_enemy_y
        cmp     enemy_col_tmp
        bcc     .coarse_enemy_above
        sec
        sbc     enemy_col_tmp
        cmp     #21
        bcc     .coarse_yes
        clc
        rts
.coarse_enemy_above:
        lda     enemy_col_tmp
        sec
        sbc     enemy_col_enemy_y
        cmp     #21
        bcc     .coarse_yes
        clc
        rts
.coarse_yes:
        sec
        rts

.select_monty_source:
        lda     <monty_sprite_last_mode
        cmp     #2
        beq     .monty_jump
        cmp     #1
        beq     .monty_climb

        lda     <monty_anim_frame
        and     #3
        tax
        lda     <monty_facing
        bmi     .monty_walk_l
        lda     monty_walk_r_lo,x
        sta     <_bp
        lda     monty_walk_r_hi,x
        sta     <_bp+1
        ldy     monty_walk_r_bank,x
        rts
.monty_walk_l:
        lda     monty_walk_l_lo,x
        sta     <_bp
        lda     monty_walk_l_hi,x
        sta     <_bp+1
        ldy     monty_walk_l_bank,x
        rts

.monty_climb:
        lda     <monty_anim_frame
        and     #3
        tax
        lda     monty_climb_lo,x
        sta     <_bp
        lda     monty_climb_hi,x
        sta     <_bp+1
        ldy     monty_climb_bank,x
        rts

.monty_jump:
        lda     <monty_anim_frame
        cmp     #12
        bcc     .jump_index_ok
        lda     #11
.jump_index_ok:
        tax
        lda     <monty_facing
        bmi     .monty_jump_l
        lda     monty_sault_r_lo,x
        sta     <_bp
        lda     monty_sault_r_hi,x
        sta     <_bp+1
        ldy     monty_sault_r_bank,x
        rts
.monty_jump_l:
        lda     monty_sault_l_lo,x
        sta     <_bp
        lda     monty_sault_l_hi,x
        sta     <_bp+1
        ldy     monty_sault_l_bank,x
        rts

; Exact C64 enemy frame: reverse uses 0..3, forward uses 4..7.
.select_enemy_source:
        ldx     enemy_col_state
        lda     enemy_state_tbl+4,x
        and     #$80
        bne     .enemy_reverse_group
        lda     #4
        bra     .enemy_group_ready
.enemy_reverse_group:
        cla
.enemy_group_ready:
        sta     enemy_col_frame
        ldy     enemy_col_slot
        lda     enemy_anim_timer_tbl,y
        and     #$06
        lsr     a
        clc
        adc     enemy_col_frame
        sta     enemy_col_frame

        ldx     enemy_col_state
        lda     enemy_state_tbl+3,x
        cmp     #$09
        bne     .enemy_not09
        lda     #<enemy_type09_patterns
        sta     <_bp
        lda     #>enemy_type09_patterns
        jsr     .add_frame_high
        ldy     #BANK(enemy_type09_patterns)
        rts
.enemy_not09:
        cmp     #$0a
        bne     .enemy_not0a
        lda     #<enemy_type0a_patterns
        sta     <_bp
        lda     #>enemy_type0a_patterns
        jsr     .add_frame_high
        ldy     #BANK(enemy_type0a_patterns)
        rts
.enemy_not0a:
        cmp     #$0b
        bne     .enemy_not0b
        lda     #<enemy_type0b_patterns
        sta     <_bp
        lda     #>enemy_type0b_patterns
        jsr     .add_frame_high
        ldy     #BANK(enemy_type0b_patterns)
        rts
.enemy_not0b:
        cmp     #$0e
        bne     .enemy_not0e
        lda     #<enemy_type0e_patterns
        sta     <_bp
        lda     #>enemy_type0e_patterns
        jsr     .add_frame_high
        ldy     #BANK(enemy_type0e_patterns)
        rts
.enemy_not0e:
        cmp     #$0f
        bne     .enemy_not0f
        lda     #<enemy_type0f_patterns
        sta     <_bp
        lda     #>enemy_type0f_patterns
        jsr     .add_frame_high
        ldy     #BANK(enemy_type0f_patterns)
        rts
.enemy_not0f:
        cmp     #$14
        bne     .enemy_not14
        lda     #<enemy_type14_patterns
        sta     <_bp
        lda     #>enemy_type14_patterns
        jsr     .add_frame_high
        ldy     #BANK(enemy_type14_patterns)
        rts
.enemy_not14:
        cmp     #$15
        bne     .enemy_not15
        lda     #<enemy_type15_patterns
        sta     <_bp
        lda     #>enemy_type15_patterns
        jsr     .add_frame_high
        ldy     #BANK(enemy_type15_patterns)
        rts
.enemy_not15:
        cmp     #$16
        bne     .enemy_not16
        lda     #<enemy_type16_patterns
        sta     <_bp
        lda     #>enemy_type16_patterns
        jsr     .add_frame_high
        ldy     #BANK(enemy_type16_patterns)
        rts
.enemy_not16:
        cmp     #$18
        bne     .enemy_not18
        lda     #<enemy_type18_patterns
        sta     <_bp
        lda     #>enemy_type18_patterns
        jsr     .add_frame_high
        ldy     #BANK(enemy_type18_patterns)
        rts
.enemy_not18:
        cmp     #$19
        bne     .enemy_not19
        lda     #<enemy_type19_patterns
        sta     <_bp
        lda     #>enemy_type19_patterns
        jsr     .add_frame_high
        ldy     #BANK(enemy_type19_patterns)
        rts
.enemy_not19:
        cmp     #$1b
        bne     .enemy_type1d
        lda     #<enemy_type1b_patterns
        sta     <_bp
        lda     #>enemy_type1b_patterns
        jsr     .add_frame_high
        ldy     #BANK(enemy_type1b_patterns)
        rts
.enemy_type1d:
        lda     #<enemy_type1d_patterns
        sta     <_bp
        lda     #>enemy_type1d_patterns
        jsr     .add_frame_high
        ldy     #BANK(enemy_type1d_patterns)
        rts

.add_frame_high:
        sta     enemy_col_tmp
        lda     enemy_col_frame
        asl     a
        clc
        adc     enemy_col_tmp
        sta     <_bp+1
        rts

; PCE frame -> compact C64-style 24x21 occupancy mask.
; Frame layout is TL,TR,BL,BR; plane 0 contains all opaque pixels.
.convert_monty_mask:
        lda     <_bp
        clc
        adc     #$80
        sta     <_di
        lda     <_bp+1
        adc     #0
        sta     <_di+1

        ldx     #0
        cly
        lda     #16
        sta     enemy_col_rows
.cm_top:
        lda     [_bp],y
        sta     enemy_col_tmp
        iny
        lda     [_bp],y
        sta     enemy_col_monty_mask,x
        inx
        lda     enemy_col_tmp
        sta     enemy_col_monty_mask,x
        inx
        lda     [_di],y
        sta     enemy_col_monty_mask,x
        inx
        iny
        dec     enemy_col_rows
        bne     .cm_top

        inc     <_bp+1
        inc     <_di+1
        cly
        lda     #5
        sta     enemy_col_rows
.cm_bottom:
        lda     [_bp],y
        sta     enemy_col_tmp
        iny
        lda     [_bp],y
        sta     enemy_col_monty_mask,x
        inx
        lda     enemy_col_tmp
        sta     enemy_col_monty_mask,x
        inx
        lda     [_di],y
        sta     enemy_col_monty_mask,x
        inx
        iny
        dec     enemy_col_rows
        bne     .cm_bottom
        rts

.convert_enemy_mask:
        lda     <_bp
        clc
        adc     #$80
        sta     <_di
        lda     <_bp+1
        adc     #0
        sta     <_di+1

        ldx     #0
        cly
        lda     #16
        sta     enemy_col_rows
.ce_top:
        lda     [_bp],y
        sta     enemy_col_tmp
        iny
        lda     [_bp],y
        sta     enemy_col_enemy_mask,x
        inx
        lda     enemy_col_tmp
        sta     enemy_col_enemy_mask,x
        inx
        lda     [_di],y
        sta     enemy_col_enemy_mask,x
        inx
        iny
        dec     enemy_col_rows
        bne     .ce_top

        inc     <_bp+1
        inc     <_di+1
        cly
        lda     #5
        sta     enemy_col_rows
.ce_bottom:
        lda     [_bp],y
        sta     enemy_col_tmp
        iny
        lda     [_bp],y
        sta     enemy_col_enemy_mask,x
        inx
        lda     enemy_col_tmp
        sta     enemy_col_enemy_mask,x
        inx
        lda     [_di],y
        sta     enemy_col_enemy_mask,x
        inx
        iny
        dec     enemy_col_rows
        bne     .ce_bottom
        rts

; Exact opaque-pixel overlap for two unexpanded 24x21 sprites.
; Both internal X values are half VIC X; Monty VIC Y is monty_y+1.
.opaque_overlap:
        lda     enemy_col_enemy_x
        cmp     <monty_x
        bcc     .enemy_left
        sec
        sbc     <monty_x
        cmp     #12
        bcc     .x_right_ok
        jmp     .no_overlap
.x_right_ok:
        asl     a
        sta     enemy_col_shift
        stz     enemy_col_shift_side
        bra     .vertical
.enemy_left:
        lda     <monty_x
        sec
        sbc     enemy_col_enemy_x
        cmp     #12
        bcc     .x_left_ok
        jmp     .no_overlap
.x_left_ok:
        asl     a
        sta     enemy_col_shift
        lda     #1
        sta     enemy_col_shift_side

.vertical:
        lda     <monty_y
        clc
        adc     #1
        sta     enemy_col_tmp
        lda     enemy_col_enemy_y
        cmp     enemy_col_tmp
        bcc     .enemy_above

        sec
        sbc     enemy_col_tmp
        cmp     #21
        bcc     .y_below_ok
        jmp     .no_overlap
.y_below_ok:
        sta     enemy_col_mrow
        stz     enemy_col_erow
        lda     #21
        sec
        sbc     enemy_col_mrow
        sta     enemy_col_rows
        bra     .make_ptrs

.enemy_above:
        lda     enemy_col_tmp
        sec
        sbc     enemy_col_enemy_y
        cmp     #21
        bcc     .y_above_ok
        jmp     .no_overlap
.y_above_ok:
        sta     enemy_col_erow
        stz     enemy_col_mrow
        lda     #21
        sec
        sbc     enemy_col_erow
        sta     enemy_col_rows

.make_ptrs:
        lda     enemy_col_mrow
        sta     enemy_col_delta
        asl     a
        clc
        adc     enemy_col_delta
        clc
        adc     #<enemy_col_monty_mask
        sta     <_bp
        lda     #>enemy_col_monty_mask
        adc     #0
        sta     <_bp+1

        lda     enemy_col_erow
        sta     enemy_col_delta
        asl     a
        clc
        adc     enemy_col_delta
        clc
        adc     #<enemy_col_enemy_mask
        sta     <_di
        lda     #>enemy_col_enemy_mask
        adc     #0
        sta     <_di+1

.row_loop:
        cly
        lda     [_bp],y
        sta     enemy_col_m0
        iny
        lda     [_bp],y
        sta     enemy_col_m1
        iny
        lda     [_bp],y
        sta     enemy_col_m2

        cly
        lda     [_di],y
        sta     enemy_col_e0
        iny
        lda     [_di],y
        sta     enemy_col_e1
        iny
        lda     [_di],y
        sta     enemy_col_e2

        lda     enemy_col_shift
        sta     enemy_col_shift_work
        beq     .test_row
        lda     enemy_col_shift_side
        beq     .shift_enemy

.shift_monty:
        lsr     enemy_col_m0
        ror     enemy_col_m1
        ror     enemy_col_m2
        dec     enemy_col_shift_work
        bne     .shift_monty
        bra     .test_row

.shift_enemy:
        lsr     enemy_col_e0
        ror     enemy_col_e1
        ror     enemy_col_e2
        dec     enemy_col_shift_work
        bne     .shift_enemy

.test_row:
        lda     enemy_col_m0
        and     enemy_col_e0
        bne     .collision
        lda     enemy_col_m1
        and     enemy_col_e1
        bne     .collision
        lda     enemy_col_m2
        and     enemy_col_e2
        bne     .collision

        clc
        lda     <_bp
        adc     #3
        sta     <_bp
        bcc     .bp_ok
        inc     <_bp+1
.bp_ok:
        clc
        lda     <_di
        adc     #3
        sta     <_di
        bcc     .di_ok
        inc     <_di+1
.di_ok:
        dec     enemy_col_rows
        beq     .rows_done
        jmp     .row_loop
.rows_done:

.no_overlap:
        clc
        rts
.collision:
        sec
        rts
.endp
