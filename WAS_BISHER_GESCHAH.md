# Was bisher geschah

Stand: 2026-09-04 — Phase 38a bestaetigt

## Portierungsstand

**Gesamtport: ca. 48 %**

Phase 38a ist vom Nutzer lokal bestaetigt. Raum $02 ist jetzt als dritter echter Raum aktiv und Monty bleibt dort nach dem Eintritt nicht mehr haengen: Gehen, Springen und Collision funktionieren wieder.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigter Runtime-Stand

- Raum $00 und $01 funktionieren mit Boden, Gehen, Springen, Landen und Animationen.
- Raum $01 zeigt die originalen `purple_flowers` und `bunch_flower`.
- Raum $02 ist aus Raum $01 nach links erreichbar.
- Monty kann in Raum $02 direkt nach dem Eintritt wieder laufen und springen.
- Room-$02-Collision funktioniert mit dem RAM-Cache-Pfad.
- Raum $02 -> $01 nach rechts funktioniert; links aus Raum $02 bleibt bis zum Port von Raum $03 gesperrt.
- Raum $00 rechts bleibt korrekt gesperrt.

## Ursache des Phase-38-Haengers

Room-$02-Collision liegt als banked Tail-Asset weit hinter dem bestaetigten Runtime-Code. Phase 38 hatte fuer `monty_room == 2` den Room-$02-Assetbank ueber MPR3/MPR4 fuer den gesamten Physics-Slice eingeblendet. Damit konnte Runtime-Code ausgeblendet werden, waehrend `monty_update_input` und `monty_jump_step` noch ausgefuehrt werden sollten.

Das erklaerte das beobachtete Fehlerbild: der Raum selbst wurde korrekt gezeichnet, danach reagierte der Gameplay-Pfad nicht mehr.

## Phase 38a — Room-$02-Collision in RAM cachen

Die bestaetigte Physics-Semantik in `src/monty_physics.asm` bleibt unveraendert. Stattdessen zeigen die vorhandenen Symbole `room02_collision_map` und `room02_tile_properties` auf RAM:

- `room02_collision_map`: 640 Byte
- `room02_tile_properties`: 8 Byte

Die ROM-Tail-Daten heissen `room02_collision_map_rom` und `room02_tile_properties_rom` und liegen direkt hintereinander im Tail-Assetblock.

Beim Laden von Raum $02 ruft `room_loader.asm` `room02_cache_collision` auf. Die Routine mappt den Tail-Assetbank nur fuer den kurzen Kopiervorgang, kopiert exakt 648 Byte nach RAM und stellt MPR3/MPR4 danach wieder her.

`collision_bank_enter` mappt fuer Raum $00/$01 weiterhin die bestaetigten ROM-Banks. Fuer Raum $02 werden MPR3/MPR4 nicht mehr umgelegt, weil dessen Collision/Properties bereits im RAM liegen. Dadurch bleibt der Runtime-Code waehrend der kompletten Physics sichtbar.

## Regressionstests

`tools/test_collision_banking.py` prueft:

- Room $00/$01 bleiben auf dem bisherigen ROM-Banking-Pfad.
- Room $02 besitzt 640+8 Byte RAM-Cache.
- Room $02 benutzt kein `BANK(room02_collision_map)` mehr im Physics-Mapping.
- `room02_cache_collision` kopiert aus `room02_collision_map_rom`.
- Physics verwendet weiter dieselben direkten `room02_collision_map`-/`room02_tile_properties`-Symbole.

`tools/test_room02.py` prueft dieselbe ROM->RAM-Verkabelung sowie die exakten Room-$02-Assets.

## Commits Phase 38a

- `1d5eb16ef37d4ac355c2c1c392de2ebc41b054e2` — Room-$02-Collision/Properties als RAM-Cache, kein MPR-Remap im Physics-Slice
- `218f7d71cdeb8894c544a861e3b31663d1d5e7d0` / `95f65f09312b3532418e798317727c714087c74c` — ROM-Tail-Payload fuer Map+Properties getrennt und contiguous gemacht
- `5a43d32f635df92701dc739b43025cc92c135c83` — 648-Byte Cache-Copy beim Room-$02-Load
- `772d8931c2a135866fd353440ca6c849dc46237f` — Collision-Banking-Test angepasst
- `4b07c2d7a8b260554ebe6d2439fa12ab4afd0a1e` — Room-$02-Test angepasst

## Verifikationsstatus

**Phase 38a ist lokal bestaetigt.**

Bestaetigt sind damit jetzt drei echte Raeume in Folge:

`$02 <-> $01 <-> $00`

inklusive funktionierender Bewegung, Spruenge und Collision in Raum $02.

## Naechste Portschritte

1. Room-$02-Decors exakt aus `Decor.room_list` und `decor_data.asm` portieren.
2. Danach Raum $03 vorbereiten und aktivieren.
3. Weitere Raeume entlang der Original-Weltkarte.
4. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
