# Was bisher geschah

Stand: 2026-09-05 — Phase 44b

## Portierungsstand

**Gesamtport: ca. 55 %**

Primaere Referenz bleibt `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` ist nur zusaetzliche Ground-Truth.

## Bestaetigter Stand vor Phase 44

- Raum $00/$01: Boden, Gehen, Springen, Landen und Animationen funktionieren.
- Raum $01: Original-Decors aktiv.
- Raum $02: spielbar, fuenf Original-Decors aktiv.
- Raum $03: spielbar und lokal bestaetigt.
- Gemeinsamer 648-Byte-RAM-Collision-Cache fuer Tail-Raeume ist bewaehrt.
- `monty_physics.asm` bleibt die empfindliche, bestaetigte Physics-Basis.

## Echte Route von $03 nach $04

Die grosse Wand in Raum $03 ist original und muss nicht direkt ueberwunden werden. Aus der 6x23-Weltkarte ergibt sich:

`$03 DOWN -> $0E LEFT -> $0D UP -> $04`

Dafuer portiert Phase 44 den fehlenden unteren Raumrand aus `Monty.UpdateMovement_down`: bei Y=$DA wird ein Down-Exit ausgeloest und Monty erscheint im Zielraum oben bei Y=$4C. `src/vertical_world_edges.asm` kapselt diesen Teil; `world_resolve_exit` macht den originalen Weltkarten-Lookup.

## Phase 44 — Room $0D/$0E

Room $0D und $0E wurden als Tail-Raeume integriert. Patterns/BAT werden bankfest geladen, Collision-Map plus 8 Properties werden in den bestehenden `room02_*`-RAM-Cache kopiert. `world_room_supported` erlaubt aktuell gezielt `$00-$04`, `$0D` und `$0E`; die Weltkarte selbst bleibt unveraendert.

Room $0D:

- Tile-IDs `$05,$0f,$4f,$19,$00,$00,$00,$00`
- Farben `$0d,$05,$02,$00,$00,$00,$00,$00`
- Properties `1,1,4,1,1,1,1,1`

Room $0E:

- Tile-IDs `$05,$0f,$6a,$36,$60,$3a,$26,$4f`
- Farben `$0d,$05,$01,$03,$07,$04,$07,$02`
- Properties `1,1,3,2,3,2,1,4`

## Phase 44a — lokaler RLE-Buildfehler behoben

Der erste lokale Phase-44-Build stoppte in `tools/test_room0d0e.py` mit:

`ValueError: decoded 624 cells, expected 640`

Die Ursache lag in `tools/room0d.py`: Beim Uebertragen von `Room.Data.tilemap.rm_0d` fehlte exakt **ein `$f0`-RLE-Byte**. In der Primaerquelle stehen an dieser Stelle fuenf aufeinanderfolgende `$f0`-Runs:

`... $f0,$f0,$f0,$f0,$f0,$22 ...`

Im Port standen nur vier. Ein `$f0` bedeutet 16 Wiederholungen von Tile 0; genau deshalb fehlten 16 Zellen: 624 statt 640.

Phase 44a stellt den fehlenden Run wieder her. Der Room-$0D-Stream ist jetzt 66 Bytes lang und dekodiert exakt 640 Zellen. `tools/test_room0d0e.py` pinnt zusaetzlich die Sequenz `f0 f0 f0 f0 f0 22`, damit dieser Fehler nicht wieder unbemerkt auftaucht.

Dass Mednafen danach `build/monty.pce` nicht fand, war nur eine Folge des vorher abgebrochenen Builds: PCEAS wurde wegen des Python-Fehlers gar nicht mehr erreicht und konnte deshalb keine ROM-Datei erzeugen.

## Commits Phase 44a

- `ae6ee6fd1d305cbdf947f7c9c6646597d639fa7a` — fehlenden `$f0`-Run in Room-$0D-RLE wiederhergestellt
- `8631166c1ba3b4ba623d616a2732a133fbd97212` — Regressionstest fuer die exakte `$f0`-Sequenz ergaenzt
- `3d70cbf8b10fd67d29d3f608e7c4d15046e81d4e` — korrekten 66-Byte-Stream im Test festgeschrieben

## Phase 44b — PCEAS-Branch-Reichweite repariert

Nach Phase 44a liefen die Python-Checks bis PCEAS durch. Der Assembler stoppte danach in `src/world.asm` beim Dispatch von `world_resolve_exit` mit:

`Error: Branch address out of range!`

Betroffen war der Fallback nach den Exit-Typen 1..4:

`bra .blocked`

Durch das Anwachsen des Resolvers auf die aktiven Raeume `$00-$04`, `$0D` und `$0E` lag `.blocked` inzwischen 130 Bytes hinter dem relativen Branch. HuC6280/PCEAS kann `BRA` dort nur mit einem signed 8-bit Offset (-128..+127) kodieren. Der Sprung wurde deshalb bewusst als absoluter Long Jump formuliert:

`jmp .blocked`

Das entspricht dem bereits in Phase 32b verwendeten Muster fuer gewachsene World-Routinen. Ein Regressionstest in `tools/test_port.py` pinnt den Long Jump jetzt fest. Nach der Aenderung liegt der groesste verbleibende relative Branch in `world_resolve_exit` bei ca. +104 Bytes und damit wieder innerhalb der PCEAS-Reichweite.

Der Abgleich mit der C64-Referenz bestaetigt ausserdem den gueltigen vertikalen Uebergang: `Monty.UpdateMovement_down` prueft bei Y=$DA den Raum unterhalb und setzt bei Erfolg den Eintritt im Zielraum auf Y=$4C. Die aktuelle PC-Engine-Route `$03 -> $0E -> $0D -> $04` bleibt damit semantisch korrekt.

## Commits Phase 44b

- `6e7e8b8d15a6b81dfaa7f32c980c5e501980f704` — `world_resolve_exit` verwendet fuer den entfernten `.blocked`-Fallback `JMP`
- `87050f173643ae23d678ca5b1f533eeb8764e9fe` — Regressionstest fuer den Long Jump ergaenzt

## Erwarteter lokaler Test

Nach `git pull && ./build.sh` sollen zuerst alle Python-Regressionstests durchlaufen. PCEAS soll anschliessend `world.asm` ohne Branch-Range-Fehler assemblieren und `build/monty.pce` erzeugen.

Danach:

`mednafen build/monty.pce`

Im Spiel ist die wichtige Route:

`$03 -> unten -> $0E -> links -> $0D -> oben -> $04`

In `$0D/$0E/$04` muessen Gehen, Springen, Fallen und Collision stabil bleiben. Besonders zu beobachten sind die Spawn-/Wrap-Koordinaten an den vertikalen Kanten. Room-$03/$04-Decors und Gegner sind noch nicht Teil dieses Schritts.

## Naechste Portschritte

1. Phase 44b lokal mit echtem PCEAS-Build bestaetigen.
2. Echten `$03 -> $0E -> $0D -> $04`-Weg in Mednafen testen und Spawn/Vertical-Exit gegen die C64-Routine abgleichen.
3. Original-Decors fuer `$03/$0E/$0D/$04` portieren.
4. Danach den naechsten tatsaechlich erreichbaren Weltzweig portieren.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio schrittweise ergaenzen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
