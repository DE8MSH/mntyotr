# Was bisher geschah

Stand: 2026-09-05 — Phase 45

## Portierungsstand

**Gesamtport: ca. 57 %**

Primaere Referenz bleibt `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` ist nur zusaetzliche Ground-Truth.

## Bestaetigter Stand

- Raum $00/$01: Boden, Gehen, Springen, Landen und Animationen funktionieren.
- Raum $01: Original-Decors aktiv.
- Raum $02: spielbar, fuenf Original-Decors aktiv; vollstaendige Traversal/Mechanismen sind noch nicht fertig.
- Raum $03: spielbar und lokal bestaetigt.
- Raum $04, $0D und $0E: als aktive Basisraeume integriert.
- Gemeinsamer 648-Byte-RAM-Collision-Cache fuer Tail-Raeume ist bewaehrt.
- `monty_physics.asm` bleibt die empfindliche, bestaetigte Physics-Basis.
- Phase 44b baut beim Nutzer mit PCEAS ohne Fehler.

## Phase 44 — vertikale Weltkante und $0D/$0E

Phase 44 portierte den fehlenden unteren Raumrand aus `Monty.UpdateMovement_down`: bei Y=$DA wird ein Down-Exit ausgeloest und Monty erscheint bei einem gueltigen Ziel oben auf Y=$4C.

Damit wurde zunaechst die Weltkartenverbindung

`$03 DOWN -> $0E LEFT -> $0D UP -> $04`

aktiviert. Room $0D und $0E werden als Tail-Raeume geladen; ihre 640 Collision-Bytes plus 8 Properties werden in den gemeinsamen `room02_*`-RAM-Cache kopiert.

### Phase 44a — Room-$0D-RLE repariert

Der erste lokale Phase-44-Build stoppte mit `decoded 624 cells, expected 640`. In `tools/room0d.py` fehlte ein `$f0`-Run. Die Primaerquelle enthaelt an dieser Stelle fuenf aufeinanderfolgende `$f0`-Bytes. Der Stream ist jetzt 66 Bytes lang und dekodiert wieder exakt 640 Zellen.

Commits:

- `ae6ee6fd1d305cbdf947f7c9c6646597d639fa7a` — fehlenden `$f0`-Run wiederhergestellt
- `8631166c1ba3b4ba623d616a2732a133fbd97212` — Regressionstest fuer die `$f0`-Sequenz
- `3d70cbf8b10fd67d29d3f608e7c4d15046e81d4e` — 66-Byte-Stream im Test festgeschrieben

### Phase 44b — PCEAS-Branch-Reichweite repariert

Nach Phase 44a erreichte der Build PCEAS und stoppte in `src/world.asm` mit `Branch address out of range`. Der entfernte Fallback von `world_resolve_exit` lag inzwischen 130 Bytes hinter einem `BRA`; erlaubt sind nur -128..+127. Der Sprung ist deshalb jetzt ein absoluter `JMP`.

Commits:

- `6e7e8b8d15a6b81dfaa7f32c980c5e501980f704` — `bra .blocked` -> `jmp .blocked`
- `87050f173643ae23d678ca5b1f533eeb8764e9fe` — Regressionstest fuer den Long Jump
- `3d2daa0a4649a14d3dba186c29e064c635813971` — Phase 44b dokumentiert

Der Nutzer hat Phase 44b lokal gebaut: **kein Assemblerfehler mehr**.

## Phase 45 — Freeze im Loch von Room $01 erklaert

Der anschliessende Runtime-Test zeigte zwei wichtige Dinge:

1. Beim Fallen in das Loch von Room $01 fror das Spiel am unteren Rand ein.
2. Der Abstecher in Room $02 fuehrte sichtbar nicht auf dem erwarteten Vorwaertsweg weiter.

Der Freeze war kein akzeptabler Endzustand, sondern ein World-Gate-Fehler des noch unvollstaendigen Ports. `monty_check_down_room_edge` erzeugte bei Y=$DA korrekt einen Down-Exit. Die C64-Weltkarte hat unter Room $01 aber **Room $0A**. Da `$0A` noch keinen Loader hatte, blockierte `world_resolve_exit` den Wechsel und setzte Monty auf Y=$D9 zurueck. Im naechsten Fall-Tick wurde wieder Y=$DA erreicht: ein endloser `$D9 <-> $DA`-Loop, der wie ein Freeze aussieht.

Der erneute Abgleich mit der originalen 6x23-Weltkarte zeigt den viel wichtigeren unteren Hausweg:

`$00 LEFT -> $01`

`$01 DOWN -> $0A LEFT -> $0B LEFT -> $0E LEFT -> $0D UP -> $04`

Danach zeigt die Weltkarte von `$04` nach links auf `$05`, das noch nicht portiert ist.

Room $02/$03 bilden weiterhin gueltige Weltzellen und bleiben als Seiten-/Alternativzweig aktiv. Dass Room $02 nicht einfach durchlaufen werden kann, ist in diesem Stadium nicht derselbe Fehler wie der Freeze: die originale Room-$02-Geometrie enthaelt unter anderem einen Piledriver/Zerstampfer, dessen Mechanik im PC-Engine-Port noch fehlt. Fuer den aktuellen Vorwaertstest ist Room $02 nicht noetig; wichtig ist, dass man von dort weiterhin nach rechts nach `$01` zurueck kann.

