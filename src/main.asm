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
        include "room01_decor_loader.asm"
        include "room_loader.asm"
        include "monty_sprite.asm"

.zp
main_jump_x_before_step:   ds 1
main_exit_before_jump:     ds 1

        .code

bare_main:
        ; Use the library's complete 7MHz/224-line setup, then narrow the
        ; horizontal timing from 352 to 320 pixels.
        call    init_352x224
        call    init_c64_video

        call    upload_room00_patterns

        ; Base room and room-$00 decor share one compact BG-palette set.
        stz     <_al
        lda     #13
        sta     <_ah
        lda     #<room00_bg_palettes
        sta     <_bp + 0
        lda     #>room00_bg_palettes
        sta     <_bp + 1
        ldy     #^room00_bg_palettes
        call    load_palettes

        ; Room $01 needs C64 purple and blue in the two remaining shared slots.
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

        ; PCE sprite palettes are indices 16..31. Monty is C64 colour 1
        ; (white), so plane-0 pixel index 1 must be visible in SPR palette 0.
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
        call    monty_sprite_init
        call    monty_sprite_update_satb
        call    set_dspon

main_loop:
        call    wait_vsync
        call    read_joypads

        call    game_clock_step
        bcc     main_loop
        inc     game_tick_counter

        ; Phase 35: temporarily map the active room's collision-map bank across
        ; the complete physics slice. This keeps direct C64-style tile reads
        ; correct even when unrelated ROM content moves room data to new banks.
        call    collision_bank_enter

        ; C64-oriented order for the currently ported subset.
        call    monty_update_input

        ; The currently loaded world subset is only rooms $00 and $01. During
        ; a jump, horizontal motion can still reach an edge that the world
        ; resolver will reject ($00 right -> $ff, $01 left -> unsupported $02).
        ; Cancel those side exits before the vertical jump step gets a chance
        ; to interpret the wrapped X coordinate as the opposite screen edge.
        lda     <monty_jump_phase
        beq     .after_unsupported_jump_edge
        lda     <monty_room
        beq     .guard_room00_right
        cmp     #1
        bne     .after_unsupported_jump_edge
        lda     <monty_room_exit
        cmp     #1
        bne     .after_unsupported_jump_edge
        lda     #$15
        sta     <monty_x
        stz     <monty_room_exit
        bra     .after_unsupported_jump_edge
.guard_room00_right:
        lda     <monty_room_exit
        cmp     #2
        bne     .after_unsupported_jump_edge
        lda     #$9b
        sta     <monty_x
        stz     <monty_room_exit
.after_unsupported_jump_edge:

        ; A real horizontal exit may already have been produced by
        ; monty_update_input. monty_jump_step calls monty_check_room_edges too,
        ; whose first instruction clears monty_room_exit. Preserve a supported
        ; exit here so jumping through a valid doorway/edge cannot be lost.
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
        ; No real horizontal exit existed before the vertical jump step. Reject
        ; a side exit synthesized only because monty_check_room_edges also tests
        ; X while processing vertical motion.
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

        ; Restore the normal HuCard mapping before world/VRAM/sprite work.
        call    collision_bank_exit

        call    world_resolve_exit
        bcc     .no_room_change
        call    room_load_pending
.no_room_change:
        call    monty_sprite_animate
        call    monty_sprite_update_satb
        bra     main_loop

; Keep the proven 352x224 vertical/DMA setup, but use the library's 320-pixel
; horizontal timing constants. 40 C64 character columns * 8 pixels = 320.
init_c64_video:
        st0     #$0a
        st1     #<VDC_HSR_320
        st2     #>VDC_HSR_320
        st0     #$0b
        st1     #<VDC_HDR_320
        st2     #>VDC_HDR_320
        rts
