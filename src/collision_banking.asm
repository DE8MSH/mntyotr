; Phase 49 collision banking.
; Room $00 keeps its proven ROM mapping path. Room $01 now owns a mutable RAM
; collision map so the original rising-cloud code-8 strip can move at runtime.
; Tail rooms $02+ continue to share the 648-byte Room02 RAM collision/property
; cache, refilled on room entry.
;
; For every tail room above $02, collision_bank_enter temporarily shadows
; monty_room as $02 while movement and the swept jump collision path run.
; collision_actual_room preserves the real room id for edge guards and is
; restored before world navigation.

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
        bcc     .select_room
        ; Active tail rooms have already copied their collision payload into
        ; the shared room02_* RAM cache. Shadow only the id for physics.
        lda     #2
        sta     <monty_room
.select_room:
        lda     <monty_room
        cmp     #2
        beq     .ram_ready
        cmp     #1
        beq     .ram_ready

.room00:
        lda     #<room00_collision_map
        sta     <_bp
        lda     #>room00_collision_map
        sta     <_bp+1
        ldy     #BANK(room00_collision_map)
        call    map_bp_to_mpr34
.ram_ready:
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
