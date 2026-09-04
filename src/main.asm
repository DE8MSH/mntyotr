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
        include "world.asm"
        include "room_loader.asm"
        include "monty_sprite.asm"

        .code

bare_main:
        ; Use the library's complete 7MHz/224-line setup, then narrow the
        ; horizontal timing from 352 to 320 pixels.
        call    init_352x224
        bsr     init_c64_video

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

        ; C64-oriented order for the currently ported subset.
        call    monty_update_input
        call    monty_jump_step
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
