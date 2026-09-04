# Was bisher geschah

Stand: 2026-09-04 — Phase 34e

## Portierungsstand

**Gesamtport: ca. 44 %**

Der stabile Phase-32b/34a-Runtime-Pfad funktioniert wieder. Monty ist steuerbar, Springen und Animationen sind in Ordnung. Phase 34d blockiert nun den ungueltigen rechten Sprung-Exit aus Raum $00 korrekt. Beim Test wurde aber ein Folgefehler sichtbar: springt Monty aus Raum $00 nach links ueber den echten offenen Ausgang, erscheint der Wechsel nicht dauerhaft; beim normalen Gehen links funktioniert Raum $00 -> $01 korrekt.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Sicher bestaetigter Runtime-Stand

- Monty ist steuerbar.
- Gehen, Springen, Falling und Landung funktionieren im Phase-32b-Pfad.
- Walk/Climb und 12+12 Somersaultframes funktionieren visuell.
- Raum $00 -> $01 nach links funktioniert beim Gehen.
- Raum $01 -> $00 nach rechts funktioniert.
- Rechts neben Raum $00 liegt im Original `$ff`; dort gibt es keinen Zielraum.
- Heraus-Springen rechts aus Raum $00 ist seit Phase 34d blockiert.
- Die Phase-34-Decor-Reaktivierung bleibt verworfen, weil sie die noch nicht bankfeste direkte Collision-Datenadressierung verschiebt.

## Phase 34d — unsupported Side-Exit waehrend Sprung blockiert

Raum $00 rechts und Raum $01 links werden waehrend eines Sprungs als aktuell nicht unterstuetzte Weltseiten abgefangen. Dadurch kann Monty nicht mehr rechts aus Raum $00 heraus-springen, waehrend die echten geladenen Nachbarraeume unangetastet bleiben sollen.

## Phase 34e — echten horizontalen Exit ueber `monty_jump_step` retten

Der neue Test zeigte die eigentliche Ursache des linken Sprungfehlers: `monty_update_input` kann waehrend des Sprungs bereits einen **echten** linken Exit setzen und X auf die Eintrittsposition `$9b` fuer den Zielraum setzen. Direkt danach laeuft `monty_jump_step`. Dessen interner `monty_check_room_edges` beginnt jedoch mit `stz monty_room_exit` und loescht damit den gerade korrekt erzeugten horizontalen Exit wieder. Beim Gehen passiert das nicht, weil kein aktiver Jump-Step den Exit danach ueberschreibt.

Phase 34e speichert deshalb `monty_room_exit` direkt vor `monty_jump_step` in `main_exit_before_jump`. War dort bereits ein echter Exit gesetzt, wird er nach dem Jump-Step wiederhergestellt. Nur wenn **vor** dem Jump-Step kein Exit existierte, darf der bisherige Guard einen rein synthetisch durch die vertikale Sprungbewegung erzeugten Side-Exit verwerfen.

Wichtig: Collision-Map, Tile-Properties, Startposition, Sprungtabellen, World-Grid und Room-Loader werden dabei nicht veraendert.

Commits Phase 34e:

- `f44049d69b1a8f6e2297cdfe7b264c85b9fae592` — echten Side-Exit ueber `monty_jump_step` bewahren
- `8746815830f580559867b6be7eea74f987c28764` — Regressionstest prueft Exit-Preservation

## Verifikationsstatus

Phase 34e ist hochgeladen, aber noch nicht lokal mit PCEAS/Mednafen verifiziert.

Als naechstes `git pull && ./build.sh` und danach pruefen:

1. Raum $00 rechts: springen -> weiterhin kein Heraus-Springen.
2. Raum $00 links: im Sprung ueber den offenen Ausgang -> dauerhaft Raum $01, nicht wieder Raum $00.
3. Raum $00 links: normal gehen -> weiterhin Raum $01.
4. Raum $01 rechts: Rueckweg nach Raum $00.
5. normaler Start, Boden, Sprung und Animationen unveraendert.

## Naechste Portschritte

1. Phase 34e lokal bestaetigen.
2. Danach Collision-ROM-Banking des bestaetigten Pfads exakt analysieren und bankfest machen, ohne Sprung-/Start-/Collision-Semantik umzuschreiben.
3. Erst danach Room-$01-Decor wieder aktivieren.
4. Danach Raum $02 und weitere Welt-Raeume portieren.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
