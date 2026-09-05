; Phase 49: original two-room lift subsystem (Room $05 / Room $0D).
;
; C64 Mechanisms.Lift exact traversal state:
;   Room $05: type1, X=$48 Y=$5B speed_dir=$82 (descend 2). On contact,
;             speed_dir=$02 (ascend 2); above $62 switches to $88 (descend 8).
;   Room $0D: type2, X=$80 Y=$53 speed_dir=$80 (stationary). On contact,
;             speed_dir=$82 and carries Monty down until $B0, then releases.
; Contact places Monty on the platform at lift_y+$17 and the original game_mode
; locks normal player control while carried.
;
; Visuals use the authentic C64 multicolour sprite pair $74/$75 converted by
; tools/lift_sprite.py and rendered as four native PCE 16x32 sprites.

LIFT_SPR_VRAM = $3200
LIFT_SAT_TL   = SAT_ADDR+8
LIFT_SAT_TR   = SAT_ADDR+12
LIFT_SAT_BL   = SAT_ADDR+16
LIFT_SAT_BR   = SAT_ADDR+20

.zp
moving_lift_type:       ds 1
moving_lift_x:          ds 1
moving_lift_y:          ds 1
moving_lift_speed_dir:  ds 1
moving_lift_speed:      ds 1
moving_lift_contains:   ds 1
moving_lift_last_room:  ds 1
moving_lift_contact_y:  ds 1
moving_lift_pce_x_lo:   ds 1
moving_lift_pce_x_hi:   ds 1
moving_lift_pce_xr_lo:  ds 1
moving_lift_pce_xr_hi:  ds 1

.code

moving_lift_init:
        stz     <moving_lift_type
        stz     <moving_lift_contains
        lda     #$ff
        sta     <moving_lift_last_room
        jmp     moving_lift_upload_patterns

moving_lift_room_sync:
        lda     <monty_room
        cmp     <moving_lift_last_room
        bne     .changed
        rts
.changed:
        sta     <moving_lift_last_room
        stz     <moving_lift_type
        stz     <moving_lift_contains
        stz     <moving_lift_speed_dir
        cmp     #$05
        beq     .room05
        cmp     #$0d
        beq     .room0d
        rts
.room05:
        lda     #$48
        sta     <moving_lift_x
        lda     #$5b
        sta     <moving_lift_y
        lda     #1
        sta     <moving_lift_type
        lda     #$82
        sta     <moving_lift_speed_dir
        rts
.room0d:
        lda     #$80
        sta     <moving_lift_x
        lda     #$53
        sta     <moving_lift_y
        lda     #2
        sta     <moving_lift_type
        lda     #$80
        sta     <moving_lift_speed_dir
        rts

; Per logical tick after normal collision movement. If already carried, any pad
; movement from this tick is cancelled by re-locking Monty to the platform.
moving_lift_update:
        lda     <moving_lift_type
        bne     .active
        rts
.active:
        lda     <moving_lift_contains
        beq     .move_lift
        call    moving_lift_lock_monty

.move_lift:
        lda     <moving_lift_speed_dir
        and     #$0f
        sta     <moving_lift_speed
        beq     .after_move
        lda     <moving_lift_speed_dir
        bpl     .ascending

.descending:
        lda     <moving_lift_y
        cmp     #$b0
        bcc     .desc_step
        ; Type1 + $88 is the original squash-death case. Death/respawn is not
        ; complete yet, so record the event but release instead of softlocking.
        lda     <moving_lift_speed_dir
        cmp     #$88
        bne     .stop_bottom
        lda     #3
        sta     <monty_action_counter
.stop_bottom:
        stz     <moving_lift_speed_dir
        stz     <moving_lift_contains
        bra     .after_move
.desc_step:
        lda     <moving_lift_y
        clc
        adc     <moving_lift_speed
        sta     <moving_lift_y
        bra     .after_move

.ascending:
        lda     <moving_lift_y
        cmp     #$62
        bcs     .asc_step
        lda     #$88
        sta     <moving_lift_speed_dir
        bra     .after_move
.asc_step:
        lda     <moving_lift_y
        sec
        sbc     <moving_lift_speed
        sta     <moving_lift_y

.after_move:
        lda     <moving_lift_contains
        beq     .contact
        call    moving_lift_lock_monty
        rts

.contact:
        ; Type2 cannot be boarded once it has reached the bottom and stopped.
        lda     <moving_lift_type
        cmp     #2
        bne     .contact_xy
        lda     <moving_lift_y
        cmp     #$b0
        bcs     .done
.contact_xy:
        ; Original requires X==lift_x+2. Allow the swept PCE player footprint a
        ; two-pixel tolerance, then snap to the exact original boarding X.
        lda     <monty_x
        cmp     <moving_lift_x
        bcc     .done
        lda     <moving_lift_x
        clc
        adc     #5
        cmp     <monty_x
        bcc     .done

        ; Original accepts lift_y+$17 or lift_y+$19. Including the middle pixel
        ; prevents a 1px unsupported-fall tick from skipping contact.
        lda     <moving_lift_y
        clc
        adc     #$17
        sta     <moving_lift_contact_y
        lda     <monty_y
        cmp     <moving_lift_contact_y
        bcc     .done
        sec
        sbc     <moving_lift_contact_y
        cmp     #3
        bcs     .done

        lda     <moving_lift_x
        clc
        adc     #2
        sta     <monty_x
        lda     #1
        sta     <moving_lift_contains
        stz     <monty_jump_phase
        stz     <monty_jump_index
        stz     <monty_falling
        stz     <monty_saved_left
        stz     <monty_saved_right
        lda     <moving_lift_type
        cmp     #1
        beq     .board_type1
        lda     #$82
        sta     <moving_lift_speed_dir
        jmp     moving_lift_lock_monty
