; Small home-bank gates for the Room $00 enemy engine.
; Enemy code itself lives in a dedicated 8 KiB ROM bank mapped at $8000 (MPR4).
; Each gate preserves the caller's MPR4 mapping across the banked JSR.

.bss
enemy00_last_room:      ds 1
enemy00_active:         ds 1
enemy00_smiley_x:       ds 1
enemy00_smiley_y:       ds 1
enemy00_smiley_flags:   ds 1
enemy00_smiley_count:   ds 1
enemy00_smiley_anim:    ds 1
enemy00_skate_x:        ds 1
enemy00_skate_y:        ds 1
enemy00_skate_flags:    ds 1
enemy00_skate_count:    ds 1
enemy00_skate_anim:     ds 1
enemy00_tmp:            ds 1

.code

enemy00_gate_init:
        tma4
        pha
        lda     #BANK(enemy00_banked_init)
        tam4
        call    enemy00_banked_init
        pla
        tam4
        rts

enemy00_gate_room_sync:
        tma4
        pha
        lda     #BANK(enemy00_banked_room_sync)
        tam4
        call    enemy00_banked_room_sync
        pla
        tam4
        rts

enemy00_gate_update:
        tma4
        pha
        lda     #BANK(enemy00_banked_update)
        tam4
        call    enemy00_banked_update
        pla
        tam4
        rts

enemy00_gate_update_satb:
        tma4
        pha
        lda     #BANK(enemy00_banked_update_satb)
        tam4
        call    enemy00_banked_update_satb
        pla
        tam4
        rts
