; Phase 50: shared death/life/room-respawn foundation.
;
; C64 Monty.Death.LifeLost decrements lives, restores the saved room-entry
; position and reloads the current room. The complete death animations/game-over
; sequence are still pending, but hazards, lift squash and enemies now share the
; correct gameplay consequence instead of leaving Monty in a softlocked state.

        ; Original hi-score Easter-egg state is shared by specials, piledrivers,
        ; C5 and the ordinary death dispatcher.
        include "easter_egg_runtime.asm"

        ; Room-scoped seed shims/table runtimes reuse the shared enemy movement,
        ; SAT and collision engine. Together these cover all original room IDs.
        include "enemy_room07_runtime.asm"
        include "enemy_room0608_runtime.asm"
        include "enemy_room09_0e_runtime.asm"
        include "enemy_room10_1f_runtime.asm"
        include "enemy_room20_33_runtime.asm"

        ; Late-game content is kept in small source-derived helpers so the
        ; proven early-room runtimes remain stable.
        include "special_item_late_runtime.asm"
        include "piledriver_late_runtime.asm"
        include "teleporter_runtime.asm"
        include "scripted_transition_runtime.asm"
        include "c5_cheat_runtime.asm"

.zp
game_lives:             ds 1
game_checkpoint_room:   ds 1
game_checkpoint_x:      ds 1
game_checkpoint_y:      ds 1
game_life_last_room:    ds 1
game_respawn_pending:   ds 1

.code

; Public game-life entry points are procedures so --newproc can relocate them
; instead of consuming the fixed HOME/MPR7 window as late-game systems grow.
.proc game_life_init
        lda     #5                  ; C64 STARTING_LIVES
        sta     <game_lives
        lda     #$ff
        sta     <game_life_last_room
        stz     <game_respawn_pending
        call    enemy_room10_1f_palette_init
        call    gem_init
        call    piledriver_late_init
        call    teleporter_init
        call    scripted_transition_init
        call    game_life_room_sync
        leave
.endp

; Call after a successful room load / at cold start. The transition code has
; already installed the C64 edge spawn ($15/$9B/$4C/$DA), so this is the exact
; position to which a life loss in that room should return.
.proc game_life_room_sync
        ; enemy_smiley_room_sync runs immediately before this routine in the
        ; main loop. It clears unsupported legacy slots first; room-specific
        ; seed/table passes then rebuild the exact original C64 records.
        call    enemy_room0608_room_sync
        call    enemy_room07_room_sync
        call    enemy_room09_0e_room_sync
        call    enemy_room10_1f_room_sync
        call    enemy_room20_33_room_sync
        call    special_item_late_room_sync
        call    piledriver_late_room_sync
        call    teleporter_room_sync
        lda     <monty_room
        cmp     <game_life_last_room
        bne     .new_room
        leave
.new_room:
        sta     <game_life_last_room
        sta     <game_checkpoint_room
        lda     <monty_x
        sta     <game_checkpoint_x
        lda     <monty_y
        sta     <game_checkpoint_y
        call    gem_draw_room
        leave
.endp

; C=1 if a death was consumed and the caller must skip normal world resolution.
; This routine is --newproc-relocated so Bank 0 keeps enough thunk space for
; subsequent rooms/systems.
.proc game_life_check
        ; The original collectible collision pass runs every gameplay tick.
        ; Collection is persistent across same-room death reloads.
        call    gem_update

        lda     <monty_action_counter
        cmp     #2
        beq     .death
        cmp     #3
        beq     .death
        cmp     #4
        beq     .death
        cmp     #5
        beq     .death
        cmp     #7
        beq     .death
        clc
        leave
.death:
        ; Original cake cheat: bit 7 suppresses ordinary deaths. Completion and
        ; non-death action values never enter this dispatcher, matching C64 flow.
        lda     <cheat_mode
        bmi     .cheat_survives
        stz     <monty_action_counter
        lda     <game_lives
        beq     .reload
        dec     <game_lives
        bra     .reload
.cheat_survives:
        stz     <monty_action_counter
        clc
        leave

.reload:
        ; Full GAME OVER presentation is a later subsystem. Keep the current
        ; development ROM testable: when the fifth life is consumed, refill the
        ; counter and still perform the normal room-entry respawn.
        lda     <game_lives
        bne     .restore
        lda     #5
        sta     <game_lives
.restore:
        lda     <game_checkpoint_room
        sta     <monty_room
        sta     <world_pending_room
        lda     <game_checkpoint_x
        sta     <monty_x
        lda     <game_checkpoint_y
        sta     <monty_y
        stz     <monty_room_exit
        stz     <monty_jump_phase
        stz     <monty_jump_index
        stz     <monty_falling
        stz     <monty_saved_left
        stz     <monty_saved_right
        stz     <monty_climbing
        stz     <moving_lift_contains
        stz     <rising_bollard_active
        lda     #1
        sta     <game_respawn_pending
        sec
        leave
.endp

; Reload graphics/collision/mechanisms after game_life_check returns C=1.
.proc game_life_reload
        call    room_load_pending_extended
        call    gem_draw_room
        ; C64 room reload reruns every room-scoped setup routine, including the
        ; complete four-slot enemy SetupRoom pass. Invalidate all helper caches.
        lda     #$ff
        sta     <rising_cloud_last_room
        sta     <rising_bollard_last_room
        sta     <moving_lift_last_room
        sta     enemy_smiley_last_room
        sta     enemy_room09_0e_last_room
        sta     enemy_room10_1f_last_room
        sta     enemy_room20_33_last_room
        sta     special_item_last_room
        sta     special_item_late_last_room
        sta     late_pile_last_room
        sta     teleporter_last_room
        call    rising_cloud_room_sync
        call    rising_bollard_room_sync
        call    moving_lift_room_sync
        stz     <game_respawn_pending
        leave
.endp
