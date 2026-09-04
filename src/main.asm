; Monty on the Run - PC Engine port
; Phase 4: 320px C64 canvas + first exact room geometry.
;
; The PCE active area is 320x224. C64 screen coordinates remain 1:1 in X.
; Room $00 is now drawn at the same character-grid position used by the C64:
; 32x20 cells beginning at screen column 4, row 3.

        include "platform.inc"
        include "bare-startup.asm"

        .list
        .mlist

        include "common.asm"
        include "vdc.asm"
        include "font.asm"
        include "joypad.asm"
        include "room00.asm"

        .code

bare_main:
        call    init_256x224
        bsr     init_c64_video

        ; Upload CORE 8x8 font after BAT/SAT reserved VRAM.
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

        ; Bring-up palette. Exact VIC-II -> VCE conversion follows.
        stz     <_al
        lda     #1
        sta     <_ah
        lda     #<test_palette
        sta     <_bp + 0
        lda     #>test_palette
        sta     <_bp + 1
        ldy     #^test_palette
        call    load_palettes
        call    xfer_palettes

        ; Row 0 identifies this as the room-geometry build.
        lda     #<(0 * BAT_LINE + 2)
        sta     <_di + 0
        lda     #>(0 * BAT_LINE + 2)
        sta     <_di + 1
        call    vdc_di_to_mawr
        cly
        bsr     print_banner

        ; First real C64 room result: exact 32x20 decoded room-$00 tile IDs.
        ; Digits are temporary glyphs for the tile IDs, not final artwork.
        call    draw_room00_debug

        ; Bottom row remains a 40-column width check.
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

; ---------------------------------------------------------------------------
; init_c64_video
;
; C64 VIC-II active matrix is 40x25 chars = 320x200 pixels.
; PCE VDC HDR low 7 bits are HDW = active tile width - 1, so $27 selects
; 40 tiles / 320 active pixels. VCE PCC=01 selects the 7.159 MHz dot clock.
;
; HSR/HDE timing remains bring-up timing until checked in emulator/hardware.
; ---------------------------------------------------------------------------
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
        db      "MONTY PCE ROOM 00 - C64 TILE IDS", 0

ruler_text:
        db      "1234567890123456789012345678901234567890", 0

        .data
        align   2

test_palette:
        dw      $0000,$0001,$01b2,$01b2,$0002,$004c,$0169,$01b2
        dw      $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

font_data:
        incbin  "font8x8-ascii-bold-short.dat"
