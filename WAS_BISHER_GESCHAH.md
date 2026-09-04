# Was bisher geschah

Stand: 2026-09-04 — Phase 35

## Portierungsstand

**Gesamtport: ca. 45 %**

Phase 34e ist vom Nutzer lokal im Emulator bestaetigt. Der stabile Runtime-Pfad bleibt intakt: Monty ist steuerbar, Springen und Animationen funktionieren, und die seitlichen Raumwechsel verhalten sich auch waehrend eines Sprungs korrekt.

Phase 35 macht jetzt den direkten Collision-Map-Zugriff gegen HuCard-ROM-Wachstum bankfest, ohne die bestaetigte C64-Physik oder Collision-Semantik umzuschreiben.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigter Runtime-Stand vor Phase 35

- Monty ist steuerbar.
- Gehen, Springen, Falling und Landung funktionieren.
- Walk/Climb und 12+12 Somersaultframes funktionieren visuell.
- Raum $00 -> $01 nach links funktioniert beim Gehen und Springen.
- Raum $01 -> $00 nach rechts funktioniert.
- Rechts neben Raum $00 liegt im Original `$ff`; Heraus-Springen nach rechts ist blockiert.
- Phase 34e ist damit der verbindliche Gameplay-Ausgangspunkt fuer Phase 35.

## Phase 35 — Collision-ROM-Banking bankfest

Die schwere Fall-durch-Boden-Regression trat zuvor immer dann auf, wenn zusaetzlicher Grafik-/Decor-Content das ROM-Layout verschob. Die Physics selbst war dabei unveraendert. Der kritische Pfad sind die direkten Pointer-Lesezugriffe auf `room00_collision_map` bzw. `room01_collision_map`: ihre HuCard-Bank kann sich beim Linken verschieben.

Phase 35 kopiert die Collision-Daten **nicht** in RAM und aendert keine Tile-Properties, Startpositionen, Sprungtabellen oder Collision-Regeln. Stattdessen wird fuer den kurzen Physics-Abschnitt des Mainloops die Bank der aktuell aktiven Collision-Map explizit in MPR3/MPR4 eingeblendet.

Neue Datei `src/collision_banking.asm`:

- speichert die normalen MPR3/MPR4-Werte,
- speichert den HuC-Scratchpointer `_bp`,
- waehlt anhand `monty_room` entweder `BANK(room00_collision_map)` oder `BANK(room01_collision_map)`,
- benutzt denselben bewaehrten `map_bp_to_mpr34`-Mechanismus wie die bereits bankfesten Monty-Sprite- und Room-Uploads,
- laesst die Collision-Bank waehrend `monty_update_input` und `monty_jump_step` aktiv,
- stellt danach MPR3/MPR4 und `_bp` wieder exakt her.

Die IRQs bleiben nur waehrend dieses kurzen temporaeren Mapping-Fensters gesperrt, damit kein Interrupt die voruebergehende MPR3/MPR4-Belegung beobachtet.

`src/monty_physics.asm` selbst wurde in Phase 35 bewusst **nicht** veraendert. Die bestaetigten direkten `[collision_ptr],y`-Reads und die C64-Koordinaten-/Tile-Semantik bleiben gleich.

## Regressionstest

Neu ist `tools/test_collision_banking.py`. Der Test prueft:

- `collision_bank_enter` liegt vor `monty_update_input` und `monty_jump_step`,
- `collision_bank_exit` liegt danach und noch vor `world_resolve_exit`,
- beide Collision-Maps werden ueber ihre echten `BANK(...)`-Werte ausgewaehlt,
- `map_bp_to_mpr34` wird verwendet,
- MPR3/MPR4 sowie `_bp` werden gesichert und restauriert,
- der verworfene `room_collision_map_ram`-Pfad kommt nicht zurueck,
- die bestehende Physics liest weiterhin direkt ueber `collision_ptr`.

`build.sh` fuehrt diesen Test jetzt automatisch mit aus.

Commits Phase 35:

- `f4d1846dcdd80f15746440c570afda7eda9ecae1` — neue bankfeste Collision-Map-MPR-Schicht
- `5e0f208cdd35d5742954ae4654932fb43f0f607d` — Physics-Slice im Mainloop mit Collision-Bank umschlossen
- `26239449a1dc03ee4700f6b3d66e56f8da00b12f` — Regressionstest
- `4714c084cbaa0b086785de9c7f46a53e0298c434` — Regressionstest in `build.sh`

## Erwartetes Resultat

Phase 35 soll **optisch und spielerisch zunaechst nichts veraendern**. Genau das ist der Test: Startposition, Boden, Gehen, Springen, Landen, Animationen und Raum $00 <-> $01 muessen identisch zu der bestaetigten Phase 34e bleiben.

Der technische Gewinn ist danach sichtbar, wenn wieder ROM-Content hinzukommt: Room-$01-Decor oder weitere Raumdaten duerfen die Collision-Map im ROM verschieben, ohne dass Monty wieder durch den Boden faellt oder falsche Tile-Collision bekommt.

Nach lokaler Bestaetigung von Phase 35 wird deshalb als naechster kontrollierter Belastungstest der bereits fertige Room-$01-Decor-Pfad wieder aktiviert. Wenn Monty danach weiter korrekt auf Boden/Plattformen landet, ist der urspruengliche ROM-Wachstumsfehler praktisch beseitigt.

## Verifikationsstatus

Phase 35 ist hochgeladen, aber noch nicht mit dem lokalen PCEAS/Mednafen des Nutzers verifiziert.

Zu pruefen:

1. Build muss ohne neue PCEAS-Fehler durchlaufen.
2. Raum $00: Start, Boden, Gehen, Sprung und Landung unveraendert.
3. Raum $00 -> $01 links: Gehen und Springen funktionieren.
4. Raum $01 -> $00 rechts funktioniert.
5. Raum $00 rechts bleibt gesperrt.

## Naechste Portschritte

1. Phase 35 lokal bestaetigen.
2. Danach Room-$01-Decor als bewussten ROM-Wachstums-Stresstest wieder aktivieren.
3. Wenn Collision stabil bleibt: Raum $02 und weitere Welt-Raeume portieren.
4. Danach Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
