; Shared C5 lethal type-2 tile guard for the Room $24/$33 transit path.
; Input A = tile property. C=1 means normal C5 death was dispatched.
.code
.proc c5_lethal_tile_check
        cmp #$02
        bne .safe
        lda <cheat_mode
        bmi .safe
        lda #7
        sta <monty_action_counter
        sec
        leave
.safe:
        clc
        leave
.endp
