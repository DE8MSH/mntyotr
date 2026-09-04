; Phase 35: keep the active room collision map mapped while gameplay physics runs.
;
; The current physics code deliberately keeps the original C64 tile/collision
; semantics and uses direct pointers to room00_collision_map / room01_collision_map.
; Those data labels can move to another HuCard bank when unrelated graphics or
; decor grow the ROM.  Mapping the selected collision bank into MPR3/MPR4 for
; the duration of monty_update_input + monty_jump_step makes those direct reads
; independent of ROM layout without copying or changing any collision bytes.

.zp
collision_saved_mpr3:   ds 1
collision_saved_mpr4:   ds 1
collision_saved_bp_lo:  ds 1
collision_saved_bp_hi:  ds 1

.code

collision_bank_enter:
        ; Physics is short; keep IRQs off while MPR3/MPR4 temporarily point at
        ; collision data so an interrupt cannot observe the temporary mapping.
        sei
        tma3
        sta     <collision_saved_mpr3
        tma4
        sta     <collision_saved_mpr4
        lda     <_bp
        sta     <collision_saved_bp_lo
        lda     <_bp+1
        sta     <collision_saved_bp_hi

        lda     <monty_room
        cmp     #1
        beq     .room01

.room00:
        lda     #<room00_collision_map
        sta     <_bp
        lda     #>room00_collision_map
        sta     <_bp+1
        ldy     #BANK(room00_collision_map)
        bra     .map

.room01:
        lda     #<room01_collision_map
        sta     <_bp
        lda     #>room01_collision_map
        sta     <_bp+1
        ldy     #BANK(room01_collision_map)

.map:
        ; Same proven mapper used by the bank-safe Monty sprite and room upload
        ; paths. It maps the selected bank into MPR3 and the following bank into
        ; MPR4, so the 640-byte collision map may straddle an 8 KiB boundary.
        call    map_bp_to_mpr34
        rts

collision_bank_exit:
        lda     <collision_saved_mpr4
        tam4
        lda     <collision_saved_mpr3
        tam3
        lda     <collision_saved_bp_lo
        sta     <_bp
        lda     <collision_saved_bp_hi
        sta     <_bp+1
        cli
        rts
