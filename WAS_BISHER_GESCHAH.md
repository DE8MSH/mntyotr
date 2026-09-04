# Was bisher geschah

Stand: 2026-09-04 — Phase 44

## Portierungsstand

**Gesamtport: ca. 55 %**

Der Nutzer hat in Phase 43 einen wichtigen Gameplay-Fehler aufgedeckt: Raum $04 war zwar technisch geladen, aber die Aussage, man koenne von Raum $03 einfach links nach $04 gehen, war falsch. In Raum $03 steht eine grosse originale Wand. Die Weltkarte zeigt den echten Weg um diese Wand herum.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigter Stand vor Phase 44

- Raum $00/$01 funktionieren mit Boden, Gehen, Springen, Landen und Animationen.
- Raum $01 zeigt seine portierten Original-Decors.
- Raum $02 ist spielbar und besitzt seine fuenf originalen Decors.
- Raum $03 ist spielbar und lokal bestaetigt.
- Raum $04 besitzt exakte Basisdaten und einen Loader, war aber praktisch noch nicht erreichbar.
- Der gemeinsame 648-Byte-RAM-Collision-Cache fuer Tail-Raeume ist bewaehrt.
- `monty_physics.asm` ist weiterhin die empfindliche, bestaetigte Physics-Basis und wird nicht unnoetig umgebaut.

## Der echte Weg von Raum $03 nach $04

Aus der originalen 6x23-Weltkarte ergibt sich:

- Raum $03 = Zeile 2, Spalte 18
- darunter liegt Raum $0E = Zeile 3, Spalte 18
- links davon liegt Raum $0D = Zeile 3, Spalte 17
- darueber liegt Raum $04 = Zeile 2, Spalte 17

Damit lautet der echte Weg:

`$03 DOWN -> $0E LEFT -> $0D UP -> $04`

Die grosse Wand in Raum $03 muss also nicht direkt uebersprungen werden. Phase 43 hatte die Weltkarte zu stark als horizontale Kette interpretiert.

## Fehlende C64-Bewegungslogik: unterer Raumrand

Die C64-Routine `Monty.UpdateMovement_down` prueft nach einer freien Abwaertsbewegung die Y-Position. Solange Y kleiner als `$DA` ist, wird Y weiter erhoeht. Am unteren Rand wird `map_row` erhoeht, der Zielraum ueber die Weltkarte geprueft und bei gueltigem Ziel ein Raumwechsel ausgeloest; Monty erscheint im neuen Raum oben bei Y=`$4C`.

Im PCE-Port fehlte genau dieser Down-Room-Exit. `src/vertical_world_edges.asm` portiert diesen Teil nun separat und setzt bei Y=`$DA` den PCE-internen Exit-Code 4 (down) sowie Y=`$4C`. `world_resolve_exit` erledigt danach wie bei den anderen Richtungen den echten Weltkarten-Lookup.

Bei einem nicht portierten Zielraum wird Y auf `$D9` zurueckgesetzt, damit der Down-Exit nicht in jedem Tick sofort erneut ausgeloest wird.

## Phase 44 — Room $0D und $0E

Damit der echte Weg spielbar werden kann, sind Room $0D und $0E jetzt als echte Tail-Raeume integriert.

### Raum $0D

Exakte C64-Daten:

- Tile-IDs: `$05,$0f,$4f,$19,$00,$00,$00,$00`
- Farben: `$0d,$05,$02,$00,$00,$00,$00,$00`
- Properties: `1,1,4,1,1,1,1,1`
- RLE aus `Room.Data.tilemap.rm_0d`
- Bitmaps direkt aus `Tiles.tile_library`

### Raum $0E

Exakte C64-Daten:

- Tile-IDs: `$05,$0f,$6a,$36,$60,$3a,$26,$4f`
- Farben: `$0d,$05,$01,$03,$07,$04,$07,$02`
- Properties: `1,1,3,2,3,2,1,4`
- RLE aus `Room.Data.tilemap.rm_0e`
- Bitmaps direkt aus `Tiles.tile_library`

`tools/room0d.py` und `tools/room0e.py` erzeugen jeweils die 640-Byte-Collision-Map, den 36x20-BAT und 9 PCE-Patterns. Die grossen Daten liegen wieder hinter dem Runtime-Code in `src/room0d_assets_tail.asm` und `src/room0e_assets_tail.asm`.

## Loader und Collision

`room_loader.asm` akzeptiert nun `$0D` und `$0E`. Beide Raeume laden Patterns/BAT bankfest und kopieren vor Wiederaufnahme des Gameplays ihre 640 Map-Bytes plus 8 Property-Bytes in den bereits bewaehrten `room02_*`-RAM-Cache.

