; Monty on the Run — isolated SNES parallel port bring-up.
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
        plb                     ; data bank = program bank ($00 here)

        jsr     init_machine
        jsr     game_clock_init

        sep     #$20
.a8
        lda     RDNMI           ; clear any pending NMI status
        lda     #$80
        sta     NMITIMEN         ; VBlank NMI, auto joy read still disabled
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

        ; S1+ gameplay update will live here. PCE behaviour is the reference,
        ; but all implementation and generated data remain under snes/.
        bra     @frame

init_machine:
        sep     #$20
.a8
        stz     NMITIMEN
        stz     MDMAEN
        stz     HDMAEN
        lda     #$80
        sta     INIDISP          ; forced blank while PPU state is established

        lda     #$01
        sta     BGMODE           ; Mode 1 target for the real port
        stz     BG1SC
        stz     BG12NBA
        stz     TM               ; backdrop only during S0 bring-up

        ; Visible non-black backdrop proves reset/PPU/header/vector bring-up.
        ; CGRAM is BGR555; colour 0 becomes a dark blue.
        stz     CGADD
        stz     CGDATA
        lda     #$20
        sta     CGDATA
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
        .word   $FFFF                   ; checksum complement placeholder
        .word   $0000                   ; checksum placeholder

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
