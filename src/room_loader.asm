; Phase 36 room loader: rooms $00 <-> $01 with Room-$01 decor restored.
; Room $01 graphics/decor are copied through MPR3/MPR4 so ROM-bank placement
; cannot corrupt the room as the ROM grows.

.zp
room_copy_rows: ds 1

.code

; C=1 when a supported pending room was committed.
room_load_pending:
        lda     <world_pending_room
        beq     .room00
        cmp     #1
        beq     .room01
        clc
        rts

.room00:
        ; This restores both the base Room-$00 chars and all 41 Room-$00 decor
        ; chars, so returning from Room-$01 cannot leave its decor in shared VRAM.
        call    upload_room00_patterns
        call    draw_room00_native
        stz     <monty_room
        stz     <world_transition_ready
        sec
        rts

.room01:
        ; Use absolute CALLs: these helpers can move out of BSR range as ROM grows.
        call    room01_upload_patterns
        call    room01_upload_decor
        call    room01_draw_native
        lda     #1
        sta     <monty_room
        stz     <world_transition_ready
        sec
        rts

; Upload 9*32 = 288 bytes to the same custom-char VRAM used by every room.
room01_upload_patterns:
        php
        sei
        tma3
        pha
        tma4
        pha

        lda     #<room01_patterns
        sta     <_bp
        lda     #>room01_patterns
        sta     <_bp+1
        ldy     #BANK(room01_patterns)
        call    map_bp_to_mpr34

        lda     #<(CHR_GAME*16)
        sta     <_di
        lda     #>(CHR_GAME*16)
        sta     <_di+1
        call    vdc_di_to_mawr

        ; First 256 bytes = 128 VDC words.
        cly
        ldx     #128
.p0:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        dex
        bne     .p0
        inc     <_bp+1
        ; Remaining 32 bytes = 16 VDC words.
        cly
        ldx     #16
.p1:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        dex
        bne     .p1

        pla
        tam4
        pla
        tam3
        plp
        rts

; Draw the exact 36x20 visible room window at C64 cols 2..37, rows 3..22.
; The generated BAT already contains the two exact Room-$01 decor overlays.
; The 1440-byte BAT source remains mapped across MPR3/MPR4 for the whole copy.
room01_draw_native:
        php
        sei
        tma3
        pha
        tma4
        pha

        lda     #<room01_screen_bat
        sta     <_bp
        lda     #>room01_screen_bat
        sta     <_bp+1
        ldy     #BANK(room01_screen_bat)
        call    map_bp_to_mpr34

        lda     #<((3)*BAT_LINE+ROOM_X)
        sta     <_di
        lda     #>((3)*BAT_LINE+ROOM_X)
        sta     <_di+1
        lda     #20
        sta     <room_copy_rows
.row:
        call    vdc_di_to_mawr
        cly
        ldx     #36
.word:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        dex
        bne     .word

        lda     <_bp
        clc
        adc     #72
        sta     <_bp
        bcc     .src_ok
        inc     <_bp+1
.src_ok:
        lda     <_di
        clc
        adc     #BAT_LINE
        sta     <_di
        bcc     .dst_ok
        inc     <_di+1
.dst_ok:
        dec     <room_copy_rows
        bne     .row

        pla
        tam4
        pla
        tam3
        plp
        rts
