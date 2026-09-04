; Phase 41: rooms $00/$01 keep their proven ROM mapping path. Tail rooms
; $02/$03 use the same 648-byte RAM collision/property cache, refilled on room
; entry. Physics itself still addresses the established room02_* RAM labels.
;
; For Room $03 only, collision_bank_enter temporarily shadows monty_room as $02
; while monty_update_input/monty_jump_step run. collision_actual_room preserves
; the real room id for edge guards and is restored before world navigation.

.zp
collision_saved_mpr3:   ds 1
collision_saved_mpr4:   ds 1
collision_saved_bp_lo:  ds 1
collision_saved_bp_hi:  ds 1
collision_actual_room:  ds 1

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
        sta     <collision_actual_room
        cmp     #3
        bne     .select_room
        ; Room $03 has already copied its collision payload into the shared
        ; room02_* RAM cache. Shadow the id only for the unchanged physics code.
        lda     #2
        sta     <monty_room
.select_room:
        lda     <monty_room
        cmp     #2
        beq     .tail_room_ram
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
.tail_room_ram:
        rts

collision_bank_exit:
        lda     <collision_actual_room
        sta     <monty_room
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
