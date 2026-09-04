; Phase 41 room loader: rooms $00 <-> $01 <-> $02 <-> $03.
; Rooms $02/$03 keep bulk assets in the ROM tail. Their 640-byte collision map
; plus 8 properties are copied into the shared room02_* RAM cache before
; gameplay resumes, so the far asset bank is never left mapped during physics.

.zp
room_copy_rows: ds 1

.code

; C=1 when a supported pending room was committed.
room_load_pending:
        lda     <world_pending_room
        beq     .room00
        cmp     #1
        beq     .room01
        cmp     #2
        beq     .room02
        cmp     #3
        beq     .room03
        clc
        rts

.room00:
        call    upload_room00_patterns
        call    draw_room00_native
        stz     <monty_room
        stz     <world_transition_ready
        sec
        rts

.room01:
        call    room01_upload_patterns
        call    room01_upload_decor
        call    room01_draw_native
        lda     #1
        sta     <monty_room
        stz     <world_transition_ready
        sec
        rts

.room02:
        call    room02_upload_patterns
        call    room02_upload_decor
        call    room02_draw_native
        call    room02_cache_collision
        lda     #2
        sta     <monty_room
        stz     <world_transition_ready
        sec
        rts

.room03:
        call    room03_upload_patterns
        call    room03_draw_native
        call    room03_cache_collision
        lda     #3
        sta     <monty_room
        stz     <world_transition_ready
        sec
        rts

; Tail-room collision caches. Both payloads are exactly 648 contiguous bytes:
; 640 collision-map bytes followed by 8 property bytes.
room02_cache_collision:
        lda     #<room02_collision_map_rom
        sta     <_bp
        lda     #>room02_collision_map_rom
        sta     <_bp+1
        ldy     #BANK(room02_collision_map_rom)
        bra     room_tail_cache_collision

room03_cache_collision:
        lda     #<room03_collision_map_rom
        sta     <_bp
        lda     #>room03_collision_map_rom
        sta     <_bp+1
        ldy     #BANK(room03_collision_map_rom)

room_tail_cache_collision:
        php
        sei
        tma3
        pha
        tma4
        pha
        call    map_bp_to_mpr34

        lda     #<room02_collision_map
        sta     <_di
        lda     #>room02_collision_map
        sta     <_di+1

        ldx     #2
        cly
.page:
        lda     [_bp],y
        sta     [_di],y
        iny
        bne     .page
        inc     <_bp+1
        inc     <_di+1
        dex
        bne     .page

        cly
        ldx     #136
.tail:
        lda     [_bp],y
        sta     [_di],y
        iny
        dex
        bne     .tail

        pla
        tam4
        pla
        tam3
        plp
        rts

; Upload 9*32 = 288 bytes to the shared custom-char VRAM.
room01_upload_patterns:
        lda     #<room01_patterns
        sta     <_bp
        lda     #>room01_patterns
        sta     <_bp+1
        ldy     #BANK(room01_patterns)
        bra     room_upload_9_patterns

room02_upload_patterns:
        lda     #<room02_patterns
        sta     <_bp
        lda     #>room02_patterns
        sta     <_bp+1
        ldy     #BANK(room02_patterns)
        bra     room_upload_9_patterns

room03_upload_patterns:
        lda     #<room03_patterns
        sta     <_bp
        lda     #>room03_patterns
        sta     <_bp+1
        ldy     #BANK(room03_patterns)

room_upload_9_patterns:
        php
        sei
        tma3
        pha
        tma4
        pha
        call    map_bp_to_mpr34

        lda     #<(CHR_GAME*16)
        sta     <_di
        lda     #>(CHR_GAME*16)
        sta     <_di+1
        call    vdc_di_to_mawr

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

room01_draw_native:
        lda     #<room01_screen_bat
        sta     <_bp
        lda     #>room01_screen_bat
        sta     <_bp+1
        ldy     #BANK(room01_screen_bat)
        bra     room_draw_native_36x20

room02_draw_native:
        lda     #<room02_screen_bat
        sta     <_bp
        lda     #>room02_screen_bat
        sta     <_bp+1
        ldy     #BANK(room02_screen_bat)
        bra     room_draw_native_36x20

room03_draw_native:
        lda     #<room03_screen_bat
        sta     <_bp
        lda     #>room03_screen_bat
        sta     <_bp+1
        ldy     #BANK(room03_screen_bat)

; Draw exact 36x20 visible room window at C64 cols 2..37, rows 3..22.
room_draw_native_36x20:
        php
        sei
        tma3
        pha
        tma4
        pha
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
