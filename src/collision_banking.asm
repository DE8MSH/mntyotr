; Phase 38a: keep Room $00/$01 collision banks mapped during physics, but use
; a RAM-backed collision/property cache for Room $02.
;
; Room $02 lives in the ROM-tail area. Mapping that far bank across MPR3/MPR4
; for the whole physics slice can hide runtime code on this build, which leaves
; Monty apparently frozen immediately after entering the room. Room $02 is
; therefore copied once on room load into RAM; physics keeps the same direct
; room02_collision_map / room02_tile_properties labels and semantics.

.zp
collision_saved_mpr3:   ds 1
collision_saved_mpr4:   ds 1
collision_saved_bp_lo:  ds 1
collision_saved_bp_hi:  ds 1

.bss
room02_collision_map:   ds 640
room02_tile_properties: ds 8

.code

collision_bank_enter:
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
        cmp     #2
        beq     .room02_ram
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
        call    map_bp_to_mpr34
.room02_ram:
        ; Room $02 direct pointers target RAM, so leave the normal runtime MPRs
        ; untouched while monty_update_input/monty_jump_step execute.
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
