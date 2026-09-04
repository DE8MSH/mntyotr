; Phase 36a: exact Room-$01 decor pattern data at the ROM tail.
;
; Keep this large 800-byte block after gameplay/physics code. The bank-safe
; room01_upload_decor routine can read it from any HuCard bank, while appending
; it here prevents the data itself from shifting the already-confirmed
; collision/physics layout.

.data
room01_decor_patterns:
        ; Exact type $42 purple_flowers (4x4) then type $41 bunch_flower (3x3),
        ; preserving the original room-list/type-init order: 25 chars total.
        incbin "room01-decor-patterns.dat"
