# Was bisher geschah

Stand: 2026-09-04 — Phase 34

## Portierungsstand

**Gesamtport: ca. 45 %**

Der Stabilitaets-Rollback auf Phase 32b ist vom Nutzer jetzt erneut praktisch bestaetigt: Monty ist steuerbar, Springen funktioniert, die Animationen sind in Ordnung, und der echte Raumwechsel von Raum $00 nach links in Raum $01 funktioniert wieder. Dass Raum $00 nach rechts nicht verlassen werden kann, ist korrekt, weil dort im originalen Weltgitter `$ff` liegt. Damit ist klar: die Physics-/Collision-Regressions aus Phase 33b/33c waren nicht Teil des eigentlichen Mehrraum-Grundstands und bleiben verworfen.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Wieder bestaetigter Runtime-Stand

- Monty startet wieder brauchbar und ist steuerbar.
- Gehen, Springen, Falling und Landung funktionieren wieder im Phase-32b-Pfad.
- Walk/Climb sowie die 12+12 Somersaultframes funktionieren visuell.
- Raum $00 -> $01 nach links funktioniert.
- Raum $01 -> $00 nach rechts war bereits zuvor bestaetigt.
- Rechts neben Raum $00 liegt `$ff`; dort darf kein Raumwechsel stattfinden.

## Phase 33d — Stabilitaets-Rollback

Nach den fehlerhaften Collision-RAM-Experimenten wurde der aktive Runtime-Pfad auf den zuletzt bewaehrten Phase-32b-Code zurueckgesetzt. Insbesondere `monty_physics.asm` blieb danach unveraendert. Der Restore-Commit ist `0bc77d50c66d7766cc1a925cda1237a182396dcd`.

## Phase 34 — Room-$01-Decor erneut, aber strikt vom Gameplay isoliert

Die bereits portierten Original-Decors fuer Raum $01 werden nun erneut aktiviert, diesmal ohne neue Collision-/Physics-Architektur:

- Type `$42` `purple_flowers`, 4x4 Zeichen
- Type `$41` `bunch_flower`, 3x3 Zeichen

`tools/room01_decor.py` erzeugt weiterhin den dekorierten 36x20-BAT und 25 PCE-Decor-Zeichen (800 Byte). `src/room01_assets.asm` bindet nur diesen neuen Grafikblock ein.

Der entscheidende Unterschied zum verworfenen Phase-33-Pfad: der Decor-Upload liegt jetzt in der separaten Datei `src/room01_decor_loader.asm`. `room_loader.asm` selbst bekommt nur einen bank-/reichweitensicheren `call room01_upload_decor`. Die bereits funktionierenden Room-$01-Aufrufe wurden ebenfalls auf `call` statt relatives `bsr` gestellt, damit wachsender Content nicht erneut einen Branch-Range-Fehler erzeugt.

`monty_physics.asm` wird in Phase 34 nicht veraendert. Es gibt keinen Collision-RAM-Cache und keine neue Startpositions-/Sprunglogik.

## Regressionstest

Neu ist `tools/test_phase34_room01_decor_safe.py`. Er prueft explizit:

- der verworfene `room_collision_map_ram`-Pfad ist nicht in der Physics,
- die bekannten direkten Room-$00/Room-$01-Collision-Pfade sind weiter vorhanden,
- Room-$01-Decor ist in einer separaten Upload-Datei,
- Loader-Aufrufe verwenden `call` statt `bsr`,
- der Decor-Upload benutzt den bewaehrten bankfaehigen `map_bp_to_mpr34`-Pfad.

`build.sh` fuehrt sowohl den bestehenden exakten Room-$01-Decor-Test als auch diesen neuen Runtime-Schutztest aus und erzeugt `room01-decor-patterns.dat` direkt im Build-Verzeichnis.

## Verifikationsstatus

Phase 34 ist hochgeladen, aber noch nicht mit dem lokalen PCEAS/Mednafen des Nutzers ausgefuehrt. Der wichtige Ausgangspunkt ist diesmal bestaetigt: Phase 32b funktioniert wieder.

Als naechstes lokal bauen. Danach zuerst kurz pruefen, dass Startposition, Sprung, Landung und Steuerung unveraendert bleiben. Dann nach links in Raum $01 gehen und auf `purple_flowers` sowie `bunch_flower` achten. Anschliessend wieder nach rechts nach Raum $00 zurueckgehen.

## Naechste Portschritte

1. Phase 34 lokal verifizieren: Gameplay muss unveraendert bleiben, Room-$01-Decors muessen sichtbar sein.
2. Danach Raum $02 mit demselben isolierten Daten-/Grafikmuster anbinden.
3. Den Mehrraum-Loader schrittweise verallgemeinern, ohne die bestaetigte Physics erneut umzubauen.
4. Danach Gegner, Mechanismen, Items und HUD/Gameflow portieren.
5. Audio/Musik folgt auf dem stabilen Gameplay-Unterbau.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
