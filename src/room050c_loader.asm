; Compact table-driven loader for tail rooms $05-$09 plus $0C.
; Rooms $06-$08 complete the upper house/Pie Are Square route. Far-pointer
; tables stay in code space so selecting an asset never depends on the ROM bank
; currently mapped into MPR3/MPR4. Bulk assets remain in the ROM tail.

.zp
room_ext_index: ds 1

.code

room_load_pending_extended:
        lda     <world_pending_room
        cmp     #$05
        bcc     .core_loader
        cmp     #$0a
        bcc     .range_05_09
        cmp     #$0c
        bne     .core_loader
        lda     #5
        bra     .have_index
.range_05_09:
        sec
        sbc     #$05
.have_index:
        sta     <room_ext_index

        ; Upload this room's nine custom character patterns.
        ldx     <room_ext_index
        lda     room_ext_patterns_lo,x
        sta     <_bp
        lda     room_ext_patterns_hi,x
        sta     <_bp+1
        ldy     room_ext_patterns_bank,x
        call    room_upload_9_patterns

        ; Draw its exact 36x20 C64 playfield window.
        ldx     <room_ext_index
        lda     room_ext_bat_lo,x
        sta     <_bp
        lda     room_ext_bat_hi,x
        sta     <_bp+1
        ldy     room_ext_bat_bank,x
        call    room_draw_native_36x20

        ; Cache 640 collision cells + 8 tile properties in the shared RAM area.
        ldx     <room_ext_index
        lda     room_ext_collision_lo,x
        sta     <_bp
        lda     room_ext_collision_hi,x
        sta     <_bp+1
        ldy     room_ext_collision_bank,x
        call    room_tail_cache_collision

        lda     <world_pending_room
        sta     <monty_room
        stz     <world_transition_ready
        sec
        rts

.core_loader:
        jmp     room_load_pending

; index 0..5 = rooms $05,$06,$07,$08,$09,$0C.
; These descriptors replace dozens of room-specific wrapper instructions,
; leaving Bank 0 headroom while the world continues to grow.
room_ext_patterns_lo:
        db <room05_patterns,<room06_patterns,<room07_patterns,<room08_patterns,<room09_patterns,<room0c_patterns
room_ext_patterns_hi:
        db >room05_patterns,>room06_patterns,>room07_patterns,>room08_patterns,>room09_patterns,>room0c_patterns
room_ext_patterns_bank:
        db BANK(room05_patterns),BANK(room06_patterns),BANK(room07_patterns),BANK(room08_patterns),BANK(room09_patterns),BANK(room0c_patterns)

room_ext_bat_lo:
        db <room05_screen_bat,<room06_screen_bat,<room07_screen_bat,<room08_screen_bat,<room09_screen_bat,<room0c_screen_bat
room_ext_bat_hi:
        db >room05_screen_bat,>room06_screen_bat,>room07_screen_bat,>room08_screen_bat,>room09_screen_bat,>room0c_screen_bat
room_ext_bat_bank:
        db BANK(room05_screen_bat),BANK(room06_screen_bat),BANK(room07_screen_bat),BANK(room08_screen_bat),BANK(room09_screen_bat),BANK(room0c_screen_bat)

room_ext_collision_lo:
        db <room05_collision_map_rom,<room06_collision_map_rom,<room07_collision_map_rom,<room08_collision_map_rom,<room09_collision_map_rom,<room0c_collision_map_rom
room_ext_collision_hi:
        db >room05_collision_map_rom,>room06_collision_map_rom,>room07_collision_map_rom,>room08_collision_map_rom,>room09_collision_map_rom,>room0c_collision_map_rom
room_ext_collision_bank:
        db BANK(room05_collision_map_rom),BANK(room06_collision_map_rom),BANK(room07_collision_map_rom),BANK(room08_collision_map_rom),BANK(room09_collision_map_rom),BANK(room0c_collision_map_rom)
