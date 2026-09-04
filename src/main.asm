; Monty on the Run - PC Engine port
; Phase 3: C64-width video bring-up.
;
; C64 active VIC-II display is 320x200. The PCE test mode uses a 320-pixel
; horizontal active area and 224 lines; the original 200-line C64 canvas is
; centred vertically with 12 lines above and below. This keeps all C64 X
; coordinates 1:1 instead of scaling 320 pixels into the PCE 256px mode.

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
        ; CORE establishes a safe known VDC state first.
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

        ; Bring-up palette; exact VIC-II -> VCE palette follows.
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

        ; Diagnostic text deliberately spans positions beyond old 32-col mode.
        ; If the whole 40-column ruler is visible, 320px mode is active.
        lda     #<(10 * BAT_LINE + 4)
        sta     <_di + 0
        lda     #>(10 * BAT_LINE + 4)
        sta     <_di + 1
        call    vdc_di_to_mawr
        cly
        bsr     print_banner

        lda     #<(13 * BAT_LINE + 0)
        sta     <_di + 0
        lda     #>(13 * BAT_LINE + 0)
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
; C64 PAL VIC-II active matrix: 40x25 chars = 320x200 pixels.
; PCE VDC HDR low 7 bits are HDW = active tile width - 1, so $27 selects
; 40 tiles / 320 active pixels. VCE PCC=01 selects the 7.159 MHz dot clock
; used by the PCE's medium-width modes.
;
; HSR/HDE timing is deliberately inherited from CORE for this first hardware
; experiment. We verify centring/blanking on Geargrafx + real hardware before
; freezing final porch values. Do not treat this routine as final timing yet.
; ---------------------------------------------------------------------------
init_c64_video:
        lda     #$01                    ; VCE PCC=01: 7.159 MHz dot clock
        sta     VCE_CR

        st0     #$0b                    ; VDC HDR
        st1     #$27                    ; HDW = 39 => 40 tiles = 320 pixels
        st2     #$00                    ; retain simple HDE for bring-up
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
        db      "MONTY PCE  C64 320x200 CANVAS", 0

; Exactly 40 printable cells. The final 9 must be visible in the new mode.
ruler_text:
        db      "1234567890123456789012345678901234567890", 0

        .data
        align   2

test_palette:
        dw      $0000,$0001,$01b2,$01b2,$0002,$004c,$0169,$01b2
        dw      $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

font_data:
        incbin  "font8x8-ascii-bold-short.dat"
