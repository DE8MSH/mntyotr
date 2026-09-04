# Was bisher geschah

Stand: 2026-09-04 — Phase 36a

## Portierungsstand

**Gesamtport: ca. 45 %**

Phase 35 war vom Nutzer lokal bestaetigt: Start, Boden, Gehen, Springen, Landen und Raum $00 <-> $01 funktionierten. Phase 36 aktivierte danach die zwei originalen Room-$01-Decors wieder. Dabei trat sofort erneut die bekannte Regression auf: Monty fiel durch den Boden.

Das ist ein wichtiger Befund: Phase 35 war fuer den unveraenderten ROM-Aufbau zwar spielerisch korrekt, aber das breite MPR3/MPR4-Mapping ueber den gesamten Physics-Slice ist noch kein ausreichender Beweis fuer beliebiges ROM-Wachstum.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Sicher bestaetigter Stand

- Phase 34e/35 ohne Room-$01-Decor funktioniert lokal.
- Monty ist steuerbar; Gehen, Springen, Falling und Landung funktionieren.
- Walk/Climb und 12+12 Somersaultframes funktionieren visuell.
- Raum $00 -> $01 links funktioniert beim Gehen und Springen.
- Raum $01 -> $00 rechts funktioniert.
- Raum $00 rechts ist im Original `$ff` und bleibt gesperrt.

## Phase 36 — Regression durch ROM-Layout

Room $01 besitzt original zwei Decor-Eintraege:

- `$01,$03,$11,$42` -> `purple_flowers`, 4x4 Zeichen
- `$01,$1d,$07,$41` -> `bunch_flower`, 3x3 Zeichen

Die Daten und BAT-Overlays sind exakt und die Python-Tests bestanden. Trotzdem fiel Monty nach Aktivierung der 800 Byte Decorpattern wieder durch den Boden.

Die entscheidende Layout-Aenderung war, dass `room01-decor-patterns.dat` direkt in `src/room01_assets.asm` eingebunden wurde. Diese Datei liegt im Include-Strom **vor** `monty_physics.asm`, `collision_banking.asm` und weiteren Runtime-Daten. Damit verschob der reine Decor-Datenblock den bereits bestaetigten Gameplay-/Collision-Bereich im ROM um 800 Byte.

## Phase 36a — grosse banked Assets ans ROM-Ende

Der Decor-Datenblock wurde deshalb aus dem fruehen `room01_assets.asm` entfernt und in die neue Datei `src/room01_decor_assets.asm` verschoben. Diese Datei wird in `main.asm` erst **nach** `monty_sprite.asm` eingebunden.

Damit gilt jetzt:

- die 800 Byte Room-$01-Decorpattern wachsen am ROM-Ende,
- der bestaetigte Physics-/Collision-Code davor wird durch diesen Grafikblock nicht mehr verschoben,
- `room01_upload_decor` bleibt bankfest und referenziert weiterhin `BANK(room01_decor_patterns)`,
- die exakten `purple_flowers`/`bunch_flower`-Daten und BAT-Overlays bleiben unveraendert,
- Room $00 stellt beim Rueckweg weiterhin seine eigenen Decorpatterns wieder her.

`tools/test_room01_decor.py` prueft jetzt explizit, dass die grossen Decorpatterns **nicht** wieder in `room01_assets.asm` landen und dass `room01_decor_assets.asm` im Include-Strom hinter `monty_sprite.asm` liegt.

## Commits Phase 36a

- `892726565aca770a5c275459d4671e14ea02f428` — Room-$01-Decorpatterns aus dem fruehen Assetblock entfernt
- `08a775d72def2434d95fd48dd5ecd35df198b781` — neuer ROM-Tail-Assetblock fuer die 800 Decorbytes
- `241219f653c00fe41a6aff2a845a5679f39e5157` — Tail-Assetblock nach dem Runtime-Code eingebunden
- `f32e6069d14a37221f13e97153b7ee1bc84a2ca6` — Regressionstest fuer die Asset-Platzierung

## Verifikationsstatus

Phase 36a ist hochgeladen, aber noch nicht lokal mit PCEAS/Mednafen verifiziert.

Erwartetes Resultat: Monty muss wieder wie im bestaetigten Phase-35-Stand auf dem Boden stehen, steuerbar sein und normal springen/landen. Gleichzeitig sollen in Raum $01 `purple_flowers` und `bunch_flower` sichtbar bleiben. Wenn das funktioniert, ist klar, dass der 800-Byte-Block selbst korrekt ist und die vorherige Regression durch seine Position im ROM-Includestrom ausgeloest wurde.

Falls Monty trotz Tail-Platzierung weiter faellt, wird Phase 35 nicht weiter als voll bankfest betrachtet; dann wird das breite Physics-Slice-Mapping verworfen und der Collision-Bankwechsel nur noch um den einzelnen `[collision_ptr],y`-Lesezugriff gelegt.

## Naechste Portschritte

1. Phase 36a lokal testen.
2. Bei stabilem Gameplay Room-$01-Decor bestaetigen.
3. Danach Raum $02 portieren.
4. Falls die Collision erneut faellt: Collision-Banking auf per-read-Mapping umbauen, bevor weiterer Content folgt.
5. Danach Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
