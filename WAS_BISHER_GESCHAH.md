# Was bisher geschah

Stand: 2026-09-04 — Phase 26

## Portierungsstand

**Gesamtport: ca. 36 %**

Phase 26 korrigiert einen konkret nachweisbaren Raum-$00-Collision-Fehler am Hauseingang und bringt damit die Bewegungsbasis einen Schritt naeher an das C64-Verhalten.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Die Basis-Raumgrafik stimmt laut Nutzer inzwischen brauchbar mit der C64-Referenz ueberein.
- Phase 25 hat Montys SAT-Position weitgehend an die richtige Stelle gebracht.
- Seitenwand-Collision reagiert grundsaetzlich plausibel.
- Verbleibender Fehler vor Phase 26: Monty konnte nicht durch die sichtbare Oeffnung in der Hauswand laufen.

## Phase 26 — Hauseingang analysiert

Die C64-Referenz startet Montys interne Y-Koordinate bei `$b0`. `UpdateMovement` prueft jedoch sofort `CheckTileBelow`. Da `(Y-$32)&7` bei `$b0` noch nicht ausgerichtet ist, meldet `CheckTileBelow` zunaechst frei und der originale `monty_jumping_flag2`-Fallpfad bewegt Monty pixelweise nach unten.

Fuer Raum $00 laesst sich das exakt aus den originalen RLE- und Tile-Property-Daten nachvollziehen:

- bei `Y=$b0`: unter Monty noch keine ausgerichtete Bodenkollision;
- bei `Y=$b1`: weiterhin keine ausgerichtete Bodenkollision;
- bei `Y=$b2`: `CheckTileBelow` trifft den Boden und Monty steht stabil.

Das ist fuer den Hauseingang entscheidend. Am relevanten X-Bereich um `monty_x=$78` prueft `CheckTileLeft` bei `Y=$b0` drei vertikale Tiles und erwischt dabei noch den soliden Wandstein **oberhalb** der Oeffnung. Bei `Y=$b2` liegen die drei Proben eine Tilezeile tiefer und die Oeffnung ist frei. Damit erklaert sich exakt, warum der PCE-Port trotz optisch korrekter Oeffnung nicht hineinlaufen konnte.

## Implementierung

Der komplette C64-`monty_jumping_flag2`-/Action-Zustandsautomat ist noch nicht portiert. Um nicht erneut einen unvollstaendigen Fall-Proxy einzubauen, startet Raum $00 vorlaeufig direkt auf der deterministischen Post-Settle-Y-Koordinate `$b2` statt `$b0`.

Das ist kein frei erfundener Offset, sondern genau der Zustand, den der C64 nach zwei unsupported-fall-Ticks aus `$b0` erreicht. Sobald `CheckTileBelow`, `monty_action` und `monty_jumping_flag2` vollstaendig 1:1 portiert sind, wird der Initialwert wieder auf `$b0` zurueckgestellt und das echte Fallen uebernimmt diese zwei Pixel automatisch.

## Regressionstest

`tools/test_port.py` prueft jetzt zusaetzlich direkt gegen Raum $00:

- `$86,$b0`: Boden noch frei
- `$86,$b1`: Boden noch frei
- `$86,$b2`: Boden blockiert/stabil
- Hauseingang bei X `$78`, Y `$b0`: linke Seitenkollision trifft die Wand ueber der Oeffnung
- Hauseingang bei X `$78`, Y `$b2`: linke Seitenkollision ist frei

Damit ist der Hauseingang nicht mehr nur visuell, sondern anhand derselben C64-Screen-/Tile-Geometrie als Regression abgedeckt.

## Noch offen

- Phase 26 lokal bauen und Hauseingang testen.
- Walk-L/R-Animationsframes weiter visuell pruefen; der Sprite-Datenpfad ist noch nicht final abgehakt.
- Danach `CheckTileBelow` Properties 1/2/3/4 exakt portieren und den echten `monty_jumping_flag2`-Fallzustand wieder aktivieren.
- Anschliessend Somersaultframes, Room-$00-Decor, generischer Room-Loader, Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
