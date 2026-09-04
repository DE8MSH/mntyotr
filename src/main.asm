; Monty on the Run - PC Engine port
; Phase 5: 320px C64 canvas + exact room geometry + converted room graphics.

        include "platform.inc"
        include "bare-startup.asm"

        .list
        .mlist

        include "common.asm"
        include "vdc.asm"
        include "font.asm"
        include "joypad.asm"
        include "room00_assets.asm"
        include "room00.asm"

        .code

bare_main:
        call    init_256x224
        bsr     init_c64_video

        ; Diagnostic font.
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

        ; Room $00 now has its original C64 character bitmaps converted to
        ; native PCE 4bpp patterns at CHR_GAME. The current room renderer still
        ; displays tile IDs; the next renderer revision switches BAT entries to
        ; these patterns after the transfer itself is verified.
        call    upload_room00_patterns

        ; Eight room palettes: one per logical C64 room tile. This preserves
        ; C64's per-character foreground colour model without changing geometry.
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

        ; Exact C64 room-$00 RLE expansion at C64 screen col 4 / row 3.
        call    draw_room00_debug

        lda     #<(27 * BAT_LINE)
        sta     <_di + 0
        lda     #>(27 * BAT_LINE)
        sta     <_di + 1
        call    vdc_di_to_mawr
        cly
        bsr     print_ruler

        call    set_dspon

main_loop:
        call    wait_vsync
        bra     main_loop

; C64 VIC-II active matrix is 40x25 chars = 320x200 pixels.
; PCE uses 40 8-pixel cells horizontally. Final porch/centering values remain
; subject to emulator + hardware verification.
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

print_ruler_loop:
        clc
        adc     #<CHR_ASCII_ZERO
        sta     VDC_DL
        lda     #$00
        adc     #>CHR_ASCII_ZERO
        sta     VDC_DH
        iny
print_ruler:
        lda     ruler_text, y
        bne     print_ruler_loop
        rts

banner_text:
        db      "MONTY PCE ROOM 00 - C64 DATA", 0

ruler_text:
        db      "1234567890123456789012345678901234567890", 0

        .data
        align   2
font_data:
        incbin  "font8x8-ascii-bold-short.dat"
