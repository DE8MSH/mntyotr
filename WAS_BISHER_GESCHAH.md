# Was bisher geschah

Stand: 2026-09-04 — Phase 30a

## Portierungsstand

**Gesamtport: ca. 41 %**

Der Nutzer hat Phase 29 visuell bestaetigt. Phase 30 brachte die patterned Decors sichtbar ins Bild, danach trat beim Gehen nach rechts ein neuer Sprite-Grafikfehler auf. Phase 30a behebt diesen Datenzugriff ohne Gameplay-/Physik-Aenderung.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Basis-Raumgrafik stimmt brauchbar.
- Montys Start-/SAT-Position passt weitgehend.
- Gehen, Springen, Falling und Landen auf Plattformen funktionieren.
- Die Hauswandoeffnung in Raum $00 ist passierbar.
- Die 12+12 Somersault-/Jumpframes funktionieren nach dem bankfesten Phase-28e-Loader visuell korrekt.
- Phase-29-Decors sind sichtbar korrekt; Phase 30 zeigt weitere Objekte.

## Phase 30 — patterned Raum-$00-Decor

Die C64-Decor-Engine arbeitet pro Zeichen mit einer Farbe. Phase 30 portiert Type 2 `street_lamp_lamp`, Type 5 `yellow_flower` und Type 6 `brown_flower` inklusive ihrer originalen C64-Farbstroeme. `tools/room00_decor.py` emittiert damit 32 PCE-Decor-Zeichen fuer Types 0..6.

## Phase 30a — Walk/Climb ebenfalls bankfest

Nach dem groesseren Decor-Block meldete der Nutzer neue Grafikfehler beim Gehen nach rechts. Das passt zu einer bereits bekannten strukturellen Schwachstelle: Phase 28e hatte nur die grossen Somersaultframes auf den bankfesten Far-Pointer-Pfad umgestellt. Walk links/rechts und Climb wurden weiterhin per direktem `TIA monty_walk_*` / `TIA monty_climb_*` aus ROM geladen.

Durch weiteres ROM-Wachstum koennen auch diese 512-Byte-Frames an oder ueber einer 8-KiB-HuCard-Bankgrenze liegen. Dann ist ein direkter TIA-Zugriff auf ein Label nicht mehr verlaesslich, obwohl die Daten selbst korrekt sind.

Phase 30a vereinheitlicht deshalb alle Monty-Framefamilien:

- Walk links: 4 Far-Pointer mit `BANK(...)`
- Walk rechts: 4 Far-Pointer mit `BANK(...)`
- Climb: 4 Far-Pointer mit `BANK(...)`
- Somersault links/rechts: weiterhin 12+12 Far-Pointer

Alle benutzen jetzt denselben `monty_upload_far_512`-Pfad mit `map_bp_to_mpr34`. Direkte `TIA monty_walk_*`, `TIA monty_climb_*` und `TIA monty_sault_*` sind aus dem Runtime-Code entfernt.

`tools/test_sprite_banking.py` prueft nun alle fünf Framefamilien und bricht ab, falls eine davon wieder auf direkten TIA-Zugriff zurueckfaellt.

## Verifikationsstatus

- Phase 30a ist hochgeladen, aber noch nicht lokal mit dem Nutzer-PCEAS gebaut.
- Als naechstes `git pull && ./build.sh`.
- Danach Walk links/rechts und Jump links/rechts pruefen; besonders der neu gemeldete Rechtslauf-Grafikfehler sollte verschwunden sein.
- Die neuen Raum-$00-Decors bleiben unveraendert aktiv.

## Naechste Portschritte

1. Phase 30a lokal bauen und Rechtslauf verifizieren.
2. Type `$43` `sad_flowers` mit eindeutig gepinntem Original-Farbstrom nachziehen.
3. Danach generischen Room-Loader und echte Raumwechsel anbinden.
4. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen danach.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
