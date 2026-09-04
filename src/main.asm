; Monty on the Run - PC Engine port
; Phase 6: 320px C64 canvas + native room graphics + PAL gameplay clock.

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

        .code

bare_main:
        call    init_256x224
        bsr     init_c64_video

        ; Diagnostic font remains available for bring-up labels.
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

        ; Original C64 room-$00 8x8 bitmaps converted to native PCE 4bpp.
        call    upload_room00_patterns

        ; One PCE BG palette per C64 room character slot.
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

        ; Exact C64 room-$00 geometry rendered with converted C64 patterns.
        call    draw_room00_native
        call    game_clock_init
        call    set_dspon

main_loop:
        call    wait_vsync
        call    game_clock_step
        bcc     main_loop              ; no PAL game tick on this VBlank
        ; Gameplay update chain is attached here. Keeping this gate explicit
        ; prevents PCE display refresh from changing C64 movement physics.
        inc     game_tick_counter
        bra     main_loop

; C64 VIC-II active matrix is 40x25 chars = 320x200 pixels.
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
