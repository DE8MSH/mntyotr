; Monty on the Run — isolated SNES parallel port.
; This source intentionally has no include/dependency on the PCE src/ tree.

.setcpu "65816"
.smart

.include "hardware.inc"

.segment "ZEROPAGE"
frame_counter:   .res 1
logic_phase:     .res 1

.segment "CODE"

Reset:
        sei
        clc
        xce                     ; enter 65816 native mode
        rep     #$38            ; 16-bit A/X/Y, decimal off
.a16
.i16
        ldx     #$1FFF
        txs
        lda     #$0000
        tcd                     ; direct page = $0000
        phk
        plb                     ; data bank = program bank ($00 in this LoROM bank)

        jsr     init_machine
        jsr     game_clock_init

        sep     #$20
.a8
        stz     frame_counter
        lda     RDNMI           ; clear any pending NMI status
        lda     #$80
        sta     NMITIMEN         ; VBlank NMI; joy auto-read comes with gameplay input
        lda     #$0F
        sta     INIDISP          ; display on, full brightness
        cli

@frame:
        wai
        lda     frame_counter
        beq     @frame
        stz     frame_counter

        jsr     game_clock_step
        bcc     @frame

        ; Gameplay/physics follows in later milestones. Room $00 rendering is
        ; already live and remains independent from all PCE source/build files.
        bra     @frame

init_machine:
        sep     #$20
.a8
.i16
        stz     NMITIMEN
        stz     MDMAEN
        stz     HDMAEN
        lda     #$80
        sta     INIDISP          ; forced blank during all PPU/VRAM setup

        ; Deterministic Mode 1 state. BG1 map = VRAM $0000, BG1 CHR = $1000 words.
        lda     #$01
        sta     BGMODE
        stz     MOSAIC
        stz     BG1SC
        lda     #$01
        sta     BG12NBA

        ; Clear BG1 scroll latches. The generated tilemap places the 32x20 room
        ; at row 4, centering the 160-line playfield within 224 visible lines.
        stz     BG1HOFS
        stz     BG1HOFS
        stz     BG1VOFS
        stz     BG1VOFS

        ; Disable unused screens/windows/colour math before enabling BG1.
        stz     TM
        stz     TS
        stz     TMW
        stz     TSW
        stz     CGWSEL
        stz     CGADSUB
        stz     SETINI

        jsr     room00_upload

        lda     #$01
        sta     TM               ; main screen: BG1 only
        rts

NmiHandler:
        php
        sep     #$20
.a8
        lda     RDNMI
        inc     frame_counter
        plp
        rti

DefaultInterrupt:
        rti

.include "game_clock.asm"
.include "room00.asm"

.segment "HEADER"
        .byte   "MONTY SNES PARALLEL  " ; 21-byte internal title
        .byte   $20                     ; LoROM, SlowROM
        .byte   $00                     ; ROM only
        .byte   $05                     ; 32 KiB ROM
        .byte   $00                     ; no SRAM yet
.ifdef SNES_NTSC
        .byte   $01                     ; USA/NTSC
.else
        .byte   $02                     ; Europe/PAL
.endif
        .byte   $00                     ; licensee (bring-up)
        .byte   $00                     ; version
        .word   $FFFF                   ; patched after link
        .word   $0000                   ; patched after link

.segment "VECTORS"
        .word   $0000, $0000            ; $FFE0-$FFE3 reserved
        .word   DefaultInterrupt        ; native COP
        .word   DefaultInterrupt        ; native BRK
        .word   DefaultInterrupt        ; native ABORT
        .word   NmiHandler              ; native NMI
        .word   $0000                   ; native reserved
        .word   DefaultInterrupt        ; native IRQ
        .word   $0000, $0000            ; $FFF0-$FFF3 reserved
        .word   DefaultInterrupt        ; emulation COP
        .word   $0000                   ; emulation reserved
        .word   DefaultInterrupt        ; emulation ABORT
        .word   NmiHandler              ; emulation NMI
        .word   Reset                   ; RESET
        .word   DefaultInterrupt        ; emulation IRQ/BRK
