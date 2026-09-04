# Was bisher geschah

Stand: 2026-09-04 — Phase 34b

## Portierungsstand

**Gesamtport: ca. 44 %**

Der Nutzer hat Phase 34a lokal bestaetigt: der wiederhergestellte Phase-32b-Runtime-Pfad funktioniert wieder. Monty ist steuerbar, Springen und Animationen sind in Ordnung, und Raum $00 -> $01 nach links funktioniert. Dabei wurde ein separater Bewegungsfehler gefunden: an seitlichen Bildschirmraendern, die im Gehen durch Collision blockiert sind, konnte Monty durch Springen trotzdem einen Raumwechsel ausloesen.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Sicher bestaetigter Runtime-Stand

- Monty ist steuerbar.
- Gehen, Springen, Falling und Landung funktionieren im Phase-32b-Pfad.
- Walk/Climb und 12+12 Somersaultframes funktionieren visuell.
- Raum $00 -> $01 nach links funktioniert.
- Raum $01 -> $00 nach rechts funktioniert.
- Rechts neben Raum $00 liegt im Original `$ff`; dort gibt es keinen Zielraum.
- Phase 34a Rollback beseitigt erneut die Fall-durch-Boden-Regression.

## Phase 34 — fehlgeschlagener Decor-Reaktivierungsversuch

Room-$01-Decor wurde in einem separaten Loader reaktiviert, ohne `monty_physics.asm` direkt zu veraendern. Trotzdem trat beim Nutzer sofort wieder die Fall-durch-Boden-Regression auf. Damit ist bestaetigt, dass bereits zusaetzliches ROM-/Code-/Asset-Layout den noch nicht vollstaendig bankfesten direkten Collision-Datenpfad beeinflussen kann.

## Phase 34a — sofortiger Rollback

Der komplette aktive Phase-34-Pfad wurde wieder auf den zuvor bestaetigten Stand `0bc77d50c66d7766cc1a925cda1237a182396dcd` zurueckgesetzt. Rollback-Commit: `95f219ccae9f4e3bc6d8058230c6e299e1b032f0`.

Die Room-$01-Decor-Generatoren bleiben nur als inaktive Referenzdaten im Repository und sind nicht Teil des aktuellen ROM-Builds.

## Phase 34b — Sprung darf keine blockierte Seitenkante umgehen

Die Ursache des neuen Randfehlers liegt im aktuellen Ablauf: `monty_update_input` prueft horizontale Collision korrekt. Direkt danach fuehrt `monty_jump_step` jedoch eine rein vertikale Y-Bewegung aus und ruft intern den gemeinsamen `monty_check_room_edges` auf. Dieser Helper prueft zuerst X. Steht Monty waehrend eines Sprungs bereits nahe genug an einer linken/rechten Exit-Schwelle, kann der vertikale Sprungschritt dadurch einen seitlichen Exit setzen, obwohl die horizontale Bewegung im selben Tick durch eine Wand blockiert wurde.

Phase 34b aendert die bestaetigte Collision-Logik selbst nicht. In `src/main.asm` wird direkt vor `monty_jump_step` die X-Position gesichert. Falls der Jump-Step anschliessend einen linken/rechten Exit meldet, obwohl `monty_is_moving` fuer diesen Tick nicht gesetzt wurde, wird dieser synthetische Side-Exit verworfen und die X-Position wiederhergestellt. Ein echter horizontaler Raumwechsel bleibt unangetastet, weil bei tatsaechlicher horizontaler Bewegung `monty_is_moving` gesetzt ist.

Neu ist `tools/test_jump_edge_guard.py`; `build.sh` fuehrt ihn automatisch aus. Der Test stellt sicher, dass der Schutzblock vorhanden bleibt und keine Collision-Map-/Tile-Property-Daten veraendert werden.

Commits Phase 34b:

- `f2a0cce234b36826fa72e56cf385eb060a299fbf` — Side-Exit-Guard im Mainloop
- `f29cd1b2d51b9799db550b86041eb7f8ab23c9bb` — Regressionstest
- `de3da59c6d7d5f33a577dad3f354aea185830143` — Test in `build.sh`

## Verifikationsstatus

Phase 34a ist vom Nutzer bestaetigt. Phase 34b ist hochgeladen, aber noch nicht lokal mit PCEAS/Mednafen verifiziert. Als naechstes `git pull && ./build.sh` und pruefen:

1. normaler Start/Boden/Sprung unveraendert,
2. an einer seitlich blockierten Wand springen: kein Raumwechsel,
3. echter offener Raumwechsel $00 -> $01 nach links muss weiterhin funktionieren.

## Naechste Portschritte

1. Phase 34b lokal bestaetigen.
2. Danach Collision-ROM-Banking des bestaetigten Phase-32b/34b-Pfads exakt analysieren und bankfest machen, ohne Sprung-/Start-/Collision-Semantik umzuschreiben.
3. Erst danach Room-$01-Decor wieder aktivieren.
4. Danach Raum $02 und weitere Welt-Raeume portieren.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
