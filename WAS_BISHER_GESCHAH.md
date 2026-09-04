# Was bisher geschah

Stand: 2026-09-04 — Phase 36

## Portierungsstand

**Gesamtport: ca. 46 %**

Phase 35 ist vom Nutzer lokal bestaetigt: der neue bankfeste Collision-MPR-Pfad veraendert das Gameplay nicht. Monty startet, laeuft, springt, landet und wechselt zwischen Raum $00 und $01 weiterhin korrekt. Damit ist der technische Unterbau fuer erneutes ROM-Wachstum jetzt erstmals praktisch bestaetigt.

Phase 36 aktiviert deshalb den zuvor wegen der Fall-durch-Boden-Regression zurueckgerollten Room-$01-Decor-Pfad erneut — diesmal auf dem bestaetigten Phase-35-Collision-Banking.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigter Runtime-Stand

- Monty ist steuerbar.
- Gehen, Springen, Falling und Landung funktionieren.
- Walk/Climb und 12+12 Somersaultframes funktionieren visuell.
- Raum $00 -> $01 nach links funktioniert beim Gehen und Springen.
- Raum $01 -> $00 nach rechts funktioniert.
- Rechts neben Raum $00 liegt im Original `$ff`; Heraus-Springen nach rechts ist blockiert.
- Phase 35 Collision-Banking ist lokal bestaetigt.

## Phase 35 — Collision-ROM-Banking bankfest

Die aktive Collision-Map wird waehrend des Physics-Slices explizit ueber `BANK(room00_collision_map)` bzw. `BANK(room01_collision_map)` in MPR3/MPR4 gemappt. `monty_physics.asm` selbst blieb unveraendert; die direkten C64-artigen `[collision_ptr],y`-Reads arbeiten damit unabhaengig von der spaeteren ROM-Anordnung.

Der Nutzer hat Phase 35 im Emulator bestaetigt. Damit ist jetzt belegt, dass dieser Mapping-Layer den bekannten Gameplay-Pfad nicht veraendert.

## Phase 36 — Room-$01-Decor wieder aktiv

Room $01 besitzt in der Original-`Decor.room_list` zwei Eintraege:

- `$01,$03,$11,$42` -> `purple_flowers`, 4x4 Zeichen
- `$01,$1d,$07,$41` -> `bunch_flower`, 3x3 Zeichen

`tools/room01_decor.py` enthaelt die exakten C64-Bitmaps und Farbstreams. Es erzeugt 25 PCE-Hintergrundzeichen (800 Byte) und ueberlagert den generierten 36x20-BAT von Raum $01 mit den beiden Objekten.

Neu/reaktiviert:

- `src/room01_assets.asm` bindet `room01-decor-patterns.dat` wieder ein.
- `src/room01_decor_loader.asm` kopiert die 800 Byte bankfest via `map_bp_to_mpr34` in die gemeinsamen Decor-VRAM-Slots ab `CHR_GAME+9`.
- `src/main.asm` bindet den isolierten Decor-Loader ein.
- `src/room_loader.asm` ruft bei Raum $01 `room01_upload_patterns`, `room01_upload_decor` und `room01_draw_native` per absolutem `call` auf.
- Beim Rueckweg nach Raum $00 wird weiterhin `upload_room00_patterns` aufgerufen; diese Routine schreibt sowohl die 9 Basiszeichen als auch alle 41 Room-$00-Decorzeichen neu. Damit bleiben keine Room-$01-Decors im gemeinsam verwendeten VRAM zurueck.
- `build.sh` fuehrt `tools/test_room01_decor.py` aus und erzeugt danach `room01-decor-patterns.dat` sowie den dekorierten `room01-screen-bat.dat`.

## Regressionstest

`tools/test_room01_decor.py` prueft jetzt nicht nur die exakten beiden Decor-Overlays, sondern auch:

- 25 generierte Decorzeichen,
- exakte Type-Reihenfolge `$42` vor `$41`,
- korrekte Palette pro Zeichen,
- `room01_decor_patterns` ist eingebunden,
- Decor-Upload verwendet `BANK(room01_decor_patterns)` und `map_bp_to_mpr34`,
- der Loader verwendet `call`, nicht reichweitenempfindliches `bsr`,
- der Rueckweg nach Raum $00 stellt dessen 41 Decorzeichen wieder her.

## Commits Phase 36

- `45eeae2d81c87039cb8a4bf7d5abd84ac847943c` — bankfester Room-$01-Decor-Uploader
- `5b4dba40e6eac14fef12756cced90838522818fb` — Room-$01-Decorpatterns wieder eingebunden
- `97f1e4add2f36f423758cfc7aecb5023d12d1273` — isolierten Decor-Loader in Main eingebunden
- `e61b4680b8e14f3580d263466d1a5b050312b04a` — Room-Loader aktiviert Decor und stellt Room-$00-VRAM sauber wieder her
- `c75b5b397653363c1f57a9624e54879bb73197c2` — Build erzeugt/testet Room-$01-Decor
- `90e023c6f718e78fecc9e9bc3657dceeccfde94d` — Regressionstest erweitert

## Erwartetes Resultat

Das ist jetzt der entscheidende Stresstest fuer Phase 35. Nach `git pull && ./build.sh` soll:

1. Monty in Raum $00 weiterhin normal auf dem Boden stehen und steuerbar sein.
2. Springen/Landen unveraendert funktionieren; kein Fall-durch-Boden.
3. Raum $00 -> $01 links weiter beim Gehen und Springen funktionieren.
4. In Raum $01 `purple_flowers` und `bunch_flower` sichtbar sein.
5. Die Collision in Raum $01 weiterhin korrekt funktionieren.
6. Raum $01 -> $00 rechts funktionieren und Raum $00 danach seine eigenen Decors korrekt anzeigen.
7. Raum $00 rechts weiterhin gesperrt bleiben.

Wenn genau das funktioniert, ist die fruehere Regression durch ROM-Wachstum praktisch widerlegt bzw. durch das Phase-35-Banking behoben. Danach kann Raum $02 portiert werden.

## Verifikationsstatus

Phase 36 ist hochgeladen, aber noch nicht mit dem lokalen PCEAS/Mednafen des Nutzers verifiziert.

## Naechste Portschritte

1. Phase 36 lokal bestaetigen.
2. Bei Erfolg Raum $02 mit exaktem RLE, Tiles, Farben, Properties und Decors portieren.
3. Danach den Mehrraum-Loader weiter verallgemeinern.
4. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
