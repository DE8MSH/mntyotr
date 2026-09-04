# Was bisher geschah

Stand: 2026-09-04 — Phase 43b

## Portierungsstand

**Gesamtport: ca. 53 %**

Phase 42 wurde vom Nutzer lokal bestaetigt: das zusaetzliche Room-$04-ROM-Tail-Wachstum hat die bestaetigten Raeume $00-$03 nicht destabilisiert. Phase 43 aktiviert Raum $04 als fuenften echten Raum. Beim ersten lokalen Build von Phase 43 stoppte nur ein veralteter Python-Regressionstest (`tools/test_room02.py`). Phase 43a aktualisierte die Kette, besass aber noch eine zweite zu fragile Kommentar-Assertion. Phase 43b ersetzt diese nun durch eine strukturelle Pruefung der echten Jump-Guard-Instruktionen. Runtime-Code wurde dabei nicht veraendert.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigter Runtime-Stand vor Phase 43

- Raum $00/$01 funktionieren mit Boden, Gehen, Springen, Landen und Animationen.
- Raum $01 zeigt `purple_flowers` und `bunch_flower`.
- Raum $02 ist spielbar und besitzt seine fuenf originalen Decors.
- Raum $03 ist spielbar und lokal bestaetigt.
- Tail-Raeume $02/$03 nutzen den bestaetigten gemeinsamen 648-Byte-RAM-Collision-Cache.
- Aktive Kette vor Phase 43: `$03 <-> $02 <-> $01 <-> $00`.

## Phase 43 — Raum $04 aktiv

Raum $04 verwendet die in Phase 42 exakt vorbereiteten C64-Daten:

- RLE aus `Room.Data.tilemap.rm_04`
- Tile-IDs `$03,$62,$3c,$60,$43,$66,$02,$4f`
- Farben `$03,$03,$04,$07,$05,$07,$0d,$09`
- Collision-Properties `1,3,2,3,2,3,1,4`
- originale Bitmaps aus `Tiles.tile_library`

`room_loader.asm` besitzt jetzt einen echten Room-$04-Pfad. Beim Eintritt werden die 9 room-spezifischen Patterns und der 36x20-BAT bankfest geladen. Danach werden die 640 Collision-Bytes plus 8 Properties aus `room04_assets_tail.asm` in denselben bewaehrten `room02_*`-RAM-Cache kopiert, den bereits Raum $02/$03 benutzen.

`collision_banking.asm` behandelt jetzt alle aktiven Tail-Raeume ab $03 gleich: die echte Room-ID wird in `collision_actual_room` gesichert, waehrend die unveraenderte `monty_physics.asm` temporaer Room $02 sieht und damit exakt den bestaetigten RAM-Pointerpfad weiterbenutzt. Vor `world_resolve_exit` wird die echte Room-ID wiederhergestellt.

`world.asm` akzeptiert jetzt Room-IDs $00-$04. Die aktive horizontale Originalkette ist damit:

`$04 <-> $03 <-> $02 <-> $01 <-> $00`

Links aus Raum $04 bleibt Raum $05 noch gesperrt; rechts aus Raum $00 bleibt die originale `$ff`-Wand. Der Jump-Edge-Guard wurde entsprechend von der linken Room-$03-Kante auf die linke Room-$04-Kante verschoben. Damit darf `$03 -> $04` gehend und springend funktionieren, ohne dass ein Sprung links aus dem noch letzten geladenen Raum $04 herauskommt.

## Phase 43a/43b — Build-Tests korrigiert

Der erste lokale Build brach in `tools/test_room02.py` an einer alten String-Assertion ueber die Room-Kette ab. Phase 43a aktualisierte diese auf `$04 <-> $03 <-> $02 <-> $01 <-> $00`, liess aber noch eine zweite Kommentar-Assertion `Room $04 left` stehen. Der Runtime-Kommentar lautet tatsaechlich kompakter `$00 right/$04 left`, deshalb schlug auch diese Assertion fehl.

Phase 43b prueft jetzt nicht mehr zufaellige Kommentarformulierung, sondern den echten Guard-Block in `src/main.asm`: `collision_actual_room`, `cmp #4`, `monty_room_exit`, `cmp #1`, Clamp auf `$15` und Loeschen von `monty_room_exit`. Damit testet `test_room02.py` jetzt das Verhalten und nicht den Wortlaut eines Kommentars.

## Regressionstests

Aktualisiert sind jetzt:

- `tools/test_room02.py` — Phase-43-Kette, World-Gate und struktureller Room-$04-Left-Guard
- `tools/test_room03.py` — Room $04 ist linker Nachbar
- `tools/test_room04.py` — aktiver Loader, World-Gate, Collision-Cache und Jump-Gate
- `tools/test_collision_banking.py` — gemeinsamer Room-$02/$03/$04-RAM-Cache
- `tools/test_jump_edge_guard.py` — neue aeussere Kante an Room $04

`monty_physics.asm` wurde fuer Phase 43/43a/43b bewusst nicht veraendert.

## Commits Phase 43 / 43a / 43b

- `f8ae9d7dca5cd30694d54297d01595ebff665355` — Room $04 ueber Shared-Collision-Cache gespiegelt
- `79b915f8773a1e867ca29c113e890a2c631ddcc0` — Room-$04-Loader, Draw und Collision-Cache aktiviert
- `2b891c2f8db45ddd16a8597a50d16c9ddecff9bb` — World-Gate auf $00-$04 erweitert
- `544025d2b2728cd00808f0e2a5cff7228f397213` — Jump-Transition $03->$04 aktiviert
- `6cb8888da790e740b5242a6f3e0e9eb1f30816f9` — Room-$04-Test aktiviert
- `0b0eedef454ecd89a0174a7fd2f8b84cea6e0fe1` — Collision-Banking-Test erweitert
- `8b3a75b2c81fdb7355cd4df3438377a4ded5f10b` — Jump-Edge-Test auf Room $04 erweitert
- `68593623ec7f41b7d606ade7e9cf9bf6287cb516` — Room-$03-Test an neuen Nachbarn angepasst
- `c2cace66c3234d53dead7392cc709d717d309ee9` — Room-$02-Test auf Phase-43-Kette aktualisiert
- `a3b3dab619086f8d29ada6f8cea2de8f2db18a5a` — fragile Kommentar-Assertion durch strukturellen Guard-Test ersetzt

## Erwartetes Resultat

Nach erneutem `git pull && ./build.sh` soll `test_room02.py` jetzt an beiden bisherigen Assertion-Stellen vorbeilaufen. Danach sollen die restlichen Python-Tests und PCEAS folgen. Im Spiel sollen die Raeume $00-$03 unveraendert funktionieren. Von Raum $03 geht es nach links in Raum $04, sowohl gehend als auch springend. In Raum $04 muss Monty sofort laufen, springen und landen koennen; nach rechts geht es zurueck nach Raum $03. Links aus Raum $04 bleibt gesperrt, bis Raum $05 portiert ist.

## Naechste Portschritte

1. Phase 43/43a/43b lokal bestaetigen.
2. Originale Room-$03-Decors portieren.
3. Originale Room-$04-Decors portieren.
4. Danach Raum $05 mit exakten C64-Daten vorbereiten/aktivieren.
5. Weitere Raeume; danach Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