## Phase 45 — Room $0A/$0B

Room $0A und $0B wurden aus `refactored/src/subsystems/room_data.asm` und `tiles.asm` exakt als neue Tail-Raeume uebernommen.

Room $0A:

- RLE: 116 Bytes -> exakt 640 Zellen
- Tile-IDs `$0c,$65,$43,$3a,$00,$00,$00,$00`
- Farben `$09,$05,$03,$04,$02,$00,$00,$00`
- Properties `1,3,2,2,1,1,1,1`

Room $0B:

- RLE: 124 Bytes -> exakt 640 Zellen
- Tile-IDs `$05,$47,$65,$3b,$36,$62,$03,$51`
- Farben `$0a,$03,$07,$04,$01,$05,$0d,$08`
- Properties `1,1,3,2,2,3,1,4`

Alle benoetigten Farben liegen bereits in den vorhandenen BG-Palettenslots. Neue Paletteintraege sind fuer diese beiden Basisraeume nicht erforderlich.

`world_room_supported` erlaubt jetzt `$00-$04`, `$0A`, `$0B`, `$0D` und `$0E`. Beide neuen Raeume benutzen denselben 648-Byte-RAM-Collision-Cache wie die bisherigen Tail-Raeume.

Weil `room_loader.asm` durch zwei weitere Raeume deutlich waechst, wurden dessen wachsende Selector-Spruenge gleichzeitig branch-range-sicher gemacht: Dispatch, Collision-Cache-Auswahl, Pattern-Upload und BAT-Draw benutzen an entfernten gemeinsamen Zielen absolute `JMP`s statt riskanter `BRA`s.

## Phase-45-Commits

- `b0e208b955127ac87a273d0a2acaddad2c480840` — exakter Room-$0A-Generator
- `4edab57b53bdcd44df471f5c04496be116ea0f7d` — exakter Room-$0B-Generator
- `119e0d64f3e39b70da72fe6b433e5537092d0328` — Room-$0A-Tail-Assets
- `955547e165320f0f7cfbd7ad0b36182ce100390c` — Room-$0B-Tail-Assets
- `0dfe6dd227415948b3c735269731e151f2439492` — `$0A/$0B` im World-Gate aktiviert
- `7d3de5923e1286c45e1c388d564396ca45101c6a` — Loader/Cache/Upload/Draw fuer `$0A/$0B`, Long-Jump-sicher
- `35d2564f3c913d28dde11f416ebac52acde662bc` — Tail-Assets in `main.asm` eingebunden
- `14a3ee9da7e4fd23cfa3852634330f4f7ac148f0` — exakter `$0A/$0B`- und Topologie-Test
- `57563a4c11087fccb4d9a2e3a69d2feeb0fc29bb` — Build erzeugt/testet `$0A/$0B`
- `bc3b12fac65c9d363d9560ba8a1a86bd09f12425` — Collision-Cache-Test erweitert
- `140c6fb0c923df2bb764042c658eb259376d35bd` — Vertical-Route-Test auf unteren Hausweg erweitert
- `eaf809f139ab8c507096f05f7e93e16cdad90561` — Collision-Banking-Dokumentation aktualisiert

## Erwarteter lokaler Test fuer Phase 45

Nach:

`git pull && ./build.sh`

sollen alle Python-Regressionstests einschliesslich

`OK: exact Room 0A/0B assets + lower-house route wiring`

laufen und PCEAS wieder `build/monty.pce` erzeugen.

Danach in Mednafen gezielt testen:

1. `$00 -> links -> $01`.
2. In `$01` in das Loch fallen: **kein Freeze mehr**, stattdessen muss `$0A` geladen werden.
3. In `$0A` nach links -> `$0B`.
4. In `$0B` nach links -> `$0E`.
5. `$0E` links -> `$0D`.
6. `$0D` oben -> `$04`.
7. Rueckwege ebenfalls testen, insbesondere `$0A` oben -> `$01` und `$0B` rechts -> `$0A`.
8. Room `$02` darf weiterhin betreten und nach rechts verlassen werden; seine noch fehlenden Mechanismen sind ein separater Portschritt.

Room-$0A/$0B-Decors, Gegner und Piledriver-Mechanismen sind in Phase 45 noch nicht enthalten. Zuerst soll der echte untere Raumweg stabil werden.

## Naechste Portschritte

1. Phase 45 lokal bauen und den unteren Hausweg in Mednafen bestaetigen.
2. Falls `$0A/$0B` Traversal stabil ist: Room `$05` als naechste Zelle links von `$04` portieren.
3. Original-Decors fuer die neu aktiven Raeume nachziehen.
4. Piledriver/Zerstampfer und weitere Mechanismen portieren; damit auch Room-$02/$03 vollstaendig gegen das C64-Verhalten pruefen.
5. Gegner, Items, HUD/Gameflow und Audio schrittweise ergaenzen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
