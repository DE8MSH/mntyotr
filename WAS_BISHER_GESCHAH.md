# Was bisher geschah

Stand: 2026-09-04 — Phase 27

## Portierungsstand

**Gesamtport: ca. 37 %**

Phase 27 ersetzt den Phase-26-Hardcode fuer Montys Y-Start durch den echten C64-Unterstuetzungs-/Fallpfad und zieht `CheckTileBelow` fuer die Properties 1/2/3/4 deutlich naeher an `refactored/src`.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Die Basis-Raumgrafik stimmt laut Nutzer brauchbar mit der C64-Referenz ueberein.
- Montys SAT-Position passt inzwischen weitgehend.
- Seitenwand-Collision funktioniert plausibel.
- Phase 26 wurde vom Nutzer bestaetigt: Monty kann durch die Hauswandoeffnung laufen.

## Phase 27 — wieder echter C64-Startwert

Phase 26 startete Monty vorlaeufig direkt bei `Y=$b2`, weil genau dort die C64-Collision nach dem Start stabilen Boden erkennt. Das war als Diagnose richtig, sollte aber kein dauerhafter Ersatz fuer das Originalverhalten bleiben.

Phase 27 setzt deshalb wieder den authentischen Startwert `monty_y=$b0`. Neu ist jetzt ein eigener `monty_falling`-Zustand als Port des C64-Flags `monty_jumping_flag2` fuer ungestuetztes Fallen. Wenn Monty nicht auf einer Property-3-Flaeche steht, keine normale Jump-Action aktiv ist und `CheckTileBelow` frei meldet, wird dieser Zustand gesetzt. Pro Gameplay-Tick wird Monty exakt einen internen Y-Schritt nach unten bewegt, bis `CheckTileBelow` Kollision meldet.

Fuer Raum $00 ergibt sich damit wieder automatisch:

- Start `$86,$b0`
- erster Falltick -> `$b1`
- zweiter Falltick -> `$b2`
- dort meldet `CheckTileBelow` Boden

Die Hauswandoeffnung bleibt dadurch passierbar, ohne dass `$b2` als Startposition fest verdrahtet ist.

## Phase 27 — `CheckTileBelow` Properties 1/2/3/4

Die Implementierung folgt jetzt der dokumentierten C64-Routine aus `refactored/src/subsystems/utils.asm`:

- Property 1 blockiert immer.
- Property 2 und 3 blockieren bei aktiver Jump-Action.
- Im normalen Ground-Zustand blockieren Property 2 und 3 nur, wenn `monty_tile_state` nicht bereits aktiv ist.
- Property 4 zaehlt Treffer separat; der zweite Property-4-Treffer setzt `monty_action_counter=5` und liefert Collision, entsprechend dem originalen Piledriver-/Trap-Pfad.
- Bei nicht auf 8 Pixel ausgerichtetem Y liefert `CheckTileBelow` wie im C64 sofort frei; genau dadurch entstehen die beiden Start-Fallticks von `$b0` nach `$b2`.

`monty_jump_phase` dient im aktuellen Teilport weiterhin als Proxy fuer den originalen `monty_action`-Zustand. Der Piledriver-Dispatcher selbst ist noch nicht portiert, aber `action_counter=5` wird bereits korrekt erzeugt.

## Regressionstests

`tools/test_port.py` prueft jetzt:

- `$b0` und `$b1` unter der Startposition sind noch frei;
- `$b2` ist stabiler Boden;
- der modellierte unsupported-fall-Pfad setzt sich von `$b0` exakt nach `$b2`;
- der Hauseingang bleibt bei `$b2` frei;
- Property 1 blockiert;
- Property 2/3 verhalten sich unterschiedlich je nach Jump-Action und `tile_state`;
- zwei Property-4-Treffer ergeben Collision plus `action_counter=5`.

## Noch offen

- Phase 27 muss lokal gebaut und im Emulator bestaetigt werden.
- Die Walk-L/R-Animationsframes muessen weiterhin visuell endgueltig abgehakt werden.
- Der aktuelle Jump-State ist noch eine vereinfachte Trennung aus `monty_jump_phase` und `monty_falling`; weitere Action-Semantik aus dem C64 folgt.
- Somersaultframes fehlen noch.
- Room-$00-Decor, generischer Room-Loader, Gegner, Mechanismen, Items, HUD/Gameflow und Audio fehlen noch.

## Naechste Portschritte

1. Phase 27 lokal bauen und kontrollieren, dass Monty bei `$b0` startet, sichtbar auf den Boden absinkt und weiterhin durch die Hauswandoeffnung kommt.
2. Walk-L/R-Animation bytegenau finalisieren; keine weiteren heuristischen Framegrenzen.
3. Somersault-L/R (12+12 Frames) und Jump-Animation an den echten C64-Zustandsautomaten anbinden.
4. Room-$00-Decor portieren.
5. Danach generischer Room-Loader, Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