`collision_banking.asm` musste logisch nicht erweitert werden: sein bestehendes `cmp #3` behandelt bereits jeden aktiven Tail-Raum ab $03 als Cache-Raum und spiegelt die Room-ID waehrend der Physics temporaer auf $02. Die Kommentare wurden auf `$02/$03/$04/$0D/$0E` aktualisiert. `monty_physics.asm` selbst bleibt unveraendert.

## World-Gate

Das alte Gate `room_id < 5` wurde durch `world_room_supported` ersetzt. Aktuell erlaubt es:

- `$00-$04`
- `$0D`
- `$0E`

Damit ist nicht versehentlich jeder dazwischenliegende Raum aktiv, sondern nur exakt der jetzt portierte Weg. Die Weltkarte selbst bleibt bytegetreu unveraendert.

## Tests und Build

Neu bzw. angepasst:

- `tools/test_room0d0e.py` prueft beide exakten RLEs, Tile-IDs, Farben, Properties, Pattern/BAT-Ausgabe, Tail-Platzierung und Loader-Verkabelung.
- `tools/test_vertical_route.py` prueft den Down-Edge bei `$DA` und die Weltkartenfolge `$03 -> $0E -> $0D -> $04`.
- `tools/test_room02.py`, `test_room03.py`, `test_room04.py` wurden von ueberholten horizontalen Annahmen bereinigt.
- `tools/test_collision_banking.py` prueft den gemeinsamen Cache nun auch fuer `$0D/$0E`.
- `build.sh` erzeugt Room-$0D/$0E-Daten und fuehrt die neuen Tests vor PCEAS aus.

## Commits Phase 44

- `3c1d2539dce091d739cf4b1ab333520ce81915d5` — exakter Room-$0D-Generator
- `c28f0717bb6f81ae8b91fb6fea4c67aeb5e3cda4` — exakter Room-$0E-Generator
- `13c48295c3f13a72b3df02b6f2cbb1cd9a397f9e` — Room-$0D-Tail-Assets
- `5a7b1af33a838f6520394d67bb1d9bb914c25885` — Room-$0E-Tail-Assets
- `97d3e8c4c7c8ad082cbc11c9f92cc641ccaca36c` — neue Tail-Assets eingebunden
- `4f7408a2fe7dff42a06c4b0d6b7500e1912cc7d1` — originalen Down-Room-Edge portiert
- `b4f017efada86355446006ecf41c3e66511e1b0d` — Down-Edge in Mainloop eingebunden
- `7c03e9fef4ccf4eef66d8f2dc222e8507cf1554d` — Loader/Cache fuer `$0D/$0E`
- `084f169daf32cb6080dece6c35a50219166d3e8c` — exaktes World-Support-Gate fuer den echten Weg
- `4952727e8fbfa3a98f50a018edb3f800527eb40e` — Room-$0D/$0E-Test
- `fec7c65c0ad029f6eafa204a610a4993a6398185` — Vertical-Route-Test
- `a981ca5713c84b6ca32c6a3a41db5cdcc726da65` — Room-$02-Test entkoppelt
- `65d67ae4d7b6286719a3689af4c8f330a26c6612` — Room-$03-Test auf Down-Route umgestellt
- `a71eb2699db2f6d06d8806f8497f50f8f2d139e5` — Room-$04-Test auf Zugang ueber $0D umgestellt
- `b71a15f4e79739ff4e4d22b725be5e53287585f2` — Collision-Cache-Test erweitert
- `07a39d27f2d42bfb189222028cabf2ceaf9ab574` — Build erzeugt/testet `$0D/$0E`
- `6c45c17d7a131fa39c05bf1b0a069cbbdba18d26` — Collision-Banking-Dokumentation aktualisiert

## Erwarteter lokaler Test

Phase 44 ist hochgeladen, aber noch nicht lokal vom Nutzer bestaetigt. Nach `git pull && ./build.sh` muss zuerst der komplette Test-/PCEAS-Build durchlaufen.

Im Spiel ist der entscheidende Test danach nicht mehr, in Raum $03 nach links durch die Wand zu kommen. Stattdessen soll Monty in Raum $03 **nach unten aus dem Raum** gelangen und in `$0E` erscheinen. Von `$0E` geht es nach links in `$0D`; von `$0D` nach oben in `$04`. In allen drei neuen/neu erreichbaren Raeumen muessen Gehen, Springen, Fallen und Collision stabil bleiben.

Room-$03/$04-Decors und Gegner sind noch nicht Teil dieses Schritts.

## Naechste Portschritte

1. Phase 44 lokal bestaetigen und den echten `$03 -> $0E -> $0D -> $04`-Weg testen.
2. Falls Vertical-Exit/Spawn-Koordinaten noch Detailabweichungen zeigen, direkt gegen `Monty.UpdateMovement_up/down` korrigieren.
3. Originale Decors fuer `$03/$0E/$0D/$04` portieren.
4. Danach den naechsten tatsaechlich erreichbaren Weltzweig portieren, statt Raum-IDs nur numerisch abzuarbeiten.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio schrittweise ergaenzen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
