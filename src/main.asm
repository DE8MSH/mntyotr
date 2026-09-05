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
        include "monty_physics.asm"
        include "collision_banking.asm"
        include "world.asm"
        include "vertical_world_edges.asm"
        include "room01_decor_loader.asm"
        include "room02_decor_loader.asm"
        include "room_loader.asm"
        include "room050c_loader.asm"
        include "monty_sprite.asm"
        include "debug_room.asm"
        include "debug_footer_visible.asm"
        ; Large banked room/decor data is appended after gameplay/runtime code so
        ; adding new content cannot move the confirmed physics/collision layout.
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

.zp
main_jump_x_before_step:   ds 1
main_exit_before_jump:     ds 1

        .code

bare_main:
        call    init_352x224
        call    init_c64_video

        call    upload_room00_patterns

        stz     <_al
        lda     #13
        sta     <_ah
        lda     #<room00_bg_palettes
        sta     <_bp + 0
        lda     #>room00_bg_palettes
        sta     <_bp + 1
        ldy     #^room00_bg_palettes
        call    load_palettes

        ; Active house rooms use C64 purple and blue in slots 13/14.
        lda     #13
        sta     <_al
        lda     #2
        sta     <_ah
        lda     #<room01_extra_palettes
        sta     <_bp + 0
        lda     #>room01_extra_palettes
        sta     <_bp + 1
        ldy     #^room01_extra_palettes
        call    load_palettes

        ; Room $03 additionally uses C64 light blue $0e in BG palette slot 15.
        lda     #15
        sta     <_al
        lda     #1
        sta     <_ah
        lda     #<room03_extra_palette
        sta     <_bp + 0
        lda     #>room03_extra_palette
        sta     <_bp + 1
        ldy     #^room03_extra_palette
        call    load_palettes

        lda     #16
        sta     <_al
        lda     #1
        sta     <_ah
        lda     #<monty_sprite_palette
        sta     <_bp + 0
        lda     #>monty_sprite_palette
        sta     <_bp + 1
        ldy     #^monty_sprite_palette
        call    load_palettes
        call    xfer_palettes

        call    draw_room00_native
        call    game_clock_init
        call    monty_physics_init
        call    world_init
        call    debug_room_init
        call    debug_footer_visible_draw
        call    monty_sprite_init
        call    monty_sprite_update_satb
        call    set_dspon

main_loop:
        call    wait_vsync
        call    read_joypads

        call    game_clock_step
        bcc     main_loop
        inc     game_tick_counter

        call    collision_bank_enter
        call    monty_update_input

        ; Phase 48 keeps only the confirmed outer edge at Room $00 right as a
        ; pre-world special case. Room $01 up->$09 is now a real supported edge.
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
        call    monty_jump_step

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

        ; Original downward edge semantics remain active for all loaded cells.
        call    monty_check_down_room_edge
        call    collision_bank_exit

        call    world_resolve_exit
        bcc     .no_room_change
        call    room_load_pending_extended
.no_room_change:
        call    debug_room_draw
        call    debug_footer_visible_draw
        call    monty_sprite_animate
        call    monty_sprite_update_satb
        bra     main_loop

init_c64_video:
        st0     #$0a
        st1     #<VDC_HSR_320
        st2     #>VDC_HSR_320
        st0     #$0b
        st1     #<VDC_HDR_320
        st2     #>VDC_HDR_320
        rts
