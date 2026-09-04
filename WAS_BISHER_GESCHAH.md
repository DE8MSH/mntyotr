# Was bisher geschah

Stand: 2026-09-04 — Phase 40

## Portierungsstand

**Gesamtport: ca. 50 %**

Phase 39 ist lokal bestaetigt. Raum $02, seine Collision und alle fuenf originalen Decors laufen stabil. Phase 40 bereitet Raum $03 jetzt exakt als ROM-Tail-Asset vor, ohne ihn bereits in die aktive Weltkette einzuschalten.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigter Runtime-Stand

- Raum $00 und $01 funktionieren mit Boden, Gehen, Springen, Landen und Animationen.
- Raum $01 zeigt die originalen `purple_flowers` und `bunch_flower`.
- Raum $02 ist aktiv, spielbar und besitzt seine fuenf originalen Decors.
- Room-$02-Collision nutzt den bestaetigten 648-Byte-RAM-Cache.
- Raum $02 -> $01 nach rechts funktioniert; links aus Raum $02 bleibt in Phase 40 noch gesperrt.
- Raum $00 rechts bleibt korrekt gesperrt.

## Phase 40 — Raum $03 vorbereiten

Die C64-RLE-Daten fuer Raum $03 wurden exakt aus `Room.Data.tilemap.rm_03` uebernommen:

`f1 f1 51 10 e1 20 51 31 f0 b0 f0 f0 f0 f0 f0 50 52 31 f0 c0 21 33 e0 22 90 73 40 04 f0 10 a3 10 04 52 b0 30 33 40 04 f0 10 30 33 40 04 f0 10 c0 04 b0 05 40 c0 04 70 36 05 40 c0 04 b0 05 40 c0 04 b0 05 40 c0 04 b0 05 40 f0 17 38 17 10 05 40 a3 f1 41 f3 43 a1 ff ff`

Die 16-Byte-Raumdefinition ist:

- Tile-IDs: `$01,$2f,$00,$65,$5f,$44,$11,$55`
- Farben: `$07,$03,$0b,$05,$03,$04,$06,$0e` (Low-Nibble der C64-Farbbytes)
- Collision-Properties nach `Monty.SetTileProperty`: `1,2,1,3,3,2,1,4`

Die acht Tile-Bitmaps stammen direkt aus `Tiles.tile_library`. `tools/room03.py` erzeugt daraus wie bei den bisherigen Raeumen exakt 640 dekodierte Zellen, den 36x20-BAT und 9 PCE-Hintergrundpatterns inklusive Blank-Char 0.

`src/room03_assets_tail.asm` bindet Pattern, Collision-Map, Properties und BAT ausschliesslich hinter dem bestaetigten Runtime-Code ein. Damit dient Phase 40 zuerst als weiterer ROM-Wachstumstest; weder World-Gate noch Physics noch Room-Loader wurden fuer Raum $03 aktiviert.

C64 light blue `$0e` wird im vorbereiteten BAT bereits auf den freien PCE-Palettenslot 15 abgebildet. Die eigentliche Initialisierung dieses Slots erfolgt erst beim Aktivieren von Raum $03, damit Phase 40 keine unnoetige Runtime-Aenderung einfuehrt.

## Regressionstest

`tools/test_room03.py` prueft RLE-Laenge/Decode, Tile-IDs, Farben, Properties, mehrere exakte Tile-Bitmaps, 9 erzeugte Patterns, 36x20-Randspiegelung sowie die ROM-Tail-Bindung.

`build.sh` fuehrt den Room-$03-Test aus und generiert `room03-map.dat`, `room03-screen-bat.dat` und `room03-patterns.dat` vor PCEAS.

## Commits Phase 40

- `fb6f58bec099b887b8d6592e0e2cd81103681853` — exakter Room-$03-Generator
- `31c86d2c5ed08d25c115ca190f39b5ebf8160f01` — Room-$03-Regressionstest
- `d744a1a45402fca4d39620211499249a110f3add` — Room-$03-ROM-Tail-Assets
- `98234d7dd6a18768bde799e5223c388fe93e7c4c` — Tail-Asset in Main eingebunden
- `acd8d2f1f14f793e52d20127fe0bd1f78505aaa0` — Build erzeugt und testet Room $03

## Erwartetes Resultat

Nach `git pull && ./build.sh` soll sich im Spiel **noch nichts sichtbar veraendern**. Raum $00/$01/$02, Decors, Gehen, Springen und Collision sollen genauso laufen wie im bestaetigten Phase-39-Stand. Raum $03 bleibt links von $02 noch gesperrt. Wenn dieser ROM-Wachstumstest stabil ist, aktiviert Phase 41 Raum $03 mit RAM-Collision-Cache und dem fehlenden light-blue-Palettenslot.

## Naechste Portschritte

1. Phase 40 lokal bestaetigen.
2. Raum $03 aktivieren: Loader, World-Gate, Jump-Edge-Guard, RAM-Collision-Cache, Palette $0e.
3. Room-$03-Decors portieren.
4. Danach weitere Raeume entlang der Original-Weltkarte.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
