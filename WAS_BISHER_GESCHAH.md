# Was bisher geschah

Stand: 2026-09-04 — Phase 34a

## Portierungsstand

**Gesamtport: ca. 44 %**

Der Nutzer hat den Phase-32b-Runtime-Stand erneut bestaetigt: Monty ist steuerbar, Springen und Animationen funktionieren, und Raum $00 -> $01 nach links funktioniert. Der anschliessende Phase-34-Versuch, Room-$01-Decor wieder zu aktivieren, hat sofort erneut die schwere Boden-/Collision-Regression ausgeloest: Monty faellt durch den Boden.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Sicher bestaetigter Runtime-Stand

- Monty ist steuerbar.
- Gehen, Springen, Falling und Landung funktionieren im Phase-32b-Pfad.
- Walk/Climb und 12+12 Somersaultframes funktionieren visuell.
- Raum $00 -> $01 nach links funktioniert.
- Raum $01 -> $00 nach rechts funktioniert.
- Rechts neben Raum $00 liegt im Original `$ff`; dort gibt es keinen Zielraum.

## Phase 34 — fehlgeschlagener Decor-Reaktivierungsversuch

Room-$01-Decor wurde in einem separaten Loader reaktiviert, ohne `monty_physics.asm` direkt zu veraendern. Trotzdem trat beim Nutzer sofort wieder die Fall-durch-Boden-Regression auf. Damit ist jetzt klar: bereits das zusaetzliche ROM-/Code-/Asset-Layout kann den noch nicht vollständig bankfesten Collision-Pfad verschieben. Es reicht nicht, nur die Physics-Datei unangetastet zu lassen.

## Phase 34a — sofortiger Rollback

Der komplette aktive Phase-34-Pfad wurde wieder auf den zuvor bestaetigten Stand `0bc77d50c66d7766cc1a925cda1237a182396dcd` zurueckgesetzt. Konkret wurden `build.sh`, `src/main.asm`, `src/room01_assets.asm` und `src/room_loader.asm` exakt auf diesen Stand gestellt; `src/room01_decor_loader.asm` und `tools/test_phase34_room01_decor_safe.py` wurden wieder entfernt.

Rollback-Commit: `95f219ccae9f4e3bc6d8058230c6e299e1b032f0`.

Die Room-$01-Decor-Generatoren bleiben als inaktive Referenzdaten im Repository, werden aber nicht mehr in den Build aufgenommen.

## Technische Konsequenz

Vor weiterem Content muss der aktive Collision-Datenzugriff bankfest gemacht werden, ohne die C64-Koordinaten-/Physiksemantik zu veraendern. Der naechste Versuch wird deshalb nicht wieder Decor zuschalten, sondern zuerst den exakt gleichen Phase-32b-Build instrumentieren bzw. die ROM-Adressen/Bank-Zuordnung der Collision-Maps verifizieren. Erst wenn klar ist, warum schon reines ROM-Wachstum die direkten `room00_collision_map`/`room01_collision_map`-Zugriffe bricht, wird neuer Content wieder aktiviert.

## Verifikationsstatus

Phase 34a ist hochgeladen, aber noch nicht lokal mit PCEAS/Mednafen verifiziert. Als naechstes `git pull && ./build.sh` und nur pruefen, ob der wiederhergestellte Phase-32b-Runtime-Stand erneut korrekt laeuft.

## Naechste Portschritte

1. Phase 34a lokal bestaetigen.
2. Collision-ROM-Banking des unveraenderten Phase-32b-Pfads exakt analysieren und bankfest machen, ohne Sprung-/Start-/Collision-Semantik umzuschreiben.
3. Danach Room-$01-Decor erneut aktivieren.
4. Erst danach Raum $02 und weitere Welt-Raeume portieren.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
