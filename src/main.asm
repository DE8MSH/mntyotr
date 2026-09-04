; Monty on the Run - PC Engine port
; Native room graphics + PAL-rate gameplay + first C64 movement path.

        include "platform.inc"
        include "bare-startup.asm"

        .list
        .mlist

        include "common.asm"
        include "vdc.asm"
        include "font.asm"
        include "joypad.asm"
        include "room00_assets.asm"
        include "room00_native.asm"
        include "game_clock.asm"
        include "monty_physics.asm"

        .code

bare_main:
        call    init_256x224
        bsr     init_c64_video

        stz     <_di + 0
        lda     #>(CHR_FONT * 16)
        sta     <_di + 1
        lda     #$ff
        sta     <_al
        stz     <_ah
        lda     #16 + 96
        sta     <_bl
        lda     #<font_data
        sta     <_bp + 0
        lda     #>font_data
        sta     <_bp + 1
        ldy     #^font_data
        call    dropfnt8x8_vdc

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

        lda     #<(0 * BAT_LINE + 2)
        sta     <_di + 0
        lda     #>(0 * BAT_LINE + 2)
        sta     <_di + 1
        call    vdc_di_to_mawr
        cly
        bsr     print_banner

        call    draw_room00_native
        call    game_clock_init
        call    monty_physics_init
        call    set_dspon

main_loop:
        call    wait_vsync
        call    game_clock_step
        bcc     main_loop
        inc     game_tick_counter

        ; Preserve C64 order at bring-up level: read controls/move horizontally,
        ; then advance the active vertical jump arc on the same logical tick.
        call    monty_update_input
        call    monty_jump_step
        bra     main_loop

init_c64_video:
        lda     #$01
        sta     VCE_CR
        st0     #$0b
        st1     #$27
        st2     #$00
        rts

print_char_loop:
        clc
        adc     #<CHR_ASCII_ZERO
        sta     VDC_DL
        lda     #$00
        adc     #>CHR_ASCII_ZERO
        sta     VDC_DH
        iny
print_banner:
        lda     banner_text, y
        bne     print_char_loop
        rts

banner_text:
        db      "MONTY PCE ROOM 00 NATIVE", 0

        .data
        align   2
font_data:
        incbin  "font8x8-ascii-bold-short.dat"
