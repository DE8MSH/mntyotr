# Was bisher geschah

Stand: 2026-09-04 — Phase 38a

## Portierungsstand

**Gesamtport: ca. 48 %**

Phase 37 ist lokal bestaetigt. Phase 38 hat Raum $02 als dritten echten Raum freigeschaltet. Der Nutzer konnte Raum $02 betreten, blieb dort aber direkt am Eintritt stehen: Gehen und Springen reagierten nicht mehr.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigter Stand vor dem Phase-38a-Fix

- Raum $00 und $01 funktionieren mit Boden, Gehen, Springen, Landen und Animationen.
- Raum $01 zeigt die originalen `purple_flowers` und `bunch_flower`.
- Raum $02 wird sichtbar geladen und ist aus Raum $01 nach links erreichbar.
- Der Fehler beginnt erst nach dem Eintritt in Raum $02: Monty bleibt dort ohne Steuerung stehen.

## Ursache

Room-$02-Collision liegt als banked Tail-Asset weit hinter dem bestaetigten Runtime-Code. Phase 38 mappt fuer `monty_room == 2` den Room-$02-Assetbank ueber MPR3/MPR4 fuer den gesamten Physics-Slice. Damit kann auf diesem ROM-Layout Runtime-Code ausgeblendet werden, waehrend `monty_update_input` und `monty_jump_step` noch ausgefuehrt werden sollen.

Das passt exakt zum beobachteten Fehlerbild: der Raum selbst wird korrekt gezeichnet, aber direkt danach reagiert der Gameplay-Pfad nicht mehr.

## Phase 38a — Room-$02-Collision in RAM cachen

Die bestaetigte Physics-Semantik in `src/monty_physics.asm` bleibt unveraendert. Stattdessen zeigen die bereits vorhandenen Symbole `room02_collision_map` und `room02_tile_properties` jetzt auf RAM:

- `room02_collision_map`: 640 Byte
- `room02_tile_properties`: 8 Byte

Die ROM-Tail-Daten heissen nun `room02_collision_map_rom` und `room02_tile_properties_rom` und bleiben direkt hintereinander im Tail-Assetblock.

Beim Laden von Raum $02 ruft `room_loader.asm` jetzt `room02_cache_collision` auf. Die Routine mappt den Tail-Assetbank nur fuer den kurzen Kopiervorgang, kopiert exakt 648 Byte nach RAM und stellt MPR3/MPR4 danach wieder her.

`collision_bank_enter` mappt fuer Raum $00/$01 weiterhin die bestaetigten ROM-Banks. Fuer Raum $02 werden MPR3/MPR4 nicht mehr umgelegt, weil dessen Collision/Properties bereits im RAM liegen. Dadurch bleibt der Runtime-Code waehrend der kompletten Physics sichtbar.

## Regressionstests

`tools/test_collision_banking.py` prueft jetzt explizit:

- Room $00/$01 bleiben auf dem bisherigen ROM-Banking-Pfad.
- Room $02 besitzt 640+8 Byte RAM-Cache.
- Room $02 benutzt **kein** `BANK(room02_collision_map)` mehr im Physics-Mapping.
- `room02_cache_collision` kopiert aus `room02_collision_map_rom`.
- Physics verwendet weiter dieselben direkten `room02_collision_map`-/`room02_tile_properties`-Symbole.

`tools/test_room02.py` wurde auf dieselbe ROM->RAM-Verkabelung umgestellt.

## Commits Phase 38a

- `1d5eb16ef37d4ac355c2c1c392de2ebc41b054e2` — Room-$02-Collision/Properties als RAM-Cache, kein MPR-Remap im Physics-Slice
- `218f7d71cdeb8894c544a861e3b31663d1d5e7d0` / `95f65f09312b3532418e798317727c714087c74c` — ROM-Tail-Payload fuer Map+Properties getrennt und contiguous gemacht
- `5a43d32f635df92701dc739b43025cc92c135c83` — 648-Byte Cache-Copy beim Room-$02-Load
- `772d8931c2a135866fd353440ca6c849dc46237f` — Collision-Banking-Test angepasst
- `4b07c2d7a8b260554ebe6d2439fa12ab4afd0a1e` — Room-$02-Test angepasst

## Erwartetes Resultat

Nach `git pull && ./build.sh` soll Raum $02 weiterhin von Raum $01 aus erreichbar sein. Direkt nach dem Eintritt muss Monty wieder normal laufen und springen koennen. Boden/Collision in Raum $02 muss funktionieren; rechts geht es zurueck nach Raum $01, links bleibt wegen noch nicht portiertem Raum $03 gesperrt. Raum $00/$01 und die Room-$01-Decors duerfen sich nicht veraendern.

## Naechste Portschritte

1. Phase 38a lokal bestaetigen.
2. Danach Room-$02-Decors portieren.
3. Danach Raum $03 vorbereiten und aktivieren.
4. Weitere Raeume entlang der Original-Weltkarte.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
