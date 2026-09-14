; Monty on the Run - PC Engine port
; Native room graphics + PAL-rate gameplay + C64 movement/world/sprite path.

        include "platform.inc"
        include "bare-startup.asm"

        .list
        .mlist

        include "common.asm"
        include "vdc.asm"
        include "joypad.asm"
        include "room00_assets.asm"
        include "room00_native.asm"
        include "room01_assets.asm"
        include "room01_native.asm"
        include "game_clock.asm"
        include "score_runtime.asm"
        include "monty_physics.asm"
        include "jump_collision_sweep.asm"
        include "collision_banking.asm"
        include "rising_cloud.asm"
        include "rising_cloud_contact.asm"
        include "rising_cloud_sprite.asm"
        include "rising_bollard.asm"
        include "moving_lift.asm"
        include "enemy_smiley_runtime.asm"
        include "world.asm"
        include "vertical_world_edges.asm"
        include "room01_decor_loader.asm"
        include "room02_decor_loader.asm"
        include "room0a_decor_loader.asm"
        include "room_loader.asm"
        include "room050c_loader.asm"
        ; Keep the non-proc Monty sprite bridge before the large table-driven
        ; late-game runtimes so it cannot straddle the MPR7->MPR0 code wrap.
        include "monty_sprite.asm"
        include "game_life.asm"
        include "special_item_runtime.asm"
        include "special_item_sprite.asm"
        include "debug_room.asm"
        include "debug_room_warp.asm"
        include "debug_footer_visible.asm"
        include "init_game_palettes.asm"
        ; Large banked room/decor/sprite data is appended after gameplay/runtime.
        include "moving_lift_assets_tail.asm"
        include "rising_cloud_sprite_assets_tail.asm"
        include "enemy_room00_assets_tail.asm"
        include "special_item_assets_tail.asm"
        include "room01_decor_assets.asm"
        include "room02_assets_tail.asm"
        include "room03_assets_tail.asm"
        include "room04_assets_tail.asm"
        include "room05_assets_tail.asm"
        include "room09_assets_tail.asm"
        include "room0a_assets_tail.asm"
        include "room0b_assets_tail.asm"
        include "room0c_assets_tail.asm"
        include "room0d_assets_tail.asm"
        include "room0e_assets_tail.asm"
        include "room0f_assets_tail.asm"

.zp
main_jump_x_before_step:   ds 1
main_exit_before_jump:     ds 1
main_y_before_step:        ds 1

        .code

bare_main:
        call    init_352x224
        call    init_c64_video
        call    upload_room00_patterns
        call    init_game_palettes

        call    draw_room00_native
        call    game_clock_init
        call    score_init
        call    monty_physics_init
        call    world_init
        call    rising_cloud_init
        call    rising_cloud_room_sync
        call    rising_cloud_sprite_init
        call    rising_bollard_init
        call    rising_bollard_room_sync
        call    moving_lift_init
        call    moving_lift_room_sync
        ; Banked enemy init owns sprite palettes 19+ and active GFX sets.
        call    enemy_smiley_init
        call    enemy_room0f_palette_init
        call    game_life_init
        call    special_item_init
        call    debug_room_init
        call    debug_room_warp_init
        call    debug_footer_visible_draw
        call    monty_sprite_init
        call    monty_sprite_update_satb
        call    moving_lift_update_satb
        call    enemy_smiley_update_satb
        call    special_item_update_satb
        call    rising_cloud_sprite_update_satb
        call    set_dspon

main_loop:
        call    wait_vsync
        call    read_joypads

        ; QA shortcut: one SELECT press loads the next supported room immediately.
        ; Skip the gameplay tick on the warp frame so the fresh spawn cannot be
        ; consumed by a stale collision/action before room-scoped state is synced.
        call    debug_room_warp_poll
        bcc     .after_debug_room_warp
        call    rising_cloud_room_sync
        call    rising_bollard_room_sync
        call    moving_lift_room_sync
        call    enemy_smiley_room_sync
        call    special_item_room_sync
        call    game_life_room_sync
        call    debug_room_draw
        call    monty_sprite_update_satb
        call    moving_lift_update_satb
        call    enemy_smiley_update_satb
        call    special_item_update_satb
        call    rising_cloud_sprite_update_satb
        jmp     main_loop
