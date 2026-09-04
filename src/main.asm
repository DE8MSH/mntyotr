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
        include "game_clock.asm"
        include "monty_physics.asm"
        include "world.asm"
        include "monty_sprite.asm"

        .code

bare_main:
        call    init_256x224
        bsr     init_c64_video

        call    upload_room00_patterns

        stz     <_al
        lda     #8
        sta     <_ah
        lda     #<room00_palettes
        sta     <_bp + 0
        lda     #>room00_palettes
        sta     <_bp + 1
        ldy     #^room00_palettes
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
        call    game_clock_step
        bcc     main_loop
        inc     game_tick_counter

        ; C64-oriented order for the currently ported subset.
        call    monty_update_input
        call    monty_jump_step
        call    world_resolve_exit
        call    monty_sprite_animate
        call    monty_sprite_update_satb
        ; A valid destination is left pending until the generic room loader is
        ; present; do not run room-$00 collision data as another room.
        bra     main_loop

init_c64_video:
        lda     #$01
        sta     VCE_CR
        st0     #$0b
        st1     #$27
        st2     #$00
        rts
