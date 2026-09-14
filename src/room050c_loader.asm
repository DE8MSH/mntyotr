; Compact table-driven loader for sparse ROM-tail rooms.
; Bulk assets remain banked; this dispatch is --newproc-relocated so extending
; the descriptor tables no longer consumes precious Bank-0 gameplay code.

        include "room10_1f_decor_loader.asm"
        include "room20_33_decor_loader.asm"

.zp
room_ext_index: ds 1

.code

; C=1 when a supported pending room was committed.
.proc room_load_pending_extended
        lda     <world_pending_room
        ldx     #0
.lookup:
        cmp     room_ext_ids,x
        beq     .found
        inx
        cpx     #ROOM_EXT_COUNT
        bne     .lookup

        ; Core/legacy rooms remain handled by room_load_pending.
        call    room_load_pending
        bcs     .core_supported
        clc
        leave
.core_supported:
        sec
        leave

.found:
        stx     <room_ext_index

        ; Upload this room's nine custom character patterns.
        lda     room_ext_patterns_lo,x
        sta     <_bp
        lda     room_ext_patterns_hi,x
        sta     <_bp+1
        ldy     room_ext_patterns_bank,x
        call    room_upload_9_patterns

        ; Original Decor.room_list payloads are split into two compact bank-safe
        ; tables. Rooms without static decor return immediately from both calls.
        call    room10_1f_upload_decor
        call    room20_33_upload_decor

        ; Draw its exact 36x20 C64 playfield window.
        ldx     <room_ext_index
        lda     room_ext_bat_lo,x
        sta     <_bp
        lda     room_ext_bat_hi,x
        sta     <_bp+1
        ldy     room_ext_bat_bank,x
        call    room_draw_native_36x20

        ; Cache 640 collision cells + 8 tile properties in shared RAM.
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
        leave
.endp

; Sparse descriptor index. Rooms $10-$33 reuse the same bank-safe generic path.
ROOM_EXT_COUNT = 43
room_ext_ids:
        db $05,$06,$07,$08,$09,$0c,$0f,$10
        db $11,$12,$13,$14,$15,$16,$17,$18
        db $19,$1a,$1b,$1c,$1d,$1e,$1f,$20
        db $21,$22,$23,$24,$25,$26,$27,$28
        db $29,$2a,$2b,$2c,$2d,$2e,$2f,$30
        db $31,$32,$33

room_ext_patterns_lo:
        db <room05_patterns,<room06_patterns,<room07_patterns,<room08_patterns,<room09_patterns,<room0c_patterns,<room0f_patterns
        db <room10_patterns,<room11_patterns,<room12_patterns,<room13_patterns,<room14_patterns,<room15_patterns,<room16_patterns
        db <room17_patterns,<room18_patterns,<room19_patterns,<room1a_patterns,<room1b_patterns,<room1c_patterns,<room1d_patterns
        db <room1e_patterns,<room1f_patterns,<room20_patterns,<room21_patterns,<room22_patterns,<room23_patterns,<room24_patterns
        db <room25_patterns,<room26_patterns,<room27_patterns,<room28_patterns,<room29_patterns,<room2a_patterns,<room2b_patterns
        db <room2c_patterns,<room2d_patterns,<room2e_patterns,<room2f_patterns,<room30_patterns,<room31_patterns,<room32_patterns
        db <room33_patterns

room_ext_patterns_hi:
        db >room05_patterns,>room06_patterns,>room07_patterns,>room08_patterns,>room09_patterns,>room0c_patterns,>room0f_patterns
        db >room10_patterns,>room11_patterns,>room12_patterns,>room13_patterns,>room14_patterns,>room15_patterns,>room16_patterns
        db >room17_patterns,>room18_patterns,>room19_patterns,>room1a_patterns,>room1b_patterns,>room1c_patterns,>room1d_patterns
        db >room1e_patterns,>room1f_patterns,>room20_patterns,>room21_patterns,>room22_patterns,>room23_patterns,>room24_patterns
        db >room25_patterns,>room26_patterns,>room27_patterns,>room28_patterns,>room29_patterns,>room2a_patterns,>room2b_patterns
        db >room2c_patterns,>room2d_patterns,>room2e_patterns,>room2f_patterns,>room30_patterns,>room31_patterns,>room32_patterns
        db >room33_patterns

