# Was bisher geschah

Stand: 2026-09-04 — Phase 34d

## Portierungsstand

**Gesamtport: ca. 44 %**

Der stabile Phase-32b/34a-Runtime-Pfad funktioniert wieder. Monty ist steuerbar, Springen und Animationen sind in Ordnung, und Raum $00 -> $01 nach links funktioniert. Nach Phase 34c wurde der neue Jump-Edge-Guard im Emulator getestet: links verhielt sich der Sprung an einer blockierten Seitenkante wie gewuenscht, rechts in Raum $00 jedoch noch nicht symmetrisch.

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

## Phase 34b/34c — erster Jump-Edge-Guard + Branchfix

Phase 34b fing seitliche Exit-Ereignisse ab, die nur durch den vertikalen `monty_jump_step` entstanden. Phase 34c ersetzte den durch `main.asm`-Wachstum zu weit gewordenen `bsr init_c64_video` durch `call init_c64_video`.

Der Emulator-Test zeigte danach: links an einer blockierten Kante funktioniert das Jump-Blocking, rechts in Raum $00 noch nicht.

## Phase 34d — unsupported Side-Exit waehrend Sprung symmetrisch blockieren

Die Asymmetrie kommt daher, dass rechts in Raum $00 die Tile-Collision selbst einen horizontalen Sprungschritt zulassen kann, obwohl die Weltkarte rechts `$ff` enthaelt. Dadurch wird `monty_is_moving` gesetzt; der Phase-34b-Guard fuer rein synthetische Side-Exits greift dann absichtlich nicht.

Phase 34d blockiert deshalb zusaetzlich genau die aktuell nicht unterstuetzten Weltseiten **waehrend eines Sprungs**, noch bevor `monty_jump_step` die bereits gewrappte X-Position als gegenueberliegende Kante missdeuten kann:

- Raum $00, Exit rechts -> X wird auf `$9b` gesetzt, Side-Exit geloescht.
- Raum $01, Exit links -> X wird auf `$15` gesetzt, Side-Exit geloescht, weil Raum $02 noch nicht geladen wird.
- Der echte unterstuetzte Wechsel Raum $00 links -> Raum $01 bleibt unveraendert.
- Der echte Rueckweg Raum $01 rechts -> Raum $00 bleibt unveraendert.
- Collision-Map, Tile-Properties, Startposition und Sprungtabellen bleiben unveraendert.

Commits Phase 34d:

- `3880e3ce7a6b3d113863fbe4450c4133f00352ef` — unsupported Side-Exits beim Springen symmetrisch blockiert
- `9843a9f72fb1c2588723b203b2914a81420ae601` — Regressionstest erweitert

## Verifikationsstatus

Phase 34d ist hochgeladen, aber noch nicht lokal mit PCEAS/Mednafen verifiziert.

Als naechstes `git pull && ./build.sh` und danach pruefen:

1. Raum $00 rechts: an der Seitenkante springen -> kein Heraus-Springen / kein Wrap.
2. Raum $00 links: echter offener Wechsel nach Raum $01 funktioniert weiterhin.
3. Raum $01 rechts: Rueckweg nach Raum $00 funktioniert weiterhin.
4. normaler Start, Boden, Sprung und Animationen bleiben unveraendert.

## Naechste Portschritte

1. Phase 34d lokal bestaetigen.
2. Danach Collision-ROM-Banking des bestaetigten Pfads exakt analysieren und bankfest machen, ohne Sprung-/Start-/Collision-Semantik umzuschreiben.
3. Erst danach Room-$01-Decor wieder aktivieren.
4. Danach Raum $02 und weitere Welt-Raeume portieren.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
