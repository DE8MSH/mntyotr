; Compact table-driven loader for sparse ROM-tail rooms.
; Bulk assets remain banked; this dispatch is --newproc-relocated so extending
; the descriptor tables no longer consumes precious Bank-0 gameplay code.

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

; Sparse descriptor index. Adding the remaining C64 rooms now only extends these
; tables; no room-specific loader code is required.
ROOM_EXT_COUNT = 7
room_ext_ids:
        db $05,$06,$07,$08,$09,$0c,$0f

room_ext_patterns_lo:
        db <room05_patterns,<room06_patterns,<room07_patterns,<room08_patterns,<room09_patterns,<room0c_patterns,<room0f_patterns
room_ext_patterns_hi:
        db >room05_patterns,>room06_patterns,>room07_patterns,>room08_patterns,>room09_patterns,>room0c_patterns,>room0f_patterns
room_ext_patterns_bank:
        db BANK(room05_patterns),BANK(room06_patterns),BANK(room07_patterns),BANK(room08_patterns),BANK(room09_patterns),BANK(room0c_patterns),BANK(room0f_patterns)

room_ext_bat_lo:
        db <room05_screen_bat,<room06_screen_bat,<room07_screen_bat,<room08_screen_bat,<room09_screen_bat,<room0c_screen_bat,<room0f_screen_bat
room_ext_bat_hi:
        db >room05_screen_bat,>room06_screen_bat,>room07_screen_bat,>room08_screen_bat,>room09_screen_bat,>room0c_screen_bat,>room0f_screen_bat
room_ext_bat_bank:
        db BANK(room05_screen_bat),BANK(room06_screen_bat),BANK(room07_screen_bat),BANK(room08_screen_bat),BANK(room09_screen_bat),BANK(room0c_screen_bat),BANK(room0f_screen_bat)

room_ext_collision_lo:
        db <room05_collision_map_rom,<room06_collision_map_rom,<room07_collision_map_rom,<room08_collision_map_rom,<room09_collision_map_rom,<room0c_collision_map_rom,<room0f_collision_map_rom
room_ext_collision_hi:
        db >room05_collision_map_rom,>room06_collision_map_rom,>room07_collision_map_rom,>room08_collision_map_rom,>room09_collision_map_rom,>room0c_collision_map_rom,>room0f_collision_map_rom
room_ext_collision_bank:
        db BANK(room05_collision_map_rom),BANK(room06_collision_map_rom),BANK(room07_collision_map_rom),BANK(room08_collision_map_rom),BANK(room09_collision_map_rom),BANK(room0c_collision_map_rom),BANK(room0f_collision_map_rom)