room_ext_patterns_bank:
        db BANK(room05_patterns),BANK(room06_patterns),BANK(room07_patterns),BANK(room08_patterns),BANK(room09_patterns),BANK(room0c_patterns),BANK(room0f_patterns)
        db BANK(room10_patterns),BANK(room11_patterns),BANK(room12_patterns),BANK(room13_patterns),BANK(room14_patterns),BANK(room15_patterns),BANK(room16_patterns)
        db BANK(room17_patterns),BANK(room18_patterns),BANK(room19_patterns),BANK(room1a_patterns),BANK(room1b_patterns),BANK(room1c_patterns),BANK(room1d_patterns)
        db BANK(room1e_patterns),BANK(room1f_patterns),BANK(room20_patterns),BANK(room21_patterns),BANK(room22_patterns),BANK(room23_patterns),BANK(room24_patterns)
        db BANK(room25_patterns),BANK(room26_patterns),BANK(room27_patterns),BANK(room28_patterns),BANK(room29_patterns),BANK(room2a_patterns),BANK(room2b_patterns)
        db BANK(room2c_patterns),BANK(room2d_patterns),BANK(room2e_patterns),BANK(room2f_patterns),BANK(room30_patterns),BANK(room31_patterns),BANK(room32_patterns)
        db BANK(room33_patterns)

room_ext_bat_lo:
        db <room05_screen_bat,<room06_screen_bat,<room07_screen_bat,<room08_screen_bat,<room09_screen_bat,<room0c_screen_bat,<room0f_screen_bat
        db <room10_screen_bat,<room11_screen_bat,<room12_screen_bat,<room13_screen_bat,<room14_screen_bat,<room15_screen_bat,<room16_screen_bat
        db <room17_screen_bat,<room18_screen_bat,<room19_screen_bat,<room1a_screen_bat,<room1b_screen_bat,<room1c_screen_bat,<room1d_screen_bat
        db <room1e_screen_bat,<room1f_screen_bat,<room20_screen_bat,<room21_screen_bat,<room22_screen_bat,<room23_screen_bat,<room24_screen_bat
        db <room25_screen_bat,<room26_screen_bat,<room27_screen_bat,<room28_screen_bat,<room29_screen_bat,<room2a_screen_bat,<room2b_screen_bat
        db <room2c_screen_bat,<room2d_screen_bat,<room2e_screen_bat,<room2f_screen_bat,<room30_screen_bat,<room31_screen_bat,<room32_screen_bat
        db <room33_screen_bat

room_ext_bat_hi:
        db >room05_screen_bat,>room06_screen_bat,>room07_screen_bat,>room08_screen_bat,>room09_screen_bat,>room0c_screen_bat,>room0f_screen_bat
        db >room10_screen_bat,>room11_screen_bat,>room12_screen_bat,>room13_screen_bat,>room14_screen_bat,>room15_screen_bat,>room16_screen_bat
        db >room17_screen_bat,>room18_screen_bat,>room19_screen_bat,>room1a_screen_bat,>room1b_screen_bat,>room1c_screen_bat,>room1d_screen_bat
        db >room1e_screen_bat,>room1f_screen_bat,>room20_screen_bat,>room21_screen_bat,>room22_screen_bat,>room23_screen_bat,>room24_screen_bat
        db >room25_screen_bat,>room26_screen_bat,>room27_screen_bat,>room28_screen_bat,>room29_screen_bat,>room2a_screen_bat,>room2b_screen_bat
        db >room2c_screen_bat,>room2d_screen_bat,>room2e_screen_bat,>room2f_screen_bat,>room30_screen_bat,>room31_screen_bat,>room32_screen_bat
        db >room33_screen_bat

room_ext_bat_bank:
        db BANK(room05_screen_bat),BANK(room06_screen_bat),BANK(room07_screen_bat),BANK(room08_screen_bat),BANK(room09_screen_bat),BANK(room0c_screen_bat),BANK(room0f_screen_bat)
        db BANK(room10_screen_bat),BANK(room11_screen_bat),BANK(room12_screen_bat),BANK(room13_screen_bat),BANK(room14_screen_bat),BANK(room15_screen_bat),BANK(room16_screen_bat)
        db BANK(room17_screen_bat),BANK(room18_screen_bat),BANK(room19_screen_bat),BANK(room1a_screen_bat),BANK(room1b_screen_bat),BANK(room1c_screen_bat),BANK(room1d_screen_bat)
        db BANK(room1e_screen_bat),BANK(room1f_screen_bat),BANK(room20_screen_bat),BANK(room21_screen_bat),BANK(room22_screen_bat),BANK(room23_screen_bat),BANK(room24_screen_bat)
        db BANK(room25_screen_bat),BANK(room26_screen_bat),BANK(room27_screen_bat),BANK(room28_screen_bat),BANK(room29_screen_bat),BANK(room2a_screen_bat),BANK(room2b_screen_bat)
        db BANK(room2c_screen_bat),BANK(room2d_screen_bat),BANK(room2e_screen_bat),BANK(room2f_screen_bat),BANK(room30_screen_bat),BANK(room31_screen_bat),BANK(room32_screen_bat)
        db BANK(room33_screen_bat)

