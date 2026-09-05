; Phase 45 room loader: active route includes rooms $00-$04, $0A/$0B and $0D/$0E.
; Tail rooms keep bulk assets in the ROM tail. Their 640-byte collision map plus
; 8 properties are copied into the shared room02_* RAM cache before gameplay.

.zp
room_copy_rows: ds 1

.code

; C=1 when a supported pending room was committed.
; Use short conditional skips plus absolute JMPs so adding rooms cannot push a
; dispatch target outside the HuC6280 signed 8-bit branch range.
room_load_pending:
        lda     <world_pending_room
        bne     .check01
        jmp     .room00
.check01:
        cmp     #1
        bne     .check02
        jmp     .room01
.check02:
        cmp     #2
        bne     .check03
        jmp     .room02
.check03:
        cmp     #3
        bne     .check04
        jmp     .room03
.check04:
        cmp     #4
        bne     .check0a
        jmp     .room04
.check0a:
        cmp     #$0a
        bne     .check0b
        jmp     .room0a
.check0b:
        cmp     #$0b
        bne     .check0d
        jmp     .room0b
.check0d:
        cmp     #$0d
        bne     .check0e
        jmp     .room0d
.check0e:
        cmp     #$0e
        bne     .unsupported
        jmp     .room0e
.unsupported:
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

.room04:
        call    room04_upload_patterns
        call    room04_draw_native
        call    room04_cache_collision
        lda     #4
        sta     <monty_room
        stz     <world_transition_ready
        sec
        rts

.room0a:
        call    room0a_upload_patterns
        call    room0a_draw_native
        call    room0a_cache_collision
        lda     #$0a
        sta     <monty_room
        stz     <world_transition_ready
        sec
        rts

.room0b:
        call    room0b_upload_patterns
        call    room0b_draw_native
        call    room0b_cache_collision
        lda     #$0b
        sta     <monty_room
        stz     <world_transition_ready
        sec
        rts

.room0d:
        call    room0d_upload_patterns
        call    room0d_draw_native
        call    room0d_cache_collision
        lda     #$0d
        sta     <monty_room
        stz     <world_transition_ready
        sec
        rts

.room0e:
        call    room0e_upload_patterns
        call    room0e_draw_native
        call    room0e_cache_collision
        lda     #$0e
        sta     <monty_room
        stz     <world_transition_ready
        sec
        rts

; Tail-room collision caches. Every payload is exactly 648 contiguous bytes:
; 640 collision-map bytes followed by 8 property bytes. Absolute JMPs are used
; because this selector grows as more rooms are ported.
room02_cache_collision:
        lda     #<room02_collision_map_rom
        sta     <_bp
        lda     #>room02_collision_map_rom
        sta     <_bp+1
        ldy     #BANK(room02_collision_map_rom)
        jmp     room_tail_cache_collision

room03_cache_collision:
        lda     #<room03_collision_map_rom
        sta     <_bp
        lda     #>room03_collision_map_rom
        sta     <_bp+1
        ldy     #BANK(room03_collision_map_rom)
        jmp     room_tail_cache_collision

room04_cache_collision:
        lda     #<room04_collision_map_rom
        sta     <_bp
        lda     #>room04_collision_map_rom
        sta     <_bp+1
        ldy     #BANK(room04_collision_map_rom)
        jmp     room_tail_cache_collision

room0a_cache_collision:
        lda     #<room0a_collision_map_rom
        sta     <_bp
        lda     #>room0a_collision_map_rom
        sta     <_bp+1
        ldy     #BANK(room0a_collision_map_rom)
        jmp     room_tail_cache_collision

room0b_cache_collision:
        lda     #<room0b_collision_map_rom
        sta     <_bp
        lda     #>room0b_collision_map_rom
        sta     <_bp+1
        ldy     #BANK(room0b_collision_map_rom)
        jmp     room_tail_cache_collision

room0d_cache_collision:
        lda     #<room0d_collision_map_rom
        sta     <_bp
        lda     #>room0d_collision_map_rom
        sta     <_bp+1
        ldy     #BANK(room0d_collision_map_rom)
        jmp     room_tail_cache_collision

