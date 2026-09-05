; Pixel-accurate Room $00 enemy collision against the actual rendered frames.
; C64 latches VIC sprite/sprite collisions in $D01E.  Monty is sprite 3 and
; Room00 enemies occupy sprites 4/5, so a hit only exists where opaque 24x21
; sprite pixels overlap.  This proc reconstructs the 24x21 occupancy masks from
; the same 512-byte PCE frames already used for rendering, then performs the
; overlap in software.  No rectangular hitbox approximation is used.
;
; --newproc note: this top-level proc exits with LEAVE.  Internal JSR helpers
; use normal RTS because they return within the already-mapped MPR6 proc bank.

.bss
enemy_col_monty_mask:   ds 63
enemy_col_enemy_mask:   ds 63
enemy_col_hit:          ds 1
enemy_col_tmp:          ds 1
enemy_col_enemy_x:      ds 1
enemy_col_enemy_y:      ds 1
enemy_col_shift:        ds 1
enemy_col_shift_work:   ds 1
enemy_col_shift_side:   ds 1      ; 0=shift enemy row, 1=shift Monty row
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

.code
.proc enemy_room00_collision_update
        lda     <monty_room
        beq     .room00
        leave
.room00:
        lda     enemy_smiley_active
        ora     enemy_skate_active
        bne     .prepare
        leave

.prepare:
        stz     enemy_col_hit

        ; map/copy source frame masks without disturbing the runtime mappings
        php
        sei
        tma3
        pha
        tma4
        pha

        jsr     .select_monty_source
        call    map_bp_to_mpr34
        jsr     .convert_monty_mask

        lda     enemy_smiley_active
        beq     .try_skate
        jsr     .select_smiley_source
        call    map_bp_to_mpr34
        jsr     .convert_enemy_mask
        lda     enemy_smiley_x
        sta     enemy_col_enemy_x
        lda     enemy_smiley_y
        sta     enemy_col_enemy_y
        jsr     .opaque_overlap
        bcc     .try_skate
        lda     #1
        sta     enemy_col_hit
        bra     .restore_maps

.try_skate:
        lda     enemy_skate_active
        beq     .restore_maps
        jsr     .select_skate_source
        call    map_bp_to_mpr34
        jsr     .convert_enemy_mask
        lda     enemy_skate_x
        sta     enemy_col_enemy_x
        lda     enemy_skate_y
        sta     enemy_col_enemy_y
        jsr     .opaque_overlap
        bcc     .restore_maps
        lda     #1
        sta     enemy_col_hit

.restore_maps:
        pla
        tam4
        pla
        tam3
        plp

        lda     enemy_col_hit
        beq     .done

        ; Normal gameplay rooms have player_dead_flag=0 in the C64, therefore
        ; enemy collision dispatches event 2 (Death.ByEnemyAlive).
        lda     #2
        sta     <monty_action_counter

        ; C64 LifeLost triggers a complete room reload, which re-runs SetupRoom.
        ; Force our room-scoped enemy sync to do the same after game_life_reload.
        lda     #$ff
        sta     enemy_smiley_last_room
.done:
        leave

; -----------------------------------------------------------------------------
; Select the exact Monty PCE frame currently on-screen.  Existing pointer/bank
; tables in monty_sprite.asm are reused, so collision cannot drift from render.
; Returns _bp=frame pointer, Y=frame bank.
; -----------------------------------------------------------------------------
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

; Enemy files are four contiguous 512-byte frames.  map_bp_to_mpr34 maps the
; base bank plus its successor, so high-byte +2/frame remains contiguous even
; when the 2 KiB payload crosses an 8 KiB ROM-bank boundary.
.select_smiley_source:
        lda     #<enemy00_smiley_patterns
        sta     <_bp
        lda     enemy_smiley_anim
        and     #$06
        lsr     a
        asl     a                       ; frame * $0200 -> high-byte delta 0,2,4,6
        clc
        adc     #>enemy00_smiley_patterns
        sta     <_bp+1
        ldy     #BANK(enemy00_smiley_patterns)
        rts

.select_skate_source:
        lda     #<enemy00_skate_patterns
        sta     <_bp
        lda     enemy_skate_anim
        and     #$06
        lsr     a
        asl     a
        clc
        adc     #>enemy00_skate_patterns
        sta     <_bp+1
        ldy     #BANK(enemy00_skate_patterns)
        rts

; -----------------------------------------------------------------------------
; PCE frame -> compact C64-style 24x21 occupancy mask.
; Frame layout is TL,TR,BL,BR 16x16 tiles; plane 0 contains all opaque pixels.
; Each output row is 3 bytes, MSB first, exactly matching C64 24-pixel rows.
; -----------------------------------------------------------------------------
.convert_monty_mask:
        ; _di = top-right tile = _bp + $0080
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
        lda     [_bp],y                 ; left tile plane0 low byte
        sta     enemy_col_tmp
        iny
        lda     [_bp],y                 ; left tile plane0 high byte = pixels 0..7
        sta     enemy_col_monty_mask,x
        inx
        lda     enemy_col_tmp           ; low byte = pixels 8..15
        sta     enemy_col_monty_mask,x
        inx
        lda     [_di],y                 ; right high byte = pixels 16..23
        sta     enemy_col_monty_mask,x
        inx
        iny
        dec     enemy_col_rows
        bne     .cm_top

        ; bottom-left/right tiles are +$0100 from their top counterparts
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

; -----------------------------------------------------------------------------
; Exact opaque-pixel overlap for two unexpanded 24x21 sprites.
; Internal X values are half VIC X for both Monty and enemies, so a difference
; of N internal units equals 2N visible pixels. Monty VIC Y is monty_y+1;
; enemy Y is already the VIC value written by Enemies.ProcessSlot.
; Returns C=1 collision, C=0 clear.
; -----------------------------------------------------------------------------
.opaque_overlap:
        ; horizontal separation / which row mask must shift right
        lda     enemy_col_enemy_x
        cmp     <monty_x
        bcc     .enemy_left
        sec
        sbc     <monty_x
        cmp     #12                     ; 12 half-pixels = full 24px width
        bcc     .x_right_ok
        jmp     .no_overlap
.x_right_ok:
        asl     a
        sta     enemy_col_shift
        stz     enemy_col_shift_side    ; enemy starts to the right
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
        sta     enemy_col_shift_side    ; Monty starts to the right

.vertical:
        lda     <monty_y
        clc
        adc     #1                      ; ProcessSprites writes Monty VIC Y = y+1
        sta     enemy_col_tmp
        lda     enemy_col_enemy_y
        cmp     enemy_col_tmp
        bcc     .enemy_above

        sec
        sbc     enemy_col_tmp           ; enemy below Monty
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
        ; _bp = monty_mask + 3*monty_start_row
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

        ; _di = enemy_mask + 3*enemy_start_row
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

        ; advance both 63-byte RAM-mask pointers by one 3-byte row
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
