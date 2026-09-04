# Was bisher geschah

Stand: 2026-09-04 — Phase 32

## Portierungsstand

**Gesamtport: ca. 44 %**

Der Nutzer hat Phase 31 visuell bestaetigt: `sad_flowers` ist sichtbar. Phase 32 beginnt jetzt den eigentlichen Mehrraum-Port und bindet Raum $01 als ersten echten Nachbarraum an.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Raum $00 Basisgrafik und alle neun statischen Decor-Records sind sichtbar; `sad_flowers` wurde vom Nutzer bestaetigt.
- Montys Start-/SAT-Position, Gehen, Springen, Falling, Plattform-Landung und Hauseingang funktionieren.
- 12+12 Somersaultframes funktionieren visuell korrekt.
- Walk links/rechts, Climb und Somersault benutzen bankfeste Far-Pointer-Uploads; der fruehere Rechtslauf-Grafikfehler ist behoben.

## Phase 32 — erster echter Raumwechsel $00 <-> $01

Die C64-Weltkarte setzt Raum $00 auf Zeile 2 / Spalte $15. Links davon liegt exakt Raum $01. Der vorhandene World-Code konnte dieses Ziel bereits bestimmen, hat bisher aber absichtlich keinen Raum geladen.

Phase 32 fuegt nun den ersten echten zweiten Raum hinzu:

- `tools/room01.py` enthaelt den exakten RLE-Stream `Room.Data.tilemap.rm_01`.
- Die 16-Byte-Raumdefinition fuer Raum $01 wird umgesetzt: Tile-Library-IDs `$02,$63,$01,$0a,$40,$05,$55,$64` sowie C64-Farben `$04,$03,$03,$05,$01,$0a,$06,$05` (der Quellwert `$63` im Farbteil wird wie echte VIC-Colour-RAM-Daten ueber das Low-Nibble als `$03` behandelt).
- Die acht exakten Tile-Bitmaps kommen aus `Tiles.tile_library`.
- `Monty.SetTileProperty` ergibt fuer diese acht Custom-Tiles exakt die Properties `1,0,1,1,2,1,4,0`.
- `tools/room01.py` erzeugt daraus `room01-map.dat`, `room01-screen-bat.dat` und `room01-patterns.dat`.

## Native PCE-Seite

Neu sind `src/room01_assets.asm`, `src/room01_native.asm` und `src/room_loader.asm`.

Raum $01 ueberschreibt beim Eintritt die gemeinsamen Custom-Character-Slots 0..8 in VRAM, genauso wie die C64-`SetupTileGraphics`-Routine pro Raum neue Zeichen 1..8 installiert. Der Upload benutzt `map_bp_to_mpr34`, damit das bekannte HuCard-ROM-Banking-Problem nicht erneut bei wachsenden Datenbloecken auftritt.

Der 36x20-BAT von Raum $01 wird ebenfalls bankfest aus ROM gelesen und zeilenweise in die 64x32-PCE-BAT geschrieben. Die zwei fuer Raum $01 zusaetzlich benoetigten C64-Farben Purple `$04` und Blue `$06` liegen in den noch freien BG-Palettenslots 13 und 14.

`src/main.asm` ruft nach einem erfolgreichen `world_resolve_exit` jetzt `room_load_pending` auf. Damit soll links aus Raum $00 erstmals wirklich Raum $01 erscheinen; rechts aus Raum $01 wird Raum $00 inklusive dessen Decor wiederhergestellt.

## Collision

Die bisherigen Collision-Routinen sind nicht mehr fest auf die Raum-$00-Daten beschraenkt. `room00_get_tile_xy`/`room00_get_tile_property` behalten vorerst ihre historischen Namen, waehlen intern aber anhand `monty_room` zwischen:

- `room00_collision_map` + `room00_tile_properties`
- `room01_collision_map` + `room01_tile_properties`

Damit benutzt Raum $01 seine eigene 32x20-Geometrie und seine eigenen C64-Properties, statt versehentlich mit dem Hausgrundriss von Raum $00 zu kollidieren.

Da bisher nur $00 und $01 voll geladen werden koennen, blockiert `world_resolve_exit` voruebergehend Ziele ab Raum $02. Dadurch kann Monty am linken Rand von Raum $01 noch nicht in Raum $02 wechseln und die World-Koordinaten koennen nicht in einen noch ungeladenen Raum driften. Diese Schranke wird mit jedem neu portierten Raum erweitert.

## Tests

Neu ist `tools/test_room01.py`. Es prueft den 640-Zellen-RLE-Decode, die exakten Tile-IDs, Farben, Properties, 9 PCE-Patterns, 36x20-Gutter-Geometrie und die Loader-/Collision-Verdrahtung. `build.sh` erzeugt die drei Raum-$01-Dateien vor PCEAS und fuehrt den Test automatisch aus.

## Verifikationsstatus

- Phase 31 (`sad_flower`) ist vom Nutzer visuell bestaetigt.
- Phase 32 ist hochgeladen, aber noch nicht lokal mit dem Nutzer-PCEAS gebaut.
- Als naechstes `git pull && ./build.sh`.
- Danach aus Raum $00 ganz nach links gehen: Raum $01 sollte geladen werden. Dort etwas bewegen/springen und anschliessend nach rechts zurueck in Raum $00 gehen.
- Raum-$01-Decor und Gegner sind noch nicht portiert; in Phase 32 geht es zunaechst um den echten Raumdaten-/Tile-/Collision-/Transition-Pfad.

## Naechste Portschritte

1. Phase 32 lokal bauen und $00 <-> $01 visuell sowie collision-seitig pruefen.
2. Die zwei originalen Raum-$01-Decor-Records (Types `$42` und `$41`) anbinden.
3. Danach Raum $02 in denselben Loader aufnehmen und die temporaere `room < 2`-Schranke erweitern.
4. Den Loader schrittweise auf die restlichen `Room.Data.tilemap_ptrs`/`room_defs` verallgemeinern.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen auf dem Mehrraum-Unterbau.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
