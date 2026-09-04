# Was bisher geschah

Stand: 2026-09-04 — Phase 36a bestaetigt

## Portierungsstand

**Gesamtport: ca. 46 %**

Phase 36a ist vom Nutzer lokal bestaetigt. Monty steht wieder korrekt auf dem Boden, bleibt steuerbar und die bestaetigte Bewegungs-/Sprung-/Raumwechsel-Logik funktioniert weiterhin, waehrend die originalen Room-$01-Decors aktiv bleiben.

Damit ist der konkrete Ausloeser der Phase-36-Regressionsserie eingegrenzt: nicht die 800 Byte Decorpattern selbst waren falsch, sondern ihre fruehe Position im Include-/ROM-Layout vor dem Runtime-Bereich. Durch die Verlagerung des grossen Decor-Datenblocks ans ROM-Ende bleibt der bestaetigte Gameplay-/Collision-Bereich stabil.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigter Runtime-Stand

- Monty ist steuerbar.
- Gehen, Springen, Falling und Landung funktionieren.
- Walk/Climb und 12+12 Somersaultframes funktionieren visuell.
- Raum $00 -> $01 links funktioniert beim Gehen und Springen.
- Raum $01 -> $00 rechts funktioniert.
- Raum $00 rechts ist im Original `$ff` und bleibt gesperrt.
- Phase 35 Collision-Mapping bleibt aktiv und funktioniert im bestaetigten Layout.
- Room $01 zeigt wieder die originalen `purple_flowers` und `bunch_flower`.
- Room-$01-Decor verursacht in der Tail-Asset-Platzierung keine Fall-durch-Boden-Regression mehr.

## Phase 36 — Regression durch ROM-Layout

Room $01 besitzt original zwei Decor-Eintraege:

- `$01,$03,$11,$42` -> `purple_flowers`, 4x4 Zeichen
- `$01,$1d,$07,$41` -> `bunch_flower`, 3x3 Zeichen

Die Daten und BAT-Overlays waren korrekt, aber die 800 Byte Decorpattern wurden zunaechst direkt in `src/room01_assets.asm` eingebunden. Diese Datei liegt im Include-Strom vor `monty_physics.asm`, `collision_banking.asm` und weiteren Runtime-Daten. Der reine Grafikblock verschob damit den zuvor bestaetigten Gameplay-/Collision-Bereich im ROM und Monty fiel wieder durch den Boden.

## Phase 36a — grosse banked Assets ans ROM-Ende

Der Decor-Datenblock wurde aus dem fruehen `room01_assets.asm` entfernt und in `src/room01_decor_assets.asm` verschoben. Diese Datei wird in `main.asm` erst nach `monty_sprite.asm` eingebunden.

Damit gilt jetzt:

- die 800 Byte Room-$01-Decorpattern wachsen am ROM-Ende,
- der bestaetigte Physics-/Collision-Code davor wird durch diesen Grafikblock nicht mehr verschoben,
- `room01_upload_decor` bleibt bankfest und referenziert weiterhin `BANK(room01_decor_patterns)`,
- die exakten `purple_flowers`/`bunch_flower`-Daten und BAT-Overlays bleiben unveraendert,
- Room $00 stellt beim Rueckweg weiterhin seine eigenen Decorpatterns wieder her.

`tools/test_room01_decor.py` prueft explizit, dass die grossen Decorpatterns nicht wieder in `room01_assets.asm` landen und dass `room01_decor_assets.asm` im Include-Strom hinter `monty_sprite.asm` liegt.

## Commits Phase 36a

- `892726565aca770a5c275459d4671e14ea02f428` — Room-$01-Decorpatterns aus dem fruehen Assetblock entfernt
- `08a775d72def2434d95fd48dd5ecd35df198b781` — neuer ROM-Tail-Assetblock fuer die 800 Decorbytes
- `241219f653c00fe41a6aff2a845a5679f39e5157` — Tail-Assetblock nach dem Runtime-Code eingebunden
- `f32e6069d14a37221f13e97153b7ee1bc84a2ca6` — Regressionstest fuer die Asset-Platzierung

## Verifikationsstatus

**Phase 36a ist lokal bestaetigt.**

Bestaetigt sind damit gleichzeitig:

1. Start/Boden/Steuerung funktionieren.
2. Springen und Landen funktionieren.
3. Raum $00 <-> $01 funktioniert inklusive Sprungwechsel.
4. Raum $00 rechts bleibt korrekt gesperrt.
5. Room-$01-Decor ist sichtbar und verursacht keine Collision-Regression mehr.

## Technische Konsequenz fuer weitere Assets

Grosse banked Grafik-/Datenbloecke werden ab jetzt nicht mehr unkontrolliert zwischen bereits bestaetigtem Runtime-Code platziert. Sie kommen in klar getrennte Tail-/Banked-Assetbereiche und werden ueber explizite `BANK(...)`-/Mapper-Pfade geladen. Dadurch bleibt der getestete Runtime-Bereich stabil, waehrend der ROM weiter wachsen kann.

## Naechste Portschritte

1. Raum $02 mit exaktem RLE, Tiles, Farben und Tile-Properties portieren.
2. Room-$02-Decors ebenfalls als banked Tail-Assets anbinden.
3. World-/Room-Loader von 2 auf 3 echte Raeume erweitern.
4. Danach weitere Welt-Raeume schrittweise portieren.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
