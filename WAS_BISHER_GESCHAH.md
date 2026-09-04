# Was bisher geschah

Stand: 2026-09-04 — Phase 24

## Portierungsstand

**Gesamtport: ca. 35 %**

Phase 24 ist wieder echter Gameplay-Fortschritt: C64-Fallzustand, horizontale Bewegungs-/Animationssemantik und Sprite-Y-Flush wurden nach der Referenz korrigiert.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Phase 23a baut laut Nutzer.
- Die Basis-Raumgrafik stimmt nun laut Nutzer zunaechst brauchbar mit der C64-Referenz ueberein.
- Monty-Sprite ist sichtbar und in brauchbarer Grundform.
- Verbleibende sichtbare Probleme: keine korrekte Walkanimation, Monty steht etwas ueber dem Boden, Durchgang durch das Mauerloch blockiert.

## Phase 24 — C64-Fallzustand und Walk-Trigger

Die verbindliche `refactored/src/subsystems/monty.asm`-Referenz setzt `monty_is_moving` bei einer akzeptierten Links-/Rechtsbewegung **vor** `ToggleStepGate`. Das ist wichtig: Die horizontale Koordinate aendert sich nur an jedem zweiten Gate-Tick, die Animation gilt aber trotzdem auf jedem akzeptierten Bewegungstick als aktiv.

Der PCE-Port setzte `monty_is_moving` bisher erst nach der tatsaechlichen X-Aenderung. Dadurch bekam `monty_sprite_animate` nur die halbe bzw. unterbrochene Bewegungsinformation und die vier Walkframes liefen nicht wie im C64-Zustandsautomaten. Links und rechts setzen `monty_is_moving` jetzt unmittelbar nach erfolgreicher Collision-Pruefung und vor dem Gate.

## Phase 24 — fehlende Gravitation

Ein groesserer Unterschied war, dass der PCE-Port den C64-Zustand `monty_jumping_flag2` fuer ungestuetztes Fallen praktisch nicht besass. Im Original prueft `UpdateMovement` vor der Eingabeverarbeitung: wenn Monty nicht auf Property-3 steht, keine Jump-Action aktiv ist und `CheckTileBelow` frei meldet, wird ein separater Fallzustand gestartet. Dabei werden horizontale Bewegungen unterdrueckt und Monty wird nach unten bewegt, bis `CheckTileBelow` wieder Kollision meldet.

Der Port hat jetzt `monty_falling` als diesen Zustand. Damit soll Monty nach dem Raumstart bzw. nach Kanten/Lochern automatisch bis zur korrekten Collision-Hoehe absinken, statt auf einer zufaelligen Y-Position stehenzubleiben. Das ist besonders relevant fuer den gemeldeten Abstand zum Boden und fuer den Durchgang durch das Mauerloch, weil die Side-Collision ihre 2/3 vertikalen Samples aus Montys aktueller Y-Position ableitet.

## Phase 24 — Sprite-Y

`Sprites.ProcessSprites` aus der C64-Referenz kopiert `monty_sprite_y2`, fuehrt danach `INX` aus und schreibt erst diesen Wert in den Sprite-3-Y-Puffer. Die PCE-SAT-Bruecke hatte dieses +1 unterschlagen. Der SAT-Y-Wert wurde daher um exakt einen Pixel nach unten korrigiert.

## Noch offen

- Die Phase-24-Aenderungen muessen lokal gebaut und visuell getestet werden.
- Falls die Walkframes trotz korrektem `monty_is_moving` noch falsch aussehen, wird als naechstes die 64-Byte-VIC-Slot->PCE-Frame-Konvertierung frameweise gegen `refactored/src/subsystems/monty_spr.asm` verglichen.
- `CheckTileBelow` Properties 2/3/4 ist noch nicht vollstaendig 1:1; insbesondere Property 4 / `action_counter=5` fehlt noch.
- Room-$00-Decor, Gegner und Spezialobjekte fehlen weiterhin.

## Naechste Portschritte

1. Phase 24 lokal bauen und Bodenposition/Links-Rechts/Walkframes/Mauerloch testen.
2. Falls Animation visuell falsch bleibt: alle 4 Walk-L/R VIC-Slots bytegenau gegen `monty_spr.asm` pruefen und Converter korrigieren.
3. `CheckTileBelow` Properties 2/3/4 exakt portieren.
4. Room-$00-Decor und danach Somersaultframes/generischer Room-Loader.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen danach.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
