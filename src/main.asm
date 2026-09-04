; Monty on the Run - PC Engine bring-up
; Phase 1: valid HuCard image skeleton. Hardware init/display follows next.

    .include "pce.inc"

    .bank 0
    .org $0000

reset:
    sei
    csh
    cld
    ldx #$ff
    txs

main_loop:
    bra main_loop

irq2:
    rti
irq1:
    rti
timer_irq:
    rti
nmi:
    rti

    .org $1ff6
    .dw irq2
    .dw irq1
    .dw timer_irq
    .dw nmi
    .dw reset
