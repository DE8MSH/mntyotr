; Monty on the Run - PC Engine port
; Phase 2: known-good CORE startup + VDC/VCE display bring-up.
;
; HuC's CORE(not TM) library owns reset/IRQ/MPR setup. bare_main is entered
; after the machine is in a predictable state.

        include "platform.inc"
        include "bare-startup.asm"

        .list
        .mlist

        include "common.asm"
        include "vdc.asm"
        include "font.asm"
        include "joypad.asm"

        .code

bare_main:
        call    init_256x224

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

        ; Temporary bring-up palette. Game palette conversion follows.
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

        ; Write a diagnostic banner into BAT row 13.
        lda     #<(13 * BAT_LINE + 5)
        sta     <_di + 0
        lda     #>(13 * BAT_LINE + 5)
        sta     <_di + 1
        call    vdc_di_to_mawr
        cly
        bsr     print_banner

        call    set_dspon

main_loop:
        call    wait_vsync
        bra     main_loop

print_loop:
        clc
        adc     #<CHR_ASCII_ZERO
        sta     VDC_DL
        lda     #$00
        adc     #>CHR_ASCII_ZERO
        sta     VDC_DH
        iny
print_banner:
        lda     banner_text, y
        bne     print_loop
        rts

banner_text:
        db      "MONTY PCE - VDC OK", 0

        .data
        align   2

test_palette:
        dw      $0000,$0001,$01b2,$01b2,$0002,$004c,$0169,$01b2
        dw      $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

font_data:
        incbin  "font8x8-ascii-bold-short.dat"
