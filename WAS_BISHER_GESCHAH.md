# Was bisher geschah

Stand: 2026-09-04 — Phase 42

## Portierungsstand

**Gesamtport: ca. 52 %**

Phase 41 ist vom Nutzer lokal bestaetigt: Raum $03 ist als vierter echter Raum aktiv, und die bisherige Kette hat sich nicht verschlechtert. Phase 42 bereitet nun Raum $04 exakt als ROM-Tail-Asset vor, ohne ihn bereits freizuschalten.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigter Runtime-Stand

- Raum $00 und $01 funktionieren mit Boden, Gehen, Springen, Landen und Animationen.
- Raum $01 zeigt die originalen `purple_flowers` und `bunch_flower`.
- Raum $02 ist aktiv, spielbar und besitzt seine fuenf originalen Decors.
- Raum $03 ist aktiv und lokal bestaetigt; $02 -> $03 und $03 -> $02 funktionieren.
- Room-$02/$03-Collision nutzt den bestaetigten gemeinsamen 648-Byte-RAM-Cache-Pfad.
- Die aktive horizontale Kette ist `$03 <-> $02 <-> $01 <-> $00`.
- Links aus Raum $03 bleibt in Phase 42 noch gesperrt; rechts aus Raum $00 bleibt die originale $ff-Wand.

## Phase 42 — Raum $04 vorbereiten

Die C64-RLE-Daten fuer Raum $04 wurden exakt aus `Room.Data.tilemap.rm_04` uebernommen:

`51 00 02 00 d1 00 06 00 51 51 00 02 00 d1 00 06 00 51 31 20 02 c0 11 00 06 60 60 02 d0 01 00 06 60 60 02 d0 01 00 06 60 60 02 50 04 60 41 40 d0 04 55 20 41 20 30 53 30 04 b0 41 d0 04 d0 21 80 53 f0 01 40 06 f0 90 43 06 f0 90 40 06 f0 90 40 06 f0 90 40 06 f0 90 40 06 30 17 78 17 90 40 06 57 78 37 70 30 77 78 97 10 f7 f7 f7 f7 ff ff ff`

Die 16-Byte-Raumdefinition ist:

- Tile-IDs: `$03,$62,$3c,$60,$43,$66,$02,$4f`
- Farben: `$03,$03,$04,$07,$05,$07,$0d,$09`
- Collision-Properties nach `Monty.SetTileProperty`: `1,3,2,3,2,3,1,4`

Die acht Tile-Bitmaps wurden direkt aus `Tiles.tile_library` uebernommen. Darunter sind beispielsweise Tile `$62` = `c6 c6 ee 6c 20 20 6c ec`, Tile `$60` = `38 20 70 20 70 10 38 08`, Tile `$66` = `1e 36 2c 3e 1a 17 0d 0b` und Tile `$4f` = `6e 7e c7 d3 da c3 67 ef`.

`tools/room04.py` dekodiert den RLE-Stream zu exakt 640 Zellen, erzeugt den 36x20-PCE-BAT mit derselben Randspiegelung wie die bisherigen Raeume und erzeugt Blank-Char 0 plus die acht room-spezifischen PCE-Patterns.

`src/room04_assets_tail.asm` bindet Pattern, Collision-Map, Properties und BAT ausschliesslich hinter dem bestaetigten Runtime-Code ein. Room $04 wird noch nicht vom World-Gate oder Loader akzeptiert. Der Schritt ist absichtlich erneut ein ROM-Wachstumstest, bevor wir den fuenften Raum aktivieren.

Room $04 benoetigt keine neue PCE-Hintergrundpalette: seine C64-Farben sind bereits durch die vorhandenen Slots fuer cyan, purple, yellow, green, light green und brown abgedeckt.

## Regressionstest und Build

`tools/test_room04.py` prueft:

- exakte Room-$04-RLE-Dekodierung auf 640 Zellen,
- die acht Tile-IDs, Farben und Properties,
- mehrere originale Tile-Bitmaps,
- 9 erzeugte PCE-Patterns,
- die 36x20-Randspiegelung und Palettenzuordnung,
- dass `room04_assets_tail.asm` hinter `monty_sprite.asm` in `main.asm` eingebunden ist.

`build.sh` fuehrt den Test aus und erzeugt `room04-map.dat`, `room04-screen-bat.dat` und `room04-patterns.dat` vor PCEAS.

## Commits Phase 42

- `c8b66ba745b29c53832fded508ffa7470145f3ed` — exakter Room-$04-Generator
- `d7e39889686d7cddef2e2c77ddeb719858f2ef7c` — Room-$04-Regressionstest
- `15a51a0d8694dd3d519f1823f76d7ecde43a8004` — Room-$04-ROM-Tail-Assets
- `ea14e47b20e83678c209f80b14e8c6991aaeca00` — Room-$04-Tail-Asset in `main.asm` eingebunden
- `9d5cfae47907cb9f68680ad244eb1c85edc182a2` — Build erzeugt und testet Room $04

## Erwartetes Resultat

Nach `git pull && ./build.sh` soll sich im Spiel noch nichts sichtbar veraendern. Raum $00-$03, Decors, Gehen, Springen und Collision sollen genauso laufen wie im bestaetigten Phase-41-Stand. Links aus Raum $03 bleibt Raum $04 noch gesperrt.

Wenn dieser ROM-Wachstumstest lokal stabil ist, wird Room $04 im naechsten Schritt ueber denselben bewaehrten Tail-Room-RAM-Cache-Pfad aktiviert.

## Naechste Portschritte

1. Phase 42 lokal bestaetigen.
2. Raum $04 aktivieren: Loader, World-Gate, Jump-Edge-Guard und Shared-RAM-Collision-Cache.
3. Originale Room-$03/Room-$04-Decors ergaenzen.
4. Weitere Raeume entlang der Original-Weltkarte.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
