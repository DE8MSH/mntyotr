# C64 room format -> PC Engine mapping

This is an implementation note derived from the refactored C64 reconstruction.
It deliberately describes the data model rather than copying the original commercial binary.

## World navigation

The C64 reconstruction uses a 6 x 23 destination grid. Each cell contains a room id or `$FF` for a blocked/nonexistent neighbour. A per-row offset table selects one of the 23-byte rows. Completion room `$30` is force-loaded by completion logic rather than entered through this grid.

## Room indexes

The room-data block contains parallel pointer tables indexed by `room_id * 2`:

- tilemap stream pointer
- enemy spawn stream pointer

The definition table is indexed from the room id with a fixed-size room definition record.

## Playfield geometry

The C64 room renderer ultimately produces a 32-tile-wide playfield. The screen itself is 40 characters wide. Rendering starts inside that screen and the border routine mirrors the first/last playfield tile into two-character gutters.

The gameplay room window is 20 rows high.

For the PC Engine port we keep the logical room geometry at exactly:

```
ROOM_COLS = 32
ROOM_ROWS = 20
ROOM_CELLS = 640
```

The PCE BAT stride is independent from the logical room width.

## Colour model

Normal C64 room tile codes 1..8 map to one of eight room-specific colour entries. Codes outside that range include blank/special/animated cases and need explicit handling rather than normal colour lookup.

The PCE representation therefore stores a logical tile id separately from its PCE palette/pattern mapping. This is important: collision/game logic must continue to see C64-semantic tile ids even when several PCE patterns are needed to reproduce one C64 visual.

## Enemy spawn records

Per-room enemy streams contain variable numbers of seven-byte records terminated by `$FF`. The original engine has four enemy state slots, so the PCE gameplay model reserves four equivalent active slots before adding any platform-specific rendering state.

## Porting rule

Do not make the PCE BAT itself authoritative game state. Maintain a 32x20 logical room buffer in CPU RAM. Rendering translates that buffer to BAT entries. Collision and mechanisms read the logical buffer. This prevents PCE graphics-format choices from changing C64 gameplay behaviour.

## Next implementation units

- `room_state.asm`: 640-cell logical room state / accessors
- `room_decode.asm`: C64-compatible tilemap-stream decoder
- `room_render.asm`: logical tile -> PCE BAT translation
- generated room-data include files
- comparison fixtures for room `$00`
