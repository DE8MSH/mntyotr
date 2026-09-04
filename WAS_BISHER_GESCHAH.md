# Was bisher geschah

Stand: 2026-09-04 — Phase 41

## Portierungsstand

**Gesamtport: ca. 51 %**

Phase 40 wurde vom Nutzer lokal bestaetigt: das zusaetzliche Room-$03-ROM-Wachstum hat die bestaetigten Raeume $00-$02 nicht destabilisiert. Phase 41 aktiviert Raum $03 jetzt als vierten echten Raum.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigter Runtime-Stand vor Phase 41

- Raum $00 und $01 funktionieren mit Boden, Gehen, Springen, Landen und Animationen.
- Raum $01 zeigt die originalen `purple_flowers` und `bunch_flower`.
- Raum $02 ist aktiv, spielbar und besitzt seine fuenf originalen Decors.
- Room-$02-Collision nutzt den bestaetigten 648-Byte-RAM-Cache.
- Raum $00-$02 sind lokal bestaetigt stabil.

## Phase 41 — Raum $03 aktiv

Raum $03 benutzt die in Phase 40 exakt vorbereiteten C64-Daten:

- RLE aus `Room.Data.tilemap.rm_03`
- Tile-IDs `$01,$2f,$00,$65,$5f,$44,$11,$55`
- Farben `$07,$03,$0b,$05,$03,$04,$06,$0e`
- Properties `1,2,1,3,3,2,1,4`
- exakte Bitmaps aus `Tiles.tile_library`

`world.asm` akzeptiert jetzt Raum-IDs $00-$03. Damit ist die horizontale Originalkette aktuell:

`$03 <-> $02 <-> $01 <-> $00`

Links aus Raum $03 bleibt Raum $04 weiterhin gesperrt; rechts aus Raum $00 bleibt die originale $ff-Wand gesperrt.

## Shared RAM-Collision-Cache fuer Tail-Raeume

Die empfindliche `monty_physics.asm` wurde fuer Phase 41 bewusst nicht umgebaut. Stattdessen teilen Raum $02 und $03 denselben bereits bestaetigten 648-Byte-RAM-Cache (`room02_collision_map` + `room02_tile_properties`). Beim Laden des jeweiligen Tail-Raums kopiert `room_loader.asm` dessen 640 Map-Bytes plus 8 Property-Bytes aus dem ROM-Tail in diesen Cache.

Fuer Raum $03 speichert `collision_banking.asm` den echten Raum in `collision_actual_room` und setzt `monty_room` nur waehrend des Physics-Slices temporaer auf $02. Dadurch benutzt die unveraenderte Physics weiterhin exakt den bestaetigten Room-$02-RAM-Pointerpfad, aber mit den frisch geladenen Room-$03-Daten. Vor `world_resolve_exit` wird der echte Raum $03 wiederhergestellt.

Der Jump-Edge-Guard benutzt deshalb `collision_actual_room`: Springen von Raum $02 nach links in Raum $03 ist jetzt erlaubt; links aus Raum $03 in den noch nicht portierten Raum $04 bleibt blockiert. Der bestaetigte Schutz gegen synthetische Jump-Side-Exits bleibt erhalten.

## Palette

Raum $03 verwendet als neue Farbe C64 light blue `$0e`. `room03_extra_palette` liegt als Tail-Asset und wird beim Start in PCE-BG-Palettenslot 15 geladen. Slots 13/14 bleiben purple/blue wie bisher.

## Regressionstests

Aktualisiert wurden:

- `tools/test_room03.py` — aktive Loader/World/Cache-Verkabelung
- `tools/test_collision_banking.py` — gemeinsamer Room-$02/$03-RAM-Cache und Room-$03-Shadow
- `tools/test_jump_edge_guard.py` — Room-$03-Aussenkante und Room-$02->$03-Sprung
- `tools/test_room02.py` — Room-$02 bleibt stabil und darf jetzt links nach Room $03

`build.sh` fuehrt die Tests weiterhin vor PCEAS aus.

## Commits Phase 41

- `219efc5357104b638c52a1f9af7e09c50fdecf9d` — Room-$03-Physics-Shadow auf bestaetigten RAM-Cache
- `b9dd6034723b4636060ad930b5c90f72b0042970` — Room-$03-Loader, Draw und Collision-Cache
- `a0db117a056767585278e1a4082043b74a91f956` — World-Gate auf $00-$03 erweitert
- `2c77c9d1a7ec58a6238987ced08f039bcbbabcb5` — Jump-Transition $02->$03 aktiviert
- `b598179a99ccc9f6583f9480bc242e99cb64e767` — Room-$03-Test aktiviert
- `28716d5960cab8954c722516f951024f890e3ebb` — Collision-Banking-Test erweitert
- `35f859d5365c2a3c8ae00b31a91f72f8d4ffa2ea` — Jump-Edge-Test erweitert
- `f056502058dba591e29708bac0d7415cfb0fa028` — Room-$02-Test an neue Kette angepasst
- `f327269a72b10a7e3155f7b973b0a220d3674034` — Light-blue-Palette als Room-$03-Tail-Asset
- `21ea90add671b5749892605ec69cff3d7112f67d` — Palettenslot 15 initialisiert

## Erwartetes Resultat

Nach `git pull && ./build.sh` soll Monty weiterhin in Raum $00-$02 normal laufen, springen und landen. Von Raum $02 geht es jetzt nach **links in Raum $03**, sowohl gehend als auch springend. In Raum $03 muss Monty direkt weiter steuerbar sein und korrekt mit Boden/Plattformen kollidieren. Nach rechts geht es zurueck nach Raum $02. Links aus Raum $03 bleibt bis Raum $04 gesperrt.

Room-$03-Decors sind in Phase 41 noch nicht aktiviert; zuerst wird die neue vierte Raum-/Collision-Kette lokal bestaetigt.

## Naechste Portschritte

1. Phase 41 lokal bestaetigen.
2. Originale Room-$03-Decors portieren.
3. Raum $04 mit exakten C64-Daten vorbereiten und aktivieren.
4. Weitere Raeume entlang der Original-Weltkarte.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
