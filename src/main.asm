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
        ; Use the library's complete 7MHz/224-line setup, then narrow the
        ; horizontal timing from 352 to 320 pixels.  The old init_256x224 plus
        ; hand-written HDR=$27 mixed incompatible timing tables and visibly
        ; squeezed the 40-column C64 screen model.
        call    init_352x224
        bsr     init_c64_video

        call    upload_room00_patterns

        ; C64 screen codes 0..8 each select the matching PCE BG palette.
        stz     <_al
        lda     #9
        sta     <_ah
        lda     #<room00_palettes
        sta     <_bp + 0
        lda     #>room00_palettes
        sta     <_bp + 1
        ldy     #^room00_palettes
        call    load_palettes

        ; Phase 29: solid-colour room-$00 decorations use BG palettes 9..11.
        lda     #9
        sta     <_al
        lda     #3
        sta     <_ah
        lda     #<room00_decor_palettes
        sta     <_bp + 0
        lda     #>room00_decor_palettes
        sta     <_bp + 1
        ldy     #^room00_decor_palettes
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

        ; Keep gameplay input deterministic while the port is brought up.
        ; bare-startup also polls during VBLANK, but an explicit poll here makes
        ; joynow current immediately before the PAL-rate C64 gameplay tick.
        call    read_joypads

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

; Keep the proven 352x224 vertical/DMA setup, but use the library's 320-pixel
; horizontal timing constants.  40 C64 character columns * 8 pixels = 320.
init_c64_video:
        st0     #$0a
        st1     #<VDC_HSR_320
        st2     #>VDC_HSR_320
        st0     #$0b
        st1     #<VDC_HDR_320
        st2     #>VDC_HDR_320
        rts