room_ext_collision_lo:
        db <room05_collision_map_rom,<room06_collision_map_rom,<room07_collision_map_rom,<room08_collision_map_rom,<room09_collision_map_rom,<room0c_collision_map_rom,<room0f_collision_map_rom
        db <room10_collision_map_rom,<room11_collision_map_rom,<room12_collision_map_rom,<room13_collision_map_rom,<room14_collision_map_rom,<room15_collision_map_rom,<room16_collision_map_rom
        db <room17_collision_map_rom,<room18_collision_map_rom,<room19_collision_map_rom,<room1a_collision_map_rom,<room1b_collision_map_rom,<room1c_collision_map_rom,<room1d_collision_map_rom
        db <room1e_collision_map_rom,<room1f_collision_map_rom,<room20_collision_map_rom,<room21_collision_map_rom,<room22_collision_map_rom,<room23_collision_map_rom,<room24_collision_map_rom
        db <room25_collision_map_rom,<room26_collision_map_rom,<room27_collision_map_rom,<room28_collision_map_rom,<room29_collision_map_rom,<room2a_collision_map_rom,<room2b_collision_map_rom
        db <room2c_collision_map_rom,<room2d_collision_map_rom,<room2e_collision_map_rom,<room2f_collision_map_rom,<room30_collision_map_rom,<room31_collision_map_rom,<room32_collision_map_rom
        db <room33_collision_map_rom

room_ext_collision_hi:
        db >room05_collision_map_rom,>room06_collision_map_rom,>room07_collision_map_rom,>room08_collision_map_rom,>room09_collision_map_rom,>room0c_collision_map_rom,>room0f_collision_map_rom
        db >room10_collision_map_rom,>room11_collision_map_rom,>room12_collision_map_rom,>room13_collision_map_rom,>room14_collision_map_rom,>room15_collision_map_rom,>room16_collision_map_rom
        db >room17_collision_map_rom,>room18_collision_map_rom,>room19_collision_map_rom,>room1a_collision_map_rom,>room1b_collision_map_rom,>room1c_collision_map_rom,>room1d_collision_map_rom
        db >room1e_collision_map_rom,>room1f_collision_map_rom,>room20_collision_map_rom,>room21_collision_map_rom,>room22_collision_map_rom,>room23_collision_map_rom,>room24_collision_map_rom
        db >room25_collision_map_rom,>room26_collision_map_rom,>room27_collision_map_rom,>room28_collision_map_rom,>room29_collision_map_rom,>room2a_collision_map_rom,>room2b_collision_map_rom
        db >room2c_collision_map_rom,>room2d_collision_map_rom,>room2e_collision_map_rom,>room2f_collision_map_rom,>room30_collision_map_rom,>room31_collision_map_rom,>room32_collision_map_rom
        db >room33_collision_map_rom
room_ext_collision_bank:
        db BANK(room05_collision_map_rom),BANK(room06_collision_map_rom),BANK(room07_collision_map_rom),BANK(room08_collision_map_rom),BANK(room09_collision_map_rom),BANK(room0c_collision_map_rom),BANK(room0f_collision_map_rom)
        db BANK(room10_collision_map_rom),BANK(room11_collision_map_rom),BANK(room12_collision_map_rom),BANK(room13_collision_map_rom),BANK(room14_collision_map_rom),BANK(room15_collision_map_rom),BANK(room16_collision_map_rom)
        db BANK(room17_collision_map_rom),BANK(room18_collision_map_rom),BANK(room19_collision_map_rom),BANK(room1a_collision_map_rom),BANK(room1b_collision_map_rom),BANK(room1c_collision_map_rom),BANK(room1d_collision_map_rom)
        db BANK(room1e_collision_map_rom),BANK(room1f_collision_map_rom),BANK(room20_collision_map_rom),BANK(room21_collision_map_rom),BANK(room22_collision_map_rom),BANK(room23_collision_map_rom),BANK(room24_collision_map_rom)
        db BANK(room25_collision_map_rom),BANK(room26_collision_map_rom),BANK(room27_collision_map_rom),BANK(room28_collision_map_rom),BANK(room29_collision_map_rom),BANK(room2a_collision_map_rom),BANK(room2b_collision_map_rom)
        db BANK(room2c_collision_map_rom),BANK(room2d_collision_map_rom),BANK(room2e_collision_map_rom),BANK(room2f_collision_map_rom),BANK(room30_collision_map_rom),BANK(room31_collision_map_rom),BANK(room32_collision_map_rom)
        db BANK(room33_collision_map_rom)
