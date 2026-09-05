; Phase 50: shared death/life/room-respawn foundation.
;
; C64 Monty.Death.LifeLost decrements lives, restores the saved room-entry
; position and reloads the current room. The complete death animations/game-over
; sequence are still pending, but hazards, lift squash and enemies now share the
; correct gameplay consequence instead of leaving Monty in a softlocked state.

.zp
game_lives:             ds 1
game_checkpoint_room:   ds 1
game_checkpoint_x:      ds 1
game_checkpoint_y:      ds 1
game_life_last_room:    ds 1
game_respawn_pending:   ds 1

.code

game_life_init:
        lda     #5                  ; C64 STARTING_LIVES
        sta     <game_lives
        lda     #$ff
        sta     <game_life_last_room
        stz     <game_respawn_pending
        jmp     game_life_room_sync

; Call after a successful room load / at cold start. The transition code has
; already installed the C64 edge spawn ($15/$9B/$4C/$DA), so this is the exact
; position to which a life loss in that room should return.
game_life_room_sync:
        lda     <monty_room
        cmp     <game_life_last_room
        bne     .new_room
        rts
.new_room:
        sta     <game_life_last_room
        sta     <game_checkpoint_room
        lda     <monty_x
        sta     <game_checkpoint_x
        lda     <monty_y
        sta     <game_checkpoint_y
        rts

; C=1 if a death was consumed and the caller must skip normal world resolution.
; Current action_counter values used by the port/reference:
;   2 enemy hit/alive, 3 lift squash, 4 piledriver, 5 property-4 hazard,
;   7 enemy hit/dead.  Event 6 is completion in the C64 dispatch and is NOT death.
game_life_check:
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
        rts
.death:
        stz     <monty_action_counter
        lda     <game_lives
        beq     .reload
        dec     <game_lives

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
        rts

; Reload graphics/collision/mechanisms after game_life_check returns C=1.
game_life_reload:
        call    room_load_pending_extended
        ; C64 room reload reruns every room-scoped setup routine, including the
        ; complete four-slot enemy SetupRoom pass.
        lda     #$ff
        sta     <rising_cloud_last_room
        sta     <rising_bollard_last_room
        sta     <moving_lift_last_room
        sta     enemy_smiley_last_room
        call    rising_cloud_room_sync
        call    rising_bollard_room_sync
        call    moving_lift_room_sync
        stz     <game_respawn_pending
        rts