room0e_cache_collision:
        lda     #<room0e_collision_map_rom
        sta     <_bp
        lda     #>room0e_collision_map_rom
        sta     <_bp+1
        ldy     #BANK(room0e_collision_map_rom)

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
; Keep the common target as an absolute JMP because this table also grows.
room01_upload_patterns:
        lda     #<room01_patterns
        sta     <_bp
        lda     #>room01_patterns
        sta     <_bp+1
        ldy     #BANK(room01_patterns)
        jmp     room_upload_9_patterns

room02_upload_patterns:
        lda     #<room02_patterns
        sta     <_bp
        lda     #>room02_patterns
        sta     <_bp+1
        ldy     #BANK(room02_patterns)
        jmp     room_upload_9_patterns

room03_upload_patterns:
        lda     #<room03_patterns
        sta     <_bp
        lda     #>room03_patterns
        sta     <_bp+1
        ldy     #BANK(room03_patterns)
        jmp     room_upload_9_patterns

room04_upload_patterns:
        lda     #<room04_patterns
        sta     <_bp
        lda     #>room04_patterns
        sta     <_bp+1
        ldy     #BANK(room04_patterns)
        jmp     room_upload_9_patterns

room0a_upload_patterns:
        lda     #<room0a_patterns
        sta     <_bp
        lda     #>room0a_patterns
        sta     <_bp+1
        ldy     #BANK(room0a_patterns)
        jmp     room_upload_9_patterns

room0b_upload_patterns:
        lda     #<room0b_patterns
        sta     <_bp
        lda     #>room0b_patterns
        sta     <_bp+1
        ldy     #BANK(room0b_patterns)
        jmp     room_upload_9_patterns

room0d_upload_patterns:
        lda     #<room0d_patterns
        sta     <_bp
        lda     #>room0d_patterns
        sta     <_bp+1
        ldy     #BANK(room0d_patterns)
        jmp     room_upload_9_patterns

room0e_upload_patterns:
        lda     #<room0e_patterns
        sta     <_bp
        lda     #>room0e_patterns
        sta     <_bp+1
        ldy     #BANK(room0e_patterns)

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

; Draw selectors also use absolute JMPs for branch-range safety.
room01_draw_native:
        lda     #<room01_screen_bat
        sta     <_bp
        lda     #>room01_screen_bat
        sta     <_bp+1
        ldy     #BANK(room01_screen_bat)
        jmp     room_draw_native_36x20

room02_draw_native:
        lda     #<room02_screen_bat
        sta     <_bp
        lda     #>room02_screen_bat
        sta     <_bp+1
        ldy     #BANK(room02_screen_bat)
        jmp     room_draw_native_36x20

room03_draw_native:
        lda     #<room03_screen_bat
        sta     <_bp
        lda     #>room03_screen_bat
        sta     <_bp+1
        ldy     #BANK(room03_screen_bat)
        jmp     room_draw_native_36x20

room04_draw_native:
        lda     #<room04_screen_bat
        sta     <_bp
        lda     #>room04_screen_bat
        sta     <_bp+1
        ldy     #BANK(room04_screen_bat)
        jmp     room_draw_native_36x20

room0a_draw_native:
        lda     #<room0a_screen_bat
        sta     <_bp
        lda     #>room0a_screen_bat
        sta     <_bp+1
        ldy     #BANK(room0a_screen_bat)
        jmp     room_draw_native_36x20

room0b_draw_native:
        lda     #<room0b_screen_bat
        sta     <_bp
        lda     #>room0b_screen_bat
        sta     <_bp+1
        ldy     #BANK(room0b_screen_bat)
        jmp     room_draw_native_36x20

room0d_draw_native:
        lda     #<room0d_screen_bat
        sta     <_bp
        lda     #>room0d_screen_bat
        sta     <_bp+1
        ldy     #BANK(room0d_screen_bat)
        jmp     room_draw_native_36x20

room0e_draw_native:
        lda     #<room0e_screen_bat
        sta     <_bp
        lda     #>room0e_screen_bat
        sta     <_bp+1
        ldy     #BANK(room0e_screen_bat)

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