.board_type1:
        lda     #$02
        sta     <moving_lift_speed_dir
        jmp     moving_lift_lock_monty
.done:
        rts

moving_lift_lock_monty:
        lda     <moving_lift_x
        clc
        adc     #2
        sta     <monty_x
        lda     <moving_lift_y
        clc
        adc     #$17
        sta     <monty_y
        stz     <monty_jump_phase
        stz     <monty_jump_index
        stz     <monty_falling
        stz     <monty_saved_left
        stz     <monty_saved_right
        lda     #1
        sta     <monty_is_moving
        rts

; ---------------------------------------------------------------------------
; Authentic lift graphics.
; ---------------------------------------------------------------------------
moving_lift_upload_patterns:
        php
        sei
        tma3
        pha
        tma4
        pha
        lda     #<moving_lift_patterns
        sta     <_bp
        lda     #>moving_lift_patterns
        sta     <_bp+1
        ldy     #BANK(moving_lift_patterns)
        call    map_bp_to_mpr34

        lda     #<LIFT_SPR_VRAM
        sta     <_di
        lda     #>LIFT_SPR_VRAM
        sta     <_di+1
        call    vdc_di_to_mawr
        ldx     #4
        cly
.page:
        ldy     #0
.word:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        bne     .word
        inc     <_bp+1
        dex
        bne     .page

        pla
        tam4
        pla
        tam3
        plp
        rts

; Update SAT entries 2..5 after Monty's entries 0..1. Pattern groups use the
; same TL/TR/BL/BR layout as the Monty converter. Palette 17 is sprite palette 1.
moving_lift_update_satb:
        lda     <moving_lift_type
        bne     .show
        jmp     moving_lift_hide_satb
.show:
        ; PCE X conversion follows the proven Monty path: 2*C64-X + 8.
        lda     <moving_lift_x
        asl     a
        ldx     #0
        bcc     .x_no_carry
        inx
.x_no_carry:
        clc
        adc     #8
        bcc     .x_add_ok
        inx
.x_add_ok:
        sta     <moving_lift_pce_x_lo
        stx     <moving_lift_pce_x_hi
        clc
        adc     #16
        sta     <moving_lift_pce_xr_lo
        txa
        adc     #0
        sta     <moving_lift_pce_xr_hi

        lda     #<LIFT_SAT_TL
        sta     <_di
        lda     #>LIFT_SAT_TL
        sta     <_di+1
        call    vdc_di_to_mawr

        ; top-left
        lda     <moving_lift_y
        clc
        adc     #15
        sta     VDC_DL
        stz     VDC_DH
        lda     <moving_lift_pce_x_lo
        sta     VDC_DL
        lda     <moving_lift_pce_x_hi
        sta     VDC_DH
        lda     #<(LIFT_SPR_VRAM>>5)
        sta     VDC_DL
        lda     #>(LIFT_SPR_VRAM>>5)
        sta     VDC_DH
        lda     #$81
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH

        ; top-right
        lda     <moving_lift_y
        clc
        adc     #15
        sta     VDC_DL
        stz     VDC_DH
        lda     <moving_lift_pce_xr_lo
        sta     VDC_DL
        lda     <moving_lift_pce_xr_hi
        sta     VDC_DH
        lda     #<((LIFT_SPR_VRAM+64)>>5)
        sta     VDC_DL
        lda     #>((LIFT_SPR_VRAM+64)>>5)
        sta     VDC_DH
        lda     #$81
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH

        ; bottom-left: original second VIC sprite is Y+$15.
        lda     <moving_lift_y
        clc
        adc     #36
        sta     VDC_DL
        stz     VDC_DH
        lda     <moving_lift_pce_x_lo
        sta     VDC_DL
        lda     <moving_lift_pce_x_hi
        sta     VDC_DH
        lda     #<((LIFT_SPR_VRAM+$100)>>5)
        sta     VDC_DL
        lda     #>((LIFT_SPR_VRAM+$100)>>5)
        sta     VDC_DH
        lda     #$81
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH

        ; bottom-right
        lda     <moving_lift_y
        clc
        adc     #36
        sta     VDC_DL
        stz     VDC_DH
        lda     <moving_lift_pce_xr_lo
        sta     VDC_DL
        lda     <moving_lift_pce_xr_hi
        sta     VDC_DH
        lda     #<((LIFT_SPR_VRAM+$140)>>5)
        sta     VDC_DL
        lda     #>((LIFT_SPR_VRAM+$140)>>5)
        sta     VDC_DH
        lda     #$81
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH
        bra     .sat_dma

moving_lift_hide_satb:
        lda     #<LIFT_SAT_TL
        sta     <_di
        lda     #>LIFT_SAT_TL
        sta     <_di+1
        call    vdc_di_to_mawr
        ldx     #4
.hide_one:
        cla
        sta     VDC_DL
        lda     #1
        sta     VDC_DH              ; Y=$0100, outside visible area
        cla
        sta     VDC_DL
        sta     VDC_DH
        sta     VDC_DL
        sta     VDC_DH
        sta     VDC_DL
        sta     VDC_DH
        dex
        bne     .hide_one
.sat_dma:
        st0     #$13
        st1     #<SAT_ADDR
        st2     #>SAT_ADDR
        rts
