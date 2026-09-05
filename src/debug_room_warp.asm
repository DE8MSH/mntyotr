; QA room warp: press SELECT once to cycle through every currently supported room.
; This is intentionally development-facing and leaves normal movement/gameplay intact.
; PCE pad bit $04 is SELECT. A software latch makes this edge-triggered even though
; the rest of the port reads the current joypad state through joynow.
;
; The poll/warp body is a --newproc routine so Bank 0 only pays for the small
; generated thunk. Internal helpers use RTS; externally returning paths use LEAVE.

.zp
debug_room_select_latch: ds 1

.code

debug_room_warp_init:
        stz     <debug_room_select_latch
        rts

; C=1 when a room warp was performed this frame.
.proc debug_room_warp_poll
        lda     joynow
        and     #$04                    ; SELECT
        beq     .released

        lda     <debug_room_select_latch
        bne     .no_warp
        lda     #1
        sta     <debug_room_select_latch
        jsr     .warp_next
        sec
        leave

.released:
        stz     <debug_room_select_latch
.no_warp:
        clc
        leave

.warp_next:
        lda     <monty_room
        inc     a
        cmp     #$0f                    ; current supported block is $00-$0E
        bcc     .room_ok
        cla
.room_ok:
        sta     <world_pending_room
        tax

        ; Keep world topology coherent so ordinary exits work immediately after
        ; a debug warp instead of resolving from the previous room's grid cell.
        lda     debug_room_world_row,x
        sta     <world_map_row
        lda     debug_room_world_col,x
        sta     <world_exit_col

        ; QA spawn points. Room $00 retains the authentic cold-start position;
        ; other rooms use a neutral interior start used only by the test warp.
        lda     debug_room_spawn_x,x
        sta     <monty_x
        lda     debug_room_spawn_y,x
        sta     <monty_y

        stz     <monty_room_exit
        stz     <monty_jump_phase
        stz     <monty_jump_index
        stz     <monty_saved_left
        stz     <monty_saved_right
        stz     <monty_climbing
        stz     <monty_falling
        stz     <monty_is_moving
        stz     <monty_action_counter
        stz     <moving_lift_contains
        stz     <rising_bollard_active
        stz     <game_respawn_pending

        call    room_load_pending_extended

        ; Force the ordinary room-sync path to reconstruct all mutable state and
        ; make the debug spawn the new death/respawn checkpoint.
        lda     #$ff
        sta     <rising_cloud_last_room
        sta     <rising_bollard_last_room
        sta     <moving_lift_last_room
        sta     enemy_smiley_last_room
        sta     <game_life_last_room
        rts
.endp

.data
; Exact coordinates of rooms $00-$0E in Room.Data.room_exit_dest_tbl.
debug_room_world_row:
        db $02,$02,$02,$02,$02,$02,$01,$01,$01,$01,$03,$03,$03,$03,$03
debug_room_world_col:
        db $15,$14,$13,$12,$11,$10,$11,$12,$13,$14,$14,$13,$10,$11,$12

; Development-only starting points used after SELECT warps.
; $00 is the original C64 cold start. The remaining rooms use the same neutral
; interior coordinate so verification begins away from edge-transition guards.
debug_room_spawn_x:
        db $86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$86
debug_room_spawn_y:
        db $b0,$b0,$b0,$b0,$b0,$b0,$b0,$b0,$b0,$b0,$b0,$b0,$b0,$b0,$b0
