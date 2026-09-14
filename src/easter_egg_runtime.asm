.zp
cheat_mode: ds 1

.bss
cheat_hiscore_name: ds 16

.code
cheat_init:
        stz <cheat_mode
        ldx #15
.clear_name:
        stz cheat_hiscore_name,x
        dex
        bpl .clear_name
        rts

.proc cheat_process_hiscore_name
        ldx #0
.compare:
        lda cheat_hiscore_name,x
        cmp cheat_trigger_phrase,x
        bne .no_match
        inx
        cpx #15
        bne .compare
        lda #1
        sta <cheat_mode
        sec
        leave
.no_match:
        clc
        leave
.endp

.data
cheat_trigger_phrase:
        db $49,$20,$57,$41,$4e,$54,$20,$54,$4f,$20,$43,$48,$45,$41,$54
