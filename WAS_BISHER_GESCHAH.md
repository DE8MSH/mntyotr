# Was bisher geschah

Stand: 2026-09-04 — Phase 38

## Portierungsstand

**Gesamtport: ca. 48 %**

Phase 37 ist vom Nutzer lokal bestaetigt: das zusaetzliche Room-$02-ROM-Tail-Wachstum verursacht keine Regression. Start/Boden, Gehen, Springen, Landen, Raum $00 <-> $01 und die Room-$01-Decors laufen weiterhin korrekt.

Phase 38 schaltet Raum $02 jetzt als dritten echten Raum frei.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigter Runtime-Stand vor Phase 38

- Monty ist steuerbar.
- Gehen, Springen, Falling und Landung funktionieren.
- Walk/Climb und 12+12 Somersaultframes funktionieren visuell.
- Raum $00 -> $01 links funktioniert beim Gehen und Springen.
- Raum $01 -> $00 rechts funktioniert.
- Raum $00 rechts ist im Original `$ff` und bleibt gesperrt.
- Room $01 zeigt `purple_flowers` und `bunch_flower`.
- Grosse banked Assets am ROM-Ende verursachen keine Fall-durch-Boden-Regression.
- Phase 37 Room-$02-Tail-Assets sind lokal regressionsfrei bestaetigt.

## Phase 37 — Raum $02 Basisdaten

Room $02 wurde exakt aus der kommentierten C64-Rekonstruktion vorbereitet:

- Tile-IDs: `$02,$01,$27,$60,$3d,$42,$77,$55`
- C64-Farben: `$05,$04,$07,$04,$06,$01,$06,$06`
- Tile-Properties: `1,1,2,3,2,2,0,4`
- exakter RLE-Stream -> 640 Zellen
- 36x20 PCE-BAT mit originaler Border-Spiegelung
- neun Patternslots (blank + acht Custom-Chars)

Die generierten Daten liegen in `src/room02_assets_tail.asm` hinter dem bestaetigten Runtime-Code.

## Phase 38 — Raum $02 aktiv

Die horizontale aktive Raumkette ist jetzt:

`$02 <-> $01 <-> $00`

Dafuer wurden gemeinsam umgestellt:

- `src/monty_physics.asm`: Room-$02-Propertytabelle und direkter `room02_collision_map`-Pfad.
- `src/collision_banking.asm`: `BANK(room02_collision_map)` wird fuer `monty_room == 2` in MPR3/MPR4 eingeblendet.
- `src/world.asm`: Loader-Gate von `<2` auf `<3`; dadurch ist Room `$01 -> $02` links und `$02 -> $01` rechts erlaubt.
- `src/room_loader.asm`: neuer Room-$02-Loader mit bankfestem Patternupload und 36x20-BAT-Copy.
- `src/main.asm`: der Jump-Edge-Guard blockiert nicht mehr Room `$01` links. Stattdessen bleibt jetzt nur Room `$00` rechts (`$ff`) und Room `$02` links (Room `$03` noch nicht portiert) gesperrt.

Die bestehenden Jump-Exit-Sicherungen bleiben aktiv, damit ein echter Raumwechsel waehrend eines Sprungs nicht vom vertikalen Jump-Step geloescht wird.

## Regressionstests

`tools/test_room02.py` prueft jetzt neben den exakten Assets auch die Runtime-Verkabelung: Room-$02-Collision/Properties, Collision-Bank, Loader und World-Gate.

`tools/test_collision_banking.py` prueft nun alle drei aktiven Collision-Maps `$00/$01/$02`.

## Commits Phase 38

- `99c43b6945749eb18f51e901c8cf00f6a839462f` — Room-$02-Collision-Bank
- `3b64806d06959c71ca2bfd82b6f37794ba155203` — Room-$02-Collision/Properties in Physics
- `49736c12cb32ce48be8b73b5c142801879014773` — World-Gate auf drei Raeume
- `14f6e15685a9674e6f371294ba6db47aca619857` — bankfester Room-$02-Loader
- `4fb3c68d34c031b07eef2e8e23f9459ff9330cab` — Jump-Edge-Guard fuer die neue Raumkette
- `b129d1fda5ba152b02f84e4c4b3ef77711eeceae` — Room-$02-Runtime-Regressionstest
- `beb3b9da6e80af8e8217b194834a650aeeb53d84` — Collision-Banking-Test auf drei Raeume erweitert

## Erwartetes Resultat

Nach `git pull && ./build.sh` soll Monty weiterhin korrekt auf dem Boden stehen, laufen, springen und landen. Danach:

1. Raum `$00 -> $01` links wie bisher.
2. In Raum `$01` weiter nach links gehen oder springen -> neuer Raum `$02`.
3. In Raum `$02` nach rechts -> zurueck nach `$01`.
4. Links aus Raum `$02` darf noch kein Wechsel stattfinden, weil Raum `$03` noch nicht aktiv ist.
5. Rechts aus Raum `$00` bleibt gesperrt.
6. Room-$01-Decor und die bisher bestaetigten Animationen bleiben intakt.

Phase 38 ist hochgeladen, aber noch nicht lokal mit dem PCEAS/Mednafen des Nutzers verifiziert.

## Naechste Portschritte

1. Phase 38 lokal bestaetigen.
2. Danach die exakten Room-$02-Decors portieren.
3. Danach Raum $03 vorbereiten/aktivieren.
4. Weitere Raeume schrittweise entlang der Original-Weltkarte.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
