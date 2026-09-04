; PC Engine VRAM layout for Monty on the Run.
; init_256x224 uses a 64x32 BAT.

BAT_LINE        = 64
BAT_SIZE        = 64 * 32
SAT_ADDR        = BAT_SIZE

; 8x8 background tiles occupy 16 VRAM words each.
CHR_ZERO        = BAT_SIZE / 16
CHR_FONT        = CHR_ZERO + 16
CHR_ASCII_ZERO  = CHR_FONT

; Game graphics will begin after the 112-tile diagnostic font allocation.
CHR_GAME        = CHR_FONT + 112
