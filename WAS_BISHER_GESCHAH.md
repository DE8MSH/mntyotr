# Was bisher geschah

Stand: 2026-09-04 — Phase 37

## Portierungsstand

**Gesamtport: ca. 47 %**

Phase 36a ist vom Nutzer lokal bestaetigt: Monty steht korrekt auf dem Boden, Gehen/Springen/Landen und Raum $00 <-> $01 funktionieren, und die originalen Room-$01-Decors bleiben aktiv. Damit ist das Tail-Asset-Schema als verbindlicher Weg fuer weiteres ROM-Wachstum bestaetigt.

Phase 37 portiert jetzt die Basisdaten von Raum $02 exakt aus der kommentierten C64-Rekonstruktion, aber noch **ohne** den Raum in die aktive Welt-Navigation einzuschalten. So koennen die neuen Daten zuerst als reiner ROM-Tail-Wachstumstest gebaut werden, ohne den bestaetigten Gameplay-Pfad zu veraendern.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigter Runtime-Stand

- Monty ist steuerbar.
- Gehen, Springen, Falling und Landung funktionieren.
- Walk/Climb und 12+12 Somersaultframes funktionieren visuell.
- Raum $00 -> $01 links funktioniert beim Gehen und Springen.
- Raum $01 -> $00 rechts funktioniert.
- Raum $00 rechts ist im Original `$ff` und bleibt gesperrt.
- Room $01 zeigt `purple_flowers` und `bunch_flower`.
- Grosse banked Assets am ROM-Ende verursachen keine Fall-durch-Boden-Regression.

## Phase 36a — Tail-Asset-Schema bestaetigt

Die 800 Byte Room-$01-Decorpattern wurden aus dem fruehen Include-Bereich an das ROM-Ende verschoben. Der Nutzer hat bestaetigt, dass damit Gameplay und Collision wieder korrekt laufen. Ab jetzt werden grosse neue Raum-/Grafikdaten deshalb in separaten Tail-Asset-Dateien abgelegt und ueber explizite `BANK(...)`-Pfade geladen.

## Phase 37 — Raum $02 Basisdaten exakt portiert

Neu ist `tools/room02.py`. Der Generator enthaelt den exakten Room-$02-RLE-Stream aus `Room.Data.tilemap.rm_02` und dekodiert ihn zu 640 C64-Screen-Codes (32x20). Die sichtbare PCE-BAT wird wie bei Raum $00/$01 auf 36x20 erweitert, indem die beiden linken/rechten Border-Spalten die jeweiligen Randzeichen spiegeln.

Room-$02-Definition:

- Tile-IDs: `$02,$01,$27,$60,$3d,$42,$77,$55`
- C64-Farben: `$05,$04,$07,$04,$06,$01,$06,$06`
- Tile-Properties: `1,1,2,3,2,2,0,4`

Die acht Bitmaps sind exakt aus `Tiles.tile_library` uebernommen. Besonders die neuen Eintraege `$27`, `$60`, `$3d`, `$42` und `$77` werden im neuen Regressionstest explizit geprueft.

`src/room02_assets_tail.asm` bindet die generierten Dateien erst im ROM-Tail ein:

- `room02-patterns.dat` — blank char 0 + acht Room-Custom-Chars
- `room02-map.dat` — 640 Collision/Screen-Codes
- `room02-screen-bat.dat` — 36x20 sichtbare PCE-BAT
- `room02_tile_properties` — acht Property-Werte

`src/main.asm` bindet diesen neuen Datenblock erst hinter `monty_sprite.asm` und hinter dem bereits bestaetigten Room-$01-Tail-Assetblock ein. Der aktuelle World-/Physics-/Room-Loader wird in Phase 37 noch nicht auf Raum $02 umgestellt; damit soll dieser Schritt spielerisch zunaechst nichts veraendern.

Neu ist `tools/test_room02.py`. Der Test prueft RLE-Laenge/Decode, Tile-IDs, Farben, Properties, mehrere kritische Tile-Bitmaps, Patternlaenge, Border-Spiegelung, Palette/BAT-Zuordnung und die Tail-Platzierung hinter dem Runtime-Code.

`build.sh` fuehrt `test_room02.py` aus und erzeugt danach die drei Room-$02-Datendateien vor dem PCEAS-Lauf.

## Commits Phase 37

- `96e88b0710a2fb8e625886dd8eb650c296586bd2` — exakter Room-$02-Generator
- `0bf2a6905b1ce89fe4dba66f010ac985c5221563` — Room-$02-Daten als ROM-Tail-Assets
- `6b40d30d66aadea142093e80fc9355596b0d7937` — Room-$02-Regressionstest
- `366e0fbac63a3fdaccaad2688f364b56ee673e6e` — Build erzeugt/testet Room $02
- `13e57b20ebde1ac808c37b5d4832495fdc8f19b2` — Tail-Asset-Include in `main.asm`

## Erwartetes Resultat

Nach `git pull && ./build.sh` soll Phase 37 **noch exakt wie Phase 36a spielen**: Start/Boden, Gehen, Springen, Landen, Room $00 <-> $01 und Room-$01-Decor muessen unveraendert bleiben. Raum $02 ist in diesem Zwischenstand bewusst noch nicht betretbar.

Wenn dieser reine Tail-Wachstumstest stabil bleibt, folgt Phase 37b: Collision-Banking, Physics-Property-Auswahl, World-Gate und Room-Loader werden gemeinsam auf drei aktive Raeume erweitert. Danach wird Raum $02 von Raum $01 aus nach links wirklich betretbar gemacht.

## Naechste Portschritte

1. Phase 37 lokal als regressionsfreien Tail-Wachstumstest bestaetigen.
2. Phase 37b: Raum $02 in Collision/Physics/World/Loader aktivieren.
3. Danach die exakten Room-$02-Decors portieren.
4. Danach weitere Welt-Raeume schrittweise portieren.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
