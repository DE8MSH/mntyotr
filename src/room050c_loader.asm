; Phase 46 loader extension for Rooms $05/$0C.
; Keep the already-confirmed Phase-45 room_loader.asm stable: this small
; dispatcher handles the new rooms first, then falls through to the proven
; loader for every older room.

.code

room_load_pending_extended:
        lda     <world_pending_room
        cmp     #$05
        beq     .room05
        cmp     #$0c
        beq     .room0c
        jmp     room_load_pending

.room05:
        call    room05_upload_patterns
        call    room05_draw_native
        call    room05_cache_collision
        lda     #$05
        sta     <monty_room
        stz     <world_transition_ready
        sec
        rts

.room0c:
        call    room0c_upload_patterns
        call    room0c_draw_native
        call    room0c_cache_collision
        lda     #$0c
        sta     <monty_room
        stz     <world_transition_ready
        sec
        rts

room05_cache_collision:
        lda     #<room05_collision_map_rom
        sta     <_bp
        lda     #>room05_collision_map_rom
        sta     <_bp+1
        ldy     #BANK(room05_collision_map_rom)
        jmp     room_tail_cache_collision

room0c_cache_collision:
        lda     #<room0c_collision_map_rom
        sta     <_bp
        lda     #>room0c_collision_map_rom
        sta     <_bp+1
        ldy     #BANK(room0c_collision_map_rom)
        jmp     room_tail_cache_collision

room05_upload_patterns:
        lda     #<room05_patterns
        sta     <_bp
        lda     #>room05_patterns
        sta     <_bp+1
        ldy     #BANK(room05_patterns)
        jmp     room_upload_9_patterns

room0c_upload_patterns:
        lda     #<room0c_patterns
        sta     <_bp
        lda     #>room0c_patterns
        sta     <_bp+1
        ldy     #BANK(room0c_patterns)
        jmp     room_upload_9_patterns

room05_draw_native:
        lda     #<room05_screen_bat
        sta     <_bp
        lda     #>room05_screen_bat
        sta     <_bp+1
        ldy     #BANK(room05_screen_bat)
        jmp     room_draw_native_36x20

room0c_draw_native:
        lda     #<room0c_screen_bat
        sta     <_bp
        lda     #>room0c_screen_bat
        sta     <_bp+1
        ldy     #BANK(room0c_screen_bat)
        jmp     room_draw_native_36x20