.after_debug_room_warp:

        call    game_clock_step
        bcc     main_loop
        inc     game_tick_counter

        ; Preserve Y so the external bottom-edge helper only runs after actual
        ; downward motion, matching the C64 UpdateMovement_down semantics.
        lda     <monty_y
        sta     <main_y_before_step

        call    collision_bank_enter
        call    monty_update_input

        ; Only the confirmed outer edge at Room $00 right is special-cased
        ; before world navigation. Supported room exits otherwise remain live.
        lda     <monty_jump_phase
        beq     .after_unsupported_jump_edge
        lda     <collision_actual_room
        bne     .after_unsupported_jump_edge
        lda     <monty_room_exit
        cmp     #2
        bne     .after_unsupported_jump_edge
        lda     #$9b
        sta     <monty_x
        stz     <monty_room_exit
.after_unsupported_jump_edge:

        lda     <monty_room_exit
        sta     <main_exit_before_jump
        lda     <monty_x
        sta     <main_jump_x_before_step
        ; C64 jump deltas are consumed one pixel at a time with collision checks.
        call    monty_jump_step_swept

        lda     <main_exit_before_jump
        beq     .guard_jump_generated_exit
        sta     <monty_room_exit
        bra     .after_jump_exit_guard

.guard_jump_generated_exit:
        lda     <monty_room_exit
        cmp     #1
        beq     .guard_jump_side_exit
        cmp     #2
        bne     .after_jump_exit_guard
.guard_jump_side_exit:
        lda     <monty_jump_phase
        beq     .after_jump_exit_guard
        lda     <monty_is_moving
        bne     .after_jump_exit_guard
        lda     <main_jump_x_before_step
        sta     <monty_x
        stz     <monty_room_exit
.after_jump_exit_guard:

        ; Non-jump downward movement (fall/climb) still uses the shared helper.
        ; The swept jump routine already checks $DA after every descent pixel.
        lda     <monty_y
        cmp     <main_y_before_step
        bcc     .after_down_room_edge
        beq     .after_down_room_edge
        call    monty_check_down_room_edge
.after_down_room_edge:
        call    collision_bank_exit

        ; Dynamic mechanisms/enemy motion run with the real room id restored.
        call    rising_cloud_contact_update
        call    rising_cloud_update
        call    rising_bollard_update
        call    piledriver_late_collision_update
        call    moving_lift_update
        call    enemy_smiley_update
        call    special_item_update
        call    teleporter_update
        call    scripted_transition_update

        ; Hazards/mechanisms now share the C64-style life-loss path. A consumed
        ; death reloads the same room at its saved entry point and skips topology.
        call    game_life_check
        bcc     .no_death
        call    game_life_reload
        bra     .no_room_change
.no_death:
        ; Teleporters and completion/C5 paths are scripted, not normal edge exits.
        lda     teleporter_transition_pending
        ora     scripted_transition_pending
        beq     .normal_world_exit
        stz     teleporter_transition_pending
        stz     scripted_transition_pending
        call    room_load_pending_extended
        bra     .no_room_change
.normal_world_exit:
        call    world_resolve_exit
        bcc     .no_room_change
        call    room_load_pending_extended
.no_room_change:
        ; Room-entry sync restores mutable/dynamic mechanism state after loading.
        call    rising_cloud_room_sync
        call    rising_bollard_room_sync
        call    moving_lift_room_sync
        call    enemy_smiley_room_sync
        call    special_item_room_sync
        call    game_life_room_sync
        call    debug_room_draw
        call    monty_sprite_animate
        call    monty_sprite_update_satb
        ; SAT order: lift, enemies, special item, cloud. Cloud remains final DMA writer.
        call    moving_lift_update_satb
        call    enemy_smiley_update_satb
        call    special_item_update_satb
        call    rising_cloud_sprite_update_satb
        jmp     main_loop

init_c64_video:
        st0     #$0a
        st1     #<VDC_HSR_320
        st2     #>VDC_HSR_320
        st0     #$0b
        st1     #<VDC_HDR_320
        st2     #>VDC_HDR_320
        rts
