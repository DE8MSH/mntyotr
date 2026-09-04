; Native room $00 renderer following the C64 screen geometry.
; refactored Room.DrawRoomPlayfield copies 32x20 chars to C64 cols 4..35,
; rows 3..22; Room.CreatePlayfieldBorder mirrors the edge chars into cols
; 2..3 and 36..37.  We render that 36-column window directly into the PCE BAT.

ROOM_X = 2
ROOM_Y = 3
ROOM_SCREEN_W = 36
ROOM_ROW_BYTES = ROOM_SCREEN_W * 2

.code

draw_room00_native:
        lda #<((3)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((3)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat,VDC_DL,72
        lda #<((4)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((4)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+72,VDC_DL,72
        lda #<((5)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((5)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+144,VDC_DL,72
        lda #<((6)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((6)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+216,VDC_DL,72
        lda #<((7)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((7)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+288,VDC_DL,72
        lda #<((8)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((8)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+360,VDC_DL,72
        lda #<((9)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((9)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+432,VDC_DL,72
        lda #<((10)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((10)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+504,VDC_DL,72
        lda #<((11)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((11)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+576,VDC_DL,72
        lda #<((12)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((12)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+648,VDC_DL,72
        lda #<((13)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((13)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+720,VDC_DL,72
        lda #<((14)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((14)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+792,VDC_DL,72
        lda #<((15)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((15)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+864,VDC_DL,72
        lda #<((16)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((16)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+936,VDC_DL,72
        lda #<((17)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((17)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+1008,VDC_DL,72
        lda #<((18)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((18)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+1080,VDC_DL,72
        lda #<((19)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((19)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+1152,VDC_DL,72
        lda #<((20)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((20)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+1224,VDC_DL,72
        lda #<((21)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((21)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+1296,VDC_DL,72
        lda #<((22)*BAT_LINE+ROOM_X)
        sta <_di+0
        lda #>((22)*BAT_LINE+ROOM_X)
        sta <_di+1
        call vdc_di_to_mawr
        tia room00_screen_bat+1368,VDC_DL,72
        rts

.data
room00_collision_map:
        incbin "room00-map.dat"
room00_native_bat:
        incbin "room00-bat.dat"
room00_screen_bat:
        incbin "room00-screen-bat.dat"
