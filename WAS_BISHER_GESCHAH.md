# Was bisher geschah

Stand: 2026-09-04 — Phase 43

## Portierungsstand

**Gesamtport: ca. 53 %**

Phase 42 wurde vom Nutzer lokal bestaetigt: das zusaetzliche Room-$04-ROM-Tail-Wachstum hat die bestaetigten Raeume $00-$03 nicht destabilisiert. Phase 43 aktiviert Raum $04 jetzt als fuenften echten Raum.

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

## Regressionstests

Aktualisiert wurden:

- `tools/test_room04.py` — aktiver Loader, World-Gate, Collision-Cache und Jump-Gate
- `tools/test_collision_banking.py` — gemeinsamer Room-$02/$03/$04-RAM-Cache
- `tools/test_jump_edge_guard.py` — neue aeussere Kante an Room $04
- `tools/test_room03.py` — Room $04 ist nun linker Nachbar

`monty_physics.asm` wurde fuer Phase 43 bewusst nicht veraendert.

## Commits Phase 43

- `f8ae9d7dca5cd30694d54297d01595ebff665355` — Room $04 ueber Shared-Collision-Cache gespiegelt
- `79b915f8773a1e867ca29c113e890a2c631ddcc0` — Room-$04-Loader, Draw und Collision-Cache aktiviert
- `2b891c2f8db45ddd16a8597a50d16c9ddecff9bb` — World-Gate auf $00-$04 erweitert
- `544025d2b2728cd00808f0e2a5cff7228f397213` — Jump-Transition $03->$04 aktiviert
- `6cb8888da790e740b5242a6f3e0e9eb1f30816f9` — Room-$04-Test aktiviert
- `0b0eedef454ecd89a0174a7fd2f8b84cea6e0fe1` — Collision-Banking-Test erweitert
- `8b3a75b2c81fdb7355cd4df3438377a4ded5f10b` — Jump-Edge-Test auf Room $04 erweitert
- `68593623ec7f41b7d606ade7e9cf9bf6287cb516` — Room-$03-Test an neuen Nachbarn angepasst

## Erwartetes Resultat

Nach `git pull && ./build.sh` sollen die Raeume $00-$03 unveraendert funktionieren. Von Raum $03 geht es jetzt nach **links in Raum $04**, sowohl gehend als auch springend. In Raum $04 muss Monty sofort laufen, springen und landen koennen; Collision/Boden duerfen nicht ausfallen. Nach rechts geht es zurueck nach Raum $03. Links aus Raum $04 bleibt gesperrt, bis Raum $05 portiert ist.

## Naechste Portschritte

1. Phase 43 lokal bestaetigen.
2. Originale Room-$03-Decors portieren.
3. Originale Room-$04-Decors portieren.
4. Danach Raum $05 mit exakten C64-Daten vorbereiten/aktivieren.
5. Weitere Raeume; danach Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
